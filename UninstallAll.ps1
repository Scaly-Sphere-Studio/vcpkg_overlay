$ErrorActionPreference = "Stop";

# Source functions & variables
. $PSScriptRoot\Functions.ps1;

# List all packages in the ports directory
Write-Output "Retrieving packages to uninstall...";
$to_remove = @();
Get-ChildItem -Name $ports_dir | %{
    $installed = Pkg-List $_;
    $installed;
    $to_remove += $installed;
}

if (!$to_remove) {
    Write-Warning "Nothing to uninstall.";
    return;
}

# Uninstall all packages installed from the ports directory
if ($to_remove) {
    vcpkg remove $to_remove;
}
