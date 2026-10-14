using F1Info_Tickets.Services.BaseInterfaces;
using F1Info_Tickets.Services.Exceptions;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace F1Info_Tickets.Services.BaseServices
{
    public class BaseCRUDService<TDb, TResponse, TSearch, TInsert, TUpdate>
    : BaseService<TDb, TResponse, TSearch>, ICRUDService<TResponse, TSearch, TInsert, TUpdate>
    where TDb : class, new()
    {
        public BaseCRUDService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public virtual async Task<TResponse> InsertAsync(TInsert request)
        {
            var entity = _mapper.Map<TDb>(request);
            await BeforeInsert(entity, request);
            _context.Set<TDb>().Add(entity);
            await SaveChangesAsync();
            return (await GetByIdAsync(GetKey(entity)))!;
        }

        public virtual async Task<TResponse?> UpdateAsync(int id, TUpdate request)
        {
            var entity = await _context.Set<TDb>().FindAsync(id);
            if (entity == null) return default;

            _mapper.Map(request, entity);
            await BeforeUpdate(entity, request);
            await SaveChangesAsync();
            return await GetByIdAsync(id);
        }

        public virtual async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.Set<TDb>().FindAsync(id);
            if (entity == null) return false;

            _context.Set<TDb>().Remove(entity);
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                throw new BusinessException("The record cannot be deleted because other data in the system uses it.");
            }
            return true;
        }

        // Validation hooks (uniqueness, business rules) that need the database.
        protected virtual Task BeforeInsert(TDb entity, TInsert request) => Task.CompletedTask;
        protected virtual Task BeforeUpdate(TDb entity, TUpdate request) => Task.CompletedTask;

        protected async Task SaveChangesAsync()
        {
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException ex) when (ex.InnerException?.Message.Contains("duplicate key", StringComparison.OrdinalIgnoreCase) == true)
            {
                throw new BusinessException("A record with these details already exists.");
            }
        }
    }
}
