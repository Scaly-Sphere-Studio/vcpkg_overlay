Write-Output "Pulling vcpkg's repository ...";
git -C C:\dev\vcpkg\ pull;
Write-Output "Upgrading vcpkg's packages ...";
vcpkg upgrade --no-dry-run;