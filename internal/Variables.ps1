$token = $env:SSS_READ_TOKEN;
$base_dir = Resolve-Path "$PSScriptRoot\..";
$tmp_dir = "$base_dir\tmp";
$ports_dir = "$base_dir\ports";
$portfile = "$PSScriptRoot\portfile.cmake";
$libraries_file = "$base_dir\Libraries.json";
