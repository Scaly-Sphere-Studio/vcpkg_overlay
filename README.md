# vcpkg_overlay
This repository is used along with [vcpkg](https://github.com/microsoft/vcpkg) _(which you need to install yourself)_ to install our own prebuilt C/C++ private libraries.<br/>

## Install
If you just installed vcpkg, you might need to go through a few more steps:
- Expand the **`PATH`** environment variable with the path to the directory where `vcpkg.exe` is located.
- Run `vcpkg integrate install` to be able to use the installed libraries in Visual Studio.
- Make at least one manual install, eg: `vcpkg install sdl2`, to ensure vcpkg installed its dependencies.

### Clone the repo and set VCPKG_OVERLAY_PORTS
Firstly, clone this repo wherever you want. For example:
```ps1
git clone "https://github.com/Scaly-Sphere-Studio/vcpkg_overlay/" "C:\dev\vcpkg_overlay"
```
Then, add the path to the future `ports/` subdirectory (which will be created later on) to the **`VCPKG_OVERLAY_PORTS`** environment variable.<br/>
```ps1
$env:VCPKG_OVERLAY_PORTS = "path_to_parent_dir\vcpkg_overlay\ports"
```

### Obtain READ permissions or more
Contact any member of the [@Admins](https://github.com/orgs/Scaly-Sphere-Studio/teams/admins/members) team to set your permission levels on the library repository.<br/>

### Use a Personal Access Token to set SSS_READ_TOKEN
A new token can be generated in your [github profile settings](https://github.com/settings/tokens).<br/>
Pick a name describing your token (eg: _SSS_READ_TOKEN_, to match the environment variable), and select the `repo` scope.<br/>
You can then create the **`SSS_READ_TOKEN`** environment variable with the generated key for value.<br/>
```ps1
$env:SSS_READ_TOKEN = "YourPersonalAccessToken"
```

### Run InstallAll.ps1
Once **`VCPKG_OVERLAY_PORTS`** and **`SSS_READ_TOKEN`** are set, you should be able to execute the install script.<br/>
```ps1
.\InstallAll.ps1
```
This will download prebuilt release archives listed in [assets.json](./assets.json) from GitHub, and install them with vcpkg.<br/>

## Installing local libraries
If you need to install a local version of a library (to test it before publishing it, for example), their folder should contain multiple scripts.<br/>
### To build and archive an export of the library
```ps1
.\export.ps1
```
### To locally install the exported archive
```ps1
.\local_install.ps1
```
### To remove the local installation of the exported archive
```ps1
.\local_remove.ps1
```

## Uninstall
To remove **ALL** libraries installed via this repo, you can execute the uninstall script.<br/>
```ps1
.\UninstallAll.ps1
```
This will uninstall the libraries from vcpkg, and delete the prebuilt packages & downloaded archives.<br/>
