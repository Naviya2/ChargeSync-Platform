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
