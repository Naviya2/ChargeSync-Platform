import http from 'k6/http';
import { check, sleep } from 'k6';
import exec from 'k6/execution';

const routes = [
  { name: 'stations', path: '/api/stations/all', list: true },
  { name: 'wallet', path: '/api/wallet', list: false },
  { name: 'payment-history', path: '/api/payments/history', list: true },
];

const phases = [
  { name: 'warmup', users: 1, startTime: '0s', duration: '30s' },
  { name: 'baseline', users: 1, startTime: '30s', duration: '60s' },
  { name: 'moderate', users: 5, startTime: '90s', duration: '60s' },
  { name: 'higher', users: 10, startTime: '150s', duration: '60s' },
];

const thresholds = {
  http_req_failed: ['rate<0.01'],
  checks: ['rate>0.99'],
};
thresholds['http_reqs{phase:warmup}'] = ['count>0'];
for (const phase of phases.filter(phase => phase.name !== 'warmup')) {
  thresholds[`http_reqs{phase:${phase.name}}`] = ['count>0'];
  thresholds[`http_req_failed{phase:${phase.name}}`] = ['rate<0.01'];
  thresholds[`checks{phase:${phase.name}}`] = ['rate>0.99'];
  for (const route of routes) {
    thresholds[`http_req_duration{phase:${phase.name},endpoint:${route.name}}`] = ['p(95)<500'];
  }
}

export const options = {
  scenarios: Object.fromEntries(phases.map(phase => [phase.name, {
    executor: 'constant-vus',
    vus: phase.users,
    startTime: phase.startTime,
    duration: phase.duration,
    gracefulStop: '10s',
  }])),
  thresholds,
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],
};

http.setResponseCallback(http.expectedStatuses(200));

export default function () {
  const route = routes[(__ITER + __VU - 1) % routes.length];
  const phase = exec.scenario.name;
  const response = http.get(`http://127.0.0.1:5036${route.path}`, {
    headers: { Authorization: `Bearer ${__ENV.PERF_TOKEN}` },
    tags: { phase, endpoint: route.name },
    timeout: '15s',
  });
  check(response, {
    'HTTP 200': r => r.status === 200,
    'valid response shape': r => {
      try {
        const data = r.json();
        return route.list ? Array.isArray(data) : typeof data?.balance === 'number';
      } catch {
        return false;
      }
    },
  }, { phase, endpoint: route.name });
  sleep(0.5);
}

export function handleSummary(data) {
  return { [__ENV.PERF_SUMMARY]: JSON.stringify(data, null, 2) };
}
