function Download-Asset
{
    param(
        [Parameter()] [object] $param,
        [Parameter()] [string] $token,
        [Parameter()] [string] $dl_dir
    );
    $repo = "$($param.owner)/$($param.repo)";
    $base_url = "https://api.github.com/repos/$repo";
    $headers = @{"Authorization" = "token $token"};

    # Check if we can access the repo
    try { Invoke-WebRequest -Headers $headers $base_url | Out-Null }
    catch {
        $msg = "Could not access '$repo' : " + ($_ | ConvertFrom-Json).message;
        Write-Error $msg;
        return;
    }
    
    # Get all releases
    $all_releases = (Invoke-WebRequest -Headers $headers "$base_url/releases") | ConvertFrom-Json;
    # Look for corresponding release from tag names
    $release = $all_releases | %{ if ($_.tag_name -eq $param.tag) { return $_ } };
    # Check if release was found
    if (!$release) {
        $msg = "Could not find any release with a tag of '$($param.tag)' from '$repo'";
        Write-Error $msg;
        return;
    }

    # Look for the file in assets
    foreach ($asset in $release.assets) {
        if ($asset.name -eq $param.filename) {
            $file = $asset;
        }
    }
    # Check if we found the file
    if (!$file) {
        $msg = "Could not find '$($param.filename)' in tag '$($param.tag)' from '$repo'";
        Write-Error -TargetObject bruh $msg;
        return
    }

    # Check if the file was previously downloaded, and if it needs an update
    $local_file = "$dl_dir\$($param.filename)";
    if (Test-Path $local_file) {
        # Target exists, check if up to date
        $last_write_time = $(Get-Item $local_file | %{$_.LastWriteTime}).ToUniversalTime();
        if ($last_write_time -ge $file.updated_at) {
            # Target is up to date, stop there
            Write-Output "$local_file is up to date.";
            return;
        } else {
            # Target is outdated
            Remove-Item $local_file;
            Write-Output "$local_file is outdated, starting download...";
        }
    } else {
        # Target does not exist
        Write-Output "$local_file not found, starting download...";
    }

    # Download the target
    $headers.Add("Accept", "application/octet-stream");
    Invoke-WebRequest -Headers $headers -OutFile "$local_file" $file.url -ErrorVariable err;
    if (!($err)) {
        Write-Output "$local_file successfully downloaded.";
    }
}

function Pkg-Triplets {
    param(
        [Parameter()] [string] $pkgname
    );

    $pkgs = @(
        "$($pkgname):x86-windows",
        "$($pkgname):x64-windows"
    );

    return $pkgs;
}

function Pkg-List {
    param(
        [Parameter()] [string] $pkgname
    );
    $ErrorActionPreference = "Stop";

    $listed = @();
    Pkg-Triplets $pkgname | foreach {
        if (vcpkg list $_) {
            $listed += $_;
        }
    };

    return $listed;
}

function Pkg-Remove {
    param(
        [Parameter()] [string] $pkgname
    );
    $ErrorActionPreference = "Stop";

    $listed = Pkg-List $pkgname;
    if ($listed) {
        vcpkg remove $listed;
    }
}

function Pkg-Install {
    param(
        [Parameter()] [string] $pkgname
    );
    $ErrorActionPreference = "Stop";
    
    # Remove old installs
    Pkg-Remove $pkgname;

    # Install freshly
    vcpkg install $(Pkg-Triplets $pkgname);
}