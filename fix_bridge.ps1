# Fix generated_bridge.dart for Windows compatibility
# This script fixes issues caused by ffigen generating Linux-specific types on Windows

$file = "flutter\lib\generated_bridge.dart"
if (!(Test-Path $file)) {
    Write-Host "generated_bridge.dart not found, skipping fix."
    exit 0
}

$content = Get-Content $file -Raw

# 1. Remove the typedef bool line (X11 header artifact)
$content = $content -replace 'typedef bool = ffi\.NativeFunction<ffi\.Int Function\(ffi\.Pointer<ffi\.Int>\)>;\r?\n\r?\n', ''

# 2. Replace Pointer<bool> with Pointer<ffi.Bool>
$content = $content -replace 'ffi\.Pointer<bool>', 'ffi.Pointer<ffi.Bool>'

# 3. Fix ffi.NativeFunction<ffi.Bool Function(DartPort -> ffi.NativeFunction<ffi.Uint8 Function(DartPort
$content = $content -replace 'ffi\.NativeFunction<ffi\.Bool Function\(DartPort', 'ffi.NativeFunction<ffi.Uint8 Function(DartPort'

$content | Set-Content $file -NoNewline
Write-Host "generated_bridge.dart fixed successfully."
