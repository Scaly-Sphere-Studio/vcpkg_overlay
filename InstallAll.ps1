$ErrorActionPreference = "Stop";

# Upgrade vcpkg
. $PSScriptRoot\UpgradeVcpkg.ps1;

#Write-Host "Pulling this repository ...";
#git -C $PSScriptRoot pull;

# Source functions & variables
. $PSScriptRoot\Functions.ps1;

# Get assets info from JSON
$assets = Get-Content -Path $PSScriptRoot\assets.json | ConvertFrom-Json;

# Download and unzip sources
$assets | %{
    Download-Port $_ $token;
}

# Build via Visual Studio then install via vcpkg
$assets | %{
    Build-Port $ports_dir\$($_.pkgname);
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