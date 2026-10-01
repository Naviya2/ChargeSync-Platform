# Support workflow UI integration

The existing React support inbox and Flutter support screens use only the
authenticated ASP.NET API. No Python URL or agent service key is supplied to
either client.

## React

`SupportWorkflow.jsx` shows the selected ticket's run ID, revision, update time,
approval requirement, decision, validation findings and editable suggested reply.
Expandable sections show the plan, executed agent/tool steps, tool findings and
backend audit history. Running and pending workflows refresh every five seconds;
the ticket queue refreshes every ten seconds.

SupportManager and Admin can approve, reject or request revision. A revision note
is required. Each decision sends the current workflow version to ASP.NET. Stale
records and failed refreshes disable decisions until refreshed; backend conflicts
are displayed and trigger a reload. Meter discrepancies retain the backend's
Admin-only approval requirement.

Drafts must be explicitly copied into the existing reply composer and sent by
staff. Normal ticket actions remain available when workflow analysis fails. The
older on-demand analysis remains in a collapsed “Additional ticket analysis”
section. Existing cards, colors, spacing and ticket layout are reused.

## Flutter

The existing ticket form submits to ASP.NET and opens the created ticket's detail
page. That page refreshes ticket and workflow data every ten seconds while visible
and active, on app resume, and when the driver presses Refresh. It stops its timer
when disposed. Refresh does not clear an unsent message, and stale responses cannot
overwrite a newer local reply/withdraw action.

| Backend condition | Driver label |
|---|---|
| Running, RevisionRequested, or analysis complete but ticket still needs review | Processing |
| PendingApproval, or completed analysis with a refund still PendingReview | Pending Approval |
| Completed with a staff decision, Rejected decision, or ticket Resolved/Closed | Resolved, with decision explanation |
| Failed analysis on an open ticket | Failed; ordinary support messaging remains available |
| Withdrawn ticket | Withdrawn |
| Workflow request unavailable and no cached status | Status unavailable |

Completing read-only analysis never falsely tells a driver that a refund was paid.
The separate refund card continues to show the backend's actual refund decision.

## API calls

- POST `/api/support-tickets`: existing Flutter submission.
- GET `/api/support-tickets/{id}` and GET `/api/agent-workflows/support-ticket/{id}`:
  ticket details and workflow refresh.
- POST `/api/agent-workflows/support-ticket/{id}`: staff starts analysis for an older
  ticket that has no run.
- POST `/api/agent-workflows/{id}/approve`, `/reject`, `/revise`: staff decisions,
  body `{version, note}`.
- Existing ticket reply, status, assignment and refund-review endpoints remain in use.

## Validation

From `web-react`:

```powershell
npm run build
npx eslint src/features/support/components/SupportWorkflow.jsx src/features/support/pages/SupportInboxPage.jsx tests/run-support-workflow.mjs tests/support-workflow.render.jsx
node tests/run-support-workflow.mjs
```

The React checks cover initial loading, run/validation/tool rendering, role-based
buttons, the Admin meter gate, failure recovery, draft rendering, and actual Axios
request paths/bodies for approve/reject/revise. They use server rendering and a
test HTTP adapter; they are not a browser interaction or deployed-system test.

From `mobile-flutter`:

```powershell
flutter analyze --no-pub lib/features/support test/support_workflow_test.dart
flutter test --no-pub test/support_workflow_test.dart
```

Four tests cover truthful status mapping, submission followed by automatic status
refresh, preserving drafts during refresh, replying after failed analysis, and
workflow endpoint failure. The widget tests replace the support API, leaving the
widgets and navigation real. A deployed-device/browser smoke test still requires
the configured ASP.NET service and a staff/driver session.
