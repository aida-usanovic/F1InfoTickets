using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Services.Database;
using F1Info_Tickets.Services.Helpers;
using F1Info_Tickets.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace F1Info_Tickets.Services.Services
{
    // Content-based filtering: races are described by track type, continent and country;
    // the user profile is the weighted average of races the user bought tickets for or viewed.
    public class RecommenderService : IRecommenderService
    {
        private const double PurchaseWeight = 1.0;
        private const double ViewWeight = 0.3;
        private const double SimilarityWeight = 0.8;
        private const double PopularityWeight = 0.2;

        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;

        public RecommenderService(ApplicationDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<List<RaceResponse>> GetRecommendationsAsync(int userId, int topN = 5)
        {
            var now = DateTime.UtcNow;
            var upcomingRaces = await _context.Races.IncludeRaceDetails()
                .Where(r => r.Date > now)
                .ToListAsync();

            if (!upcomingRaces.Any())
                return new List<RaceResponse>();

            var purchasedRaceIds = await _context.Tickets
                .Where(t => t.UserID == userId && t.Status != TicketStatus.Refunded)
                .Select(t => t.RaceTicketCategory.RaceID)
                .Distinct()
                .ToListAsync();

            var viewCounts = await _context.RaceViews
                .Where(v => v.UserID == userId)
                .GroupBy(v => v.RaceID)
                .Select(g => new { RaceID = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.RaceID, x => x.Count);

            var historyIds = purchasedRaceIds.Union(viewCounts.Keys).ToList();
            var historyRaces = await _context.Races.IncludeRaceDetails()
                .Where(r => historyIds.Contains(r.RaceID))
                .ToListAsync();

            var popularity = await _context.Tickets
                .Where(t => t.Status != TicketStatus.Refunded && t.RaceTicketCategory.Race.Date > now)
                .GroupBy(t => t.RaceTicketCategory.RaceID)
                .Select(g => new { RaceID = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.RaceID, x => (double)x.Count);
            var maxPopularity = popularity.Values.DefaultIfEmpty(0).Max();
            double PopularityOf(Race r) => maxPopularity > 0 ? popularity.GetValueOrDefault(r.RaceID) / maxPopularity : 0;

            // One entry per circuit (the nearest edition), skipping races the user already has tickets for.
            var candidates = upcomingRaces
                .Where(r => !purchasedRaceIds.Contains(r.RaceID))
                .GroupBy(r => r.CircuitID)
                .Select(g => g.OrderBy(r => r.Date).First())
                .ToList();

            if (!historyRaces.Any())
            {
                return candidates
                    .OrderByDescending(PopularityOf)
                    .ThenBy(r => r.Date)
                    .Take(topN)
                    .Select(r => ToResponse(r, "Popular with other fans (most tickets sold)."))
                    .ToList();
            }

            var features = await BuildFeatureSpaceAsync();
            var userVector = new double[features.Count];
            double totalWeight = 0;
            foreach (var race in historyRaces)
            {
                var weight = (purchasedRaceIds.Contains(race.RaceID) ? PurchaseWeight : 0)
                    + ViewWeight * Math.Min(viewCounts.GetValueOrDefault(race.RaceID), 5);
                var vector = CreateRaceVector(race, features);
                for (int i = 0; i < vector.Length; i++) userVector[i] += weight * vector[i];
                totalWeight += weight;
            }
            if (totalWeight > 0)
                for (int i = 0; i < userVector.Length; i++) userVector[i] /= totalWeight;

            var topTrackType = historyRaces.GroupBy(r => r.Circuit.TrackType.Name).OrderByDescending(g => g.Count()).First().Key;
            var topContinent = historyRaces.GroupBy(r => r.Circuit.City.Country.Continent.Name).OrderByDescending(g => g.Count()).First().Key;

            return candidates
                .Select(r => new
                {
                    Race = r,
                    Similarity = CosineSimilarity(userVector, CreateRaceVector(r, features)),
                    Popularity = PopularityOf(r)
                })
                .OrderByDescending(x => SimilarityWeight * x.Similarity + PopularityWeight * x.Popularity)
                .ThenBy(x => x.Race.Date)
                .Take(topN)
                .Select(x => ToResponse(x.Race, BuildReason(x.Race, topTrackType, topContinent)))
                .ToList();
        }

        private record FeatureSpace(Dictionary<int, int> TrackTypes, Dictionary<int, int> Continents, Dictionary<int, int> Countries)
        {
            public int Count => TrackTypes.Count + Continents.Count + Countries.Count;
        }

        private async Task<FeatureSpace> BuildFeatureSpaceAsync()
        {
            var trackTypes = await _context.TrackTypes.Select(t => t.TrackTypeID).OrderBy(x => x).ToListAsync();
            var continents = await _context.Continents.Select(c => c.ContinentID).OrderBy(x => x).ToListAsync();
            var countries = await _context.Countries.Select(c => c.CountryID).OrderBy(x => x).ToListAsync();

            int index = 0;
            return new FeatureSpace(
                trackTypes.ToDictionary(id => id, _ => index++),
                continents.ToDictionary(id => id, _ => index++),
                countries.ToDictionary(id => id, _ => index++));
        }

        // Track type and continent carry most of the signal; the exact country is a weaker hint.
        private static double[] CreateRaceVector(Race race, FeatureSpace features)
        {
            var vector = new double[features.Count];
            if (features.TrackTypes.TryGetValue(race.Circuit.TrackTypeID, out var t)) vector[t] = 1.0;
            if (features.Continents.TryGetValue(race.Circuit.City.Country.ContinentID, out var c)) vector[c] = 1.0;
            if (features.Countries.TryGetValue(race.Circuit.City.CountryID, out var k)) vector[k] = 0.5;
            return vector;
        }

        private static double CosineSimilarity(double[] a, double[] b)
        {
            double dot = 0, magA = 0, magB = 0;
            for (int i = 0; i < a.Length; i++)
            {
                dot += a[i] * b[i];
                magA += a[i] * a[i];
                magB += b[i] * b[i];
            }
            return magA == 0 || magB == 0 ? 0 : dot / (Math.Sqrt(magA) * Math.Sqrt(magB));
        }

        private static string BuildReason(Race race, string topTrackType, string topContinent)
        {
            var sameType = race.Circuit.TrackType.Name == topTrackType;
            var sameContinent = race.Circuit.City.Country.Continent.Name == topContinent;
            if (sameType && sameContinent)
                return $"You like races on \"{topTrackType}\" circuits and races in {topContinent}.";
            if (sameType)
                return $"Similar to the races you follow: a \"{topTrackType}\" circuit.";
            if (sameContinent)
                return $"A race in {topContinent}, the region you choose most often.";
            return "A popular upcoming race you have not attended yet.";
        }

        private RaceResponse ToResponse(Race race, string reason)
        {
            var response = _mapper.Map<RaceResponse>(race);
            response.RecommendationReason = reason;
            return response;
        }
    }
}
