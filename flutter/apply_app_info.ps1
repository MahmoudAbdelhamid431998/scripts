if (!(Test-Path app_info.json)) {
    Write-Host "[-] Error: app_info.json not found! Please create it first." -ForegroundColor Red
    exit 1
}

$info = Get-Content app_info.json -Raw -Encoding utf8 | ConvertFrom-Json
$name = $info.appName
$shortDesc = $info.appShortDescription
$longDesc = $info.appLongDescription
$bundle = $info.appBundle
$icon = $info.appIconPath

function Update-FileContent($path, $pattern, $replacement) {
    if (Test-Path $path) {
        $c = Get-Content $path -Raw -Encoding utf8
        $newC = [regex]::Replace($c, $pattern, $replacement)
        if ($newC -ne $c) {
            Set-Content -Path $path -Value $newC -Encoding utf8 -NoNewline
            Write-Host "  [✓] Updated $path" -ForegroundColor Green
        }
    }
}

Write-Host "`n[+] Applying App Info: '$name' ($bundle)...`n" -ForegroundColor Cyan

# 1. Android
Update-FileContent "android/app/src/main/AndroidManifest.xml" 'android:label="[^"]*"' "android:label=`"$name`""
Update-FileContent "android/app/build.gradle" 'applicationId\s+["=][^"\n]*["=]?' "applicationId = `"$bundle`""
Update-FileContent "android/app/build.gradle" 'namespace\s+["=][^"\n]*["=]?' "namespace = `"$bundle`""
Update-FileContent "android/app/build.gradle.kts" 'applicationId\s*=\s*"[^"]*"' "applicationId = `"$bundle`""
Update-FileContent "android/app/build.gradle.kts" 'namespace\s*=\s*"[^"]*"' "namespace = `"$bundle`""

# 2. iOS
Update-FileContent "ios/Runner/Info.plist" '<key>CFBundleDisplayName</key>\s*<string>[^<]*</string>' "<key>CFBundleDisplayName</key>`n`t<string>$name</string>"
Update-FileContent "ios/Runner/Info.plist" '<key>CFBundleName</key>\s*<string>[^<]*</string>' "<key>CFBundleName</key>`n`t<string>$name</string>"
Update-FileContent "ios/Runner.xcodeproj/project.pbxproj" 'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*[^;]*;' "PRODUCT_BUNDLE_IDENTIFIER = $bundle;"

# 3. Web
Update-FileContent "web/index.html" '<title>[^<]*</title>' "<title>$name</title>"
Update-FileContent "web/index.html" '<meta\s+name="description"\s+content="[^"]*"' "<meta name=`"description`" content=`"$shortDesc`""
if (Test-Path "web/manifest.json") {
    $m = Get-Content "web/manifest.json" -Raw -Encoding utf8 | ConvertFrom-Json
    $m.name = $name
    $m.short_name = $name
    $m.description = if ($shortDesc) { $shortDesc } else { $longDesc }
    $m | ConvertTo-Json -Depth 10 | Set-Content "web/manifest.json" -Encoding utf8
    Write-Host "  [✓] Updated web/manifest.json" -ForegroundColor Green
}

# 4. macOS
Update-FileContent "macos/Runner/Configs/AppInfo.xcconfig" 'PRODUCT_NAME\s*=\s*.*' "PRODUCT_NAME = $name"
Update-FileContent "macos/Runner/Configs/AppInfo.xcconfig" 'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*.*' "PRODUCT_BUNDLE_IDENTIFIER = $bundle"

# 5. Windows
Update-FileContent "windows/runner/main.cpp" 'window\.Create\(L"[^"]*"' "window.Create(L`"$name`""
Update-FileContent "windows/runner/Runner.rc" 'VALUE "FileDescription", "[^"]*"' "VALUE `"FileDescription`", `"$($shortDesc ? $shortDesc : $name)`""
Update-FileContent "windows/runner/Runner.rc" 'VALUE "ProductName", "[^"]*"' "VALUE `"ProductName`", `"$name`""

# 6. Linux
Update-FileContent "linux/my_application.cc" 'gtk_header_bar_set_title\(header_bar,\s*"[^"]*"' "gtk_header_bar_set_title(header_bar, `"$name`""
Update-FileContent "linux/my_application.cc" 'gtk_window_set_title\(window,\s*"[^"]*"' "gtk_window_set_title(window, `"$name`""

# 7. Launcher Icons
if ($icon -and (Test-Path $icon)) {
    $yaml = @"
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "$icon"
  min_sdk_android: 21
  web:
    generate: true
    image_path: "$icon"
  windows:
    generate: true
    image_path: "$icon"
  macos:
    generate: true
    image_path: "$icon"
  linux:
    generate: true
    image_path: "$icon"
"@
    Set-Content -Path "flutter_launcher_icons.yaml" -Value $yaml -Encoding utf8
    Write-Host "  [✓] Generated flutter_launcher_icons.yaml" -ForegroundColor Green
    
    flutter pub add --dev flutter_launcher_icons
    dart run flutter_launcher_icons
} else {
    Write-Host "  [!] Icon file not found or not specified at '$icon'" -ForegroundColor Yellow
}

Write-Host "`n[✓] All platform metadata updated successfully!" -ForegroundColor Green
