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
      'No command provided. Use: env, apply-all, apply-name, apply-version, apply-bundle, apply-icon, keystore-properties, keystore, keystore-link, keystore-info, keystore-info-to-env, copy-all, copy-apk, copy-aab, copy-ios, copy-windows, copy-linux, copy-macos, copy-web',
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
      await _applyVersion(env);
      await _applyBundle(env);
      await _applyIcon(env);
      break;
    case 'apply-name':
      await _applyName(env);
      break;
    case 'apply-version':
      await _applyVersion(env);
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

Future<ProcessResult> _runFlutter(List<String> args) async {
  String exec = Platform.isWindows ? 'flutter.bat' : 'flutter';
  var res = await Process.run(exec, args, runInShell: true);
  stdout.write(res.stdout);
  stderr.write(res.stderr);
  return res;
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

Future<void> _applyVersion(Map<String, String> env) async {
  final version = env['APP_VERSION'];
  final shortDesc = env['APP_SHORT_DESCRIPTION'];

  if (version == null || version.isEmpty) {
    printMsg('error', 'APP_VERSION not found in .env');
    return;
  }
  printMsg(
    'info',
    'Applying App Version & Short Description to pubspec.yaml...',
  );

  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    printMsg('error', 'pubspec.yaml not found.');
    return;
  }

  var content = pubspec.readAsStringSync();

  if (content.contains(RegExp(r'^version:\s*.*$', multiLine: true))) {
    content = content.replaceAll(
      RegExp(r'^version:\s*.*$', multiLine: true),
      'version: $version',
    );
    printMsg('success', 'Updated version in pubspec.yaml to $version');
  } else {
    printMsg('warning', 'Could not find version field in pubspec.yaml');
  }

  if (shortDesc != null && shortDesc.isNotEmpty) {
    if (content.contains(RegExp(r'^description:\s*.*$', multiLine: true))) {
      content = content.replaceAll(
        RegExp(r'^description:\s*.*$', multiLine: true),
        'description: "$shortDesc"',
      );
      printMsg(
        'success',
        'Updated description in pubspec.yaml to "$shortDesc"',
      );
    } else {
      printMsg('warning', 'Could not find description field in pubspec.yaml');
    }
  }

  pubspec.writeAsStringSync(content);
}

Future<void> _applyBundle(Map<String, String> env) async {
  final newBundle = env['APP_BUNDLE'];
  if (newBundle == null || newBundle.isEmpty) {
    printMsg('error', 'APP_BUNDLE not found in .env');
    return;
  }

  String oldBundle = _extractCurrentBundleId();
  if (oldBundle.isNotEmpty) {
    printMsg('info', 'Current App Bundle ID detected: $oldBundle');
  }

  printMsg('info', 'Adding change_app_package_name dependency...');
  await _runFlutter(['pub', 'add', '--dev', 'change_app_package_name']);

  printMsg(
    'info',
    'Running change_app_package_name package to set new bundle: $newBundle',
  );
  var res = await _runFlutter([
    'pub',
    'run',
    'change_app_package_name:main',
    newBundle,
  ]);

  if (res.exitCode == 0) {
    printMsg(
      'success',
      'Successfully applied new package via change_app_package_name library.',
    );
  } else {
    printMsg('error', 'Failed to run change_app_package_name package.');
    return;
  }

  if (oldBundle.isNotEmpty && oldBundle != newBundle) {
    printMsg(
      'info',
      'Searching project for full bundle "$oldBundle" and replacing with "$newBundle"...',
    );
    _replaceInProject(oldBundle, newBundle);

    List<String> oldParts = oldBundle.split('.');
    List<String> newParts = newBundle.split('.');
    if (oldParts.length >= 2 && newParts.length >= 2) {
      String oldPrefix = '${oldParts[0]}.${oldParts[1]}';
      String newPrefix = '${newParts[0]}.${newParts[1]}';

      if (oldPrefix != newPrefix) {
        printMsg(
          'info',
          'Searching project for prefix "$oldPrefix" and replacing with "$newPrefix"...',
        );
        _replaceInProject(oldPrefix, newPrefix);
      }
    }
  }

  printMsg(
    'success',
    'App Bundle update completed seamlessly across the entire project!',
  );
}

String _extractCurrentBundleId() {
  File? gradleFile = _findGradleFile();
  if (gradleFile != null && gradleFile.existsSync()) {
    String content = gradleFile.readAsStringSync();
    RegExp regExp = RegExp(r'applicationId\s*=?\s*"([^"]+)"');
    Match? match = regExp.firstMatch(content);
    if (match != null) {
      return match.group(1) ?? '';
    }
  }
  return '';
}

File? _findGradleFile() {
  final possiblePaths = [
    'android/app/build.gradle.kts',
    'android/app/build.gradle',
    'android/build.gradle.kts',
    'android/build.gradle',
  ];
  for (var p in possiblePaths) {
    if (File(p).existsSync()) {
      return File(p);
    }
  }
  final androidDir = Directory('android');
  if (androidDir.existsSync()) {
    for (var entity in androidDir.listSync(recursive: true)) {
      if (entity is File &&
          (entity.path.endsWith('build.gradle.kts') ||
              entity.path.endsWith('build.gradle'))) {
        if (entity.path.contains('app')) {
          return entity;
        }
      }
    }
  }
  return null;
}

void _replaceInProject(String fromText, String toText) {
  final targetDirs = [
    'android',
    'ios',
    'macos',
    'windows',
    'linux',
    'lib',
    'test',
  ];
  int count = 0;

  for (var dirName in targetDirs) {
    final dir = Directory(dirName);
    if (!dir.existsSync()) continue;

    dir.listSync(recursive: true).forEach((entity) {
      if (entity is File) {
        if (entity.path.contains('.git') ||
            entity.path.contains('build/') ||
            entity.path.contains('.dart_tool/') ||
            entity.path.endsWith('.png') ||
            entity.path.endsWith('.jks') ||
            entity.path.endsWith('.so'))
          return;

        try {
          String content = entity.readAsStringSync();
          if (content.contains(fromText)) {
            content = content.replaceAll(fromText, toText);
            entity.writeAsStringSync(content);
            count++;
          }
        } catch (_) {}
      }
    });
  }
  printMsg('success', 'Replaced occurrences of "$fromText" in $count files.');
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

  final keystorePath = File(
    env['KEYSTORE_PATH'] ?? 'android/app/upload-keystore.jks',
  ).absolute.path.replaceAll('\\', '/');

  final content =
      '''
storePassword=${env['STORE_PASSWORD']}
keyPassword=${env['KEY_PASSWORD']}
keyAlias=${env['KEY_ALIAS']}
storeFile=$keystorePath
''';
  propFile.writeAsStringSync(content.trim() + '\n');
  printMsg(
    'success',
    'Created $propPath with absolute storeFile path: $keystorePath',
  );
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
  printMsg(
    'info',
    'Linking Keystore with absolute paths for key.properties...',
  );

  File? gradleFile = _findGradleFile();
  if (gradleFile == null || !gradleFile.existsSync()) {
    printMsg(
      'error',
      'Could not locate build.gradle or build.gradle.kts anywhere in android/ directory.',
    );
    return;
  }

  final keyPropsPath = File(
    env['KEY_PROPERTIES_PATH'] ?? 'android/key.properties',
  ).absolute.path.replaceAll('\\', '/');

  var content = gradleFile.readAsStringSync();
  final isKotlinDsl = gradleFile.path.endsWith('.kts');

  content = content.replaceAll(
    RegExp(r'val keystoreProperties =[\s\S]*?\}'),
    '',
  );
  content = content.replaceAll(
    RegExp(r'def keystoreProperties =[\s\S]*?\}'),
    '',
  );
  content = content.replaceAll(RegExp(r'import java\.util\.Properties\s*'), '');
  content = content.replaceAll(
    RegExp(r'import java\.io\.FileInputStream\s*'),
    '',
  );

  final keystoreLoadBlock = isKotlinDsl
      ? '''
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = File("$keyPropsPath")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { stream ->
        keystoreProperties.load(stream)
    }
}
'''
      : '''
def keystoreProperties = new Properties()
def keystorePropertiesFile = new File('$keyPropsPath')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
''';
  content = keystoreLoadBlock + '\n' + content;

  content = content.replaceAll(
    RegExp(r'signingConfigs\s*\{[\s\S]*?\}', multiLine: true),
    '',
  );

  final signingConfigBlock = isKotlinDsl
      ? '''
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { File(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }
'''
      : '''
    signingConfigs {
        release {
            keyAlias keystoreProperties.getProperty('keyAlias')
            keyPassword keystoreProperties.getProperty('keyPassword')
            storeFile keystoreProperties.getProperty('storeFile') ? new File(keystoreProperties.getProperty('storeFile')) : null
            storePassword keystoreProperties.getProperty('storePassword')
        }
    }
''';

  int androidIndex = content.indexOf('android {');
  if (androidIndex != -1) {
    int insertIndex = androidIndex + 'android {'.length;
    content =
        content.substring(0, insertIndex) +
        '\n' +
        signingConfigBlock +
        content.substring(insertIndex);
  }

  if (content.contains('release {')) {
    content = content.replaceAll(RegExp(r'signingConfig\s*=.*'), '');
    content = content.replaceAll(
      RegExp(r'signingConfig\s+signingConfigs\.release'),
      '',
    );

    content = content.replaceAll(
      RegExp(r'release\s*\{', multiLine: true),
      isKotlinDsl
          ? 'release {\n            signingConfig = signingConfigs.getByName("release")'
          : 'release {\n\t\t\tsigningConfig signingConfigs.release',
    );
  }

  gradleFile.writeAsStringSync(content);
  printMsg('success', 'Gradle file updated successfully with absolute paths.');
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

  Map<String, String> filePaths = {
    'apk': 'build/app/outputs/flutter-apk/app-release.apk',
    'aab': 'build/app/outputs/bundle/release/app-release.aab',
  };

  Map<String, String> dirPaths = {
    'ios': 'build/ios/iphoneos/Runner.app',
    'windows': 'build/windows/x64/runner/Release',
    'linux': 'build/linux/x64/release/bundle',
    'macos': 'build/macos/Build/Products/Release/Runner.app',
    'web': 'build/web',
  };

  if (type == 'all') {
    filePaths.forEach(
      (k, v) => _copyFileArtifact(v, releaseDir.path, appName, k),
    );
    dirPaths.forEach(
      (k, v) => _copyDirArtifact(v, releaseDir.path, appName, k),
    );
  } else {
    if (filePaths.containsKey(type)) {
      _copyFileArtifact(filePaths[type]!, releaseDir.path, appName, type);
    } else if (dirPaths.containsKey(type)) {
      _copyDirArtifact(dirPaths[type]!, releaseDir.path, appName, type);
    }
  }
}

void _copyFileArtifact(
  String srcPath,
  String destDir,
  String appName,
  String type,
) {
  final srcFile = File(srcPath);
  String ext = (type == 'apk')
      ? '.apk'
      : (type == 'aab')
      ? '.aab'
      : '';
  String destPath = '$destDir/$appName$ext';

  if (srcFile.existsSync()) {
    srcFile.copySync(destPath);
    printMsg('success', 'Copied $type file to $destPath');
  } else {
    printMsg(
      'warning',
      'Source file for $type not found at $srcPath (Make sure to build first).',
    );
  }
}

void _copyDirArtifact(
  String srcPath,
  String destDir,
  String appName,
  String type,
) {
  final srcDir = Directory(srcPath);
  String destPath = '$destDir/$appName-$type';

  if (srcDir.existsSync()) {
    final targetSubDir = Directory(destPath);
    if (targetSubDir.existsSync()) {
      targetSubDir.deleteSync(recursive: true);
    }
    targetSubDir.createSync(recursive: true);

    _copyDirectoryRecursive(srcDir, targetSubDir);
    printMsg(
      'success',
      'Copied $type folder completely to ${targetSubDir.path}',
    );
  } else {
    printMsg(
      'warning',
      'Source directory for $type not found at $srcPath (Make sure to build first).',
    );
  }
}

void _copyDirectoryRecursive(Directory source, Directory destination) {
  source.listSync(recursive: false).forEach((entity) {
    String entityName = entity.uri.pathSegments.last;
    if (entityName.isEmpty && entity.path.isNotEmpty) {
      entityName = Directory(entity.path).path
          .split(Platform.pathSeparator)
          .last;
    }
    if (entity is Directory) {
      var newDirectory = Directory('${destination.path}/$entityName');
      newDirectory.createSync(recursive: true);
      _copyDirectoryRecursive(entity, newDirectory);
    } else if (entity is File) {
      entity.copySync('${destination.path}/$entityName');
    }
  });
}
