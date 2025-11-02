# How to Protect a Service with OAuth2-Proxy

This guide shows you how to add OAuth2 authentication to any service using the deployed oauth2-proxy stack.

## Prerequisites

- OAuth2-proxy stack deployed and working
- Service running in Docker/Podman on the same host
- Domain/subdomain pointing to your server

## Configuration

### 1. Add Traefik Labels to Your Service

Add these labels to your service in `docker-compose.yml`:

```yaml
services:
  myapp:
    image: your-app-image:latest
    container_name: myapp
    networks:
      - default              # Your service's existing network (if any)
      - traefik_default      # Required: Traefik network
    labels:
      # Enable Traefik
      - "traefik.enable=true"

      # Router configuration
      - "traefik.http.routers.myapp.rule=Host(`myapp.yourdomain.com`)"
      - "traefik.http.routers.myapp.entrypoints=websecure"
      - "traefik.http.routers.myapp.tls.certresolver=myresolver"

      # Service configuration (port your app listens on)
      - "traefik.http.services.myapp.loadbalancer.server.port=8080"

      # 🔐 OAuth2 Protection with Auto-Redirect
      - "traefik.http.routers.myapp.middlewares=auth-errors@docker,forward-auth@docker"

networks:
  default:
    name: myapp_default
    external: true
  traefik_default:
    external: true
```

### 2. Replace Placeholders

| Placeholder | Replace With | Example |
|-------------|--------------|---------|
| `myapp` | Your service/router name | `gitea`, `nextcloud`, `portainer` |
| `myapp.yourdomain.com` | Your domain/subdomain | `git.kfamcloud.com` |
| `8080` | Port your app listens on | `3000`, `80`, `9000` |
| `myapp_default` | Your service's network name (if it has one) | `gitea_default` |

**Important:**
- Router name (`myapp`) must be unique across all services
- If your service doesn't have its own network, remove the `default` network section

### 3. Deploy

Update/redeploy your service in Portainer:
- Go to **Stacks** → Your stack
- Update the compose file
- Click **Update the stack**

## How It Works

When a user visits your protected service:

1. **Not authenticated:**
   - Traefik returns 401 Unauthorized
   - `auth-errors` middleware shows beautiful redirect page
   - Auto-redirects to oauth2-proxy sign-in (1 second delay)

2. **After sign-in:**
   - OAuth flow completes
   - Cookie set for `.yourdomain.com` (all subdomains)
   - User redirected back to original service

3. **Already authenticated:**
   - Cookie recognized by `forward-auth` middleware
   - Direct access granted

## Example: Protecting Portainer

```yaml
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    networks:
      - traefik_default
    volumes:
      - /var/run/podman/podman.sock:/var/run/docker.sock
      - portainer_data:/data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.portainer.rule=Host(`portainer.kfamcloud.com`)"
      - "traefik.http.routers.portainer.entrypoints=websecure"
      - "traefik.http.routers.portainer.tls.certresolver=myresolver"
      - "traefik.http.services.portainer.loadbalancer.server.port=9000"
      - "traefik.http.routers.portainer.middlewares=auth-errors@docker,forward-auth@docker"

networks:
  traefik_default:
    external: true

volumes:
  portainer_data:
```

## Troubleshooting

### Service shows "Unauthorized" without redirecting

**Cause:** Missing or incorrect middleware order

**Fix:** Ensure middlewares are in correct order:
```yaml
- "traefik.http.routers.myapp.middlewares=auth-errors@docker,forward-auth@docker"
```
(`auth-errors` must come BEFORE `forward-auth`)

### Redirect loop

**Cause:** Cookie domain mismatch or middleware configuration issue

**Fix:**
1. Clear browser cookies for `*.yourdomain.com`
2. Verify `OAUTH2_PROXY_COOKIE_DOMAIN` is set to `.yourdomain.com` (with leading dot)
3. Check oauth2-proxy logs: `sudo podman logs oauth2-proxy`

### Service not discovered by Traefik

**Cause:** Not on same network as Traefik

**Fix:** Ensure service is on `traefik_default` network:
```yaml
networks:
  - traefik_default
```

### Certificate errors

**Cause:** Wrong cert resolver or DNS not configured

**Fix:**
1. Verify domain DNS points to your server
2. Check cert resolver name matches Traefik config
3. Wait 1-2 minutes for certificate generation

## Testing

After deploying:

1. **Open incognito window**
2. Go to `https://myapp.yourdomain.com`
3. Should see redirect page → auto-redirect → sign-in
4. After sign-in: access granted

Once authenticated, the cookie works for ALL protected services on `*.yourdomain.com`!

## Network Configuration Reference

### Service with its own network (like vaultwarden + database)
```yaml
networks:
  - default              # Service's internal network
  - traefik_default      # Traefik network

networks:
  default:
    name: myapp_default
    external: true
  traefik_default:
    external: true
```

### Service without its own network (standalone)
```yaml
networks:
  - traefik_default

networks:
  traefik_default:
    external: true
```

## Additional Notes

- **One sign-in for all services:** Once authenticated, access all protected services without re-authenticating
- **Session duration:** 1 hour (configurable in oauth2-proxy)
- **Cookie security:** Secure, HttpOnly, SameSite=Lax
- **Auto-redirect delay:** 1 second (configurable in error page HTML)

## Related Documentation

- [OAuth2-Proxy Configuration](https://oauth2-proxy.github.io/oauth2-proxy/)
- [Traefik ForwardAuth Middleware](https://doc.traefik.io/traefik/middlewares/http/forwardauth/)
- [Traefik Error Pages Middleware](https://doc.traefik.io/traefik/middlewares/http/errorpages/)
