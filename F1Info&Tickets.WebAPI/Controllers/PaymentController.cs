using System.Threading.Tasks;
using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace F1Info_Tickets.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PaymentController : ControllerBase
    {
        private readonly IPaymentService _paymentService;

        public PaymentController(IPaymentService paymentService)
        {
            _paymentService = paymentService;
        }

        [HttpPost("create")]
        [Authorize]
        public async Task<IActionResult> Create([FromBody] PaymentCreateRequest request)
        {
            var userId = GetCurrentUserId();
            var resp = await _paymentService.CreatePayPalOrderAsync(request, userId);
            return Ok(resp);
        }

        [HttpPost("capture")]
        [Authorize]
        public async Task<IActionResult> Capture([FromBody] PaymentCaptureRequest request)
        {
            var userId = GetCurrentUserId();
            var resp = await _paymentService.CapturePayPalOrderAsync(request.OrderId, userId);
            return Ok(resp);
        }

        [HttpPost("refund")]
        [Authorize]
        public async Task<IActionResult> Refund([FromBody] PaymentRefundRequest request)
        {
            var userId = GetCurrentUserId();
            var resp = await _paymentService.RefundPayPalPaymentAsync(request.PaymentId, userId);
            return Ok(resp);
        }

        private int GetCurrentUserId()
        {
            var value = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(value, out var userId))
            {
                throw new UnauthorizedAccessException("Invalid user token.");
            }

            return userId;
        }
    }
}

