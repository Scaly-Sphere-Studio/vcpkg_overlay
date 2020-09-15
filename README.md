# vcpkg_overlay
This repository is used along with [vcpkg](https://github.com/microsoft/vcpkg) _(which you need to install yourself)_ to install our own prebuilt C/C++ private libraries.<br/>

## Install
### Clone and set the path
Clone this repo wherever you want, and add the path to the `ports/` subdirectory to the `VCPKG_OVERLAY_PORTS` environment variable.<br/>
```ps1
$env:VCPKG_OVERLAY_PORTS = "path_to_parent_dir\vcpkg_overlay\ports";
```

### Obtain READ permissions or more
Contact any member of the [@Admins](https://github.com/orgs/Scaly-Sphere-Studio/teams/admins/members) team to set your permission levels.<br/>

### Generate a Personal Access Token
A new token can be generated in your [profile settings](https://github.com/settings/tokens).<br/>
You can then add the token key to the `SSS_READ_TOKEN` environment variable.<br/>
```ps1
$env:SSS_READ_TOKEN = "yourpersonalaccesstoken";
```

### Install the library releases
Once `VCPKG_OVERLAY_PORTS` and `SSS_READ_TOKEN` are set, you should be able to execute the install script.<br/>
```ps1
.\InstallAll.ps1
```
This will download prebuilt release archives listed in [assets.json](./assets.json) from GitHub, and install them with vcpkg.<br/>

### Install modified library locally
If you need to install a local version of a library (to test it before publishing it, for example), the lib repo should contain multiple scripts.<br/>
#### To build and archive an export of the library 
```ps1
.\export.ps1
```
#### To locally install the exported archive
```ps1
.\local_install.ps1
```
#### To remove the local installation of the exported archive
```ps1
.\local_remove.ps1
```

## Uninstall
To remove all custom libraries installed via this repo, you can execute the uninstall script.<br/>
```ps1
.\UninstallAll.ps1
```
This will uninstall the libraries from vcpkg, and delete the prebuilt packages & downloaded archives.<br/>
