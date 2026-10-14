using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace F1Info_Tickets.WebAPI.Controllers
{
    // User administration; customers manage their own account through ProfileController.
    [Authorize(Roles = "Admin")]
    public class UserController : BaseCRUDController<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        public UserController(IUserService service) : base(service) { }

        [HttpDelete("{id}")]
        public override async Task<IActionResult> Delete(int id)
        {
            if (id == GetCurrentUserId())
                return BadRequest(new { message = "You cannot delete your own account." });
            return await base.Delete(id);
        }
    }
}
