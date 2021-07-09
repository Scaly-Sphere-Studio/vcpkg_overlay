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
    $release = $all_releases | ?{ $_.tag_name -eq $param.tag };
    # Check if release was found
    if (!$release) {
        $msg = "Could not find any release with a tag of '$($param.tag)' from '$repo'";
        Write-Error $msg;
        return;
    }

    # Download the target
    New-Item -ItemType Directory -Force tmp | Out-Null;
    $archive = "tmp\$($param.pkgname).zip";
    Invoke-WebRequest -Headers $headers -OutFile "$archive" $release.zipball_url -ErrorVariable err;
    if ($err) {
        Write-Error "$archive failed to download : $err";
        return
    }

    # Create port
    $tmp_dir = "tmp\$($param.pkgname)";
    Expand-Archive -Path $archive -DestinationPath $tmp_dir;
    $sources = Resolve-Path "$tmp_dir\*";
    Create-Port $param.pkgname $param.tag $sources;
    Remove-Item -Recurse -Force tmp;
}

function Create-Port {
    param(
        [Parameter()] [string] $pkgname,
        [Parameter()] [string] $tag,
        [Parameter()] [string] $folder_path
    );

    # Save previous build if present, or create the folder
    $port = "$ports_dir\$pkgname";
    if (Test-Path $port) {
        $port = Resolve-Path $port;
        Get-ChildItem -Recurse $port | Select -ExpandProperty FullName `
            | ?{ $_ -notlike "$port\obj*" } `
            | ?{ $_ -notlike "$port\Debug*"} `
            | ?{ $_ -notlike "$port\Release*"} `
            | ?{ $_ -notlike "$port\x64*"} `
            | Remove-Item -Recurse -Force;
    }
    else {
        New-Item -ItemType Directory $port;
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

function Build-Port {
    param(
        [Parameter()] [string] $path
    );

    # Project path & name
    $vcxproj    = Resolve-Path "$path\*.vcxproj";
    $proj_name  = $vcxproj.ToString().Split('\')[-1].Split('.')[0].ToLower();

    # Visual Studio parameters
    $vc_dir     = (Get-CimInstance MSFT_VSInstance).InstallLocation;
    if (!(Test-Path $vc_dir)) {
        $msg = "Could not find Microsoft Visual Studio.";
        Write-Error $msg;
    }
    $vc_varsall_bat = "$vc_dir\VC\Auxiliary\Build\vcvarsall.bat"
    $vc_build_cmd   = "devenv $vcxproj /Project $proj_name /Build"

    # List of configs to build
    $jobs = @(
        "`"Debug|x86`"",
        "`"Release|x86`"",
        "`"Debug|x64`"",
        "`"Release|x64`""
    )

    # Build configs in threads
    $jobs | %{
        $cmd = "`"$vc_varsall_bat`" x64 >NUL && $vc_build_cmd $_";
        $script = {
            param([Parameter()] [string] $arg);
            CMD /c $arg;
        }
        $_ = Start-Job -Name $_ -ScriptBlock $script -ArgumentList $cmd;
        $_;
    }
    Write-Host "";

    # Wait end of all threads
    Wait-Job $jobs | Out-Null;

    # Format and display outputs
    $success = 1;
    $jobs | %{
        $output = Receive-Job $_;
        $output;
        $result = $output.Split("\n")[-1];
        if ($result -like "*0 failed*") {
            Write-Host -ForegroundColor green "Build $_ succeeded.";
        }
        else {
            Write-Host -ForegroundColor red "Build $_ failed";
            $success = 0;
        }
        Remove-Job $_;
    }
    Write-Host "";

    if (!$success) {
        Write-Error "One or more build(s) failed.";
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

    $listed = @();
    Pkg-Triplets $pkgname | foreach {
        if (vcpkg list $_) {
            $listed += $_;
        }
    };

    return $listed;
}

function Pkg-Install {
    param(
        [Parameter()] [string] $pkgname
    );

    $pkg = $(Pkg-Triplets $pkgname);

    $listed = Pkg-List $pkgname;
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
    $installed = Pkg-List $pkgname;
    $not_installed = Compare-Object -ReferenceObject "$pkg" -DifferenceObject "$installed" -PassThru;
    if (!($not_installed)) {
        Write-Output "'$pkgname' successfully installed.`n";
    }
    else {
        if ($installed) {
            Write-Error "'$pkgname' could only be partially installed.`n";
        }
        else {
            Write-Error "'$pkgname' could not be installed.`n";
        }
    }
}

function Pkg-Remove {
    param(
        [Parameter()] [string] $pkgname
    );

    $listed = Pkg-List $pkgname;
    if ($listed) {
        vcpkg remove $listed;
    }
}