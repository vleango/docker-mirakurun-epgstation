# Mirakurun + EPGstation + Ngrok

## Installation

1. get docker installed

```
https://www.smarthomebeginner.com/install-docker-on-ubuntu-22-04/
```

2. grab the project

```
git clone git@github.com:vleango/docker-ngrok.git
- switch to basic-auth branch
git clone git@github.com:vleango/docker-mirakurun-epgstation.git
```

3. add config/.tunnel.development.env

4. add certs
```
openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out MyCertificate.crt -keyout MyKey.key
mv MyCertificate.crt epgstation/config/
mv MyKey.key epgstation/config/
```

5. Install PX-S1UD driver
```
wget http://plex-net.co.jp/plex/px-s1ud/PX-S1UD_driver_Ver.1.0.1.zip
unzip PX-S1UD_driver_Ver.1.0.1.zip
sudo cp PX-S1UD_driver_Ver.1.0.1/x64/amd64/isdbt_rio.inp /lib/firmware/
sudo reboot
```

6. start
```
docker-compose up -d
```

7. Scan for channels
```
curl -X PUT "http://localhost:40772/api/config/channels/scan?minCh=10&maxCh=30&refresh=true"
```
- docker-compose will automatically add those channels. Just be patient

8. Restart
```
curl -X PUT "http://localhost:40772/api/restart"
```

9. Status
```
curl "http://localhost:40772/api/status" >> status.txt
```

