param(
    [Parameter()] [string] $pkgname,
    [Parameter()] [string] $archive_path
);

$ErrorActionPreference = "Stop";

$base_dir = $PSScriptRoot;
$ports_dir = "$base_dir\ports";
$assets_file = "$base_dir\local_assets.json";
$functions_file = "$base_dir\Functions.ps1";

# Source functions
. $functions_file;

# Retrieve local assets list
$local_assets = Get-Content -Path $assets_file | ConvertFrom-Json;
if (!($local_assets -is [array])) {
    $local_assets = ,$local_assets;
}
# Check if pkg is listed
$pkg_is_listed = !(!($local_assets | ?{$_ -eq $pkgname}));

if (!$pkg_is_listed) {
    Write-Error "'$pkgname' is locally installed. It's possible a classic install overwrote the local one."
}

# Remove pkg
Pkg-Remove $pkgname;
# Remove pkg folder
Remove-Item -Recurse -Force "$ports_dir\$pkgname";
# Unlist pkg from json
$local_assets = $local_assets | ?{$_ -ne $pkgname};
$local_assets | ConvertTo-Json | Out-File $assets_file;
