### partycopy
> Simple CLI file transfer utility for [copyparty](https://github.com/9001/copyparty) servers.

The utility acts similarly to **scp** and uses **curl** and **jq** under the hood.

Requirements to build:
* make
* ldc2
* upx (optional)

Requirements to run:
* a copyparty server
* curl
* jq

##### Build
```
make
make compress
sudo/doas make install
```

#### Usage

First create a server config file under */etc/partycopy/server_name.cfg* (or same directory as executable on Windows):

```properties
<username>
<password>
<protocol (e.g. https)>
<domain>
<response_format (e.g. json)>
```

The utility works best if you have Read-Write-Delete permissions for your server user on the remote directory.

Run the utility (`partycopy`, symlinked to **pcp**) to upload, delete or download files.

> pcp <server_name> <file> <remote_directory> [operation = PUT] ["--verbose"]

where <server_name> corresponds to a configuration file named "server_name.cfg", file is a local or remote file depending on the operation, operation is to upload, delete or download a file AND "--verbose" is an optional switch to show each server operation.

##### Upload (local) file.

For instance, to upload the file *partycopy.7z* to the *junk* directory on the *homelab* server, run:

> pcp homelab partycopy.7z junk PUT

The PUT or 0 operation is the default, so it can be omitted for the same effect.

##### Delete (remote) file.

To delete the remote file *partycopy.7z* in the *junk* directory on the *homelab* server, run:

> pcp homelab partycopy.7z junk DEL

DEL or 1 operation is used.

##### Download (remote) file.

To download the remote file *partycopy.7z* in the *junk* directory on the *homelab* server, run:

> pcp homelab partycopy.7z junk GET

GET or 2 operation is used.

#### Disclaimer
Please note this is an unoffical project and is not endorsed by the author(s) of copyparty. I am just a fan and use it on my homelab.

