using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace F1Info_Tickets.Model.Responses
{
    public class ResultResponse
    {
        public int ResultID { get; set; }
        public int RaceID { get; set; }
        public string RaceName { get; set; }
        public int DriverID { get; set; }
        public string DriverName { get; set; }
        public int TeamID { get; set; }
        public string TeamName { get; set; }
        public int Position { get; set; }
        public double Points { get; set; }
        public bool IsFastestLap { get; set; }
        public string TimeTaken { get; set; }
    }
}
