#!/bin/sh
set -e
: "${OAUTH_BASE_URL:?OAUTH_BASE_URL must be set (e.g. https://oauth.example.com)}"
sed "s|__OAUTH_BASE_URL__|${OAUTH_BASE_URL}|g" /usr/share/nginx/html/index.html.template > /usr/share/nginx/html/index.html
