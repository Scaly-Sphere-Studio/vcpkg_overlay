$ErrorActionPreference = "Stop";

# Pull repo
Write-Host "> Pulling this repository ...";
git -C $PSScriptRoot pull --force;
Write-Host "";

# Source functions & variables
. $PSScriptRoot\internal\Functions.ps1;

# Get libraries info from JSON
$libraries = Get-Content -Path $libraries_file | ConvertFrom-Json;

# Download and unzip sources
Write-Host "> Downloading sources ..."
$libraries | %{
    Download-Port $_ $token;
}
Write-Host "";

# Upgrade vcpkg
. $base_dir\UpgradeVcpkg.ps1;
Write-Host "";

# Build via Visual Studio then install via vcpkg
Write-Host "> Installing sources via vcpkg ..."
Pkg-Install $($libraries | %{ $_.vcpkg_name });