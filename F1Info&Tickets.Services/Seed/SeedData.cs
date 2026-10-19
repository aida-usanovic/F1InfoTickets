using F1Info_Tickets.Services.Database;
using F1Info_Tickets.Services.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace F1Info_Tickets.Services.Seed
{
    public static class SeedData
    {
        private const int AdminRoleId = 2;
        private const int UserRoleId = 1;
        private const string DefaultPassword = "test";

        public static async Task InitializeAsync(ApplicationDbContext context)
        {
            await context.Database.MigrateAsync();

            var hasher = new PasswordHasher<User>();

            // Required logins; the password is reset on every start so it always matches the README.
            var desktop = await EnsureUserAsync(context, hasher, "desktop", "Desktop", "Admin", "desktop@f1tickets.ba", "+38761000001", new DateTime(1990, 5, 12));
            await EnsureUserRoleAsync(context, desktop.UserID, AdminRoleId);
            var mobile = await EnsureUserAsync(context, hasher, "mobile", "Mobile", "User", "mobile@f1tickets.ba", "+38761000002", new DateTime(1998, 3, 24));
            await EnsureUserRoleAsync(context, mobile.UserID, UserRoleId);

            if (await context.Continents.AnyAsync())
            {
                await AddMissingWorldCountriesAsync(context);
                return;
            }

            var random = new Random(2025);
            var reference = await SeedReferenceDataAsync(context);
            var teams = await SeedTeamsAsync(context, reference);
            var drivers = await SeedDriversAsync(context, reference);
            var circuits = await SeedCircuitsAsync(context, reference);
            var races = await SeedRacesAsync(context, circuits);
            await SeedLineupsAsync(context, teams, drivers);
            await SeedResultsAsync(context, races, random);
            await SeedTicketCategoriesAsync(context, races, reference);
            var customers = await SeedCustomersAsync(context, hasher, mobile);
            await SeedCustomerActivityAsync(context, customers, races, drivers, teams, random);
        }

        // Databases seeded before the full country list only had the countries used by races and teams.
        // Runs once: after that the admin manages countries, so deleted ones are not re-added.
        private static async Task AddMissingWorldCountriesAsync(ApplicationDbContext context)
        {
            if (await context.Countries.CountAsync() >= 100)
                return;

            var codes = (await context.Countries.Select(c => c.Code).ToListAsync()).ToHashSet(StringComparer.OrdinalIgnoreCase);
            var names = (await context.Countries.Select(c => c.Name).ToListAsync()).ToHashSet(StringComparer.OrdinalIgnoreCase);
            var continents = await context.Continents.ToDictionaryAsync(c => c.Name, StringComparer.OrdinalIgnoreCase);

            foreach (var (code, name, continent) in WorldCountries.All)
            {
                if (codes.Contains(code) || names.Contains(name) || !continents.TryGetValue(continent, out var c))
                    continue;
                context.Countries.Add(new Country { Code = code, Name = name, Continent = c });
            }
            await context.SaveChangesAsync();
        }

        private record ReferenceData(
            Dictionary<string, Country> Countries,
            Dictionary<string, City> Cities,
            Dictionary<string, TrackType> TrackTypes,
            Dictionary<string, TicketType> TicketTypes);

        private record CustomerSeed(User User, string PreferredTrackType, string PreferredContinent);

        private static async Task<ReferenceData> SeedReferenceDataAsync(ApplicationDbContext context)
        {
            var continents = new[] { "Europe", "Asia", "North America", "South America", "Oceania", "Africa" }
                .ToDictionary(n => n, n => new Continent { Name = n });
            context.Continents.AddRange(continents.Values);

            var countries = WorldCountries.All.ToDictionary(c => c.Code, c => new Country { Code = c.Code, Name = c.Name, Continent = continents[c.Continent] });
            context.Countries.AddRange(countries.Values);

            var cityData = new (string Name, string Country)[]
            {
                ("Melbourne", "AUS"), ("Shanghai", "CHN"), ("Suzuka", "JPN"), ("Sakhir", "BHR"), ("Jeddah", "SAU"),
                ("Miami", "USA"), ("Imola", "ITA"), ("Monte Carlo", "MCO"), ("Barcelona", "ESP"), ("Montreal", "CAN"),
                ("Spielberg", "AUT"), ("Silverstone", "GBR"), ("Stavelot", "BEL"), ("Budapest", "HUN"), ("Zandvoort", "NLD"),
                ("Monza", "ITA"), ("Baku", "AZE"), ("Singapore", "SGP"), ("Austin", "USA"), ("Mexico City", "MEX"),
                ("São Paulo", "BRA"), ("Las Vegas", "USA"), ("Lusail", "QAT"), ("Abu Dhabi", "ARE"),
                ("Woking", "GBR"), ("Milton Keynes", "GBR"), ("Brackley", "GBR"), ("Enstone", "GBR"), ("Grove", "GBR"),
                ("Maranello", "ITA"), ("Faenza", "ITA"), ("Hinwil", "CHE"), ("Kannapolis", "USA"),
                ("Sarajevo", "BIH"), ("Mostar", "BIH"), ("Kyalami", "ZAF")
            };
            var cities = cityData.ToDictionary(c => c.Name, c => new City { Name = c.Name, Country = countries[c.Country] });
            context.Cities.AddRange(cities.Values);

            var trackTypes = new[]
            {
                new TrackType { Name = "Street", Description = "Temporary circuit on city streets, narrow and with little run-off." },
                new TrackType { Name = "High-speed", Description = "Long straights and fast corners with high average speeds." },
                new TrackType { Name = "Technical", Description = "Many slow and medium-speed corners where handling matters most." }
            }.ToDictionary(t => t.Name);
            context.TrackTypes.AddRange(trackTypes.Values);

            var ticketTypes = new[]
            {
                new TicketType { Name = "General Admission", Description = "Trackside access without a reserved seat." },
                new TicketType { Name = "Grandstand", Description = "Reserved grandstand seat overlooking a key part of the circuit." },
                new TicketType { Name = "Hospitality", Description = "VIP lounge, food and drinks, pit lane access and the best view." }
            }.ToDictionary(t => t.Name);
            context.TicketTypes.AddRange(ticketTypes.Values);

            await context.SaveChangesAsync();
            return new ReferenceData(countries, cities, trackTypes, ticketTypes);
        }

        private static async Task<Dictionary<string, Team>> SeedTeamsAsync(ApplicationDbContext context, ReferenceData reference)
        {
            var teamData = new (string Name, string Base, string Principal, string? Logo)[]
            {
                ("McLaren", "Woking", "Andrea Stella", null),
                ("Ferrari", "Maranello", "Frédéric Vasseur", "/Images/Teams/ferrari.png"),
                ("Red Bull Racing", "Milton Keynes", "Laurent Mekies", "/Images/Teams/redbull.jpg"),
                ("Mercedes", "Brackley", "Toto Wolff", "/Images/Teams/mercedes.png"),
                ("Aston Martin", "Silverstone", "Andy Cowell", null),
                ("Alpine", "Enstone", "Flavio Briatore", null),
                ("Williams", "Grove", "James Vowles", null),
                ("Racing Bulls", "Faenza", "Alan Permane", null),
                ("Kick Sauber", "Hinwil", "Jonathan Wheatley", null),
                ("Haas", "Kannapolis", "Ayao Komatsu", null)
            };

            var teams = teamData.ToDictionary(t => t.Name, t => new Team
            {
                TeamName = t.Name,
                BaseCity = reference.Cities[t.Base],
                TeamPrincipal = t.Principal,
                LogoUrl = t.Logo
            });
            context.Teams.AddRange(teams.Values);
            await context.SaveChangesAsync();
            return teams;
        }

        private record DriverSeed(Driver Driver, string Team);

        private static async Task<List<DriverSeed>> SeedDriversAsync(ApplicationDbContext context, ReferenceData reference)
        {
            var photos = new HashSet<string> { "antonelli", "hamilton", "leclerc", "norris", "piastri", "russell", "tsunoda", "verstappen" };
            var driverData = new (string First, string Last, int Number, string Country, DateTime Born, string Team, bool Reserve)[]
            {
                ("Lando", "Norris", 4, "GBR", new DateTime(1999, 11, 13), "McLaren", false),
                ("Oscar", "Piastri", 81, "AUS", new DateTime(2001, 4, 6), "McLaren", false),
                ("Charles", "Leclerc", 16, "MCO", new DateTime(1997, 10, 16), "Ferrari", false),
                ("Lewis", "Hamilton", 44, "GBR", new DateTime(1985, 1, 7), "Ferrari", false),
                ("Max", "Verstappen", 1, "NLD", new DateTime(1997, 9, 30), "Red Bull Racing", false),
                ("Yuki", "Tsunoda", 22, "JPN", new DateTime(2000, 5, 11), "Red Bull Racing", false),
                ("George", "Russell", 63, "GBR", new DateTime(1998, 2, 15), "Mercedes", false),
                ("Andrea Kimi", "Antonelli", 12, "ITA", new DateTime(2006, 8, 25), "Mercedes", false),
                ("Fernando", "Alonso", 14, "ESP", new DateTime(1981, 7, 29), "Aston Martin", false),
                ("Lance", "Stroll", 18, "CAN", new DateTime(1998, 10, 29), "Aston Martin", false),
                ("Pierre", "Gasly", 10, "FRA", new DateTime(1996, 2, 7), "Alpine", false),
                ("Franco", "Colapinto", 43, "ARG", new DateTime(2003, 5, 27), "Alpine", false),
                ("Alexander", "Albon", 23, "THA", new DateTime(1996, 3, 23), "Williams", false),
                ("Carlos", "Sainz", 55, "ESP", new DateTime(1994, 9, 1), "Williams", false),
                ("Liam", "Lawson", 30, "NZL", new DateTime(2002, 2, 11), "Racing Bulls", false),
                ("Isack", "Hadjar", 6, "FRA", new DateTime(2004, 9, 28), "Racing Bulls", false),
                ("Nico", "Hülkenberg", 27, "DEU", new DateTime(1987, 8, 19), "Kick Sauber", false),
                ("Gabriel", "Bortoleto", 5, "BRA", new DateTime(2004, 10, 14), "Kick Sauber", false),
                ("Esteban", "Ocon", 31, "FRA", new DateTime(1996, 9, 17), "Haas", false),
                ("Oliver", "Bearman", 87, "GBR", new DateTime(2005, 5, 8), "Haas", false),
                ("Valtteri", "Bottas", 77, "FIN", new DateTime(1989, 8, 28), "Mercedes", true),
                ("Zhou", "Guanyu", 24, "CHN", new DateTime(1999, 5, 30), "Ferrari", true),
                ("Jack", "Doohan", 7, "AUS", new DateTime(2003, 1, 20), "Alpine", true)
            };

            var drivers = driverData.Select(d => new DriverSeed(new Driver
            {
                FirstName = d.First,
                LastName = d.Last,
                Number = d.Number,
                Country = reference.Countries[d.Country],
                BirthDate = d.Born,
                IsReserveDriver = d.Reserve,
                PhotoUrl = photos.Contains(d.Last.ToLowerInvariant()) ? $"/Images/Drivers/{d.Last.ToLowerInvariant()}.png" : null
            }, d.Team)).ToList();

            context.Drivers.AddRange(drivers.Select(d => d.Driver));
            await context.SaveChangesAsync();
            return drivers;
        }

        private static async Task<List<Circuit>> SeedCircuitsAsync(ApplicationDbContext context, ReferenceData reference)
        {
            // Calendar order; also used as the order of the races in every season.
            var circuitData = new (string Name, string City, string Type, int Laps, double Length)[]
            {
                ("Albert Park Circuit", "Melbourne", "Street", 58, 5.278),
                ("Shanghai International Circuit", "Shanghai", "Technical", 56, 5.451),
                ("Suzuka Circuit", "Suzuka", "Technical", 53, 5.807),
                ("Bahrain International Circuit", "Sakhir", "High-speed", 57, 5.412),
                ("Jeddah Corniche Circuit", "Jeddah", "Street", 50, 6.174),
                ("Miami International Autodrome", "Miami", "Street", 57, 5.412),
                ("Autodromo Enzo e Dino Ferrari", "Imola", "Technical", 63, 4.909),
                ("Circuit de Monaco", "Monte Carlo", "Street", 78, 3.337),
                ("Circuit de Barcelona-Catalunya", "Barcelona", "Technical", 66, 4.657),
                ("Circuit Gilles Villeneuve", "Montreal", "Street", 70, 4.361),
                ("Red Bull Ring", "Spielberg", "High-speed", 71, 4.318),
                ("Silverstone Circuit", "Silverstone", "High-speed", 52, 5.891),
                ("Circuit de Spa-Francorchamps", "Stavelot", "High-speed", 44, 7.004),
                ("Hungaroring", "Budapest", "Technical", 70, 4.381),
                ("Circuit Zandvoort", "Zandvoort", "Technical", 72, 4.259),
                ("Autodromo Nazionale Monza", "Monza", "High-speed", 53, 5.793),
                ("Baku City Circuit", "Baku", "Street", 51, 6.003),
                ("Marina Bay Street Circuit", "Singapore", "Street", 62, 4.940),
                ("Circuit of the Americas", "Austin", "Technical", 56, 5.513),
                ("Autódromo Hermanos Rodríguez", "Mexico City", "High-speed", 71, 4.304),
                ("Autódromo José Carlos Pace", "São Paulo", "Technical", 71, 4.309),
                ("Las Vegas Strip Circuit", "Las Vegas", "Street", 50, 6.201),
                ("Lusail International Circuit", "Lusail", "High-speed", 57, 5.419),
                ("Yas Marina Circuit", "Abu Dhabi", "Technical", 58, 5.281)
            };

            var circuits = circuitData.Select(c => new Circuit
            {
                Name = c.Name,
                City = reference.Cities[c.City],
                TrackType = reference.TrackTypes[c.Type],
                Laps = c.Laps,
                LengthKm = c.Length
            }).ToList();

            context.Circuits.AddRange(circuits);
            await context.SaveChangesAsync();
            return circuits;
        }

        private static async Task<List<Race>> SeedRacesAsync(ApplicationDbContext context, List<Circuit> circuits)
        {
            var raceNames = new[]
            {
                "Australian Grand Prix", "Chinese Grand Prix", "Japanese Grand Prix", "Bahrain Grand Prix",
                "Saudi Arabian Grand Prix", "Miami Grand Prix", "Emilia Romagna Grand Prix", "Monaco Grand Prix",
                "Spanish Grand Prix", "Canadian Grand Prix", "Austrian Grand Prix", "British Grand Prix",
                "Belgian Grand Prix", "Hungarian Grand Prix", "Dutch Grand Prix", "Italian Grand Prix",
                "Azerbaijan Grand Prix", "Singapore Grand Prix", "United States Grand Prix", "Mexico City Grand Prix",
                "São Paulo Grand Prix", "Las Vegas Grand Prix", "Qatar Grand Prix", "Abu Dhabi Grand Prix"
            };

            // Three real calendars around the first start: last season (finished), the current one
            // (partly finished) and the next one (all upcoming), so there are always results and tickets to buy.
            var now = DateTime.UtcNow;
            var races = new List<Race>();
            foreach (var year in new[] { now.Year - 1, now.Year, now.Year + 1 })
            {
                var season = new Season { Year = year, Description = $"FIA Formula One World Championship {year}" };
                context.Seasons.Add(season);
                var opening = new DateTime(year, 3, 8, 14, 0, 0, DateTimeKind.Utc);
                for (int i = 0; i < circuits.Count; i++)
                {
                    races.Add(new Race
                    {
                        RaceName = raceNames[i],
                        Circuit = circuits[i],
                        Date = opening.AddDays(i * 12),
                        Season = season
                    });
                }
            }

            // The latest finished race happened yesterday and has no results yet, so the admin can enter them (48h rule).
            var latest = races.Where(r => r.Date < now).OrderByDescending(r => r.Date).First();
            latest.Date = now.Date.AddDays(-1).AddHours(14);

            context.Races.AddRange(races);
            await context.SaveChangesAsync();
            return races;
        }

        private static async Task SeedLineupsAsync(ApplicationDbContext context, Dictionary<string, Team> teams, List<DriverSeed> drivers)
        {
            foreach (var season in await context.Seasons.ToListAsync())
            {
                foreach (var d in drivers)
                {
                    context.TeamDrivers.Add(new TeamDriver { Team = teams[d.Team], Driver = d.Driver, Season = season });
                }
            }
            await context.SaveChangesAsync();
        }

        private static async Task SeedResultsAsync(ApplicationDbContext context, List<Race> races, Random random)
        {
            var strength = new Dictionary<string, double>
            {
                ["McLaren"] = 10, ["Ferrari"] = 8.5, ["Mercedes"] = 8.5, ["Red Bull Racing"] = 8.5, ["Williams"] = 5.5,
                ["Racing Bulls"] = 5, ["Aston Martin"] = 4.5, ["Haas"] = 4.5, ["Kick Sauber"] = 4, ["Alpine"] = 3.5
            };

            var lineups = await context.TeamDrivers
                .Include(td => td.Team)
                .Include(td => td.Driver)
                .Where(td => !td.Driver.IsReserveDriver)
                .ToListAsync();

            var yesterday = DateTime.UtcNow.AddDays(-2);
            foreach (var race in races.Where(r => r.Date < yesterday))
            {
                var order = lineups
                    .Where(td => td.SeasonID == race.SeasonID)
                    .Select(td => new { td.DriverID, td.TeamID, Score = strength[td.Team.TeamName] + random.NextDouble() * 7 })
                    .OrderByDescending(x => x.Score)
                    .ToList();

                var fastestLap = random.Next(1, 11);
                var raceTime = 5100 + random.NextDouble() * 900;
                for (int p = 0; p < order.Count; p++)
                {
                    if (p > 0) raceTime += 0.5 + random.NextDouble() * 8.5;
                    var position = p + 1;
                    context.Results.Add(new Result
                    {
                        RaceID = race.RaceID,
                        DriverID = order[p].DriverID,
                        TeamID = order[p].TeamID,
                        Position = position,
                        Points = ResultService.CalculatePoints(position),
                        IsFastestLap = position == fastestLap,
                        TimeTaken = TimeSpan.FromSeconds(raceTime).ToString(@"h\:mm\:ss\.fff")
                    });
                }
            }
            await context.SaveChangesAsync();
        }

        private static async Task SeedTicketCategoriesAsync(ApplicationDbContext context, List<Race> races, ReferenceData reference)
        {
            var premium = new HashSet<string> { "Circuit de Monaco", "Las Vegas Strip Circuit", "Yas Marina Circuit", "Marina Bay Street Circuit" };
            foreach (var race in races)
            {
                var basePrice = premium.Contains(race.Circuit.Name) ? 190m : 90m + (race.CircuitID % 5) * 20m;
                context.RaceTicketCategories.AddRange(
                    new RaceTicketCategory { RaceID = race.RaceID, TicketType = reference.TicketTypes["General Admission"], Price = basePrice, Capacity = 400 },
                    new RaceTicketCategory { RaceID = race.RaceID, TicketType = reference.TicketTypes["Grandstand"], Price = Math.Round(basePrice * 2.5m), Capacity = 150 },
                    new RaceTicketCategory { RaceID = race.RaceID, TicketType = reference.TicketTypes["Hospitality"], Price = Math.Round(basePrice * 9m), Capacity = 30 });
            }
            await context.SaveChangesAsync();
        }

        private static async Task<List<CustomerSeed>> SeedCustomersAsync(ApplicationDbContext context, PasswordHasher<User> hasher, User mobile)
        {
            var customerData = new (string Username, string First, string Last, DateTime Born, string Track, string Continent)[]
            {
                ("amina.hodzic", "Amina", "Hodžić", new DateTime(1995, 4, 18), "Street", "Europe"),
                ("emir.begic", "Emir", "Begić", new DateTime(1992, 9, 2), "High-speed", "Europe"),
                ("lejla.kovac", "Lejla", "Kovač", new DateTime(2000, 1, 27), "Technical", "Asia"),
                ("tarik.mehic", "Tarik", "Mehić", new DateTime(1988, 6, 11), "High-speed", "North America"),
                ("sara.husic", "Sara", "Husić", new DateTime(1997, 12, 5), "Street", "Asia"),
                ("kenan.delic", "Kenan", "Delić", new DateTime(1994, 3, 30), "Technical", "Europe"),
                ("ajla.basic", "Ajla", "Bašić", new DateTime(2001, 8, 14), "Street", "North America"),
                ("haris.omerovic", "Haris", "Omerović", new DateTime(1985, 11, 22), "High-speed", "Asia"),
                ("ivana.peric", "Ivana", "Perić", new DateTime(1999, 7, 8), "Technical", "South America"),
                ("marko.jovic", "Marko", "Jović", new DateTime(1993, 2, 16), "High-speed", "Oceania")
            };

            var customers = new List<CustomerSeed> { new(mobile, "Street", "Europe") };
            int phone = 3;
            foreach (var c in customerData)
            {
                var user = new User
                {
                    Username = c.Username,
                    FirstName = c.First,
                    LastName = c.Last,
                    Email = $"{c.Username}@example.com",
                    Phone = $"+3876100000{phone++:D2}",
                    BirthDate = c.Born,
                    UserRoles = new List<UserRole> { new() { RoleID = UserRoleId } }
                };
                user.PasswordHash = hasher.HashPassword(user, DefaultPassword);
                context.Users.Add(user);
                customers.Add(new CustomerSeed(user, c.Track, c.Continent));
            }
            await context.SaveChangesAsync();
            return customers;
        }

        private static async Task SeedCustomerActivityAsync(ApplicationDbContext context, List<CustomerSeed> customers,
            List<Race> races, List<DriverSeed> drivers, Dictionary<string, Team> teams, Random random)
        {
            var now = DateTime.UtcNow;
            var raceDetails = await context.Races
                .Include(r => r.Circuit).ThenInclude(c => c.TrackType)
                .Include(r => r.Circuit).ThenInclude(c => c.City).ThenInclude(c => c.Country).ThenInclude(c => c.Continent)
                .Include(r => r.TicketCategories).ThenInclude(c => c.TicketType)
                .ToListAsync();
            var teamList = teams.Values.ToList();
            var mainDrivers = drivers.Where(d => !d.Driver.IsReserveDriver).Select(d => d.Driver).ToList();
            int transaction = 1;

            foreach (var customer in customers)
            {
                bool Matches(Race r) => r.Circuit.TrackType.Name == customer.PreferredTrackType
                    || r.Circuit.City.Country.Continent.Name == customer.PreferredContinent;
                Race PickRace(IList<Race> pool)
                {
                    var preferred = pool.Where(Matches).ToList();
                    var source = preferred.Any() && random.NextDouble() < 0.8 ? preferred : pool;
                    return source[random.Next(source.Count)];
                }

                // Purchases: a few finished races (tickets already used) and one or two upcoming ones.
                var past = raceDetails.Where(r => r.Date < now).ToList();
                var upcoming = raceDetails.Where(r => r.Date > now).ToList();
                var bought = new HashSet<int>();
                int purchases = 3 + random.Next(3);
                for (int p = 0; p < purchases; p++)
                {
                    var race = PickRace(p < purchases - 2 ? past : upcoming);
                    if (!bought.Add(race.RaceID)) continue;

                    var roll = random.NextDouble();
                    var typeName = roll < 0.6 ? "General Admission" : roll < 0.9 ? "Grandstand" : "Hospitality";
                    var category = race.TicketCategories.First(c => c.TicketType.Name == typeName);
                    var quantity = typeName == "Hospitality" ? 1 : 1 + random.Next(3);
                    var purchaseDate = race.Date < now
                        ? race.Date.AddDays(-10 - random.Next(50))
                        : now.AddDays(-1 - random.Next(40));

                    var payment = new Payment
                    {
                        UserID = customer.User.UserID,
                        Amount = category.Price * quantity,
                        Currency = "EUR",
                        PaymentMethod = "PayPal",
                        PayPalTransactionID = $"SEED-{transaction++:D5}",
                        Status = "COMPLETED",
                        PaymentDate = purchaseDate
                    };
                    context.Payments.Add(payment);

                    for (int q = 0; q < quantity; q++)
                    {
                        context.Tickets.Add(new Ticket
                        {
                            UserID = customer.User.UserID,
                            RaceTicketCategoryID = category.RaceTicketCategoryID,
                            Payment = payment,
                            Price = category.Price,
                            PurchaseDate = purchaseDate,
                            QRCode = Guid.NewGuid().ToString("N"),
                            Status = race.Date < now ? TicketStatus.Used : TicketStatus.Active
                        });
                    }

                    context.Notifications.Add(new Notification
                    {
                        UserID = customer.User.UserID,
                        Title = "Purchase successful",
                        Message = $"You bought {quantity} x {typeName} for {race.RaceName}. Your QR tickets are in your profile.",
                        CreatedAt = purchaseDate,
                        IsRead = race.Date < now
                    });
                }

                // Browsing history for the recommender, mostly races that match the customer's taste.
                int views = 8 + random.Next(12);
                for (int v = 0; v < views; v++)
                {
                    context.RaceViews.Add(new RaceView
                    {
                        UserID = customer.User.UserID,
                        RaceID = PickRace(raceDetails).RaceID,
                        ViewedAt = now.AddDays(-random.Next(90)).AddMinutes(-random.Next(1440))
                    });
                }

                foreach (var driver in mainDrivers.OrderBy(_ => random.Next()).Take(1 + random.Next(2)))
                    context.FavoriteDrivers.Add(new FavoriteDriver { UserID = customer.User.UserID, DriverID = driver.DriverID, CreatedAt = now.AddDays(-random.Next(200)) });
                context.FavoriteTeams.Add(new FavoriteTeam { UserID = customer.User.UserID, TeamID = teamList[random.Next(teamList.Count)].TeamID, CreatedAt = now.AddDays(-random.Next(200)) });

                var lastFinished = raceDetails.Where(r => r.Date < now.AddDays(-2)).OrderByDescending(r => r.Date).First();
                context.Notifications.Add(new Notification
                {
                    UserID = customer.User.UserID,
                    Title = "Results published",
                    Message = $"The results of {lastFinished.RaceName} are available in the app.",
                    CreatedAt = lastFinished.Date.AddHours(3),
                    IsRead = random.NextDouble() < 0.5
                });
            }

            // A few customers already have something waiting in the cart.
            foreach (var customer in customers.Take(3))
            {
                var race = raceDetails.Where(r => r.Date > now).OrderBy(r => r.Date).Skip(customers.IndexOf(customer) + 1).First();
                context.Carts.Add(new Cart
                {
                    UserID = customer.User.UserID,
                    CreatedAt = now,
                    CartItems =
                    {
                        new CartItem
                        {
                            RaceTicketCategoryID = race.TicketCategories.First(c => c.TicketType.Name == "General Admission").RaceTicketCategoryID,
                            Quantity = 2,
                            AddedAt = now
                        }
                    }
                });
            }

            await context.SaveChangesAsync();
        }

        private static async Task<User> EnsureUserAsync(ApplicationDbContext context, PasswordHasher<User> hasher,
            string username, string firstName, string lastName, string email, string phone, DateTime birthDate)
        {
            var user = await context.Users.FirstOrDefaultAsync(u => u.Username == username);

            if (user == null)
            {
                user = new User
                {
                    Username = username,
                    FirstName = firstName,
                    LastName = lastName,
                    Email = email,
                    Phone = phone,
                    BirthDate = birthDate
                };
                context.Users.Add(user);
            }

            user.PasswordHash = hasher.HashPassword(user, DefaultPassword);
            await context.SaveChangesAsync();
            return user;
        }

        private static async Task EnsureUserRoleAsync(ApplicationDbContext context, int userId, int roleId)
        {
            var otherRoles = await context.UserRoles
                .Where(ur => ur.UserID == userId && ur.RoleID != roleId)
                .ToListAsync();
            context.UserRoles.RemoveRange(otherRoles);

            if (!await context.UserRoles.AnyAsync(ur => ur.UserID == userId && ur.RoleID == roleId))
                context.UserRoles.Add(new UserRole { UserID = userId, RoleID = roleId });

            await context.SaveChangesAsync();
        }
    }
}
