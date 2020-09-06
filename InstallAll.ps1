. .\Functions.ps1

$token = $env:SSS_READ_TOKEN;
$base_dir = Get-Location;
$dl_dir = "$base_dir\downloads";
$ports_dir = "$base_dir\ports";

# Create directories if needed
if (!(Test-Path $dl_dir)) {
    New-Item -Path $dl_dir -ItemType directory | Out-Null
}
if (!(Test-Path $ports_dir)) {
    New-Item -Path $ports_dir -ItemType directory | Out-Null
}

# Get assets info from JSON
$assets = Get-Content -Path assets.json | ConvertFrom-Json;

# Download and unzip all assets
foreach ($_ in $assets) {
    # Error status
    $_ | Add-Member -NotePropertyName error -NotePropertyValue $false;
    # Download
    Download-Asset $_ $token $dl_dir -ErrorVariable err;
    if ($err) {
        $_.error = $true;
        continue
    }
    # Unzip
    Expand-Archive -Force -Path $dl_dir\$($_.filename) -DestinationPath $ports_dir -ErrorVariable err;
    if ($err) {
        $_.error = $true;
        continue
    }
}

# Install via vcpkg
foreach ($_ in $assets) {
    # Skip if an error occured
    if ($_.error) {
        continue
    }

    # Triplets
    $pkgs = @(
        "$($_.pkgname):x86-windows",
        "$($_.pkgname):x64-windows"
    );
    
    # Remove old installs
    $to_remove = @();
    $pkgs | foreach {
        if (vcpkg list $_) {
            $to_remove += $_;
        }
    }
    if ($to_remove) {
        vcpkg remove $to_remove;
    }

    # Install freshly
    vcpkg install $pkgs;
}
