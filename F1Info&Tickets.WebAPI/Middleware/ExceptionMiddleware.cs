using F1Info_Tickets.Services.Exceptions;
using System.Net;
using System.Text.Json;

namespace F1Info_Tickets.WebAPI.Middleware
{
    public class ExceptionMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ExceptionMiddleware> _logger;

        public ExceptionMiddleware(RequestDelegate next, ILogger<ExceptionMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (NotFoundException ex)
            {
                await WriteResponse(context, HttpStatusCode.NotFound, ex.Message);
            }
            catch (BusinessException ex) when (ex.Field != null)
            {
                // Same shape as model validation errors, so the client shows the message under the field.
                context.Response.ContentType = "application/json";
                context.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                var errors = new Dictionary<string, string[]> { [ex.Field] = [ex.Message] };
                await context.Response.WriteAsync(JsonSerializer.Serialize(new { message = ex.Message, errors }));
            }
            catch (BusinessException ex)
            {
                await WriteResponse(context, HttpStatusCode.BadRequest, ex.Message);
            }
            catch (UnauthorizedAccessException ex)
            {
                await WriteResponse(context, HttpStatusCode.Forbidden, ex.Message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unhandled exception on {Path}", context.Request.Path);
                await WriteResponse(context, HttpStatusCode.InternalServerError, "A server error occurred.");
            }
        }

        private static Task WriteResponse(HttpContext context, HttpStatusCode status, string message)
        {
            context.Response.ContentType = "application/json";
            context.Response.StatusCode = (int)status;
            var payload = JsonSerializer.Serialize(new { message });
            return context.Response.WriteAsync(payload);
        }
    }

}
