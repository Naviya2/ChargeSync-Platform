import http from 'k6/http';
import { check, sleep } from 'k6';

const routes = [
  { name: 'all-stations', path: '/api/stations/all', list: true },
  { name: 'my-stations', path: '/api/stations', list: true },
  { name: 'search-stations', path: '/api/stations/search?latitude=6.9&longitude=79.8', list: true },
  { name: 'station-details', path: '/api/stations', list: false },
];

const thresholds = {
  http_req_failed: ['rate<0.01'],
  checks: ['rate>0.99'],
};

for (const route of routes) {
  thresholds[`http_req_duration{endpoint:${route.name}}`] = ['p(95)<2000'];
}

export const options = {
  scenarios: {
    station_load: {
      executor: 'per-vu-iterations',
      vus: Number(__ENV.PERF_USERS || 5),
      iterations: 5,
      maxDuration: '1m',
      gracefulStop: '5s',
    },
  },
  thresholds,
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(95)'],
};

http.setResponseCallback(http.expectedStatuses(200));

export default function () {
  const route = routes[(__ITER + __VU - 1) % routes.length];
  const url = route.list
    ? `http://127.0.0.1:5036${route.path}`
    : `http://127.0.0.1:5036${route.path}/${__ENV.PERF_STATION_ID}`;

  const res = http.get(url, {
    headers: {
      Authorization: `Bearer ${__ENV.PERF_TOKEN}`,
      'Content-Type': 'application/json'
    },
    tags: { endpoint: route.name },
    timeout: '10s',
  });

  check(res, {
    'HTTP 200': r => r.status === 200,
    'Valid Station payload': r => {
      try {
        const data = r.json();
        return Array.isArray(data) || typeof data === 'object';
      } catch {
        return false;
      }
    },
  }, { endpoint: route.name });

  sleep(1);
}

export function handleSummary(data) {
  return { [__ENV.PERF_SUMMARY || 'station_summary.json']: JSON.stringify(data, null, 2) };
}
