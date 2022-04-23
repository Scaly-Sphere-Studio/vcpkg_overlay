$ErrorActionPreference = "Stop";

# Clean previous doc files
$old_doc = "$PSScriptRoot/doxygen/*";
if (Test-Path $old_doc) {
    Remove-Item -Recurse -Force $old_doc;
}
$shortcut_path = Join-Path $PSScriptRoot "Documentation.lnk";
if (Test-Path $shortcut_path) {
    Remove-Item -Force $shortcut_path;
}
# Generate doc
$(type "$PSScriptRoot/Doxyfile"; echo "OUTPUT_DIRECTORY=$PSScriptRoot/doxygen") | doxygen.exe -
# Create shortcut to index.html
$index_path = Join-Path $PSScriptRoot "doxygen\html\index.html";
if (Test-Path $index_path) {
    $WScript_obj = New-Object -ComObject ("WScript.Shell");
    $shortcut = $WScript_obj.CreateShortcut($shortcut_path);
    $shortcut.TargetPath = $index_path;
    $shortcut.Save();
}