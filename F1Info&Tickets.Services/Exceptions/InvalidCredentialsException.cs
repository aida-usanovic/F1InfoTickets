namespace F1Info_Tickets.Services.Exceptions
{
    public class InvalidCredentialsException : Exception
    {
        public InvalidCredentialsException() : base("Incorrect username or password.") { }
    }
}
