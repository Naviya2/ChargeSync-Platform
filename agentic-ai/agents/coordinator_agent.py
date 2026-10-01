from datetime import datetime, timezone
from pydantic import BaseModel, Field
from langgraph.graph import StateGraph, START, END

from agents.support_agent import SupportAgent
from agents.validation_support_agent import ValidationSupportAgent
from models.support_models import SupportSuggestion
from models.workflow_models import PlanStep, Step, ToolName, ToolResult, WorkflowRequest, WorkflowResponse


class WorkflowState(BaseModel):
    request: WorkflowRequest
    plan: list[PlanStep] = Field(default_factory=list)
    completed_steps: list[Step] = Field(default_factory=list)
    tool_results: list[ToolResult] = Field(default_factory=list)
    suggestion: SupportSuggestion | None = None


class CoordinatorAgent:
    """Bounded domain plan delegates Student 4 work to ValidationSupportAgent.

    ASP.NET persists input, attempts and final state. A crashed read-only graph
    can be replayed; financial approval is never executed in this graph.
    """

    def __init__(self, support: SupportAgent):
        self.validation = ValidationSupportAgent(support)
        graph = StateGraph(WorkflowState)
        graph.add_node("plan", self.plan)
        graph.add_node("delegate_validation", self.delegate)
        graph.add_node("draft_reply", self.draft)
        graph.add_edge(START, "plan")
        graph.add_edge("plan", "delegate_validation")
        graph.add_edge("delegate_validation", "draft_reply")
        graph.add_edge("draft_reply", END)
        self.graph = graph.compile()

    def plan(self, state: WorkflowState):
        started = datetime.now(timezone.utc)
        names: list[ToolName] = ["get_support_ticket"]
        if state.request.invoice:
            names.extend(["get_invoice", "get_payment"])
        if state.request.session:
            names.extend(["get_charging_session", "calculate_meter_discrepancy"])
        if state.request.loyalty:
            names.append("get_loyalty_account")
        return {"plan": [PlanStep(tool=name) for name in names], "completed_steps": [
            Step(agent="CoordinatorAgent", step="Plan", started_at=started,
                 completed_at=datetime.now(timezone.utc), outcome="Delegated authorized read-only checks to ValidationSupportAgent.")]}

    def delegate(self, state: WorkflowState):
        results, steps = self.validation.collect(state.request, state.plan)
        return {"tool_results": results, "completed_steps": [*state.completed_steps, *steps]}

    def draft(self, state: WorkflowState):
        started = datetime.now(timezone.utc)
        suggestion = self.validation.draft(state.request)
        return {"suggestion": suggestion, "completed_steps": [*state.completed_steps,
            Step(agent="ValidationSupportAgent", step="Draft reply", started_at=started,
                 completed_at=datetime.now(timezone.utc), outcome="Structured suggestion ready for staff review. No action executed.")]}

    def run(self, request: WorkflowRequest) -> WorkflowResponse:
        result = self.graph.invoke({"request": request})
        return WorkflowResponse(workflow_id=request.workflow_id, revision=request.revision,
            plan=result["plan"], completed_steps=result["completed_steps"],
            tool_results=result["tool_results"], suggestion=result["suggestion"])
