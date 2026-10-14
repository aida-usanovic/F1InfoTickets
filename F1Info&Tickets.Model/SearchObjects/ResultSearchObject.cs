using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace F1Info_Tickets.Model.SearchObjects
{
    public class ResultSearchObject : BaseSearchObject
    {
        public int? RaceID { get; set; }
        public int? DriverID { get; set; }
        public int? Position { get; set; }
    }
}
