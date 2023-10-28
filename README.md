# Interactive Brokers Gateway Docker

## What is it?

A docker image to run the Interactive Brokers Gateway Application without any human interaction on a docker container.

As a basis, the [Github repository](https://github.com/UnusualAlpha/ib-gateway-docker) was taken.

It includes:

- [IB Gateway Application](https://www.interactivebrokers.com/en/index.php?f=16457) ([stable](https://www.interactivebrokers.com/en/trading/ibgateway-stable.php), [latest](https://www.interactivebrokers.com/en/trading/ibgateway-latest.php))
- [IBC Application](https://github.com/IbcAlpha/IBC) -
to control the IB Gateway Application (simulates user input).
- [Xvfb](https://www.x.org/releases/X11R7.6/doc/man/man1/Xvfb.1.xhtml) -
a X11 virtual framebuffer to run IB Gateway Application without graphics hardware.
- [x11vnc](https://wiki.archlinux.org/title/x11vnc) -
a VNC server that allows to interact with the IB Gateway user interface (optional, for development / maintenance purpose).
- [socat](https://linux.die.net/man/1/socat) a tool to accept TCP connection from non-localhost and relay it to IB Gateway from localhost (IB Gateway restricts connections to 127.0.0.1 by default).

## How to use?

Create a `docker-compose.yml` (or include ib-gateway services on your existing one)

```yaml
version: "3.4"

services:
  ib-gateway:
    image: docker.wyden.io/interactivebrokers/ibgateway:latest
    restart: always
    environment:
      TWS_USERID: ${TWS_USERID}
      TWS_PASSWORD: ${TWS_PASSWORD}
      TRADING_MODE: ${TRADING_MODE:-live}
      VNC_SERVER_PASSWORD: ${VNC_SERVER_PASSWORD:-}
    ports:
      - "127.0.0.1:4001:4001"
      - "127.0.0.1:4002:4002"
      - "127.0.0.1:5900:5900"
```

Create an .env on root directory or set the following environment variables:

| Variable              | Description                                                         | Default                    |
| --------------------- | ------------------------------------------------------------------- | -------------------------- |
| `TWS_USERID`          | The TWS **username**.                                               |                            |
| `TWS_PASSWORD`        | The TWS **password**.                                               |                            |
| `TRADING_MODE`        | **live** or **paper**                                               | **paper**                  |
| `READ_ONLY_API`       | **yes** or **no** ([see](resources/config.ini#L316))                | **not defined**            |
| `VNC_SERVER_PASSWORD` | VNC server password. If not defined, no VNC server will be started. | **not defined** (VNC disabled)|

Example .env file:

```text
TWS_USERID=myTwsAccountName
TWS_PASSWORD=myTwsPassword
TRADING_MODE=paper
READ_ONLY_API=no
VNC_SERVER_PASSWORD=myVncPassword
```

Run:

  $ docker-compose up

After image is downloaded, container is started + 30s, the following ports will be ready for usage on the
container and docker host:

| Port | Description                                                  |
| ---- | ------------------------------------------------------------ |
| 4001 | TWS API port for live accounts.                              |
| 4002 | TWS API port for paper accounts.                             |
| 5900 | When `VNC_SERVER_PASSWORD` was defined, the VNC server port. |

_Note that with the above `docker-compose.yml`, ports are only exposed to the
docker host (127.0.0.1), but not to the network of the host. To expose it to
the whole network change the port mappings on accordingly (remove the
'127.0.0.1:'). **Attention**: See [Leaving localhost](#leaving-localhost)
