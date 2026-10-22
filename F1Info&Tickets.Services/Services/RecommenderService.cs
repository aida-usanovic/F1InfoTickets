using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Services.Database;
using F1Info_Tickets.Services.Helpers;
using F1Info_Tickets.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace F1Info_Tickets.Services.Services
{
    // Content-based recommendation of upcoming races. Every candidate race gets a score from three signals:
    //  - similarity: cosine similarity between the race vector (track type, continent, country) and the user profile,
    //    the weighted average of the races the user bought tickets for (1.0) or viewed (0.3 per view, at most 5 views);
    //  - favourites: the best finish of a favourite driver, or of a driver of a favourite team, on the race's circuit;
    //  - popularity: tickets sold for the race compared with the best-selling upcoming race.
    // The reason shown with a race comes from the signal that contributed most to its score, and the ticket type
    // the user buys most often is offered with every recommended race.
    public class RecommenderService : IRecommenderService
    {
        private const double PurchaseWeight = 1.0;
        private const double ViewWeight = 0.3;
        private const int MaxCountedViews = 5;

        private const double SimilarityWeight = 0.6;
        private const double FavoriteWeight = 0.25;
        private const double PopularityWeight = 0.15;

        // Only finishes in the points count for favourites: P1 = 1.0, P2 = 0.9 ... P10 = 0.1.
        private const int ScoredPositions = 10;

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

            var purchases = await _context.Tickets
                .Where(t => t.UserID == userId && t.Status != TicketStatus.Refunded)
                .Select(t => new { t.RaceTicketCategory.RaceID, t.RaceTicketCategory.TicketTypeID })
                .ToListAsync();
            var purchasedRaceIds = purchases.Select(p => p.RaceID).ToHashSet();

            var viewCounts = await _context.RaceViews
                .Where(v => v.UserID == userId)
                .GroupBy(v => v.RaceID)
                .Select(g => new { RaceID = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.RaceID, x => x.Count);

            var historyIds = purchasedRaceIds.Union(viewCounts.Keys).ToList();
            var historyRaces = await _context.Races.IncludeRaceDetails()
                .Where(r => historyIds.Contains(r.RaceID))
                .ToListAsync();

            var features = await BuildFeatureSpaceAsync();
            var profile = BuildProfile(historyRaces, race =>
                (purchasedRaceIds.Contains(race.RaceID) ? PurchaseWeight : 0)
                + ViewWeight * Math.Min(viewCounts.GetValueOrDefault(race.RaceID), MaxCountedViews), features);

            var favoriteFinishes = await LoadFavoriteFinishesAsync(userId);

            var popularity = await _context.Tickets
                .Where(t => t.Status != TicketStatus.Refunded && t.RaceTicketCategory.Race.Date > now)
                .GroupBy(t => t.RaceTicketCategory.RaceID)
                .Select(g => new { RaceID = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.RaceID, x => (double)x.Count);
            var maxPopularity = popularity.Values.DefaultIfEmpty(0).Max();

            // One entry per circuit (the nearest edition), skipping races the user already has tickets for.
            var recommended = upcomingRaces
                .Where(r => !purchasedRaceIds.Contains(r.RaceID))
                .GroupBy(r => r.CircuitID)
                .Select(g => g.OrderBy(r => r.Date).First())
                .Select(race =>
                {
                    var favorite = favoriteFinishes.GetValueOrDefault(race.CircuitID);
                    return new ScoredRace(
                        race,
                        Similarity: profile == null ? 0 : SimilarityWeight * CosineSimilarity(profile.Vector, CreateRaceVector(race, features)),
                        Favorite: FavoriteWeight * (favorite?.Score ?? 0),
                        Popularity: maxPopularity > 0 ? PopularityWeight * popularity.GetValueOrDefault(race.RaceID) / maxPopularity : 0,
                        favorite);
                })
                .OrderByDescending(x => x.Total)
                .ThenBy(x => x.Race.Date)
                .Take(topN)
                .ToList();

            var ticketOffers = await FindPreferredTicketOffersAsync(purchases.Select(p => p.TicketTypeID).ToList(), recommended);

            return recommended.Select(x =>
            {
                var response = _mapper.Map<RaceResponse>(x.Race);
                response.RecommendationReason = BuildReason(x, profile);
                if (ticketOffers.TryGetValue(x.Race.RaceID, out var offer))
                {
                    response.RecommendedTicketTypeID = offer.TicketTypeID;
                    response.RecommendedTicketType = offer.TicketType.Name;
                    response.RecommendedTicketPrice = offer.Price;
                }
                return response;
            }).ToList();
        }

        private record ScoredRace(Race Race, double Similarity, double Favorite, double Popularity, FavoriteFinish? FavoriteFinish)
        {
            public double Total => Similarity + Favorite + Popularity;
        }

        private record FavoriteFinish(string Who, int Position, int Year)
        {
            public double Score => Position <= ScoredPositions ? (ScoredPositions + 1 - Position) / (double)ScoredPositions : 0;
        }

        // Best finish (lowest position) of the user's favourite drivers and of drivers of favourite teams, per circuit.
        private async Task<Dictionary<int, FavoriteFinish>> LoadFavoriteFinishesAsync(int userId)
        {
            var driverIds = await _context.FavoriteDrivers.Where(f => f.UserID == userId).Select(f => f.DriverID).ToListAsync();
            var teamIds = await _context.FavoriteTeams.Where(f => f.UserID == userId).Select(f => f.TeamID).ToListAsync();
            if (!driverIds.Any() && !teamIds.Any())
                return new Dictionary<int, FavoriteFinish>();

            var finishes = await _context.Results
                .Where(r => r.Position <= ScoredPositions && (driverIds.Contains(r.DriverID) || teamIds.Contains(r.TeamID)))
                .Select(r => new
                {
                    r.Race.CircuitID,
                    r.Position,
                    r.Race.Season.Year,
                    r.DriverID,
                    DriverName = r.Driver.FirstName + " " + r.Driver.LastName,
                    r.Team.TeamName
                })
                .ToListAsync();

            return finishes
                .GroupBy(f => f.CircuitID)
                .ToDictionary(g => g.Key, g =>
                {
                    // For an equal position the more recent season is the better story.
                    var best = g.OrderBy(f => f.Position).ThenByDescending(f => f.Year).First();
                    var who = driverIds.Contains(best.DriverID)
                        ? $"Your favourite driver {best.DriverName}"
                        : $"Your favourite team {best.TeamName} ({best.DriverName})";
                    return new FavoriteFinish(who, best.Position, best.Year);
                });
        }

        // The ticket type the user bought most often, offered for each recommended race that still has seats of that type.
        private async Task<Dictionary<int, RaceTicketCategory>> FindPreferredTicketOffersAsync(List<int> purchasedTicketTypeIds, List<ScoredRace> races)
        {
            if (!purchasedTicketTypeIds.Any())
                return new Dictionary<int, RaceTicketCategory>();

            var preferredTypeId = purchasedTicketTypeIds
                .GroupBy(id => id)
                .OrderByDescending(g => g.Count())
                .ThenBy(g => g.Key)
                .First().Key;
            var raceIds = races.Select(r => r.Race.RaceID).ToList();

            var offers = await _context.RaceTicketCategories
                .Include(c => c.TicketType)
                .Where(c => raceIds.Contains(c.RaceID) && c.TicketTypeID == preferredTypeId)
                .Select(c => new { Category = c, Sold = c.Tickets.Count(t => t.Status != TicketStatus.Refunded) })
                .ToListAsync();

            return offers
                .Where(o => o.Sold < o.Category.Capacity)
                .ToDictionary(o => o.Category.RaceID, o => o.Category);
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

        // Weighted average of the history race vectors, plus the track type and continent with the highest
        // weight in it (used for the reason, so it always matches the ranking).
        private record UserProfile(double[] Vector, string? TopTrackType, string? TopContinent);

        private static UserProfile? BuildProfile(List<Race> history, Func<Race, double> weightOf, FeatureSpace features)
        {
            var vector = new double[features.Count];
            var trackTypeWeights = new Dictionary<string, double>();
            var continentWeights = new Dictionary<string, double>();
            double totalWeight = 0;

            foreach (var race in history)
            {
                var weight = weightOf(race);
                if (weight <= 0)
                    continue;
                var raceVector = CreateRaceVector(race, features);
                for (int i = 0; i < vector.Length; i++) vector[i] += weight * raceVector[i];
                totalWeight += weight;

                var trackType = race.Circuit.TrackType.Name;
                var continent = race.Circuit.City.Country.Continent.Name;
                trackTypeWeights[trackType] = trackTypeWeights.GetValueOrDefault(trackType) + weight;
                continentWeights[continent] = continentWeights.GetValueOrDefault(continent) + weight;
            }

            if (totalWeight == 0)
                return null;
            for (int i = 0; i < vector.Length; i++) vector[i] /= totalWeight;

            return new UserProfile(
                vector,
                trackTypeWeights.OrderByDescending(x => x.Value).First().Key,
                continentWeights.OrderByDescending(x => x.Value).First().Key);
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

        // The reason describes the signal with the largest weighted contribution to the race's score.
        private static string BuildReason(ScoredRace scored, UserProfile? profile)
        {
            var strongest = new[] { scored.Similarity, scored.Favorite, scored.Popularity }.Max();
            if (strongest <= 0)
                return "An upcoming race you have not attended yet.";

            if (scored.Favorite == strongest && scored.FavoriteFinish != null)
            {
                var finish = scored.FavoriteFinish;
                return finish.Position == 1
                    ? $"{finish.Who} won here in {finish.Year}."
                    : $"{finish.Who} finished P{finish.Position} here in {finish.Year}.";
            }

            if (scored.Similarity == strongest && profile != null)
            {
                var sameType = scored.Race.Circuit.TrackType.Name == profile.TopTrackType;
                var sameContinent = scored.Race.Circuit.City.Country.Continent.Name == profile.TopContinent;
                if (sameType && sameContinent)
                    return $"You like races on \"{profile.TopTrackType}\" circuits and races in {profile.TopContinent}.";
                if (sameType)
                    return $"Similar to the races you follow: a \"{profile.TopTrackType}\" circuit.";
                if (sameContinent)
                    return $"A race in {profile.TopContinent}, the region you choose most often.";
                return "Similar to the races you viewed and bought tickets for.";
            }

            return "Popular with other fans (most tickets sold).";
        }
    }
}
