### partycopy
> Simple CLI file transfer utility for copyparty servers.

The utility acts similarly to **scp** and uses **curl** and **jq** under the hood.

Requirements build:
* make
* ldc2
* upx

Requirments run:
* curl
* jq

##### Build
```
make
make compress
sudo/doas make install
```

##### Usage

First create a server config file under */etc/partycopy/server_name.cfg* (or same directory as executable on Windows):

```properties
<username>
<password>
<protocol (e.g. https)>
<domain>
<response_format (e.g. json)>
```

Run the utility (`partycopy`, symlinked to **pcp**) to upload a **file** to your **remote_directory** (as named under your copyparty server's config file).

> pcp <server_name> <local_file> <remote_directory> ["--verbose"]

where <server_name> corresponds to a configuration file named "server_name.cfg" and "--verbose" is an optional switch to show each server operation.

For instance, to upload the file *partycopy.7z* to the *junk* directory on the *homelab* server, run:

> pcp homelab partycopy.7z junk
