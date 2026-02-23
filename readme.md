# NETWAR Streaming
RTMP ingest server with HLS output and web frontend for NETWAR LAN events.

Accepts RTMP streams (port 1935), generates HLS segments via nginx-rtmp-module, and serves the web player frontend (port 80).

### Build
```bash
./build.sh
```

### Run
```bash
docker run -p 80:80 -p 1935:1935 ghcr.io/netwarlan/streaming
```

### Stream to it
Using OBS, set the stream URL to `rtmp://<server-ip>/live`. No stream key needed.

Visit `http://<server-ip>` in a browser to watch.

### Streamservice deployment
For event use with FFMPEG transcoding, see the [streamservice](https://github.com/netwarlan/streamservice) repo which orchestrates this image alongside an FFMPEG encoder.
