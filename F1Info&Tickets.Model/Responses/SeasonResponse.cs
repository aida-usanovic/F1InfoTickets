using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace F1Info_Tickets.Model.Responses
{
    public class SeasonResponse
    {
        public int SeasonID { get; set; }
        public int Year { get; set; }
        public string Description { get; set; }
    }
}
