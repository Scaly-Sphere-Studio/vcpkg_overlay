$ErrorActionPreference = "Stop";

$vcpkg_dir = ($env:path).Split(";") | ?{ $_ -like "*\vcpkg" };
if ($vcpkg_dir -is [array]) {
    $vcpkg_dir = $vcpkg_dir[0];
}
if (!(Test-Path $vcpkg_dir)) {
    Write-Error "Could not find vcpkg from PATH environment variable.";
}

Write-Host "> Pulling vcpkg's repository ...";
git -C $vcpkg_dir pull;

Write-Host "`n> Rebuilding vcpkg.exe ...";
CMD /c $vcpkg_dir\bootstrap-vcpkg.bat

Write-Host "`n> Upgrading vcpkg's packages ...";
vcpkg upgrade --no-dry-run;