namespace Application.ReservationPlanning.DTOs;

public record TimeSlotDto(DateTimeOffset StartTime, DateTimeOffset EndTime);
