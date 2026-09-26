namespace Application.Authentication.Models;

public record GoogleLoginRequest(string IdToken, string Role);
