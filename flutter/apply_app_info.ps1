if (!(Test-Path "app_info.json")) {
    Write-Host "[-] Error: app_info.json not found! Please create it first." -ForegroundColor Red
    exit 1
}

$info = Get-Content "app_info.json" -Raw -Encoding utf8 | ConvertFrom-Json
$name =$info.appName
$version =$info.appVersion
$shortDesc =$info.appShortDescription
$longDesc =$info.appLongDescription
$bundle =$info.appBundle
$icon =$info.appIconPath

# Split version to name and code (e.g. 1.0.0+1)
$verParts = if ($version) {$version.Split('+') } else { @("1.0.0", "1") }
$verName = $verParts[0]$verCode = if ($verParts.Length -gt 1) {$verParts[1] } else { "1" }

$desc = if ($shortDesc) { $shortDesc } else {$name }
$manifestDesc = if ($shortDesc) { $shortDesc } else {$longDesc }

function Update-FileContent($path, $pattern,$replacement) {
    if (Test-Path $path) {
        $c = [System.IO.File]::ReadAllText((Resolve-Path$path), [System.Text.Encoding]::UTF8)
        $newC = [regex]::Replace($c, $pattern,$replacement)
        if ($newC -ne$c) {
            [System.IO.File]::WriteAllText((Resolve-Path $path),$newC, [System.Text.Encoding]::UTF8)
            Write-Host "  [✓] Updated $path" -ForegroundColor Green
        }
    }
}

Write-Host "`n[+] Applying App Info: '$name' (v$version - $bundle)...`n" -ForegroundColor Cyan

# 1. pubspec.yaml
if ($version) { Update-FileContent "pubspec.yaml" '(?m)^version:\s*.*$' "version: $version" }
if ($shortDesc) { Update-FileContent "pubspec.yaml" '(?m)^description:\s*.*$' "description: `"$shortDesc`"" }

# 2. Android
Update-FileContent "android/app/src/main/AndroidManifest.xml" 'android:label="[^"]*"' "android:label=`"$name`""
Update-FileContent "android/app/src/main/AndroidManifest.xml" 'package="[^"]*"' "package=`"$bundle`""
Update-FileContent "android/app/build.gradle" 'applicationId\s+["=][^"\n]*["=]?' "applicationId = `"$bundle`""
Update-FileContent "android/app/build.gradle" 'namespace\s+["=][^"\n]*["=]?' "namespace = `"$bundle`""
Update-FileContent "android/app/build.gradle.kts" 'applicationId\s*=\s*"[^"]*"' "applicationId = `"$bundle`""
Update-FileContent "android/app/build.gradle.kts" 'namespace\s*=\s*"[^"]*"' "namespace = `"$bundle`""

# Move and update MainActivity (Kotlin / Java)
$roots = @("android/app/src/main/kotlin", "android/app/src/main/java")
foreach ($rootCode in$roots) {
    if (Test-Path $rootCode) {
        $files = Get-ChildItem -Path$rootCode -Recurse -Include *.kt, *.java
        foreach ($fileItem in $files) {$content = [System.IO.File]::ReadAllText($fileItem.FullName, [System.Text.Encoding]::UTF8)$newContent = [regex]::Replace($content, 'package\s+[a-zA-Z0-9_.]+', "package $bundle")
            [System.IO.File]::WriteAllText($fileItem.FullName, $newContent, [System.Text.Encoding]::UTF8)$subPath = $bundle.Replace('.', [System.IO.Path]::DirectorySeparatorChar)$targetDir = Join-Path $rootCode$subPath
            if (!(Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force \vert{} Out-Null }$targetFile = Join-Path $targetDir$fileItem.Name
            if ($fileItem.FullName -ne$targetFile) {
                Move-Item -Path $fileItem.FullName -Destination$targetFile -Force
                Write-Host "  [✓] Moved $($fileItem.Name) to$targetDir" -ForegroundColor Green
            }
        }
    }
}

# 3. iOS
Update-FileContent "ios/Runner/Info.plist" '<key>CFBundleDisplayName</key>\s*<string>[^<]*</string>' "<key>CFBundleDisplayName</key>`n`t<string>$name</string>"
Update-FileContent "ios/Runner/Info.plist" '<key>CFBundleName</key>\s*<string>[^<]*</string>' "<key>CFBundleName</key>`n`t<string>$name</string>"
Update-FileContent "ios/Runner/Info.plist" '<key>CFBundleShortVersionString</key>\s*<string>[^<]*</string>' "<key>CFBundleShortVersionString</key>`n`t<string>$verName</string>"
Update-FileContent "ios/Runner/Info.plist" '<key>CFBundleVersion</key>\s*<string>[^<]*</string>' "<key>CFBundleVersion</key>`n`t<string>$verCode</string>"
Update-FileContent "ios/Runner.xcodeproj/project.pbxproj" 'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*[^;]*;' "PRODUCT_BUNDLE_IDENTIFIER = $bundle;"

# 4. Web
Update-FileContent "web/index.html" '<title>[^<]*</title>' "<title>$name</title>"
Update-FileContent "web/index.html" '<meta\s+name="description"\s+content="[^"]*"' "<meta name=`"description`" content=`"$shortDesc`""
if (Test-Path "web/manifest.json") {
    try {
        $m = Get-Content "web/manifest.json" -Raw -Encoding utf8 | ConvertFrom-Json
        $m.name =$name
        $m.short_name =$name
        $m.description =$manifestDesc
        $jsonOut =$m | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText((Resolve-Path "web/manifest.json"), $jsonOut, [System.Text.Encoding]::UTF8)
        Write-Host "  [✓] Updated web/manifest.json" -ForegroundColor Green
    } catch {
        Write-Host "  [!] Warning updating web/manifest.json: $_" -ForegroundColor Yellow
    }
}

# 5. macOS
Update-FileContent "macos/Runner/Configs/AppInfo.xcconfig" 'PRODUCT_NAME\s*=\s*.*' "PRODUCT_NAME = $name"
Update-FileContent "macos/Runner/Configs/AppInfo.xcconfig" 'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*.*' "PRODUCT_BUNDLE_IDENTIFIER = $bundle"
Update-FileContent "macos/Runner.xcodeproj/project.pbxproj" 'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*[^;]*;' "PRODUCT_BUNDLE_IDENTIFIER = $bundle;"

# 6. Windows
Update-FileContent "windows/runner/main.cpp" 'window\.Create\(L"[^"]*"' "window.Create(L`"$name`""
Update-FileContent "windows/runner/Runner.rc" 'VALUE "FileDescription", "[^"]*"' "VALUE `"FileDescription`", `"$desc`""
Update-FileContent "windows/runner/Runner.rc" 'VALUE "ProductName", "[^"]*"' "VALUE `"ProductName`", `"$name`""
Update-FileContent "windows/runner/Runner.rc" 'VALUE "ProductVersion", "[^"]*"' "VALUE `"ProductVersion`", `"$version`""

# 7. Linux
Update-FileContent "linux/my_application.cc" 'gtk_header_bar_set_title\(header_bar,\s*"[^"]*"' "gtk_header_bar_set_title(header_bar, `"$name`""
Update-FileContent "linux/my_application.cc" 'gtk_window_set_title\(window,\s*"[^"]*"' "gtk_window_set_title(window, `"$name`""
Update-FileContent "linux/CMakeLists.txt" 'set\(APPLICATION_ID\s+"[^"]*"\)' "set(APPLICATION_ID `"$bundle`")"

# 8. Keystore & android/key.properties
if ($info.keystore) {
    $ks =$info.keystore
    $sp =$ks.storePassword
    $kp =$ks.keyPassword
    $ka =$ks.keyAlias
    $sf =$ks.storeFile
    if (!$sf) {$sf = "upload-keystore.jks" }

    if (!(Test-Path "android")) { New-Item -ItemType Directory -Path "android" -Force | Out-Null }
    $kpLines = @(
        "storePassword=$sp",
        "keyPassword=$kp",
        "keyAlias=$ka",
        "storeFile=../$sf"
    )
    $kpContent =$kpLines -join "`r`n"
    [System.IO.File]::WriteAllText((Join-Path (Get-Location) "android/key.properties"), $kpContent, [System.Text.Encoding]::UTF8)
    Write-Host "  [✓] Created android/key.properties from app_info.json" -ForegroundColor Green

    # Configure build.gradle with signingConfigs
    $bg = "android/app/build.gradle"
    if (Test-Path $bg) {
        $c = [System.IO.File]::ReadAllText((Resolve-Path$bg), [System.Text.Encoding]::UTF8)
        if ($c -notmatch 'keystoreProperties') {$hdr = "def keystoreProperties = new Properties()`ndef keystorePropertiesFile = rootProject.file('key.properties')`nif (keystorePropertiesFile.exists()) {`n    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))`n}`n`n"
            $sc = "`n    signingConfigs {`n        release {`n            keyAlias = keystoreProperties['keyAlias']`n            keyPassword = keystoreProperties['keyPassword']`n            storeFile = keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null`n            storePassword = keystoreProperties['storePassword']`n        }`n    }`n`n    buildTypes {"
            $c =$hdr + ($c -replace 'buildTypes\s*\{',$sc -replace 'signingConfig\s*=\s*signingConfigs\.debug', 'signingConfig = signingConfigs.release')
            [System.IO.File]::WriteAllText((Resolve-Path $bg),$c, [System.Text.Encoding]::UTF8)
            Write-Host "  [✓] Configured android/app/build.gradle with release signing" -ForegroundColor Green
        }
    }

    # Generate Keystore file if missing
    if (!(Test-Path $sf)) {
        Write-Host "`n[+] Generating Keystore: '$sf' via keytool..." -ForegroundColor Cyan
        $dname = "CN=$($ks.commonName), OU=$($ks.organizationUnit), O=$($ks.organizationName), L=$($ks.locality), ST=$($ks.state), C=$($ks.country)"
        keytool -genkeypair -v -keystore $sf -alias $ka -keyalg RSA -keysize 2048 -validity 10000 -storepass $sp -keypass $kp -dname $dname
        if (Test-Path $sf) {
            Write-Host "  [✓] Keystore file '$sf' created successfully!" -ForegroundColor Green
        }
    }
}

# 9. Launcher Icons
if ($icon -and (Test-Path $icon)) {
    $yamlLines = @(
        'flutter_launcher_icons:',
        '  android: true',
        '  ios: true',
        "  image_path: `"$icon`"",
        '  min_sdk_android: 21',
        '  web:',
        '    generate: true',
        "    image_path: `"$icon`"", '  windows:', '    generate: true', "    image_path: `"$icon`"",
        '  macos:',
        '    generate: true',
        "    image_path: `"$icon`"", '  linux:', '    generate: true', "    image_path: `"$icon`""
    )
    $yaml = $yamlLines -join "`r`n"
    [System.IO.File]::WriteAllText((Join-Path (Get-Location) "flutter_launcher_icons.yaml"), $yaml, [System.Text.Encoding]::UTF8)
    Write-Host "  [✓] Generated flutter_launcher_icons.yaml" -ForegroundColor Green

    Write-Host "`n[+] Running flutter_launcher_icons...`n" -ForegroundColor Cyan
    flutter pub add --dev flutter_launcher_icons
    dart run flutter_launcher_icons
} elseif ($icon) {
    Write-Host "  [!] Warning: Icon image not found at '$icon'" -ForegroundColor Yellow
}

Write-Host "`n[✓] All app metadata, bundles, versions, keystore, and icons updated successfully!" -ForegroundColor Green
