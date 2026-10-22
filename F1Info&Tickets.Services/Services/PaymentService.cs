using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Services.Configuration;
using F1Info_Tickets.Services.Database;
using F1Info_Tickets.Services.Exceptions;
using F1Info_Tickets.Services.Helpers;
using F1Info_Tickets.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System.Globalization;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;

namespace F1Info_Tickets.Services.Services
{
    public class PaymentService : IPaymentService
    {
        private const string StatusPending = "PENDING";
        private const string StatusCompleted = "COMPLETED";
        private const string StatusRefunded = "REFUNDED";

        private readonly ApplicationDbContext _context;
        private readonly PayPalSettings _settings;
        private readonly HttpClient _httpClient;
        private readonly IMessageProducer _messageProducer;
        private readonly ILogger<PaymentService> _logger;

        public PaymentService(ApplicationDbContext context, IOptions<PayPalSettings> options, HttpClient httpClient, IMessageProducer messageProducer, ILogger<PaymentService> logger)
        {
            _context = context;
            _settings = options.Value;
            _httpClient = httpClient;
            _messageProducer = messageProducer;
            _logger = logger;
        }

        private string BaseUrl => _settings.Mode == "live" ? "https://api-m.paypal.com" : "https://api-m.sandbox.paypal.com";

        private async Task<string> GetPayPalAccessToken()
        {
            var auth = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{_settings.ClientId}:{_settings.Secret}"));
            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", auth);

            var content = new StringContent("grant_type=client_credentials", Encoding.UTF8, "application/x-www-form-urlencoded");
            var response = await _httpClient.PostAsync($"{BaseUrl}/v1/oauth2/token", content);

            if (!response.IsSuccessStatusCode) throw new BusinessException("Connecting to PayPal failed. Please try again.");

            var json = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(json);
            return doc.RootElement.GetProperty("access_token").GetString()!;
        }

        public async Task<PaymentResponse> CreatePayPalOrderAsync(PaymentCreateRequest request, int userId)
        {
            var items = await LoadCartItemsAsync(userId);
            await EnsureItemsAvailableAsync(items);
            var amount = items.Sum(i => i.RaceTicketCategory.Price * i.Quantity);

            var token = await GetPayPalAccessToken();
            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

            var orderRequest = new
            {
                intent = "CAPTURE",
                purchase_units = new[]
                {
                    new
                    {
                        description = "F1 Info & Tickets - race tickets",
                        amount = new { currency_code = _settings.Currency, value = FormatAmount(amount) }
                    }
                },
                application_context = new
                {
                    brand_name = "F1 Info & Tickets",
                    user_action = "PAY_NOW",
                    return_url = request.ReturnUrl,
                    cancel_url = string.IsNullOrWhiteSpace(request.CancelUrl) ? request.ReturnUrl : request.CancelUrl
                }
            };

            var response = await _httpClient.PostAsJsonAsync($"{BaseUrl}/v2/checkout/orders", orderRequest);
            if (!response.IsSuccessStatusCode)
                await ThrowPayPalErrorAsync(response, "Creating the PayPal order failed. Please try again.");

            var json = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(json);

            var orderId = doc.RootElement.GetProperty("id").GetString()!;
            var approvalUrl = doc.RootElement.GetProperty("links").EnumerateArray()
                .Where(l => l.GetProperty("rel").GetString() is "approve" or "payer-action")
                .Select(l => l.GetProperty("href").GetString())
                .FirstOrDefault() ?? throw new BusinessException("PayPal did not return a payment approval link.");

            var payment = new Payment
            {
                UserID = userId,
                Amount = amount,
                Currency = _settings.Currency,
                PaymentMethod = "PayPal",
                PayPalTransactionID = orderId,
                Status = StatusPending,
                PaymentDate = DateTime.UtcNow
            };

            _context.Payments.Add(payment);
            await _context.SaveChangesAsync();

            return new PaymentResponse
            {
                PaymentID = payment.PaymentID,
                ProviderOrderId = orderId,
                ApprovalUrl = approvalUrl,
                Status = StatusPending
            };
        }

        // Logs PayPal's error body and turns the known issue codes into a message the customer can act on.
        private async Task ThrowPayPalErrorAsync(HttpResponseMessage response, string fallbackMessage)
        {
            var body = await response.Content.ReadAsStringAsync();
            _logger.LogWarning("PayPal request {Url} failed with {Status}: {Body}", response.RequestMessage?.RequestUri, (int)response.StatusCode, body);

            var issue = string.Empty;
            try
            {
                using var doc = JsonDocument.Parse(body);
                if (doc.RootElement.TryGetProperty("details", out var details) && details.ValueKind == JsonValueKind.Array)
                    issue = details.EnumerateArray().Select(d => d.TryGetProperty("issue", out var i) ? i.GetString() : null).FirstOrDefault(i => i != null) ?? string.Empty;
            }
            catch (JsonException)
            {
                // Not a PayPal JSON error; the fallback message is used.
            }

            throw new BusinessException(issue switch
            {
                "COMPLIANCE_VIOLATION" => "PayPal declined the payment for compliance reasons (the PayPal account's country does not allow this transaction). Use a PayPal sandbox account registered in another country, e.g. the US.",
                "INSTRUMENT_DECLINED" => "PayPal declined the selected payment method. Start the payment again and choose another one.",
                "ORDER_NOT_APPROVED" or "PAYER_ACTION_REQUIRED" => "The payment was not approved in PayPal. Start the payment again and confirm it in PayPal.",
                "ORDER_ALREADY_CAPTURED" => "This payment has already been completed.",
                _ => fallbackMessage
            });
        }

        public async Task<PaymentResponse> CapturePayPalOrderAsync(string providerOrderId, int userId)
        {
            var payment = await _context.Payments.FirstOrDefaultAsync(p => p.PayPalTransactionID == providerOrderId)
                ?? throw new NotFoundException("Payment not found.");
            if (payment.UserID != userId)
                throw new UnauthorizedAccessException("The payment does not belong to the signed-in user.");
            if (payment.Status == StatusCompleted)
                return ToResponse(payment);
            if (payment.Status != StatusPending)
                throw new BusinessException("This payment can no longer be completed.");

            // The cart must still match the amount the user approved on PayPal.
            var items = await LoadCartItemsAsync(userId);
            await EnsureItemsAvailableAsync(items);
            if (items.Sum(i => i.RaceTicketCategory.Price * i.Quantity) != payment.Amount)
                throw new BusinessException("Your cart changed after the payment was started. Please start the payment again.");

            var token = await GetPayPalAccessToken();
            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

            var response = await _httpClient.PostAsync($"{BaseUrl}/v2/checkout/orders/{providerOrderId}/capture",
                new StringContent("{}", Encoding.UTF8, "application/json"));
            if (!response.IsSuccessStatusCode)
                await ThrowPayPalErrorAsync(response, "The PayPal payment was not approved or failed.");

            var user = await _context.Users.FindAsync(userId);
            var tickets = new List<Ticket>();

            // Tickets, cart cleanup, payment status and notification are stored in one SaveChanges (atomic).
            foreach (var item in items)
            {
                for (int i = 0; i < item.Quantity; i++)
                {
                    tickets.Add(new Ticket
                    {
                        UserID = userId,
                        RaceTicketCategoryID = item.RaceTicketCategoryID,
                        Payment = payment,
                        Price = item.RaceTicketCategory.Price,
                        PurchaseDate = DateTime.UtcNow,
                        QRCode = Guid.NewGuid().ToString("N"),
                        Status = TicketStatus.Active
                    });
                }
            }

            _context.Tickets.AddRange(tickets);
            _context.CartItems.RemoveRange(items);
            payment.Status = StatusCompleted;
            payment.PaymentDate = DateTime.UtcNow;

            _context.Notifications.Add(new Notification
            {
                UserID = userId,
                Title = "Purchase successful",
                Message = $"You bought {tickets.Count} ticket(s) for {FormatAmount(payment.Amount)} {payment.Currency}. Your QR tickets are in your profile.",
                CreatedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            // The email is sent after the purchase is stored, so a messaging outage never loses a paid order.
            try
            {
                var lines = tickets.Select(t =>
                {
                    var category = items.First(i => i.RaceTicketCategoryID == t.RaceTicketCategoryID).RaceTicketCategory;
                    return new EmailTemplates.TicketLine(category.Race.RaceName, category.Race.Date, category.TicketType.Name, t.Price, t.QRCode);
                }).ToList();
                await _messageProducer.PublishEmailAsync(EmailTemplates.Purchase(user!, lines, payment.Amount, payment.Currency));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Purchase email for payment {PaymentId} could not be queued.", payment.PaymentID);
            }

            return ToResponse(payment);
        }

        public async Task<PaymentResponse> RefundPayPalPaymentAsync(int paymentId, int userId)
        {
            var payment = await _context.Payments
                .Include(p => p.User)
                .Include(p => p.Tickets).ThenInclude(t => t.RaceTicketCategory).ThenInclude(c => c.Race)
                .Include(p => p.Tickets).ThenInclude(t => t.RaceTicketCategory).ThenInclude(c => c.TicketType)
                .FirstOrDefaultAsync(p => p.PaymentID == paymentId)
                ?? throw new NotFoundException("Payment not found.");

            if (payment.UserID != userId)
                throw new UnauthorizedAccessException("The payment does not belong to the signed-in user.");
            if (payment.Status != StatusCompleted)
                throw new BusinessException("Only completed payments can be refunded.");
            if (payment.Tickets.Any(t => t.RaceTicketCategory.Race.Date <= DateTime.UtcNow))
                throw new BusinessException("Tickets for a race that has already taken place cannot be refunded.");

            var token = await GetPayPalAccessToken();
            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

            var captureId = await ResolveCaptureIdFromOrderAsync(payment.PayPalTransactionID);
            if (string.IsNullOrWhiteSpace(captureId))
                throw new BusinessException("The PayPal transaction to refund was not found.");

            var refundBody = new
            {
                amount = new { value = FormatAmount(payment.Amount), currency_code = payment.Currency }
            };

            var refundResponse = await _httpClient.PostAsJsonAsync($"{BaseUrl}/v2/payments/captures/{captureId}/refund", refundBody);
            if (!refundResponse.IsSuccessStatusCode)
                await ThrowPayPalErrorAsync(refundResponse, "The PayPal refund failed.");

            // Tickets, payment status and notification are stored in one SaveChanges; PaymentDate keeps the purchase time.
            foreach (var ticket in payment.Tickets)
            {
                ticket.Status = TicketStatus.Refunded;
            }

            payment.Status = StatusRefunded;
            payment.RefundedAt = DateTime.UtcNow;

            var races = string.Join(", ", payment.Tickets.Select(t => t.RaceTicketCategory.Race.RaceName).Distinct());
            _context.Notifications.Add(new Notification
            {
                UserID = userId,
                Title = "Refund successful",
                Message = $"Your purchase of {payment.Tickets.Count} ticket(s) for {races} was refunded. {FormatAmount(payment.Amount)} {payment.Currency} is returned to your PayPal account and the tickets are no longer valid.",
                CreatedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            try
            {
                var lines = payment.Tickets.Select(t => new EmailTemplates.TicketLine(
                    t.RaceTicketCategory.Race.RaceName, t.RaceTicketCategory.Race.Date, t.RaceTicketCategory.TicketType.Name, t.Price, t.QRCode)).ToList();
                await _messageProducer.PublishEmailAsync(EmailTemplates.Refund(payment.User, lines, payment.Amount, payment.Currency));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Refund email for payment {PaymentId} could not be queued.", payment.PaymentID);
            }

            return ToResponse(payment);
        }

        private async Task<List<CartItem>> LoadCartItemsAsync(int userId)
        {
            var items = await _context.CartItems
                .Include(i => i.RaceTicketCategory).ThenInclude(c => c.Race)
                .Include(i => i.RaceTicketCategory).ThenInclude(c => c.TicketType)
                .Where(i => i.Cart.UserID == userId)
                .ToListAsync();

            if (items.Count == 0)
                throw new BusinessException("Your cart is empty.");

            return items;
        }

        private async Task EnsureItemsAvailableAsync(List<CartItem> items)
        {
            var categoryIds = items.Select(i => i.RaceTicketCategoryID).ToList();
            var sold = await _context.Tickets
                .Where(t => categoryIds.Contains(t.RaceTicketCategoryID) && t.Status != TicketStatus.Refunded)
                .GroupBy(t => t.RaceTicketCategoryID)
                .Select(g => new { g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.Key, x => x.Count);

            foreach (var item in items)
            {
                var category = item.RaceTicketCategory;
                if (category.Race.Date <= DateTime.UtcNow)
                    throw new BusinessException($"Tickets for {category.Race.RaceName} are no longer on sale. Remove them from your cart.");

                var available = category.Capacity - sold.GetValueOrDefault(category.RaceTicketCategoryID);
                if (item.Quantity > available)
                    throw new BusinessException($"Only {Math.Max(available, 0)} seats are left for {category.Race.RaceName} ({category.TicketType.Name}).");
            }
        }

        private async Task<string> ResolveCaptureIdFromOrderAsync(string orderId)
        {
            var response = await _httpClient.GetAsync($"{BaseUrl}/v2/checkout/orders/{orderId}");
            if (!response.IsSuccessStatusCode) return string.Empty;

            var json = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(json);

            if (!doc.RootElement.TryGetProperty("purchase_units", out var purchaseUnits) || purchaseUnits.GetArrayLength() == 0)
                return string.Empty;
            if (!purchaseUnits[0].TryGetProperty("payments", out var payments))
                return string.Empty;
            if (!payments.TryGetProperty("captures", out var captures) || captures.GetArrayLength() == 0)
                return string.Empty;

            return captures[0].GetProperty("id").GetString() ?? string.Empty;
        }

        private static string FormatAmount(decimal amount) => amount.ToString("F2", CultureInfo.InvariantCulture);

        private static PaymentResponse ToResponse(Payment payment) => new()
        {
            PaymentID = payment.PaymentID,
            ProviderOrderId = payment.PayPalTransactionID,
            Status = payment.Status
        };
    }
}
