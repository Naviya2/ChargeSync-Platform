from datetime import datetime
from decimal import Decimal
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator
from pydantic.alias_generators import to_camel
from models.support_models import SupportSuggestion


class Contract(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True, extra="forbid")


class Ticket(Contract):
    id: UUID
    driver_id: UUID
    subject: str = Field(min_length=1, max_length=150)
    description: str = Field(min_length=1, max_length=4000)
    category: str
    priority: str
    messages: list[str] = Field(max_length=12)
    invoice_id: UUID | None = None
    requested_refund_amount: Decimal | None = None
    refund_status: str


class Session(Contract):
    id: UUID
    automatic_kwh: Decimal | None
    meter_kwh: Decimal | None
    final_kwh: Decimal | None
    start_time: datetime
    end_time: datetime | None


class Invoice(Contract):
    id: UUID
    session_id: UUID
    driver_id: UUID | None
    status: str
    gross: Decimal
    discount: Decimal
    advance: Decimal
    net_due: Decimal
    refunded_amount: Decimal
    tariff: Decimal


class Loyalty(Contract):
    driver_id: UUID
    points_balance: int


class Finding(Contract):
    code: str
    outcome: Literal["Pass", "Review", "Error", "Info"]
    message: str


class WorkflowRequest(Contract):
    workflow_id: UUID
    revision: int = Field(ge=1)
    objective: str = Field(max_length=500)
    ticket: Ticket
    session: Session | None = None
    invoice: Invoice | None = None
    loyalty: Loyalty | None = None
    validation_results: list[Finding] = Field(max_length=30)
    approval_required: bool
    action: Literal["None", "Refund"]
    revision_note: str | None = Field(default=None, max_length=1000)

    @model_validator(mode="after")
    def linked_records(self):
        if self.ticket.invoice_id is not None and self.invoice is None:
            raise ValueError("Linked invoice is missing")
        if self.invoice and (self.invoice.id != self.ticket.invoice_id or
                             self.invoice.driver_id != self.ticket.driver_id):
            raise ValueError("Invoice does not match the authorized ticket")
        if self.invoice and (self.session is None or self.session.id != self.invoice.session_id):
            raise ValueError("Linked session is missing or inconsistent")
        if self.session and self.invoice is None:
            raise ValueError("Session requires a linked invoice")
        if self.loyalty and self.loyalty.driver_id != self.ticket.driver_id:
            raise ValueError("Loyalty account does not match the ticket")
        return self


ToolName = Literal["get_support_ticket", "get_charging_session", "get_invoice",
                   "get_payment", "calculate_meter_discrepancy", "get_loyalty_account"]


class ToolCall(Contract):
    tool: ToolName
    record_id: UUID


class PlanStep(Contract):
    agent: Literal["ValidationSupportAgent"] = "ValidationSupportAgent"
    tool: ToolName


class Step(Contract):
    agent: Literal["CoordinatorAgent", "ValidationSupportAgent"]
    step: str
    tool: ToolName | None = None
    started_at: datetime
    completed_at: datetime
    outcome: str


class ToolResult(Contract):
    tool: ToolName
    outcome: str


class WorkflowResponse(Contract):
    workflow_id: UUID
    revision: int
    plan: list[PlanStep]
    completed_steps: list[Step]
    tool_results: list[ToolResult]
    suggestion: SupportSuggestion
