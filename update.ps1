. .\DownloadAsset.ps1

$OWNER = "Scaly-Sphere-Studio"
$REPO = "debug"
$TAG = "v0.1.0"
$FILENAME = "sss-debug.zip"

# Bad credentials
Download-Asset $OWNER $REPO $TAG $FILENAME "wrongtoken" -ErrorVariable err;
# Repo not found
Download-Asset $OWNER "doesnotexist" $TAG $FILENAME $env:SSS_READ_TOKEN -ErrorVariable err;
# Tag not found
Download-Asset $OWNER $REPO "doesnotexist" $FILENAME $env:SSS_READ_TOKEN -ErrorVariable err;
# File not found
Download-Asset $OWNER $REPO $TAG "doesnotexist" $env:SSS_READ_TOKEN -ErrorVariable err;

$error.clear()

# Good call
Download-Asset $OWNER $REPO $TAG $FILENAME $env:SSS_READ_TOKEN -ErrorVariable err;

#Expand-Archive -Force -Path $PWD\$FILENAME -DestinationPath $PWD

#$ASSETS_TXT = Get-Content -Path assets.txt
