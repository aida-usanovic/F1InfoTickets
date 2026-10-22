using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace F1Info_Tickets.Model.Responses
{
    public class TeamStandingResponse
    {
        // Championship position in the whole season (not in the searched or paged list).
        public int Position { get; set; }
        public int TeamID { get; set; }
        public string TeamName { get; set; }
        public string? LogoUrl { get; set; } 
        public double TotalPoints { get; set; }
        public int DriversCount { get; set; }
    }
}
