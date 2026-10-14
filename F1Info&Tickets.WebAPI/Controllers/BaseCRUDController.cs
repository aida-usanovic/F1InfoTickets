using F1Info_Tickets.Services.BaseInterfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace F1Info_Tickets.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BaseCRUDController<T, TSearch, TInsert, TUpdate> : BaseController<T, TSearch>
    {
        protected readonly ICRUDService<T, TSearch, TInsert, TUpdate> _crudService;

        public BaseCRUDController(ICRUDService<T, TSearch, TInsert, TUpdate> crudService)
            : base(crudService)
        {
            _crudService = crudService;
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public virtual async Task<ActionResult<T>> Insert([FromBody] TInsert request)
        {
            var result = await _crudService.InsertAsync(request);
            return Ok(result);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public virtual async Task<ActionResult<T>> Update(int id, [FromBody] TUpdate request)
        {
            var result = await _crudService.UpdateAsync(id, request);
            if (result == null)
                return NotFound();
            return Ok(result);
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public virtual async Task<IActionResult> Delete(int id)
        {
            var deleted = await _crudService.DeleteAsync(id);
            if (!deleted)
                return NotFound();
            return NoContent();
        }
    }
}


