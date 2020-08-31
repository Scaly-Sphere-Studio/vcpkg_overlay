# Get assets info from JSON
$assets = Get-Content -Path assets.json | ConvertFrom-Json;

# Download and unzip all assets
$to_remove = @();
foreach ($_ in $assets) {
    $pkgs = @(
        "$($_.pkgname):x86-windows",
        "$($_.pkgname):x64-windows"
    );
    $to_remove += $pkgs;
}

if ($to_remove) {
    vcpkg remove $to_remove;
}