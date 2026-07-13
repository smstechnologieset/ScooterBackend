# ISOKO Admin Web

Standalone fleet-operations dashboard for Vercel.

## Local Run

```bash
cd admin-web
npm run dev
```

The local default API URL is `http://localhost:3000`. You can also edit it in the dashboard.

Set the deployment default API URL with:

```bash
ADMIN_API_BASE_URL=http://localhost:3000 npm run build
```

For the VPS API behind HTTPS/Nginx, use your API domain:

```bash
ADMIN_API_BASE_URL=https://api.example.com npm run build
```

## Temporary Admin Token

Until a full admin login flow is added, generate a short-lived admin token on the backend server:

```bash
cd /opt/scooter-lock
npm run admin:token -- admin
```

Paste the token into the dashboard.

## Vercel

Create a separate Vercel project with:

- Root directory: `admin-web`
- Build command: `npm run build`
- Output directory: `dist`
- Environment variable: `ADMIN_API_BASE_URL=https://your-api-domain`
