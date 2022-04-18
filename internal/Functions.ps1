. $PSScriptRoot\Variables.ps1;

# Create directories if needed
if (!(Test-Path $dl_dir)) {
    New-Item -Path $dl_dir -ItemType directory | Out-Null
}
if (!(Test-Path $ports_dir)) {
    New-Item -Path $ports_dir -ItemType directory | Out-Null
}

function Download-Port
{
    param(
        [Parameter()] [object] $param,
        [Parameter()] [string] $token
    );
    $repo_full = "$($param.repo_owner)/$($param.repo_name)";
    $base_url = "https://api.github.com/repos/$repo_full";
    $headers = @{"Authorization" = "token $token"};

    # Check if we can access the repo
    try { Invoke-WebRequest -Headers $headers $base_url | Out-Null }
    catch {
        $msg = "Could not access '$repo_full': " + ($_ | ConvertFrom-Json).message;
        Write-Error $msg;
        return;
    }
    
    # Get all releases
    $all_releases;
    try {
        $all_releases = (Invoke-WebRequest -Headers $headers "$base_url/releases") | ConvertFrom-Json;
    }
    catch {
        $msg = "No release for repo '$repo_full'";
        Write-Error $msg;
        return;
    }
    # Look for corresponding release from tag names
    $release = $all_releases | ?{ $_.tag_name -eq $param.version_tag };
    # Check if release was found, and if "latest" was requested
    if ($param.version_tag -eq "latest" || !$release) {
        try {
            $release = (Invoke-WebRequest -Headers $headers "$base_url/releases/latest") | ConvertFrom-Json;
        }
        catch {
            $msg = "No 'latest' release for repo '$repo_full'";
            Write-Error $msg;
            return;
        }
    }

    # Download the target
    $tmp_dir = "$base_dir\tmp";
    New-Item -ItemType Directory -Force $tmp_dir | Out-Null;
    $archive = "$tmp_dir\$($param.vcpkg_name).zip";
    Invoke-WebRequest -Headers $headers -OutFile "$archive" $release.zipball_url -ErrorVariable err;
    if ($err) {
        Remove-Item -Recurse -Force $tmp_dir;
        Write-Error "$archive failed to download: $err";
        return
    }

    # Create port
    $archives_output = "$tmp_dir\$($param.vcpkg_name)";
    Expand-Archive -Path $archive -DestinationPath $archives_output;
    $sources = Resolve-Path "$archives_output\*";
    Create-Port $param.vcpkg_name $param.version_tag $sources;
    Remove-Item -Recurse -Force $tmp_dir;
}

function Create-Port {
    param(
        [Parameter()] [string] $vcpkg_name,
        [Parameter()] [string] $tag,
        [Parameter()] [string] $folder_path
    );

    # Save previous build if present, or create the folder
    $port = "$ports_dir\$vcpkg_name";
    if (Test-Path $port) {
        $port = Resolve-Path $port;
        Remove-Item -Recurse -Force $port/*;
    }
    else {
        New-Item -ItemType Directory $port | Out-Null;
    }

    # Copy new sources
    Copy-Item -Recurse -Force -Path $folder_path/* -Exclude .vs,.git* -Destination $port;

    # Add version to CONTROL file
    $control = Get-Content -Path $port\CONTROL;
    $control += "Version: $tag";
    $control | Out-File $port\CONTROL -Encoding ascii;

    # Copy portfile.cmake
    Copy-Item -Path $PSScriptRoot\portfile.cmake -Destination $port;
}

function Pkg-Triplets {
    param(
        [Parameter()] [string] $vcpkg_name
    );

    $pkgs = @(
        "$($vcpkg_name):x86-windows",
        "$($vcpkg_name):x64-windows"
    );

    return $pkgs;
}

function Pkg-List {
    param(
        [Parameter()] [string] $vcpkg_name
    );

    $listed = @();
    Pkg-Triplets $vcpkg_name | foreach {
        if (vcpkg list $_) {
            $listed += $_;
        }
    };

    return $listed;
}

function Pkg-Install {
    param(
        [Parameter()] [string] $vcpkg_name
    );

    $pkg = $(Pkg-Triplets $vcpkg_name);

    $listed = Pkg-List $vcpkg_name;
    $not_listed = Compare-Object -ReferenceObject "$pkg" -DifferenceObject "$listed" -PassThru;
    # Upgrade old installed versions
    if ($listed) {
        vcpkg upgrade --no-dry-run $listed;
    }
    # Install non installed versions
    if ($not_listed) {
        vcpkg install $not_listed.Split(" ");
    }

    # Log output
    $installed = Pkg-List $vcpkg_name;
    $not_installed = Compare-Object -ReferenceObject "$pkg" -DifferenceObject "$installed" -PassThru;
    if (!($not_installed)) {
        Write-Output "'$vcpkg_name' successfully installed.`n";
    }
    else {
        if ($installed) {
            Write-Error "'$vcpkg_name' could only be partially installed.`n";
        }
        else {
            Write-Error "'$vcpkg_name' could not be installed.`n";
        }
    }
}

function Pkg-Remove {
    param(
        [Parameter()] [string] $vcpkg_name
    );

    $listed = Pkg-List $vcpkg_name;
    if ($listed) {
        vcpkg remove $listed;
    }
}