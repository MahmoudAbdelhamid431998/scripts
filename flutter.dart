import 'dart:io';

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print(
      '[ERROR] No command provided. Use: env, apply-all, apply-name, apply-icon, apply-bundle, keystore-properties, keystore, keystore-link, keystore-info, keystore-sha, copy-all, copy-apk, copy-aab, copy-ios, copy-windows, copy-linux, copy-macos, copy-web',
    );
    return;
  }

  final command = arguments[0];
  final env = _loadEnv();

  switch (command) {
    case 'env':
      _createEnvTemplate();
      break;
    case 'apply-all':
      await _applyName(env);
      await _applyBundle(env);
      await _applyIcon(env);
      break;
    case 'apply-name':
      await _applyName(env);
      break;
    case 'apply-bundle':
      await _applyBundle(env);
      break;
    case 'apply-icon':
      await _applyIcon(env);
      break;
    case 'keystore-properties':
      _createKeystoreProperties(env);
      break;
    case 'keystore':
      _generateKeystore(env);
      break;
    case 'keystore-link':
      _linkKeystore(env);
      break;
    case 'keystore-info':
      _showKeystoreInfo(env);
      break;
    case 'keystore-sha':
      _updateKeystoreSha(env);
      break;
    case 'copy-all':
      _copyArtifacts(env, 'all');
      break;
    case 'copy-apk':
      _copyArtifacts(env, 'apk');
      break;
    case 'copy-aab':
      _copyArtifacts(env, 'aab');
      break;
    case 'copy-ios':
      _copyArtifacts(env, 'ios');
      break;
    case 'copy-windows':
      _copyArtifacts(env, 'windows');
      break;
    case 'copy-linux':
      _copyArtifacts(env, 'linux');
      break;
    case 'copy-macos':
      _copyArtifacts(env, 'macos');
      break;
    case 'copy-web':
      _copyArtifacts(env, 'web');
      break;
    default:
      print('[ERROR] Unknown command: $command');
  }
}

Map<String, String> _loadEnv() {
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('[WARNING] .env file not found in current directory.');
    return {};
  }
  final lines = envFile.readAsLinesSync();
  final Map<String, String> env = {};
  for (var line in lines) {
    final cleanedLine = line.trim();
    if (cleanedLine.isEmpty || cleanedLine.startsWith('#')) continue;
    final parts = cleanedLine.split('=');
    if (parts.length >= 2) {
      final key = parts[0].replaceAll('"', '').replaceAll("'", "").trim();
      final value = parts
          .sublist(1)
          .join('=')
          .replaceAll('"', '')
          .replaceAll("'", "")
          .trim();
      env[key] = value;
    }
  }
  return env;
}

void _createEnvTemplate() {
  final content = '''
# App Info
APP_NAME="App"
APP_BUNDLE="com.mahmoud.app"
APP_VERSION="1.0.0+1"
APP_SHORT_DESCRIPTION="Simple and fast Flutter application"
APP_LONG_DESCRIPTION="A complete cross-platform Flutter application built with Flutter."
APP_CATEGORY="Utilities"
APP_ICON_PATH="assets/images/app_icon.png"

# Publisher Info
COMMON_NAME="Mahmoud Abdelhamid"
ORGANIZATION_NAME="Mahmoud Abdelhamid"
ORGANIZATION_UNIT="Independent"
COUNTRY="EG"
STATE="Cairo"
LOCALITY="Cairo"

# Keystore Info
KEY_ALIAS="upload"
STORE_PASSWORD="password123"
KEY_PASSWORD="password123"
STORE_FILE="upload-keystore.jks"
STORE_TYPE="PKCS12"
ALGORITHM="RSA 2048-bit"
SIGNATURE="SHA384withRSA"
KEY_PROPERTIES_PATH="android/key.properties"
KEYSTORE_PATH="android/app/upload-keystore.jks"
VALIDITY="10000"
SHA1=""
SHA256=""
''';
  File('.env').writeAsStringSync(content);
  print('[OK] Created default .env template successfully.');
}

Future<void> _runFlutter(List<String> args) async {
  String exec = Platform.isWindows ? 'flutter.bat' : 'flutter';
  var res = await Process.run(exec, args, runInShell: true);
  stdout.write(res.stdout);
  stderr.write(res.stderr);
}

Future<void> _applyName(Map<String, String> env) async {
  final name = env['APP_NAME'];
  if (name == null) {
    print('[ERROR] APP_NAME not found in .env');
    return;
  }
  print('[INFO] Applying App Name: $name');

  final androidManifest = File('android/app/src/main/AndroidManifest.xml');
  if (androidManifest.existsSync()) {
    var content = androidManifest.readAsStringSync();
    content = content.replaceAll(
      RegExp(r'android:label="[^"]*"'),
      'android:label="$name"',
    );
    androidManifest.writeAsStringSync(content);
    print('[OK] Updated Android app label.');
  }

  final infoPlist = File('ios/Runner/Info.plist');
  if (infoPlist.existsSync()) {
    var content = infoPlist.readAsStringSync();
    if (content.contains('CFBundleDisplayName')) {
      content = content.replaceAll(
        RegExp(r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)'),
        '\$1$name\$2',
      );
    }
    infoPlist.writeAsStringSync(content);
    print('[OK] Updated iOS app display name.');
  }
}

Future<void> _applyBundle(Map<String, String> env) async {
  final bundle = env['APP_BUNDLE'];
  if (bundle == null) {
    print('[ERROR] APP_BUNDLE not found in .env');
    return;
  }
  print('[INFO] Applying App Bundle: $bundle');

  final gradle = File('android/app/build.gradle');
  if (gradle.existsSync()) {
    var content = gradle.readAsStringSync();
    content = content.replaceAll(
      RegExp(r'applicationId\s+"[^"]+"'),
      'applicationId "$bundle"',
    );
    gradle.writeAsStringSync(content);
    print('[OK] Updated Android applicationId.');
  }

  final pbx = File('ios/Runner.xcodeproj/project.pbxproj');
  if (pbx.existsSync()) {
    var content = pbx.readAsStringSync();
    content = content.replaceAll(
      RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = [^;]+;'),
      'PRODUCT_BUNDLE_IDENTIFIER = $bundle;',
    );
    pbx.writeAsStringSync(content);
    print('[OK] Updated iOS Bundle Identifier.');
  }
}

Future<void> _applyIcon(Map<String, String> env) async {
  final iconPath = env['APP_ICON_PATH'];
  if (iconPath == null || !File(iconPath).existsSync()) {
    print('[ERROR] Icon path invalid or not found in .env');
    return;
  }
  print('[INFO] Applying App Icon from: $iconPath');

  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) return;
  var content = pubspec.readAsStringSync();

  if (!content.contains('flutter_launcher_icons')) {
    await _runFlutter(['pub', 'add', '--dev', 'flutter_launcher_icons']);
  }

  final config =
      '''
flutter_launcher_icons:
  image_path: "$iconPath"
  android: true
  ios: true
  web:
    generate: true
    image_path: "$iconPath"
  windows:
    generate: true
    image_path: "$iconPath"
    icon_size: 48
  macos:
    generate: true
    image_path: "$iconPath"
''';

  content = content.trim() + '\n\n' + config;
  pubspec.writeAsStringSync(content);

  await _runFlutter(['pub', 'get']);
  await _runFlutter(['pub', 'run', 'flutter_launcher_icons:main']);
  print('[OK] Icons generated successfully!');
}

void _createKeystoreProperties(Map<String, String> env) {
  final propPath = env['KEY_PROPERTIES_PATH'] ?? 'android/key.properties';
  final propFile = File(propPath);
  propFile.parent.createSync(recursive: true);

  final content =
      '''
storePassword=${env['STORE_PASSWORD']}
keyPassword=${env['KEY_PASSWORD']}
keyAlias=${env['KEY_ALIAS']}
storeFile=${env['STORE_FILE']}
''';
  propFile.writeAsStringSync(content);
  print('[OK] Created $propPath successfully.');
}

void _generateKeystore(Map<String, String> env) {
  final path = env['KEYSTORE_PATH'] ?? 'android/app/upload-keystore.jks';
  final storePass = env['STORE_PASSWORD'] ?? 'password123';
  final keyPass = env['KEY_PASSWORD'] ?? 'password123';
  final alias = env['KEY_ALIAS'] ?? 'upload';
  final validity = env['VALIDITY'] ?? '10000';

  final cn = env['COMMON_NAME'] ?? 'Mahmoud Abdelhamid';
  final o = env['ORGANIZATION_NAME'] ?? 'Mahmoud Abdelhamid';
  final ou = env['ORGANIZATION_UNIT'] ?? 'Independent';
  final c = env['COUNTRY'] ?? 'EG';
  final st = env['STATE'] ?? 'Cairo';
  final l = env['LOCALITY'] ?? 'Cairo';

  final dname = 'CN=$cn, OU=$ou, O=$o, L=$l, ST=$st, C=$c';

  File(path).parent.createSync(recursive: true);

  final res = Process.runSync('keytool', [
    '-genkey',
    '-v',
    '-keystore',
    path,
    '-keyalg',
    'RSA',
    '-keysize',
    '2048',
    '-validity',
    validity,
    '-alias',
    alias,
    '-storepass',
    storePass,
    '-keypass',
    keyPass,
    '-dname',
    dname,
  ], runInShell: true);

  if (res.exitCode == 0) {
    print(
      '[OK] Keystore generated successfully at $path with all publisher details.',
    );
  } else {
    print('[ERROR] Error generating keystore: ${res.stderr}');
  }
}

void _linkKeystore(Map<String, String> env) {
  print('[INFO] Linking Keystore to android/app/build.gradle...');
  final gradleFile = File('android/app/build.gradle');
  if (!gradleFile.existsSync()) {
    print('[ERROR] android/app/build.gradle not found.');
    return;
  }

  var content = gradleFile.readAsStringSync();

  if (!content.contains('keyProperties.load')) {
    final keystoreLoadBlock = '''
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
''';
    content = keystoreLoadBlock + '\n' + content;
    print('[OK] Added keystoreProperties loader to build.gradle.');
  }

  if (!content.contains('signingConfigs')) {
    final signingConfigBlock = '''
    signingConfigs {
        release {
            if (keystoreProperties.getProperty('storeFile') != null) {
                storeFile file(keystoreProperties.getProperty('storeFile'))
                storePassword keystoreProperties.getProperty('storePassword')
                keyAlias keystoreProperties.getProperty('keyAlias')
                keyPassword keystoreProperties.getProperty('keyPassword')
            }
        }
    }
''';
    if (content.contains('android {')) {
      content = content.replaceFirst(
        'android {',
        'android {\n' + signingConfigBlock,
      );
      print('[OK] Injected signingConfigs block.');
    }
  }

  if (content.contains('buildTypes {') || content.contains('buildTypes{')) {
    if (!content.contains('signingConfig signingConfigs.release')) {
      content = content.replaceAll(
        RegExp(r'release\s*\{', multiLine: true),
        'release {\n\t\t\tsigningConfig signingConfigs.release',
      );
      print('[OK] Linked release build type to signingConfigs.release.');
    }
  }

  gradleFile.writeAsStringSync(content);
  print('[OK] Keystore linked successfully to android/app/build.gradle.');
}

void _showKeystoreInfo(Map<String, String> env) {
  final path = env['KEYSTORE_PATH'] ?? 'android/app/upload-keystore.jks';
  final storePass = env['STORE_PASSWORD'] ?? 'password123';
  final alias = env['KEY_ALIAS'] ?? 'upload';

  if (!File(path).existsSync()) {
    print('[ERROR] Keystore file not found at $path');
    return;
  }

  print('[INFO] Reading Keystore info from $path...');
  final res = Process.runSync('keytool', [
    '-list',
    '-v',
    '-keystore',
    path,
    '-storepass',
    storePass,
    '-alias',
    alias,
  ], runInShell: true);

  if (res.exitCode == 0) {
    print(res.stdout);
  } else {
    print('[ERROR] Failed to read keystore info: ${res.stderr}');
  }
}

void _updateKeystoreSha(Map<String, String> env) {
  final path = env['KEYSTORE_PATH'] ?? 'android/app/upload-keystore.jks';
  final storePass = env['STORE_PASSWORD'] ?? 'password123';
  final alias = env['KEY_ALIAS'] ?? 'upload';

  if (!File(path).existsSync()) {
    print('[ERROR] Keystore file not found at $path');
    return;
  }

  print('[INFO] Extracting SHA1 and SHA256 from keystore...');
  final res = Process.runSync('keytool', [
    '-list',
    '-v',
    '-keystore',
    path,
    '-storepass',
    storePass,
    '-alias',
    alias,
  ], runInShell: true);

  if (res.exitCode != 0) {
    print('[ERROR] Failed to extract certificates: ${res.stderr}');
    return;
  }

  String output = res.stdout.toString();
  String sha1 = '';
  String sha256 = '';

  for (var line in output.split('\n')) {
    if (line.trim().startsWith('SHA1:')) {
      sha1 = line.trim().substring(5).trim();
    } else if (line.trim().startsWith('SHA256:')) {
      sha256 = line.trim().substring(7).trim();
    }
  }

  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('[ERROR] .env file not found.');
    return;
  }

  var lines = envFile.readAsLinesSync();
  List<String> newLines = [];
  bool sha1Updated = false;
  bool sha256Updated = false;

  for (var line in lines) {
    if (line.startsWith('SHA1=')) {
      newLines.add('SHA1="$sha1"');
      sha1Updated = true;
    } else if (line.startsWith('SHA256=')) {
      newLines.add('SHA256="$sha256"');
      sha256Updated = true;
    } else {
      newLines.add(line);
    }
  }

  if (!sha1Updated) newLines.add('SHA1="$sha1"');
  if (!sha256Updated) newLines.add('SHA256="$sha256"');

  envFile.writeAsStringSync(newLines.join('\n') + '\n');
  print('[OK] Updated .env successfully with SHA1: $sha1 and SHA256: $sha256');
}

void _copyArtifacts(Map<String, String> env, String type) {
  final appName = env['APP_NAME'] ?? 'App';
  final releaseDir = Directory('release');
  releaseDir.createSync(recursive: true);

  Map<String, String> paths = {
    'apk': 'build/app/outputs/flutter-apk/app-release.apk',
    'aab': 'build/app/outputs/bundle/release/app-release.aab',
    'ios': 'build/ios/iphoneos/Runner.app',
    'windows': 'build/windows/x64/runner/Release',
    'linux': 'build/linux/x64/release/bundle',
    'macos': 'build/macos/Build/Products/Release/Runner.app',
    'web': 'build/web',
  };

  if (type == 'all') {
    paths.forEach((k, v) => _copySingle(v, releaseDir.path, appName, k));
  } else {
    if (paths.containsKey(type)) {
      _copySingle(paths[type]!, releaseDir.path, appName, type);
    }
  }
}

void _copySingle(String srcPath, String destDir, String appName, String type) {
  final srcFile = File(srcPath);
  final srcDir = Directory(srcPath);

  String ext = (type == 'apk')
      ? '.apk'
      : (type == 'aab')
      ? '.aab'
      : '';
  String destName = '$appName-$type$ext';
  String destPath = '$destDir/$destName';

  if (srcFile.existsSync()) {
    srcFile.copySync(destPath);
    print('[OK] Copied $type to $destPath');
  } else if (srcDir.existsSync()) {
    print('[OK] Found folder for $type at $srcPath');
  } else {
    print('[WARNING] Source for $type not found at $srcPath');
  }
}
