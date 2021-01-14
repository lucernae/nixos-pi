# Pi-Hole

Installing pihole using docker/docker-compose

[Pi-Hole](https://github.com/pi-hole/pi-hole), the blackhole of ads can be installed relatively easy with docker/docker-compose.

It also provide a way to declaratively persists the configuration.

## Requirements

- Machine with Docker installed
- Machine with Docker Compose installed

## TL;DR

To run pi-hole, first copy `.example.env` file in this directory and paste it as `.env`.

Run this command in terminal from within this directory

```
docker-compose up -d
```

To shut it down, go to this directory and execute

```
docker-compose down
```

## Customization

The default costumization were intended to run Pi-Hole + CloudflareD DOH + DHCPD Helper inside a RaspberryPi so that it can serve as DHCPD server in the LAN.

Customization can be done via `.env` file. See comments in the file for more info. Some general customization:

### Add/remove docker-compose recipe

`COMPOSE_FILE` variable contains colon separated list of docker-compose file with file on the right override the file on the left.

### Assign different port for Pi-Hole Admin interface

Specify different port for `PIHOLE_HTTP_EXPOSE_PORT` and `PIHOLE_HTTPS_EXPOSE_PORT`.

### Change timezone

Assign it via `TIMEZONE` variable

### Set Pi Hole Server IP

Useful for analytics and binding in the real RaspberryPi interface.
Set the `SERVER_IP` to your interface IP


### Finding the configuration files

The configuration files will be generated in `etc-pihole` and `etc-dnsmasq.d` if you want to configure it manually.

You can also change this into a different location by overriding/modifying `services.pihole.volumes` keys

### Change Admin UI password

Change it via `WEBPASSWORD`. If you already run pihole, then change it from the `etc-pihole/setupVars.conf`.

### Set fallback DNS

You must set your backbone `ISP_DNS` to your ISP's DNS. Or to a DNS IP Address that you believe will work, e.g. 1.1.1.1 or 8.8.8.8. This is used as the DNS that pihole itself will use to fetch it's configuration file.

If you want to set fallback DNS for the client (if you set your pihole as DHCPD server), then set `DNS1` and `DNS2` in that order of priority. You can also set it the same as `ISP_DNS`, or in my case I set `DNS1` to resolve over DOH (DNS over HTTPS).

### Set DNS Tunnel/DoH

You can specify DoH that CloudflareD will use (if you use CloudflareD as `DNS1`, the default settings). The settings is naemd `DNS_TUNNEL_DOH`

### Change private networking

It maybe possible that the default subnet conflicted with whatever subnet you have in your machine. In this case, change `DOCKER_SUBNET` to specify the subnet that docker will use. You must then change any settings with suffix `_PRIVATE_ADDRESS` to any valid IP Address in that subnet.


## Accessing the Admin UI

If you already setup your machine to use pi-hole, then you can simply click this link [pi.hole](http://pi.hole) to go to the admin interface (default settings).

Password is using whatever you set in `WEBPASSWORD`.

From there you can access it's functionality.

If you want to reach it by IP address, you may use `http://SERVER_IP:PIHOLE_HTTP_EXPOSE_PORT`.


## Backing up data

Use the admin interface or just keep `etc-pihole` somewhere safe.