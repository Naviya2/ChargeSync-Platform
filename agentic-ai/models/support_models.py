from typing import Literal
from pydantic import BaseModel, ConfigDict, Field


class SupportRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    subject: str = Field(min_length=1, max_length=150)
    description: str = Field(min_length=1, max_length=4000)
    messages: list[str] = Field(default_factory=list, max_length=12)
    findings: list[str] = Field(default_factory=list, max_length=30)


class SupportSuggestion(BaseModel):
    model_config = ConfigDict(extra="forbid", populate_by_name=True)
    category: Literal["Charging", "Reservation", "Payment", "Refund", "Technical", "Membership", "Other"]
    priority: Literal["Low", "Medium", "High", "Urgent"]
    explanation: str = Field(min_length=1, max_length=4000)
    draft_reply: str = Field(alias="draftReply", min_length=1, max_length=4000)
