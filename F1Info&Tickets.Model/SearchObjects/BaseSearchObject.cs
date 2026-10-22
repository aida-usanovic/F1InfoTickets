using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace F1Info_Tickets.Model.SearchObjects
{
    public class BaseSearchObject : PageRequest
    {
        public string? SearchTerm { get; set; }
    }
}
