from datetime import datetime, timezone

from agents.support_agent import SupportAgent
from models.support_models import SupportRequest
from models.workflow_models import PlanStep, Step, ToolCall, WorkflowRequest
from tools.support_tools import SupportTools


class ValidationSupportAgent:
    def __init__(self, support: SupportAgent):
        self.support = support

    def collect(self, request: WorkflowRequest, plan: list[PlanStep]):
        tools = SupportTools(request)
        results, steps = [], []
        for item in plan:
            started = datetime.now(timezone.utc)
            record_id = request.ticket.id
            if item.tool in ("get_invoice", "get_payment") and request.invoice:
                record_id = request.invoice.id
            elif item.tool in ("get_charging_session", "calculate_meter_discrepancy") and request.session:
                record_id = request.session.id
            elif item.tool == "get_loyalty_account":
                record_id = request.ticket.driver_id
            result = tools.execute(ToolCall(tool=item.tool, record_id=record_id))
            results.append(result)
            steps.append(Step(agent="ValidationSupportAgent", step="Load and validate", tool=item.tool,
                              started_at=started, completed_at=datetime.now(timezone.utc), outcome=result.outcome))
        return results, steps

    def draft(self, request: WorkflowRequest):
        findings = [f"{f.code}: {f.outcome}. {f.message}" for f in request.validation_results]
        findings.append(f"Backend action: {request.action}. Approval required: {request.approval_required}. Currency: LKR. Nothing executed.")
        if request.loyalty:
            findings.append(f"Available loyalty points: {request.loyalty.points_balance}. No linked redemption request.")
        # Revision notes also remain data, never a new system instruction.
        messages = request.ticket.messages[:11] if request.revision_note else request.ticket.messages
        if request.revision_note:
            messages = [*messages, f"Staff revision note: {request.revision_note}"]
        return self.support.analyze(SupportRequest(subject=request.ticket.subject,
            description=request.ticket.description, messages=messages, findings=findings))
