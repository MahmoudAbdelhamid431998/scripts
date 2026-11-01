#!/usr/bin/env bash

if [ ! -f "app_info.json" ]; then
    echo "[-] Error: app_info.json not found! Please create it first."
    exit 1
fi

python3 -c "
import os, json, re

with open('app_info.json', 'r', encoding='utf-8') as f:
    info = json.load(f)

name = info.get('appName', '')
short_desc = info.get('appShortDescription', '')
long_desc = info.get('appLongDescription', '')
bundle = info.get('appBundle', '')
icon = info.get('appIconPath', '')

def update_file(path, pattern, repl):
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            c = f.read()
        new_c = re.sub(pattern, repl, c)
        if new_c != c:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(new_c)
            print(f'  [✓] Updated {path}')

print(f'\n[+] Applying App Info: {name} ({bundle})...\n')

# Android
update_file('android/app/src/main/AndroidManifest.xml', r'android:label=\"[^\"]*\"', f'android:label=\"{name}\"')
update_file('android/app/build.gradle', r'applicationId\s+[\"=][^\"\n]*[\"=]?', f'applicationId = \"{bundle}\"')
update_file('android/app/build.gradle', r'namespace\s+[\"=][^\"\n]*[\"=]?', f'namespace = \"{bundle}\"')
update_file('android/app/build.gradle.kts', r'applicationId\s*=\s*\"[^\"]*\"', f'applicationId = \"{bundle}\"')
update_file('android/app/build.gradle.kts', r'namespace\s*=\s*\"[^\"]*\"', f'namespace = \"{bundle}\"')

# iOS
update_file('ios/Runner/Info.plist', r'<key>CFBundleDisplayName</key>\s*<string>[^<]*</string>', f'<key>CFBundleDisplayName</key>\\n\\t<string>{name}</string>')
update_file('ios/Runner/Info.plist', r'<key>CFBundleName</key>\s*<string>[^<]*</string>', f'<key>CFBundleName</key>\\n\\t<string>{name}</string>')
update_file('ios/Runner.xcodeproj/project.pbxproj', r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*[^;]*;', f'PRODUCT_BUNDLE_IDENTIFIER = {bundle};')

# Web
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

# macOS
update_file('macos/Runner/Configs/AppInfo.xcconfig', r'PRODUCT_NAME\s*=\s*.*', f'PRODUCT_NAME = {name}')
update_file('macos/Runner/Configs/AppInfo.xcconfig', r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*.*', f'PRODUCT_BUNDLE_IDENTIFIER = {bundle}')

# Windows
update_file('windows/runner/main.cpp', r'window\.Create\(L\"[^\"]*\"', f'window.Create(L\"{name}\"')
update_file('windows/runner/Runner.rc', r'VALUE \"FileDescription\", \"[^\"]*\"', f'VALUE \"FileDescription\", \"{short_desc or name}\"')
update_file('windows/runner/Runner.rc', r'VALUE \"ProductName\", \"[^\"]*\"', f'VALUE \"ProductName\", \"{name}\"')

# Linux
update_file('linux/my_application.cc', r'gtk_header_bar_set_title\(header_bar,\s*\"[^\"]*\"', f'gtk_header_bar_set_title(header_bar, \"{name}\"')
update_file('linux/my_application.cc', r'gtk_window_set_title\(window,\s*\"[^\"]*\"', f'gtk_window_set_title(window, \"{name}\"')

# Icons
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
