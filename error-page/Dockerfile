# Dockerfile for auth error page
FROM nginx:alpine

# Add build argument for commit SHA
ARG COMMIT_SHA=unknown

# index.html is a template; rendered at container start with OAUTH_BASE_URL substituted in.
COPY index.html /usr/share/nginx/html/index.html.template
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY docker-entrypoint.d/10-render-index.sh /docker-entrypoint.d/10-render-index.sh

RUN chmod +x /docker-entrypoint.d/10-render-index.sh && \
    sed -i "s|</body>|<!-- Version: ${COMMIT_SHA} -->\n</body>|g" /usr/share/nginx/html/index.html.template

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://127.0.0.1/ || exit 1
