$ErrorActionPreference = "Stop";

git pull;

# Source functions & variables
. $PSScriptRoot\Functions.ps1;

# Get assets info from JSON
$assets = Get-Content -Path assets.json | ConvertFrom-Json;

# Download and unzip all assets
$assets | %{
    # Download
    Download-Asset $_ $token $dl_dir;
    # Remove pkd port dir if present
    $pkg_dir = "$ports_dir\$($_.pkgname)";
    if (Test-Path $pkg_dir) {
        Remove-Item -Force -Recurse $pkg_dir;
    }
    # Unzip
    Expand-Archive -Force -Path $dl_dir\$($_.filename) -DestinationPath $ports_dir;
}

# Install via vcpkg
$assets | %{
    Pkg-Install $_.pkgname;
}

# Remove deprecated pkgs
$all_sss = vcpkg list sss | %{ $_.Split(" ")[0] };
$new_pkgs = $assets | %{ Pkg-List $_.pkgname };
$deprecated = Compare-Object -ReferenceObject $all_sss -DifferenceObject $new_pkgs -PassThru;
if ($deprecated) {
    vcpkg remove $deprecated;
    $ports_to_remove = $deprecated | %{ $_.Split(":")[0] } | select -Unique;
    $ports_to_remove | %{
        Remove-Item -Force -Recurse "$ports_dir/$_";
    }
}