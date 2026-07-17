# ---- Build stage ----
FROM ghcr.io/cirruslabs/flutter:3.19.0 AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
# .env is referenced as an asset in pubspec.yaml; ensure it exists so the build does not fail
RUN touch .env
RUN flutter build web --release

# ---- Runtime stage ----
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
# Rewrite nginx to listen on Railway's $PORT at container start
COPY <<'EOF' /docker-entrypoint.d/99-listen-port.sh
#!/bin/sh
sed -i "s/listen\s*80;/listen ${PORT:-80};/" /etc/nginx/conf.d/default.conf
EOF
RUN chmod +x /docker-entrypoint.d/99-listen-port.sh
EXPOSE 8080
