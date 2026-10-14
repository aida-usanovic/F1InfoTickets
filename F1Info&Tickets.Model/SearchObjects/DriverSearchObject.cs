using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace F1Info_Tickets.Model.SearchObjects
{
    public class DriverSearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public int? SeasonId { get; set; }
    }
}
