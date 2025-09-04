# Nginx RTMP Docker
This docker image provides an easy way to run an custom instance of Nginx with the [RTMP module](https://github.com/arut/nginx-rtmp-module) enabled.

[![Build and Push Docker Image](https://github.com/Mqxx/nginx-rtmp-docker/actions/workflows/build.yml/badge.svg)](https://github.com/Mqxx/nginx-rtmp-docker/actions/workflows/build.yml)

## Features
- All latest features that Nginx provides
- All latest features that the [RTMP module](https://github.com/arut/nginx-rtmp-module) provides

## Usage
Use with `compose.yml`:
```yml
services:
  nginx-service:
    container_name: 'nginx-service'
    image: ghcr.io/mqxx/nginx-rtmp:latest
    ports:
      - '80:80' # HTTP
      - '443:443' # HTTPS
      - '1935:1935' # RTMP

    volumes:
      - './data/nginx:/etc/nginx'
      - './data/stream/hls:/tmp/stream/hls'

    restart: unless-stopped
```

## Example Config
`nginx.conf` config:
```nginx
user nginx; # Optional
worker_processes auto; # Optional
error_log /var/log/nginx/error.log warn; # Optional
pid /var/run/nginx.pid; # Optional

events {
    worker_connections 1024;
}

rtmp_auto_push on;

rtmp {
  server {
    listen 1935;
    listen [::]:1935 ipv6only=on;

    application live {
    #           ^ Needs to match the path for your RTMP stream URL specified below 
      live on;
      record off;

      hls on;
      hls_path /tmp/stream/hls; # Path specified in compose.yml
      hls_playlist_length 1s;

      hls_fragment 500ms;
      hls_fragment_naming system;
      hls_fragment_slicing aligned;

      hls_cleanup on;
      hls_nested on;

      hls_continuous off;
      hls_sync 100ms;
    }
  }
}

http {
  include mime.types; # <-- get from https://github.com/nginx/nginx/blob/master/conf/mime.types
  default_type application/octet-stream;

  sendfile on;
  keepalive_timeout 65;

  server {
    listen 80;

    location /hls {
      types {
        application/vnd.apple.mpegurl m3u8;
        video/mp2t ts;
      }
      alias /tmp/stream/hls; # Path specified in compose.yml
      add_header Cache-Control no-cache;
    }

    # Optional: Monitoring
    location /status {
      stub_status;
      allow all;
    }
  }
}
```

Provide a stream from a source (ex. GoPro RTMP Streaming) to this URL, replace `<streamkey>` with a unique identifier:
```
rtmp://localhost:1935/live/<streamkey>
```

Access the stream from a browser, replace `<streamkey>` with the unique identifier that matches the stream provider:
```
http://localhost:80/hls/<streamkey>/index.m3u8
```
