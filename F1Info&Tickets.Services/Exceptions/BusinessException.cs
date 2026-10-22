using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace F1Info_Tickets.Services.Exceptions
{
    public class BusinessException : Exception
    {
        public BusinessException(string message) : base(message) { }

        // Request field the error belongs to (e.g. "Image"), so the client can show it under that field.
        public BusinessException(string field, string message) : base(message)
        {
            Field = field;
        }

        public string? Field { get; }
    }
}
