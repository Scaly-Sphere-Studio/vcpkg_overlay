. $PSScriptRoot\Variables.ps1;
$ErrorActionPreference = "Stop";

# Create directories if needed
if (!(Test-Path $ports_dir)) {
    New-Item -Path $ports_dir -ItemType directory | Out-Null
}

function Download-Port
{
    param(
        [Parameter(Mandatory)] [object] $param,
        [Parameter(Mandatory)] [string] $token
    );
    $repo_full = "$($param.repo_owner)/$($param.repo_name)";
    $base_url = "https://api.github.com/repos/$repo_full";
    $headers = @{"Authorization" = "token $token"};

    # Check if we can access the repo
    $http_code = (Invoke-WebRequest -Uri $base_url -Headers $headers).StatusCode;
    if ($http_code -ne 200) {
        $msg = "Could not access '$repo_full': Returned " + $http_code;
        Write-Error $msg;
        return;
    }
    
    # Get all releases
    $all_releases;
    try {
        $all_releases = (Invoke-WebRequest -Uri $base_url/releases -Headers $headers) | ConvertFrom-Json;
    }
    catch {
        $msg = "No release for repo '$repo_full'";
        Write-Error $msg;
        return;
    }
    # Look for corresponding release from tag names
    $release = $all_releases | ?{ $_.tag_name -eq $param.version_tag };
    # Check if release was found, and if "latest" was requested
    if (($param.version_tag -eq "latest") -or !$release) {
        try {
            $release = (Invoke-WebRequest -Uri $base_url/releases/latest -Headers $headers) | ConvertFrom-Json;
        }
        catch {
            $msg = "No 'latest' release for repo '$repo_full'";
            Write-Error $msg;
            return;
        }
    }

    # Download the target
    New-Item -ItemType Directory -Force $tmp_dir | Out-Null;
    $archive = "$tmp_dir\$($param.vcpkg_name).zip";
    Write-Host "Downloading $archive ...";
    $ProgressPreference = 'SilentlyContinue';
    Invoke-WebRequest -Uri $release.zipball_url -Headers $headers -OutFile $archive
    $ProgressPreference = 'Continue';
    if ($err) {
        Remove-Item -Recurse -Force $tmp_dir;
        Write-Error "$archive failed to download: $err";
        return
    }

    # Create port
    $archives_output = "$tmp_dir\$($param.vcpkg_name)";
    Expand-Archive -Path $archive -DestinationPath $archives_output;
    $sources = Resolve-Path "$archives_output\*";
    Create-Port $param.vcpkg_name $release.tag_name $sources;
    Remove-Item -Recurse -Force $tmp_dir;
}

function Create-Port {
    param(
        [Parameter(Mandatory)] [string] $vcpkg_name,
        [Parameter(Mandatory)] [string] $tag,
        [Parameter(Mandatory)] [string] $folder_path
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
    $control = "$port\CONTROL";
    $control_tmp = "$control.tmp";
    "Version: $tag" | Out-File $control_tmp -Encoding ascii;
    Add-Content -Path $control_tmp -Value (Get-Content -Path $control);
    rm $control;
    mv $control_tmp $control;

    # Copy portfile.cmake
    Copy-Item -Path $PSScriptRoot\portfile.cmake -Destination $port;
}

function Pkg-Triplets {
    param(
       [Parameter(Mandatory, ValueFromRemainingArguments)] [string[]] $vcpkg_name
    );

    $pkgs = @();
    $vcpkg_name | %{
        $pkgs += "$($_):x86-windows";
        $pkgs += "$($_):x64-windows";
    }

    return $pkgs;
}

function Pkg-List {
    param(
        [Parameter(Mandatory, ValueFromRemainingArguments)] [string[]] $vcpkg_name
    );

    $listed = @();
    Pkg-Triplets $vcpkg_name | foreach {
        $ret = vcpkg list $_
        if ($ret -contains $_) {
            $listed += $_;
        }
    };

    return $listed;
}

function Pkg-Install {
    param(
        [Parameter(Mandatory, ValueFromRemainingArguments)] [string[]] $vcpkg_name
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
        vcpkg install --recurse $not_listed.Split(" ");
    }
}

function Pkg-Remove {
    param(
        [Parameter(Mandatory, ValueFromRemainingArguments)] [string[]] $vcpkg_name
    );

    $listed = Pkg-List $vcpkg_name;
    if ($listed) {
        vcpkg remove $listed;
    }
}
