$ErrorActionPreference = "Stop";

# Upgrade vcpkg
. $PSScriptRoot\UpgradeVcpkg.ps1;

# Ignore libraries.json changes
git -C $PSScriptRoot update-index --assume-unchanged Libraries.json;

#Write-Host "Pulling this repository ...";
git -C $PSScriptRoot pull;

# Source functions & variables
. $PSScriptRoot\internal\Functions.ps1;

# Get libraries info from JSON
$libraries = Get-Content -Path $libraries_file | ConvertFrom-Json;

# Download and unzip sources
$libraries | %{
    Download-Port $_ $token;
}

# Build via Visual Studio then install via vcpkg
$libraries | %{
    Pkg-Install $_.vcpkg_name;
}

# Remove no longer used pkgs
$all_sss = vcpkg list sss | %{ $_.Split(" ")[0] };
$new_pkgs = $libraries | %{ Pkg-List $_.vcpkg_name };
$no_longer_used;
if ($new_pkgs) {
    $no_longer_used = Compare-Object -ReferenceObject $all_sss -DifferenceObject $new_pkgs -PassThru;
} else {
    $no_longer_used = $all_sss;
}
if ($no_longer_used) {
    vcpkg remove $no_longer_used;
    $ports_to_remove = $no_longer_used | %{ $_.Split(":")[0] } | select -Unique;
    $ports_to_remove | %{
        Remove-Item -Force -Recurse "$ports_dir/$_";
    }
}