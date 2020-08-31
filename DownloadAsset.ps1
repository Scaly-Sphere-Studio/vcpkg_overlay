function Download-Asset
{
    param(
        [Parameter()] [string] $OWNER,
        [Parameter()] [string] $REPO,
        [Parameter()] [string] $TAG,
        [Parameter()] [string] $FILENAME,
        [Parameter()] [string] $TOKEN
    );

    $headers = @{"Authorization" = "token $TOKEN"};
    $base_url = "https://api.github.com/repos/$OWNER/$REPO";

    # Check if we can access the repo
    try { Invoke-WebRequest -Headers $headers $base_url | Out-Null }
    catch {
        $msg = "Could not access '$OWNER/$REPO' : " + ($_ | ConvertFrom-Json).message;
        Write-Error $msg;
        return;
    }
    
    # Get all releases
    $all_releases = (Invoke-WebRequest -Headers $headers "$base_url/releases") | ConvertFrom-Json;
    # Look for corresponding release from tag names
    $release = $all_releases | %{ if ($_.tag_name -eq $TAG) { return $_ } };
    # Check if release was found
    if (!$release) {
        $msg = "Could not find any release with a tag of '$TAG' from '$OWNER/$REPO'";
        Write-Error $msg;
        return;
    }

    # Look for the file in assets
    foreach ($asset in $release.assets) {
        if ($asset.name -eq $FILENAME) {
            $file = $asset;
        }
    }
    # Check if we found the file
    if (!$file) {
        $name = $release.name;
        $msg = "Asset '$FILENAME' was not found in '$name' from '$OWNER/$REPO'";
        Write-Error $msg;
        return
    }

    # Check if the file was previously downloaded, and if it needs an update
    $local_file = ".\downloads\$FILENAME";
    if (Test-Path $local_file) {
        # Target exists, check if up to date
        $last_write_time = $(Get-Item $local_file | %{$_.LastWriteTime});
        if ($last_write_time -ge $file.updated_at) {
            # Target is up to date, stop there
            Write-Output "$local_file is up to date.";
            return;
        } else {
            # Target is outdated
            Remove-Item $local_file;
            Write-Output "$local_file is outdated, starting download.";
        }
    } else {
        # Target does not exist
        Write-Output "$local_file not found, starting download.";
    }

    # Download the target
    $headers.Add("Accept", "application/octet-stream");
    Invoke-WebRequest -Headers $headers -OutFile "$local_file" $file.url
}
