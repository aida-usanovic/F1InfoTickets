using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace F1Info_Tickets.Model.Responses
{
    public class TeamStandingResponse
    {
        public int TeamID { get; set; }
        public string TeamName { get; set; }
        public string? LogoUrl { get; set; } 
        public double TotalPoints { get; set; }
        public int DriversCount { get; set; }
    }
}
