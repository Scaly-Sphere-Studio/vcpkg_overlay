$ErrorActionPreference = "Stop";

# Source functions & variables
. $PSScriptRoot\Functions.ps1;

# Get assets info from JSON
$assets = Get-Content -Path assets.json | ConvertFrom-Json;

# Download and unzip all assets
$assets | %{
    # Download
    Download-Asset $_ $token $dl_dir -ErrorVariable err;
    # Unzip
    Expand-Archive -Force -Path $dl_dir\$($_.filename) -DestinationPath $ports_dir -ErrorVariable err;
}

# Install via vcpkg
$assets | %{
    Pkg-Install $_.pkgname;
}
