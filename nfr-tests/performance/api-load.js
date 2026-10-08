import http from 'k6/http';
import { check, sleep } from 'k6';

const routes = [
  { name: 'stations', path: '/api/stations/all', list: true },
  { name: 'wallet', path: '/api/wallet', list: false },
  { name: 'payment-history', path: '/api/payments/history', list: true },
];
const thresholds = { http_req_failed: ['rate<0.01'], checks: ['rate>0.99'] };
for (const route of routes) thresholds[`http_req_duration{endpoint:${route.name}}`] = ['p(95)<2000'];
export const options = {
  scenarios: { baseline: { executor: 'per-vu-iterations', vus: Number(__ENV.PERF_USERS || 1), iterations: 3, maxDuration: '1m' } },
  thresholds, gracefulStop: '5s', summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(95)'],
};
http.setResponseCallback(http.expectedStatuses(200));

export default function () {
  const route = routes[(__ITER + __VU - 1) % routes.length];
  const res = http.get(`http://127.0.0.1:5036${route.path}`, {
    headers: { Authorization: `Bearer ${__ENV.PERF_TOKEN}` },
    tags: { endpoint: route.name }, timeout: '10s',
  });
  check(res, {
    'HTTP 200': r => r.status === 200,
    'valid application response': r => {
      try {
        const value = r.json();
        return route.list ? Array.isArray(value) : typeof value?.balance === 'number';
      } catch { return false; }
    },
  }, { endpoint: route.name });
  sleep(1);
}

export function handleSummary(data) {
  return { [__ENV.PERF_SUMMARY]: JSON.stringify(data, null, 2) };
}
