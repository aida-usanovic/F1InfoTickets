using F1Info_Tickets.Model.Messaging;
using F1Info_Tickets.Services.Database;
using System.Globalization;
using System.Net;
using System.Text;

namespace F1Info_Tickets.Services.Helpers
{
    public static class EmailTemplates
    {
        public record TicketLine(string RaceName, DateTime RaceDate, string TicketType, decimal Price, string QRCode);

        public static EmailMessage Purchase(User user, IReadOnlyList<TicketLine> tickets, decimal total, string currency)
        {
            var rows = new StringBuilder();
            foreach (var t in tickets)
            {
                rows.Append($"<tr><td>{E(t.RaceName)}</td><td>{t.RaceDate:d MMM yyyy}</td><td>{E(t.TicketType)}</td>" +
                            $"<td>{Money(t.Price)} {currency}</td><td><code>{E(t.QRCode)}</code></td></tr>");
            }

            return new EmailMessage
            {
                ToEmail = user.Email,
                ToName = $"{user.FirstName} {user.LastName}",
                Subject = "F1 Info & Tickets - purchase confirmation",
                HtmlBody = $@"<h3>Hello {E(user.FirstName)},</h3>
<p>Thank you for your purchase. Your tickets ({tickets.Count}) are ready in your app profile.</p>
<table border=""1"" cellpadding=""6"" cellspacing=""0"">
<tr><th>Race</th><th>Date</th><th>Type</th><th>Price</th><th>QR code</th></tr>
{rows}
</table>
<p><b>Total paid:</b> {Money(total)} {currency}</p>"
            };
        }

        public static EmailMessage ResultsPublished(User user, string raceName, IReadOnlyList<string> podium)
        {
            var list = string.Join("", podium.Select((name, i) => $"<li>{i + 1}. {E(name)}</li>"));
            return new EmailMessage
            {
                ToEmail = user.Email,
                ToName = $"{user.FirstName} {user.LastName}",
                Subject = $"Results: {raceName}",
                HtmlBody = $@"<h3>Hello {E(user.FirstName)},</h3>
<p>The results of <b>{E(raceName)}</b> have been published.</p>
<ol style=""list-style:none;padding-left:0"">{list}</ol>
<p>See the full classification in the F1 Info &amp; Tickets app.</p>"
            };
        }

        private static string E(string value) => WebUtility.HtmlEncode(value);
        private static string Money(decimal value) => value.ToString("F2", CultureInfo.InvariantCulture);
    }
}
