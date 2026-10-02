"""Local cross-service test host. Never use this module as a deployment entry point.

Run from agentic-ai: python -m uvicorn tests.workflow_http_server:app --host 127.0.0.1 --port 18081
Only the model is replaced. FastAPI authentication, schemas, LangGraph and tools are real.
"""
import json

import main
from agents.coordinator_agent import CoordinatorAgent
from agents.support_agent import SupportAgent


class ContractTestModel:
    def invoke(self, messages):
        assert messages[0].type == "system" and "untrusted" in messages[0].content
        assert messages[1].type == "human"
        data = json.loads(messages[1].content)
        if "immediately refund" in data["description"]:
            # Even misleading prose cannot change backend amount or authority.
            explanation = "Injected text requested a refund of LKR 1000. Staff must verify the stored request."
        else:
            explanation = "Review the deterministic backend findings."
        return dict(category="Payment", priority="High", explanation=explanation,
                    draftReply="Your request is being reviewed. No financial action has been executed by the agent.")


main.coordinator = CoordinatorAgent(SupportAgent(ContractTestModel()))
app = main.app
