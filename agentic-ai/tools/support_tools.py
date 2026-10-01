from models.workflow_models import ToolCall, ToolResult, WorkflowRequest


class SupportTools:
    """Read only the authorized backend snapshot; no SQL, URLs or mutations.

    Arithmetic and permission findings are computed by ASP.NET. The meter tool
    retrieves that result rather than recalculating it in a language model.
    """

    def __init__(self, request: WorkflowRequest):
        self.request = request

    def execute(self, call: ToolCall) -> ToolResult:
        r = self.request
        records = {
            "get_support_ticket": r.ticket,
            "get_invoice": r.invoice,
            "get_payment": r.invoice,
            "get_charging_session": r.session,
            "calculate_meter_discrepancy": r.session,
            "get_loyalty_account": r.loyalty,
        }
        record = records[call.tool]
        expected = r.ticket.driver_id if call.tool == "get_loyalty_account" else getattr(record, "id", None)
        if record is None or call.record_id != expected:
            raise ValueError("Tool record is unavailable or outside the authorized snapshot")
        if call.tool == "calculate_meter_discrepancy":
            finding = next((f for f in r.validation_results if f.code == "METER_DISCREPANCY"), None)
            if finding is None:
                raise ValueError("Backend meter validation is missing")
            outcome = f"{finding.outcome}: {finding.message}"
        elif call.tool == "get_payment":
            outcome = f"Recorded invoice settlement status: {r.invoice.status if r.invoice else 'Unknown'}. No payment executed."
        elif call.tool == "get_loyalty_account":
            outcome = f"Available points: {r.loyalty.points_balance if r.loyalty else 0}. No redemption requested or executed."
        else:
            outcome = "Authorized linked record loaded from backend snapshot."
        return ToolResult(tool=call.tool, outcome=outcome)
