# Clean previous doc files
Remove-Item -Recurse -Force "$PSScriptRoot/doxygen/*";
# Generate doc
doxygen.exe;
# Create shortcut to index.html
$SourceFilePath = Resolve-Path "$PSScriptRoot\doxygen\html\index.html";
$ShortcutPath = "$PSScriptRoot\Documentation.lnk";
$WScriptObj = New-Object -ComObject ("WScript.Shell");
$shortcut = $WscriptObj.CreateShortcut($ShortcutPath);
$shortcut.TargetPath = $SourceFilePath;
$shortcut.Save();
