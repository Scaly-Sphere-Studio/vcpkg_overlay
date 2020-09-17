$ErrorActionPreference = "Stop";

# Source functions & variables
. $PSScriptRoot\Functions.ps1;

# Get assets info from JSON
$assets = Get-Content -Path assets.json | ConvertFrom-Json;

# Download and unzip all assets
$assets | %{
    # Download
    Download-Asset $_ $token $dl_dir;
    # 
    if (Test-Path "$ports_dir\$_.pkgname") {
        Remove-Item -Force -Recurse "$ports_dir\$_.pkgname";
    }
    # Unzip
    Expand-Archive -Force -Path $dl_dir\$($_.filename) -DestinationPath $ports_dir;
}

# Install via vcpkg
$assets | %{
    Pkg-Install $_.pkgname;
}
