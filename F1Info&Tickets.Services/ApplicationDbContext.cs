using F1Info_Tickets.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace F1Info_Tickets.Services
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options) { }

        // Reference data
        public DbSet<Continent> Continents { get; set; }
        public DbSet<Country> Countries { get; set; }
        public DbSet<City> Cities { get; set; }
        public DbSet<TrackType> TrackTypes { get; set; }
        public DbSet<TicketType> TicketTypes { get; set; }
        public DbSet<Season> Seasons { get; set; }
        public DbSet<Role> Roles { get; set; }
        public DbSet<UserRole> UserRoles { get; set; }

        // Core data
        public DbSet<User> Users { get; set; }
        public DbSet<Team> Teams { get; set; }
        public DbSet<Driver> Drivers { get; set; }
        public DbSet<TeamDriver> TeamDrivers { get; set; }
        public DbSet<Circuit> Circuits { get; set; }
        public DbSet<Race> Races { get; set; }
        public DbSet<Result> Results { get; set; }
        public DbSet<RaceTicketCategory> RaceTicketCategories { get; set; }
        public DbSet<Payment> Payments { get; set; }
        public DbSet<Ticket> Tickets { get; set; }
        public DbSet<Cart> Carts { get; set; }
        public DbSet<CartItem> CartItems { get; set; }
        public DbSet<RaceView> RaceViews { get; set; }
        public DbSet<FavoriteDriver> FavoriteDrivers { get; set; }
        public DbSet<FavoriteTeam> FavoriteTeams { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<RevokedToken> RevokedTokens { get; set; }
        public DbSet<PasswordResetCode> PasswordResetCodes { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // Deleting a record that other data depends on must fail instead of silently wiping history.
            foreach (var fk in modelBuilder.Model.GetEntityTypes().SelectMany(e => e.GetForeignKeys()))
            {
                fk.DeleteBehavior = DeleteBehavior.Restrict;
            }

            // Data that only belongs to its owner goes away with it.
            modelBuilder.Entity<UserRole>().HasOne(x => x.User).WithMany(u => u.UserRoles).HasForeignKey(x => x.UserID).OnDelete(DeleteBehavior.Cascade);
            modelBuilder.Entity<Cart>().HasOne(x => x.User).WithOne(u => u.Cart).HasForeignKey<Cart>(x => x.UserID).OnDelete(DeleteBehavior.Cascade);
            modelBuilder.Entity<CartItem>().HasOne(x => x.Cart).WithMany(c => c.CartItems).HasForeignKey(x => x.CartID).OnDelete(DeleteBehavior.Cascade);
            modelBuilder.Entity<CartItem>().HasOne(x => x.RaceTicketCategory).WithMany().HasForeignKey(x => x.RaceTicketCategoryID).OnDelete(DeleteBehavior.Cascade);
            modelBuilder.Entity<RaceView>().HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserID).OnDelete(DeleteBehavior.Cascade);
            modelBuilder.Entity<RaceView>().HasOne(x => x.Race).WithMany(r => r.Views).HasForeignKey(x => x.RaceID).OnDelete(DeleteBehavior.Cascade);
            modelBuilder.Entity<FavoriteDriver>().HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserID).OnDelete(DeleteBehavior.Cascade);
            modelBuilder.Entity<FavoriteDriver>().HasOne(x => x.Driver).WithMany().HasForeignKey(x => x.DriverID).OnDelete(DeleteBehavior.Cascade);
            modelBuilder.Entity<FavoriteTeam>().HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserID).OnDelete(DeleteBehavior.Cascade);
            modelBuilder.Entity<FavoriteTeam>().HasOne(x => x.Team).WithMany().HasForeignKey(x => x.TeamID).OnDelete(DeleteBehavior.Cascade);
            modelBuilder.Entity<Notification>().HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserID).OnDelete(DeleteBehavior.Cascade);
            modelBuilder.Entity<PasswordResetCode>().HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserID).OnDelete(DeleteBehavior.Cascade);
            modelBuilder.Entity<PasswordResetCode>().HasIndex(x => new { x.UserID, x.ExpiresAt });
            modelBuilder.Entity<TeamDriver>().HasOne(x => x.Team).WithMany(t => t.TeamDrivers).HasForeignKey(x => x.TeamID).OnDelete(DeleteBehavior.Cascade);
            modelBuilder.Entity<TeamDriver>().HasOne(x => x.Driver).WithMany(d => d.TeamDrivers).HasForeignKey(x => x.DriverID).OnDelete(DeleteBehavior.Cascade);
            modelBuilder.Entity<RaceTicketCategory>().HasOne(x => x.Race).WithMany(r => r.TicketCategories).HasForeignKey(x => x.RaceID).OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Payment>().Property(p => p.Amount).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<Ticket>().Property(t => t.Price).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<RaceTicketCategory>().Property(t => t.Price).HasColumnType("decimal(18,2)");

            modelBuilder.Entity<Role>().HasData(
                new Role { RoleID = 1, Name = "User" },
                new Role { RoleID = 2, Name = "Admin" }
            );

            modelBuilder.Entity<User>().HasIndex(u => u.Username).IsUnique();
            modelBuilder.Entity<User>().HasIndex(u => u.Email).IsUnique();
            modelBuilder.Entity<UserRole>().HasIndex(ur => new { ur.UserID, ur.RoleID }).IsUnique();
            modelBuilder.Entity<Role>().HasIndex(r => r.Name).IsUnique();
            modelBuilder.Entity<Continent>().HasIndex(x => x.Name).IsUnique();
            modelBuilder.Entity<Country>().HasIndex(x => x.Name).IsUnique();
            modelBuilder.Entity<City>().HasIndex(x => new { x.CountryID, x.Name }).IsUnique();
            modelBuilder.Entity<TrackType>().HasIndex(x => x.Name).IsUnique();
            modelBuilder.Entity<TicketType>().HasIndex(x => x.Name).IsUnique();
            modelBuilder.Entity<Season>().HasIndex(x => x.Year).IsUnique();
            modelBuilder.Entity<TeamDriver>().HasIndex(td => new { td.DriverID, td.SeasonID }).IsUnique();
            modelBuilder.Entity<Result>().HasIndex(r => new { r.RaceID, r.DriverID }).IsUnique();
            modelBuilder.Entity<Result>().HasIndex(r => new { r.RaceID, r.Position }).IsUnique();
            modelBuilder.Entity<RaceTicketCategory>().HasIndex(c => new { c.RaceID, c.TicketTypeID }).IsUnique();
            modelBuilder.Entity<Ticket>().HasIndex(t => t.QRCode).IsUnique();
            modelBuilder.Entity<Payment>().HasIndex(p => p.PayPalTransactionID).IsUnique();
            modelBuilder.Entity<CartItem>().HasIndex(ci => new { ci.CartID, ci.RaceTicketCategoryID }).IsUnique();
            modelBuilder.Entity<FavoriteDriver>().HasIndex(f => new { f.UserID, f.DriverID }).IsUnique();
            modelBuilder.Entity<FavoriteTeam>().HasIndex(f => new { f.UserID, f.TeamID }).IsUnique();
        }
    }
}
