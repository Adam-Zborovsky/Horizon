# Stage 1: Build Flutter web app
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web --pwa-strategy=none
RUN BUILD_TS=$(date +%s) && \
    sed -i "s|\"mainJsPath\":\"main.dart.js\"|\"mainJsPath\":\"main.dart.js?v=${BUILD_TS}\"|g" /app/build/web/flutter_bootstrap.js && \
    sed -i "s|src=\"flutter_bootstrap.js\"|src=\"flutter_bootstrap.js?v=${BUILD_TS}\"|g" /app/build/web/index.html && \
    printf "self.addEventListener('install',function(e){self.skipWaiting();});\nself.addEventListener('activate',function(e){e.waitUntil(caches.keys().then(function(k){return Promise.all(k.map(function(n){return caches.delete(n);}));}).then(function(){return self.registration.unregister();}).then(function(){return self.clients.matchAll({type:'window'});}).then(function(c){c.forEach(function(w){w.navigate(w.url);});}));});\n" > /app/build/web/flutter_service_worker.js

# Stage 2: Serve with Nginx
FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
