using F1Info_Tickets.Model.Requests;
using F1Info_Tickets.Model.Responses;
using F1Info_Tickets.Model.SearchObjects;
using F1Info_Tickets.Services.BaseServices;
using F1Info_Tickets.Services.Database;
using F1Info_Tickets.Services.Exceptions;
using F1Info_Tickets.Services.Interfaces;
using MapsterMapper;

namespace F1Info_Tickets.Services.Services
{
    public class RoleService : BaseCRUDService<Role, RoleResponse, RoleSearchObject, RoleUpsertRequest, RoleUpsertRequest>, IRoleService
    {
        public RoleService(ApplicationDbContext context, IMapper mapper) : base(context, mapper) { }

        protected override IQueryable<Role> AddFilter(IQueryable<Role> query, RoleSearchObject? search)
        {
            if (!string.IsNullOrWhiteSpace(search?.SearchTerm))
                query = query.Where(r => r.Name.Contains(search.SearchTerm));
            return query;
        }

        protected override IQueryable<Role> ApplyOrder(IQueryable<Role> query) => query.OrderBy(r => r.Name);

        public override async Task<RoleResponse?> UpdateAsync(int id, RoleUpsertRequest request)
        {
            var role = await _context.Roles.FindAsync(id);
            if (role == null) return default;
            if (Roles.IsSystemRole(role.Name) && role.Name != request.Name)
                throw new BusinessException($"The system role \"{role.Name}\" cannot be renamed.");
            return await base.UpdateAsync(id, request);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var role = await _context.Roles.FindAsync(id);
            if (role != null && Roles.IsSystemRole(role.Name))
                throw new BusinessException($"The system role \"{role.Name}\" cannot be deleted.");
            return await base.DeleteAsync(id);
        }
    }
}
