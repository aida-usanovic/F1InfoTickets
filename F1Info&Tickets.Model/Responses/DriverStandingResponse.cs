using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace F1Info_Tickets.Model.Responses
{
    public class DriverStandingResponse
    {
        // Championship position in the whole season (not in the searched or paged list).
        public int Position { get; set; }
        public int DriverID { get; set; }
        public string DriverName { get; set; }
        public string? PhotoUrl { get; set; }
        public string TeamName { get; set; }
        public double TotalPoints { get; set; }
        public int RacesCompleted { get; set; }
        public int BestFinish { get; set; }
    }

}
