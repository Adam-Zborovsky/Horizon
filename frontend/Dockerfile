# Stage 1: Build the Flutter web app
FROM debian:latest AS build-env

# Install dependencies
RUN apt-get update && apt-get install -y 
    curl 
    git 
    unzip 
    xz-utils 
    zip 
    libglu1-mesa 
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable web support and build
RUN flutter doctor
RUN flutter config --enable-web

WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web --release

# Stage 2: Serve the app with Nginx
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
