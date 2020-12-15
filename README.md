# rtmp2hls

This is a very simple Docker image for ingesting RTMP streams and republishing them via relatively low-latency HLS streams.

The RTMP ingestion and HLS publishing is handled by [Sergey Dryabzhinsky's fork of nginx-rtmp-module](https://github.com/sergey-dryabzhinsky/nginx-rtmp-module). The HTML5 video player is [video.js](https://videojs.com/).

The image is intentionally very barebones and uncustomizable. I've only implemented as much as I need for my personal setup. TLS, RTMP authentication, and transcoding are not implemented.

## Usage

```sh
<docker or podman> run --rm -it \
    -p 8080:80 \
    -p 1935:1935 \
    chenxiaolong/rtmp2hls:0.1.2
```

The source stream should be output to `rtmp://<hostname>/live/<your stream key>`. The HLS stream is made available at `http://<hostname>:8080/?stream_key=<your stream key>`.

To reduce latency, the source should be encoding the H.264 video with frequent keyframes.

## Security

The image does not support TLS natively. It is recommended to have the container sit behind a reverse proxy that terminates SSL for both the HTTP and RTMP ports.

There is also no authentication for the incoming RTMP streams. If the RTMP port is directly exposed, anyone will be able to send streams to the server. This can be worked around by modifying `nginx.conf` to specify an [`on_connect`](https://github.com/arut/nginx-rtmp-module/wiki/Directives#on_connect) URL to an external authentication service. My personal setup does not expose RTMP at all and requires an SSH tunnel from the source host to the server.
