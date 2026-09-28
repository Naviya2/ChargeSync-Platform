namespace Application.Common.Exceptions;
public sealed class MembershipConflictException : Exception
{
    public MembershipConflictException() : base("Your membership or points changed during this request. Refresh and retry.") { }
}
