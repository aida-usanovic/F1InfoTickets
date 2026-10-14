namespace F1Info_Tickets.Model.Dtos
{
    public class UserActivityDto
    {
        public int TotalUsersRegistered { get; set; }
        public int ActiveBuyers { get; set; }
        public int TotalTicketsPurchased { get; set; }
        public decimal TotalRevenue { get; set; }
        public int RaceViews { get; set; }
        public List<CustomerActivityDto> TopCustomers { get; set; } = new();
    }

    public class CustomerActivityDto
    {
        public string Username { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public int TicketsPurchased { get; set; }
        public decimal TotalSpent { get; set; }
        public DateTime? LastPurchase { get; set; }
        public int RaceViews { get; set; }
    }
}
