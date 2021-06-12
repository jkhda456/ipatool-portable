# ipatool-portable
ipatool-portable is windows port of majd's ipatool

## Requirements
* Apple ID set up to use the App Store.
* MAC Address

## Usage

```
usage: ipatool.exe (lookup|search|download) [params]

lookup
 --appid, -i        : app bundle id

search
 --keyword, -k      : search keyword

download
 --appid, -i        : app bundle id
 --appleid, -e      : apple user id
 --password, -p     : apple user password
 --output-dir, -o   : download path or download file name
 --uuid, -u         : MAC address of your owned Mac (without this parameter, use this PC's MAC address)
```
