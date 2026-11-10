#!/usr/bin/env bash

if [ ! -f "app_info.json" ]; then
    echo "[-] Error: app_info.json not found! Please create it first."
    exit 1
fi

python3 -c "
import os, json, re, shutil

with open('app_info.json', 'r', encoding='utf-8') as f:
    info = json.load(f)

name = info.get('appName', '')
version = info.get('appVersion', '')
short_desc = info.get('appShortDescription', '')
long_desc = info.get('appLongDescription', '')
bundle = info.get('appBundle', '')
icon = info.get('appIconPath', '')
ks = info.get('keystore', {})

ver_parts = version.split('+') if version else ['1.0.0', '1']
ver_name = ver_parts[0]
ver_code = ver_parts[1] if len(ver_parts) > 1 else '1'

def update_file(path, pattern, repl):
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            c = f.read()
        new_c = re.sub(pattern, repl, c)
        if new_c != c:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(new_c)
            print(f'  [✓] Updated {path}')

print(f'\n[+] Applying App Info: {name} (v{version} - {bundle})...\n')

# 1. pubspec.yaml
if version: update_file('pubspec.yaml', r'(?m)^version:\s*.*$', f'version: {version}')
if short_desc: update_file('pubspec.yaml', r'(?m)^description:\s*.*$', f'description: \"{short_desc}\"')

# 2. Android
update_file('android/app/src/main/AndroidManifest.xml', r'android:label=\"[^\"]*\"', f'android:label=\"{name}\"')
update_file('android/app/src/main/AndroidManifest.xml', r'package=\"[^\"]*\"', f'package=\"{bundle}\"')
update_file('android/app/build.gradle', r'applicationId\s+[\"=][^\"\n]*[\"=]?', f'applicationId = \"{bundle}\"')
update_file('android/app/build.gradle', r'namespace\s+[\"=][^\"\n]*[\"=]?', f'namespace = \"{bundle}\"')
update_file('android/app/build.gradle.kts', r'applicationId\s*=\s*\"[^\"]*\"', f'applicationId = \"{bundle}\"')
update_file('android/app/build.gradle.kts', r'namespace\s*=\s*\"[^\"]*\"', f'namespace = \"{bundle}\"')

for root_code in ['android/app/src/main/kotlin', 'android/app/src/main/java']:
    if os.path.exists(root_code):
        for root, dirs, files in os.walk(root_code):
            for file in files:
                if file.endswith(('.kt', '.java')):
                    file_path = os.path.join(root, file)
                    with open(file_path, 'r', encoding='utf-8') as f:
                        c = f.read()
                    c = re.sub(r'package\s+[a-zA-Z0-9_.]+', f'package {bundle}', c)
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(c)
                    new_pkg_dir = os.path.join(root_code, *bundle.split('.'))
                    os.makedirs(new_pkg_dir, exist_ok=True)
                    new_file_path = os.path.join(new_pkg_dir, file)
                    if os.path.abspath(file_path) != os.path.abspath(new_file_path):
                        shutil.move(file_path, new_file_path)
                        print(f'  [✓] Moved {file} to {new_pkg_dir}')

# 3. iOS
update_file('ios/Runner/Info.plist', r'<key>CFBundleDisplayName</key>\s*<string>[^<]*</string>', f'<key>CFBundleDisplayName</key>\\n\\t<string>{name}</string>')
update_file('ios/Runner/Info.plist', r'<key>CFBundleName</key>\s*<string>[^<]*</string>', f'<key>CFBundleName</key>\\n\\t<string>{name}</string>')
update_file('ios/Runner/Info.plist', r'<key>CFBundleShortVersionString</key>\s*<string>[^<]*</string>', f'<key>CFBundleShortVersionString</key>\\n\\t<string>{ver_name}</string>')
update_file('ios/Runner/Info.plist', r'<key>CFBundleVersion</key>\s*<string>[^<]*</string>', f'<key>CFBundleVersion</key>\\n\\t<string>{ver_code}</string>')
update_file('ios/Runner.xcodeproj/project.pbxproj', r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*[^;]*;', f'PRODUCT_BUNDLE_IDENTIFIER = {bundle};')

# 4. Web
update_file('web/index.html', r'<title>[^<]*</title>', f'<title>{name}</title>')
update_file('web/index.html', r'<meta\s+name=\"description\"\s+content=\"[^\"]*\"', f'<meta name=\"description\" content=\"{short_desc}\"')
if os.path.exists('web/manifest.json'):
    try:
        with open('web/manifest.json', 'r', encoding='utf-8') as f:
            m = json.load(f)
        m['name'] = name
        m['short_name'] = name
        m['description'] = short_desc or long_desc
        with open('web/manifest.json', 'w', encoding='utf-8') as f:
            json.dump(m, f, indent=4)
        print('  [✓] Updated web/manifest.json')
    except Exception as e:
        pass

# 5. macOS
update_file('macos/Runner/Configs/AppInfo.xcconfig', r'PRODUCT_NAME\s*=\s*.*', f'PRODUCT_NAME = {name}')
update_file('macos/Runner/Configs/AppInfo.xcconfig', r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*.*', f'PRODUCT_BUNDLE_IDENTIFIER = {bundle}')
update_file('macos/Runner.xcodeproj/project.pbxproj', r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*[^;]*;', f'PRODUCT_BUNDLE_IDENTIFIER = {bundle};')

# 6. Windows
update_file('windows/runner/main.cpp', r'window\.Create\(L\"[^\"]*\"', f'window.Create(L\"{name}\"')
update_file('windows/runner/Runner.rc', r'VALUE \"FileDescription\", \"[^\"]*\"', f'VALUE \"FileDescription\", \"{short_desc or name}\"')
update_file('windows/runner/Runner.rc', r'VALUE \"ProductName\", \"[^\"]*\"', f'VALUE \"ProductName\", \"{name}\"')
if version: update_file('windows/runner/Runner.rc', r'VALUE \"ProductVersion\", \"[^\"]*\"', f'VALUE \"ProductVersion\", \"{version}\"')

# 7. Linux
update_file('linux/my_application.cc', r'gtk_header_bar_set_title\(header_bar,\s*\"[^\"]*\"', f'gtk_header_bar_set_title(header_bar, \"{name}\"')
update_file('linux/my_application.cc', r'gtk_window_set_title\(window,\s*\"[^\"]*\"', f'gtk_window_set_title(window, \"{name}\"')
update_file('linux/CMakeLists.txt', r'set\(APPLICATION_ID\s+\"[^\"]*\"\)', f'set(APPLICATION_ID \"{bundle}\")')

# 8. Keystore & android/key.properties
if ks:
    sp = ks.get('storePassword', '')
    kp = ks.get('keyPassword', '')
    ka = ks.get('keyAlias', '')
    sf = ks.get('storeFile', 'upload-keystore.jks')
    os.makedirs('android', exist_ok=True)
    with open('android/key.properties', 'w', encoding='utf-8') as f:
        f.write(f'storePassword={sp}\\nkeyPassword={kp}\\nkeyAlias={ka}\\nstoreFile=../{sf}\\n')
    print('  [✓] Created android/key.properties from app_info.json')

    bg = 'android/app/build.gradle'
    if os.path.exists(bg):
        with open(bg, 'r', encoding='utf-8') as f: c = f.read()
        if 'keystoreProperties' not in c:
            hdr = 'def keystoreProperties = new Properties()\\ndef keystorePropertiesFile = rootProject.file(\"key.properties\")\\nif (keystorePropertiesFile.exists()) {\\n    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\\n}\\n\\n'
            sc = '\\n    signingConfigs {\\n        release {\\n            keyAlias = keystoreProperties[\"keyAlias\"]\\n            keyPassword = keystoreProperties[\"keyPassword\"]\\n            storeFile = keystoreProperties[\"storeFile\"] ? file(keystoreProperties[\"storeFile\"]) : null\\n            storePassword = keystoreProperties[\"storePassword\"]\\n        }\\n    }\\n\\n    buildTypes {'
            c = hdr + re.sub(r'buildTypes\s*\{', sc, c)
            c = re.sub(r'signingConfig\s*=\s*signingConfigs\.debug', 'signingConfig = signingConfigs.release', c)
            with open(bg, 'w', encoding='utf-8') as f: f.write(c)
            print('  [✓] Configured android/app/build.gradle with release signing')

    if not os.path.exists(sf):
        dname = f'CN={ks.get(\"commonName\", \"\")}, OU={ks.get(\"organizationUnit\", \"\")}, O={ks.get(\"organizationName\", \"\")}, L={ks.get(\"locality\", \"\")}, ST={ks.get(\"state\", \"\")}, C={ks.get(\"country\", \"\")}'
        os.system(f'keytool -genkeypair -v -keystore {sf} -alias {ka} -keyalg RSA -keysize 2048 -validity 10000 -storepass {sp} -keypass {kp} -dname \"{dname}\"')
        print(f'  [✓] Created keystore file: {sf}')

# 9. Icons
if icon and os.path.exists(icon):
    yaml_c = f'''flutter_launcher_icons:
  android: true
  ios: true
  image_path: \"{icon}\"
  min_sdk_android: 21
  web:
    generate: true
    image_path: \"{icon}\"
  windows:
    generate: true
    image_path: \"{icon}\"
  macos:
    generate: true
    image_path: \"{icon}\"
  linux:
    generate: true
    image_path: \"{icon}\"
'''
    with open('flutter_launcher_icons.yaml', 'w', encoding='utf-8') as f:
        f.write(yaml_c)
    print('  [✓] Generated flutter_launcher_icons.yaml')
"

if [ -f "flutter_launcher_icons.yaml" ]; then
    flutter pub add --dev flutter_launcher_icons
    dart run flutter_launcher_icons
fi
