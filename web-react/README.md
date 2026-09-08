# chargesync-web

Admin portal for the **ChargeSync** EV charging platform.

React (plain JavaScript + JSX) · Vite · React Router v6 · TanStack Query · Zustand · Axios · Tailwind CSS · Recharts · lucide-react

## Getting started

```bash
npm install
cp .env.example .env   # set VITE_API_BASE_URL
npm run dev
```

| Script            | Purpose                     |
| ----------------- | --------------------------- |
| `npm run dev`     | Start the Vite dev server   |
| `npm run build`   | Production build            |
| `npm run preview` | Preview the production build |
| `npm run lint`    | Run ESLint                  |

## Project structure

```
src/
  api/
    client.js              # Axios instance + JWT request / 401 response interceptors
    endpoints/              # One module per resource (vehicles, stations, reservations,
                            #   chargingPlans, sessions, payments, loyalty, support,
                            #   agentWorkflows)
  components/
    ui/                     # Presentational primitives (Button, Card, Spinner)
    layout/                 # AppLayout, Sidebar, Topbar
    shared/                 # Cross-feature pieces (PageHeader, PlaceholderPage, NotificationHost)
  features/
    landing/                 # Public marketing page shown at "/" (section components + page)
    auth|stations|reservations|analytics|approvals|support|users/
      components/ hooks/ pages/
  hooks/                    # App-wide hooks (useAuth, useNotify)
  lib/                      # queryClient, constants, cn
  routes/
    AppRouter.jsx           # Route table + placeholder routes
    ProtectedRoute.jsx      # Auth + role-based guard
    roleRoutes.js           # Role -> allowed routes map
  store/                    # Zustand stores (authStore, notificationStore)
  styles/                   # Tailwind entry + component layer
```

## Navigation flow

`/` renders the public **landing page** ([`features/landing/`](src/features/landing/)). Its
CTAs link to `/login`, where a dev role picker seeds a session and forwards to that
role's dashboard. All `/dashboard`, `/stations`, … routes are behind `ProtectedRoute`.

Each role lands on its own workspace after login (see `DEFAULT_ROUTE` in
[`routes/roleRoutes.js`](src/routes/roleRoutes.js)):

| Role | Lands on | Page |
| --- | --- | --- |
| Admin | `/dashboard` | [`AdminDashboardPage`](src/features/dashboard/pages/AdminDashboardPage.jsx) — metrics, AI grid queue, telemetry, reservations table, dev-only state dock |
| StationOwner | `/stations` | [`MyStationsPage`](src/features/stations/pages/MyStationsPage.jsx) — KPI strip, station cards, and a per-station console (Overview / Chargers / Operating Hours / Maintenance tabs) |
| SupportManager | `/support` | placeholder |
| Driver | `/reservations` | placeholder |

`/dashboard` ([`DashboardPage.jsx`](src/features/dashboard/pages/DashboardPage.jsx)) and
`/stations` ([`StationsPage.jsx`](src/features/stations/pages/StationsPage.jsx)) are
role-aware entry points — they render the rich view for the owning role and a placeholder
otherwise. The shared shell ([`components/layout/`](src/components/layout/)) is a
Material 3 sidebar (section label + nav adapt to role) + topbar.

## Auth & roles

Roles: `Driver`, `StationOwner`, `Admin`, `SupportManager`.

`ProtectedRoute` reads `token` / `user.role` from `store/authStore` (persisted to
`localStorage`). It redirects unauthenticated users to `/login` and users without
access to their default route. Per-route access is defined in
[`src/routes/roleRoutes.js`](src/routes/roleRoutes.js) or via an explicit
`allowedRoles` prop.

The Axios client attaches `Authorization: Bearer <token>` on every request and,
on a `401`, clears the session and redirects to `/login`.

## Server state

All data fetching goes through **TanStack Query**. API calls live in
`src/api/endpoints/*` and return unwrapped `response.data`. Zustand is reserved
for lightweight global UI state (auth session, notifications).

## Theming

Tailwind exposes a custom `brand` color (teal `#0EA5A0` → green `#22C55E`) plus a
`bg-brand-gradient` utility and a `.btn-brand` component class.

The landing page uses a Material 3 token set also declared in
[`tailwind.config.js`](tailwind.config.js) (`primary`, `surface`, `inverse-surface`,
`space-*` spacing, `display-lg` / `body-md` type scale, …). Fonts (Inter + Material
Symbols) load from Google Fonts in [`index.html`](index.html).
