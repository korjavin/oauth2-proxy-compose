# OAuth2 Proxy with Pocket-ID (OIDC)

Docker Compose setup for oauth2-proxy using Pocket-ID as OIDC provider, designed for GitOps deployment with Portainer.

## Features

- **OIDC Authentication** via Pocket-ID
- **Traefik Integration** with forward authentication middleware
- **Fully Parameterized** - all secrets and domains configured via environment variables
- **GitOps Ready** - no secrets in repository
- **Portainer Compatible** - easy deployment via Portainer stacks

## Prerequisites

- Docker and Docker Compose
- Traefik reverse proxy with external network
- Pocket-ID (or any OIDC provider) configured
- Portainer (for deployment)

## Quick Start with Portainer

### 1. Create OIDC Client in Pocket-ID

Before deploying, create an OAuth2/OIDC client in your Pocket-ID instance:

- **Client ID**: Note this down
- **Client Secret**: Note this down
- **Redirect URI**: `https://auth.yourdomain.com/oauth2/callback` (update with your domain)
- **Scopes**: `openid`, `email`, `profile`

### 2. Generate Cookie Secret

Generate a secure random cookie secret (32 bytes):

```bash
python -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(32)).decode())'
```

Or using OpenSSL:

```bash
openssl rand -base64 32
```

### 3. Deploy in Portainer

1. Go to **Stacks** → **Add Stack**
2. **Name**: `oauth2-proxy`
3. **Build method**: Select **Repository**
4. **Repository URL**: `https://github.com/yourusername/oauth2-proxy-compose`
5. **Repository reference**: `main` (or your branch name)
6. **Compose path**: `docker-compose.yml`

### 4. Configure Environment Variables

In the **Environment variables** section, copy and paste the following (update with your values):

```
NETWORK_NAME=traefik-net
OAUTH2_PROXY_PROVIDER=oidc
OAUTH2_PROXY_OIDC_ISSUER_URL=https://sso.yourdomain.com
OAUTH2_PROXY_CLIENT_ID=your-client-id-from-pocket-id
OAUTH2_PROXY_CLIENT_SECRET=your-client-secret-from-pocket-id
OAUTH2_PROXY_COOKIE_SECRET=your-generated-32-byte-secret
OAUTH2_PROXY_COOKIE_DOMAIN=.yourdomain.com
OAUTH2_PROXY_REDIRECT_URL=https://auth.yourdomain.com/oauth2/callback
OAUTH_HOST=auth.yourdomain.com
TRAEFIK_CERTRESOLVER=myresolver
```

**Optional variables** (defaults are usually fine):

```
OAUTH2_PROXY_IMAGE=quay.io/oauth2-proxy/oauth2-proxy:latest
CONTAINER_NAME=oauth2-proxy
OAUTH2_PROXY_COOKIE_SECURE=true
OAUTH2_PROXY_COOKIE_SAMESITE=strict
OAUTH2_PROXY_HTTP_ADDRESS=0.0.0.0:4180
OAUTH2_PROXY_PORT=4180
OAUTH2_PROXY_EMAIL_DOMAINS=*
OAUTH2_PROXY_UPSTREAMS=static://200
TRAEFIK_ENTRYPOINT=websecure
MIDDLEWARE_NAME=forward-auth
ERROR_MIDDLEWARE_NAME=auth-error-page
```

### 5. Deploy

Click **Deploy the stack**

## Configuration Reference

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `NETWORK_NAME` | Docker network name (must match Traefik network) | `traefik-net` |
| `OAUTH2_PROXY_OIDC_ISSUER_URL` | Your Pocket-ID issuer URL | `https://sso.yourdomain.com` |
| `OAUTH2_PROXY_CLIENT_ID` | Client ID from Pocket-ID | `oauth2-proxy-client` |
| `OAUTH2_PROXY_CLIENT_SECRET` | Client secret from Pocket-ID | `super-secret-value` |
| `OAUTH2_PROXY_COOKIE_SECRET` | Random 32-byte secret (base64 encoded) | Generated value |
| `OAUTH2_PROXY_COOKIE_DOMAIN` | Cookie domain (note the leading dot!) | `.yourdomain.com` |
| `OAUTH2_PROXY_REDIRECT_URL` | OAuth callback URL | `https://auth.yourdomain.com/oauth2/callback` |
| `OAUTH_HOST` | Hostname for oauth2-proxy UI | `auth.yourdomain.com` |
| `TRAEFIK_CERTRESOLVER` | Traefik certificate resolver name | `myresolver` |

### Optional Environment Variables

All optional variables have sensible defaults. See `.env.example` for the complete list.

## Using Forward Auth with Other Services

Once deployed, you can protect any service with oauth2-proxy by adding these labels to your service:

```yaml
labels:
  - "traefik.http.routers.myapp.middlewares=forward-auth@docker,auth-error-page@docker"
```

Replace `myapp` with your router name. The middleware names (`forward-auth`, `auth-error-page`) can be customized via `MIDDLEWARE_NAME` and `ERROR_MIDDLEWARE_NAME` environment variables.

## Troubleshooting

### Check Logs

```bash
docker logs oauth2-proxy
```

### Common Issues

1. **401/403 errors**: Check that `OAUTH2_PROXY_COOKIE_DOMAIN` includes a leading dot (`.yourdomain.com`)
2. **Redirect loop**: Verify `OAUTH2_PROXY_REDIRECT_URL` matches your Pocket-ID client configuration
3. **Network errors**: Ensure the `NETWORK_NAME` matches your Traefik network exactly
4. **Certificate errors**: Check `TRAEFIK_CERTRESOLVER` is correct

## Security Notes

- Never commit secrets to the repository
- Use strong, randomly generated values for `OAUTH2_PROXY_COOKIE_SECRET`
- Regularly rotate client secrets
- Review `OAUTH2_PROXY_EMAIL_DOMAINS` - use `*` for all domains or restrict to specific domain

## License

MIT

## Resources

- [OAuth2 Proxy Documentation](https://oauth2-proxy.github.io/oauth2-proxy/)
- [Pocket-ID Documentation](https://github.com/stonith404/pocket-id)
- [Traefik Forward Auth](https://doc.traefik.io/traefik/middlewares/http/forwardauth/)
