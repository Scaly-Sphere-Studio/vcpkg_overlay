param(
    [Parameter()] [string] $pkgname,
    [Parameter()] [string] $archive_path
);

$ErrorActionPreference = "Stop";

$base_dir = $PSScriptRoot;
$ports_dir = "$base_dir\ports";
$assets_file = "$base_dir\local_assets.json";
$functions_file = "$base_dir\Functions.ps1";

# Unzip local archive into ports directory
Expand-Archive -Force -Path $archive_path -DestinationPath $ports_dir -ErrorVariable err;

# Source functions
. $functions_file;

# Install pkg
Pkg-Install $pkgname;

# Retrieve local assets list
$local_assets = Get-Content -Path $assets_file | ConvertFrom-Json;
if (!($local_assets -is [array])) {
    $local_assets = ,$local_assets;
}
# Check if pkg is listed
$pkg_is_listed = !(!($local_assets | ?{$_ -eq $pkgname}));

# Verify Install
if (Pkg-List $pkgname) {
    # Add pkg to local assets if needed
    if (!$pkg_is_listed) {
        $local_assets += $pkgname;
        $local_assets | ConvertTo-Json | Out-File $assets_file;
    }
    Write-Output "'$pkgname' successfully installed."
} else {
    # Remove pkg if needed
    if ($pkg_is_listed) {
        # Remove pkg folder
        Remove-Item -Recurse -Force "$ports_dir\$pkgname";
        # Unlist pkg from json
        $local_assets = $local_assets | ?{$_ -ne $pkgname};
        $local_assets | ConvertTo-Json | Out-File $assets_file;
    }
    Write-Error "'$pkgname' could not be installed."
}
