FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY packages ./packages
COPY apps/app_web ./apps/app_web

WORKDIR /app/apps/app_web
ARG API_BASE_URL=
ARG API_FALLBACK_URLS=
RUN flutter pub get && flutter build web --release \
  --dart-define=API_BASE_URL=${API_BASE_URL} \
  --dart-define=API_FALLBACK_URLS=${API_FALLBACK_URLS}

FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/apps/app_web/build/web /usr/share/nginx/html

EXPOSE 80
