param(
    [Parameter()] [string] $pkgname,
    [Parameter()] [string] $archive_path
);

$ErrorActionPreference = "Stop";

# Source functions & variables
. $PSScriptRoot\Functions.ps1;


# Set local variables
$pkg_dir = "$ports_dir\$pkgname";
$control_file = "$pkg_dir\CONTROL";

# Remove the old package directory if present
if (Test-Path $pkg_dir) {
    Remove-Item -Recurse -Force $pkg_dir;
}

# Unzip local archive into ports directory
Expand-Archive -Force -Path $archive_path -DestinationPath $ports_dir;

# Overwrite old CONTROL file with local "Version :"
$control = Get-Content -Path $control_file;
$new_control = @();
$control | %{
    if ($_ -match "Version: ") {
        $date = $(Get-Date -UFormat %s).Split(",")[0];
        $new_control += "Version: local_$date";
    } else {
        $new_control += $_;
    }
}
$new_control | Out-File $control_file -Encoding ASCII;

$ErrorActionPreference = "Continue";

# Install pkg
Pkg-Install $pkgname -ErrorVariable err;

# Remove the package directory if the install failed
if ($err) {
    Remove-Item -Recurse -Force $pkg_dir;
}
