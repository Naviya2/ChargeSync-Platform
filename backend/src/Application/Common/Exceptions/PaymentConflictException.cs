namespace Application.Common.Exceptions;

public sealed class PaymentConflictException : Exception
{
    public PaymentConflictException()
        : base("This invoice or wallet changed while the payment was being processed. Refresh and try again.")
    {
    }
}
