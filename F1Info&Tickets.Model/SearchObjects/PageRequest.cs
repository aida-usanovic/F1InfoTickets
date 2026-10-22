namespace F1Info_Tickets.Model.SearchObjects
{
    // Query parameters for paged lists: ?page=1&pageSize=10 (at most MaxPageSize items per page).
    public class PageRequest
    {
        public const int MaxPageSize = 100;

        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }
}
