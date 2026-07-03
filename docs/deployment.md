# Deployment Notes

Target server: Ubuntu 24.04 VPS with a static public IP that the manufacturer binds into the scooter locks.

Recommended first production layout:

1. Run PostgreSQL on a managed service or hardened local instance.
2. Build with `npm run build`.
3. Run migrations with `npm run prisma:migrate`.
4. Start with `pm2 start ecosystem.config.cjs`.
5. Put Nginx in front of the REST API port.
6. Expose the TCP lock port directly through the firewall to the scooter network.

Nginx should proxy only HTTP/WebSocket API traffic. Do not proxy the raw scooter TCP protocol through an HTTP virtual host.

Minimal Nginx API location:

```nginx
server {
  listen 80;
  server_name api.example.com;

  location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
```

Firewall example:

```bash
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 7000/tcp
ufw enable
```

Scale-out note: raw TCP sockets are stateful. Horizontal scaling should use a connection-aware routing strategy, such as one TCP ingress tier with sticky device routing, or a shared command bus keyed by `deviceId`.
