import json
import sys
import uuid
import urllib.request
import urllib.error
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'agentic-ai'))
from config import settings

body = {
    'workflowId': str(uuid.uuid4()), 'revision': 1,
    'objective': 'Diagnose a general support question without financial actions',
    'ticket': {
        'id': str(uuid.uuid4()), 'driverId': str(uuid.uuid4()),
        'subject': 'Help with support',
        'description': 'How can I see my charging history?',
        'category': 'General', 'priority': 'Medium', 'messages': [],
        'refundStatus': 'NotRequested',
    },
    'validationResults': [{'code': 'NO_INVOICE', 'outcome': 'Info',
        'message': 'No linked invoice; billing checks were not performed.'}],
    'approvalRequired': False, 'action': 'None',
}
request = urllib.request.Request(
    'http://127.0.0.1:8000/api/workflows/support',
    data=json.dumps(body).encode(),
    headers={'Content-Type': 'application/json',
             'X-Agent-Service-Key': settings.AGENT_SERVICE_API_KEY},
)
try:
    with urllib.request.urlopen(request, timeout=30) as response:
        data = json.load(response)
        print('HTTP:', response.status)
        print('Workflow ID matches:', data.get('workflowId') == body['workflowId'])
        print('Has suggestion:', bool(data.get('suggestion')))
except urllib.error.HTTPError as error:
    print('HTTP:', error.code, error.read().decode())
except Exception as error:
    print(type(error).__name__, str(error))
