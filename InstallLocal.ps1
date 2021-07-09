param(
    [Parameter()] [string] $pkg_name,
    [Parameter()] [string] $pkg_path
);

$ErrorActionPreference = "Stop";

# Source functions & variables
. $PSScriptRoot\Functions.ps1;

# Build sources
Build-Port $pkg_path;

# Export sources
$date = $(Get-Date -UFormat %s).Split(",")[0];
Create-Port $pkg_name local_$date $pkg_path;

# Install pkg
Pkg-Install $pkg_name;