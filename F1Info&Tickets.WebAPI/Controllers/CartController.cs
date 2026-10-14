using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace F1Info_Tickets.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "User")]
    public class CartController : ControllerBase
    {
        private readonly ICartService _cartService;

        public CartController(ICartService cartService)
        {
            _cartService = cartService;
        }

        [HttpGet]
        public async Task<ActionResult<CartResponse>> Get()
        {
            return Ok(await _cartService.GetCartAsync(GetCurrentUserId()));
        }

        [HttpPost("items")]
        public async Task<ActionResult<CartResponse>> AddItem([FromBody] CartItemInsertRequest request)
        {
            return Ok(await _cartService.AddItemAsync(GetCurrentUserId(), request));
        }

        [HttpPut("items/{cartItemId}")]
        public async Task<ActionResult<CartResponse>> UpdateItem(int cartItemId, [FromBody] CartItemUpdateRequest request)
        {
            return Ok(await _cartService.UpdateItemAsync(GetCurrentUserId(), cartItemId, request));
        }

        [HttpDelete("items/{cartItemId}")]
        public async Task<ActionResult<CartResponse>> RemoveItem(int cartItemId)
        {
            return Ok(await _cartService.RemoveItemAsync(GetCurrentUserId(), cartItemId));
        }

        [HttpDelete]
        public async Task<IActionResult> Clear()
        {
            await _cartService.ClearAsync(GetCurrentUserId());
            return NoContent();
        }

        private int GetCurrentUserId()
        {
            var value = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(value, out var userId))
                throw new UnauthorizedAccessException("Invalid user token.");
            return userId;
        }
    }
}
