import 'dart:io';

class AppColors {
  static const String reset = '\x1B[0m';
  static const String green = '\x1B[32m';
  static const String red = '\x1B[31m';
  static const String yellow = '\x1B[33m';
  static const String cyan = '\x1B[36m';
}

void printMsg(String type, String message) {
  switch (type) {
    case 'success':
      stdout.writeln(
        '${AppColors.green}[✓] [SUCCESS] $message${AppColors.reset}',
      );
      break;
    case 'error':
      stdout.writeln('${AppColors.red}[×] [ERROR] $message${AppColors.reset}');
      break;
    case 'warning':
      stdout.writeln(
        '${AppColors.yellow}[!] [WARNING] $message${AppColors.reset}',
      );
      break;
    case 'info':
      stdout.writeln('${AppColors.cyan}[i] [INFO] $message${AppColors.reset}');
      break;
    default:
      stdout.writeln(message);
  }
}

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    printMsg(
      'error',
      'No command provided. Use: env, apply-all, apply-name, apply-icon, apply-bundle, keystore-properties, keystore, keystore-link, keystore-info, keystore-info-to-env, copy-all, copy-apk, copy-aab, copy-ios, copy-windows, copy-linux, copy-macos, copy-web',
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
    case 'keystore-info-to-env':
      _updateKeystoreInfoToEnv(env);
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
      printMsg('error', 'Unknown command: $command');
  }
}

Map<String, String> _loadEnv() {
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    printMsg(
      'warning',
      '.env file not found in current directory (${Directory.current.path}).',
    );
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
SERIAL_NUMBER=""
CREATION_DATE=""
EXPIRE_DATE=""
''';

  final file = File('.env');
  file.writeAsStringSync(content);
  printMsg(
    'success',
    'Created default .env file successfully at: ${file.absolute.path}',
  );
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
    printMsg('error', 'APP_NAME not found in .env');
    return;
  }
  printMsg('info', 'Applying App Name: $name');

  final androidManifest = File('android/app/src/main/AndroidManifest.xml');
  if (androidManifest.existsSync()) {
    var content = androidManifest.readAsStringSync();
    content = content.replaceAll(
      RegExp(r'android:label="[^"]*"'),
      'android:label="$name"',
    );
    androidManifest.writeAsStringSync(content);
    printMsg('success', 'Updated Android app label.');
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
    printMsg('success', 'Updated iOS app display name.');
  }
}

Future<void> _applyBundle(Map<String, String> env) async {
  final bundle = env['APP_BUNDLE'];
  if (bundle == null) {
    printMsg('error', 'APP_BUNDLE not found in .env');
    return;
  }
  printMsg('info', 'Applying App Bundle across all project files: $bundle');

  File? gradleFile;
  if (File('android/app/build.gradle.kts').existsSync()) {
    gradleFile = File('android/app/build.gradle.kts');
  } else if (File('android/app/build.gradle').existsSync()) {
    gradleFile = File('android/app/build.gradle');
  }

  if (gradleFile != null && gradleFile.existsSync()) {
    var content = gradleFile.readAsStringSync();
    content = content.replaceAll(
      RegExp(r'applicationId\s*=\s*"[^"]+"'),
      'applicationId = "$bundle"',
    );
    content = content.replaceAll(
      RegExp(r'applicationId\s+"[^"]+"'),
      'applicationId "$bundle"',
    );
    gradleFile.writeAsStringSync(content);
    printMsg('success', 'Updated Android applicationId in ${gradleFile.path}');
  }

  final manifestFile = File('android/app/src/main/AndroidManifest.xml');
  if (manifestFile.existsSync()) {
    var content = manifestFile.readAsStringSync();
    content = content.replaceAll(
      RegExp(r'package="[^"]*"'),
      'package="$bundle"',
    );
    manifestFile.writeAsStringSync(content);
    printMsg('success', 'Updated package in AndroidManifest.xml');
  }

  final pbxFile = File('ios/Runner.xcodeproj/project.pbxproj');
  if (pbxFile.existsSync()) {
    var content = pbxFile.readAsStringSync();
    content = content.replaceAll(
      RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = [^;]+;'),
      'PRODUCT_BUNDLE_IDENTIFIER = $bundle;',
    );
    pbxFile.writeAsStringSync(content);
    printMsg('success', 'Updated iOS Bundle Identifier in project.pbxproj');
  }

  final infoPlistFile = File('ios/Runner/Info.plist');
  if (infoPlistFile.existsSync()) {
    var content = infoPlistFile.readAsStringSync();
    content = content.replaceAll(
      RegExp(r'<key>CFBundleIdentifier</key>\s*<string>[^<]*</string>'),
      '<key>CFBundleIdentifier</key>\n\t<string>$bundle</string>',
    );
    infoPlistFile.writeAsStringSync(content);
    printMsg('success', 'Updated CFBundleIdentifier in iOS Info.plist');
  }
}

Future<void> _applyIcon(Map<String, String> env) async {
  final iconPath = env['APP_ICON_PATH'];
  if (iconPath == null || !File(iconPath).existsSync()) {
    printMsg('error', 'Icon path invalid or file not found at: $iconPath');
    return;
  }
  printMsg('info', 'Applying App Icon from: $iconPath');

  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    printMsg('error', 'pubspec.yaml not found.');
    return;
  }

  String content = pubspec.readAsStringSync();

  if (!content.contains('flutter_launcher_icons:')) {
    printMsg('info', 'Adding flutter_launcher_icons dependency...');
    await _runFlutter(['pub', 'add', '--dev', 'flutter_launcher_icons']);
    content = pubspec.readAsStringSync();
  }

  if (content.contains('flutter_launcher_icons:')) {
    int index = content.indexOf('flutter_launcher_icons:');
    while (index != -1) {
      String sub = content.substring(0, index);
      if (sub.contains('dev_dependencies:')) {
        int nextIndex = content.indexOf('flutter_launcher_icons:', index + 23);
        if (nextIndex != -1) {
          content = content.substring(0, nextIndex).trimRight() + '\n';
          break;
        } else {
          break;
        }
      } else {
        content = content.substring(0, index).trimRight() + '\n';
        break;
      }
    }
  }

  final configBlock =
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

  content = content.trim() + '\n' + configBlock;
  pubspec.writeAsStringSync(content);

  printMsg('info', 'Running flutter pub get...');
  await _runFlutter(['pub', 'get']);

  printMsg('info', 'Generating platform icons...');
  await _runFlutter(['pub', 'run', 'flutter_launcher_icons:main']);
  printMsg(
    'success',
    'Icons applied and generated successfully without duplication.',
  );
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
  printMsg('success', 'Created $propPath successfully.');
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

  printMsg('info', 'Generating keystore at $path...');
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
    printMsg('success', 'Keystore generated successfully at $path');
  } else {
    printMsg('error', 'Error generating keystore: ${res.stderr}');
  }
}

void _linkKeystore(Map<String, String> env) {
  printMsg('info', 'Linking Keystore to Android configuration...');

  File? gradleFile;
  if (File('android/app/build.gradle.kts').existsSync()) {
    gradleFile = File('android/app/build.gradle.kts');
  } else if (File('android/app/build.gradle').existsSync()) {
    gradleFile = File('android/app/build.gradle');
  }

  if (gradleFile == null || !gradleFile.existsSync()) {
    printMsg(
      'error',
      'Neither build.gradle nor build.gradle.kts found in android/app/.',
    );
    return;
  }

  var content = gradleFile.readAsStringSync();
  final isKotlinDsl = gradleFile.path.endsWith('.kts');

  if (!content.contains('keyProperties')) {
    final keystoreLoadBlock = isKotlinDsl
        ? '''
val keystoreProperties = java.util.Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    java.io.FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}
'''
        : '''
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
''';
    content = keystoreLoadBlock + '\n' + content;
    printMsg('success', 'Added keystoreProperties loader.');
  }

  if (!content.contains('signingConfigs')) {
    final signingConfigBlock = isKotlinDsl
        ? '''
    signingConfigs {
        create("release") {
            if (keystoreProperties.getProperty("storeFile") != null) {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }
'''
        : '''
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
      printMsg('success', 'Injected signingConfigs block.');
    }
  }

  if (content.contains('buildTypes {') || content.contains('buildTypes{')) {
    if (!content.contains('signingConfig')) {
      content = content.replaceAll(
        RegExp(r'release\s*\{', multiLine: true),
        isKotlinDsl
            ? 'release {\n            signingConfig = signingConfigs.getByName("release")'
            : 'release {\n\t\t\tsigningConfig signingConfigs.release',
      );
      printMsg('success', 'Linked release build type to signingConfig.');
    }
  }

  gradleFile.writeAsStringSync(content);
  printMsg('success', 'Keystore linked successfully to ${gradleFile.path}');
}

void _showKeystoreInfo(Map<String, String> env) {
  final path = env['KEYSTORE_PATH'] ?? 'android/app/upload-keystore.jks';
  final storePass = env['STORE_PASSWORD'] ?? 'password123';
  final alias = env['KEY_ALIAS'] ?? 'upload';

  if (!File(path).existsSync()) {
    printMsg('error', 'Keystore file not found at $path');
    return;
  }

  printMsg('info', 'Reading Keystore info from $path...');
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
    stdout.writeln(res.stdout);
  } else {
    printMsg('error', 'Failed to read keystore info: ${res.stderr}');
  }
}

void _updateKeystoreInfoToEnv(Map<String, String> env) {
  final path = env['KEYSTORE_PATH'] ?? 'android/app/upload-keystore.jks';
  final storePass = env['STORE_PASSWORD'] ?? 'password123';
  final alias = env['KEY_ALIAS'] ?? 'upload';

  if (!File(path).existsSync()) {
    printMsg('error', 'Keystore file not found at $path');
    return;
  }

  printMsg('info', 'Extracting full details from keystore...');
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
    printMsg('error', 'Failed to extract certificates: ${res.stderr}');
    return;
  }

  String output = res.stdout.toString();
  String sha1 = '';
  String sha256 = '';
  String serialNumber = '';
  String creationDate = '';
  String expireDate = '';

  for (var line in output.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('SHA1:')) {
      sha1 = trimmed.substring(5).trim();
    } else if (trimmed.startsWith('SHA256:')) {
      sha256 = trimmed.substring(7).trim();
    } else if (trimmed.startsWith('Serial number:')) {
      serialNumber = trimmed.substring(14).trim();
    } else if (trimmed.startsWith('Valid from:')) {
      final parts = trimmed.split('until');
      if (parts.length >= 2) {
        creationDate = parts[0].replaceFirst('Valid from:', '').trim();
        expireDate = parts[1].trim();
      } else {
        creationDate = trimmed.replaceFirst('Valid from:', '').trim();
      }
    }
  }

  final envFile = File('.env');
  if (!envFile.existsSync()) {
    printMsg('error', '.env file not found.');
    return;
  }

  var lines = envFile.readAsLinesSync();
  List<String> newLines = [];

  bool sha1Found = false;
  bool sha256Found = false;
  bool serialFound = false;
  bool creationFound = false;
  bool expireFound = false;

  for (var line in lines) {
    if (line.startsWith('SHA1=')) {
      newLines.add('SHA1="$sha1"');
      sha1Found = true;
    } else if (line.startsWith('SHA256=')) {
      newLines.add('SHA256="$sha256"');
      sha256Found = true;
    } else if (line.startsWith('SERIAL_NUMBER=')) {
      newLines.add('SERIAL_NUMBER="$serialNumber"');
      serialFound = true;
    } else if (line.startsWith('CREATION_DATE=')) {
      newLines.add('CREATION_DATE="$creationDate"');
      creationFound = true;
    } else if (line.startsWith('EXPIRE_DATE=')) {
      newLines.add('EXPIRE_DATE="$expireDate"');
      expireFound = true;
    } else {
      newLines.add(line);
    }
  }

  if (!sha1Found) newLines.add('SHA1="$sha1"');
  if (!sha256Found) newLines.add('SHA256="$sha256"');
  if (!serialFound) newLines.add('SERIAL_NUMBER="$serialNumber"');
  if (!creationFound) newLines.add('CREATION_DATE="$creationDate"');
  if (!expireFound) newLines.add('EXPIRE_DATE="$expireDate"');

  envFile.writeAsStringSync(newLines.join('\n') + '\n');
  printMsg(
    'success',
    'Updated .env successfully with all keystore certificate details.',
  );
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
    printMsg('success', 'Copied $type to $destPath');
  } else if (srcDir.existsSync()) {
    printMsg('success', 'Found folder for $type at $srcPath');
  } else {
    printMsg('warning', 'Source for $type not found at $srcPath');
  }
}
