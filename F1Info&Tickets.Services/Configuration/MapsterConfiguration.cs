using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Services.Database;
using Mapster;

namespace F1Info_Tickets.Services.Configuration
{
    // Flattened names for responses; every query that maps these types includes the navigations used here.
    public static class MapsterConfiguration
    {
        public static void Configure()
        {
            var config = TypeAdapterConfig.GlobalSettings;

            config.NewConfig<Circuit, CircuitResponse>()
                .Map(d => d.CityName, s => s.City.Name)
                .Map(d => d.CountryID, s => s.City.CountryID)
                .Map(d => d.CountryName, s => s.City.Country.Name)
                .Map(d => d.ContinentName, s => s.City.Country.Continent.Name)
                .Map(d => d.TrackTypeName, s => s.TrackType.Name);

            config.NewConfig<Race, RaceResponse>()
                .Map(d => d.SeasonYear, s => s.Season.Year)
                .Map(d => d.CircuitName, s => s.Circuit.Name)
                .Map(d => d.Location, s => s.Circuit.City.Name + ", " + s.Circuit.City.Country.Name)
                .Map(d => d.CountryID, s => s.Circuit.City.CountryID)
                .Map(d => d.CountryName, s => s.Circuit.City.Country.Name)
                .Map(d => d.ContinentID, s => s.Circuit.City.Country.ContinentID)
                .Map(d => d.ContinentName, s => s.Circuit.City.Country.Continent.Name)
                .Map(d => d.TrackType, s => s.Circuit.TrackType.Name)
                .Map(d => d.Laps, s => s.Circuit.Laps)
                .Map(d => d.CircuitLength, s => s.Circuit.LengthKm)
                .Map(d => d.ImageUrl, s => s.Circuit.ImageUrl)
                .Map(d => d.MinTicketPrice, s => s.TicketCategories.Any() ? s.TicketCategories.Min(c => c.Price) : (decimal?)null);

            config.NewConfig<RaceTicketCategory, RaceTicketCategoryResponse>()
                .Map(d => d.RaceName, s => s.Race.RaceName)
                .Map(d => d.RaceDate, s => s.Race.Date)
                .Map(d => d.TicketTypeName, s => s.TicketType.Name)
                .Map(d => d.TicketTypeDescription, s => s.TicketType.Description)
                .Map(d => d.Sold, s => s.Tickets.Count(t => t.Status != TicketStatus.Refunded));

            config.NewConfig<Ticket, TicketResponse>()
                .Map(d => d.Username, s => s.User.Username)
                .Map(d => d.CustomerName, s => s.User.FirstName + " " + s.User.LastName)
                .Map(d => d.RaceID, s => s.RaceTicketCategory.RaceID)
                .Map(d => d.RaceName, s => s.RaceTicketCategory.Race.RaceName)
                .Map(d => d.RaceDate, s => s.RaceTicketCategory.Race.Date)
                .Map(d => d.CircuitName, s => s.RaceTicketCategory.Race.Circuit.Name)
                .Map(d => d.TicketType, s => s.RaceTicketCategory.TicketType.Name)
                .Map(d => d.PaymentMethod, s => s.Payment.PaymentMethod)
                .Map(d => d.PaymentStatus, s => s.Payment.Status)
                .Map(d => d.RefundedAt, s => s.Payment.RefundedAt)
                .Map(d => d.Status, s => s.Status.ToString());

            config.NewConfig<Driver, DriverResponse>()
                .Map(d => d.Nationality, s => s.Country.Name);

            config.NewConfig<Team, TeamResponse>()
                .Map(d => d.BaseCityName, s => s.BaseCity.Name)
                .Map(d => d.CountryID, s => s.BaseCity.CountryID)
                .Map(d => d.Country, s => s.BaseCity.Country.Name);

            config.NewConfig<Result, ResultResponse>()
                .Map(d => d.RaceName, s => s.Race.RaceName)
                .Map(d => d.DriverName, s => s.Driver.FirstName + " " + s.Driver.LastName)
                .Map(d => d.TeamName, s => s.Team.TeamName);

            config.NewConfig<Country, CountryResponse>()
                .Map(d => d.ContinentName, s => s.Continent.Name);

            config.NewConfig<User, UserResponse>()
                .Map(d => d.RoleID, s => s.UserRoles.Select(ur => ur.RoleID).FirstOrDefault())
                .Map(d => d.RoleName, s => s.UserRoles.Select(ur => ur.Role.Name).FirstOrDefault());

            config.NewConfig<Role, RoleResponse>()
                .Map(d => d.IsSystemRole, s => Roles.IsSystemRole(s.Name));

            config.NewConfig<City, CityResponse>()
                .Map(d => d.CountryName, s => s.Country.Name);
        }
    }
}
