import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/core_info.dart';
import 'security_utils.dart';

/// Resolves the PM3 client executable from the active installation source and
/// keeps extracted bundled runtimes usable across fresh installs.
class CoreManager {
  Future<CoreInfo> resolveCore() async {
    final supportDir = await getApplicationSupportDirectory();
    final coreRoot = Directory('${supportDir.path}/core');
    if (!await coreRoot.exists()) {
      await coreRoot.create(recursive: true);
    }

    final currentFile = File('${coreRoot.path}/current.json');
    if (await currentFile.exists()) {
      final data = jsonDecode(await currentFile.readAsString());
      if (data is Map<String, dynamic>) {
        final path = data['path'] as String?;
        final version = data['version'] as String?;
        if (path != null &&
            await File(path).exists() &&
            SecurityUtils.isTrustedManagedOrSystemExecutablePath(
              candidatePath: path,
              managedRootPath: coreRoot.path,
            ) &&
            await _isUsableCoreEntryPoint(path)) {
          return CoreInfo(
            path: path,
            source: CoreSource.updated,
            versionLabel: version,
          );
        }
      }
    }

    final embedded = await _extractEmbedded(coreRoot);
    if (embedded != null) {
      return CoreInfo(
        path: embedded,
        source: CoreSource.embedded,
        versionLabel: 'embedded',
      );
    }

    final systemBundled = await _bootstrapFromSystem(coreRoot);
    if (systemBundled != null) {
      await writeCurrent(path: systemBundled, version: 'system-bundled');
      return CoreInfo(
        path: systemBundled,
        source: CoreSource.system,
        versionLabel: 'system-bundled',
      );
    }

    return const CoreInfo(path: null, source: CoreSource.missing);
  }

  Future<void> writeCurrent({
    required String path,
    required String version,
  }) async {
    final supportDir = await getApplicationSupportDirectory();
    final coreRoot = Directory('${supportDir.path}/core');
    if (!await coreRoot.exists()) {
      await coreRoot.create(recursive: true);
    }

    if (!SecurityUtils.isTrustedManagedOrSystemExecutablePath(
      candidatePath: path,
      managedRootPath: coreRoot.path,
    )) {
      throw ArgumentError.value(
        path,
        'path',
        'Only app-managed or known system Proxmark3 binaries can be trusted.',
      );
    }

    final currentFile = File('${coreRoot.path}/current.json');
    await currentFile.writeAsString(
      jsonEncode({'path': path, 'version': version}),
    );
  }

  Future<String?> importCore(
    File file, {
    String? versionLabel,
    bool setAsCurrent = true,
  }) async {
    final supportDir = await getApplicationSupportDirectory();
    final coreRoot = Directory('${supportDir.path}/core');
    if (!await coreRoot.exists()) {
      await coreRoot.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final importDir = Directory('${coreRoot.path}/imported/$timestamp');
    await importDir.create(recursive: true);
    final importBinDir = Directory('${importDir.path}/bin');
    await importBinDir.create(recursive: true);

    final sourceExecutableName = file.uri.pathSegments.last;
    final outFile = File('${importBinDir.path}/$sourceExecutableName');
    await file.copy(outFile.path);
    await _copySiblingClientIfAvailable(file, importDir);
    await _copyShareDirectoryIfAvailable(file.parent, importDir);
    await _restoreExecutableBits(importDir);

    if (!await _isUsableCoreEntryPoint(outFile.path)) {
      await importDir.delete(recursive: true);
      throw StateError(
        'The selected Proxmark3 client could not start cleanly. Import a complete, working build that passes `pm3 --helpclient`.',
      );
    }

    if (setAsCurrent) {
      await writeCurrent(
        path: outFile.path,
        version: versionLabel ?? 'manual-$timestamp',
      );
    }
    return outFile.path;
  }

  Future<String?> _extractEmbedded(Directory coreRoot) async {
    final platform = _platformSlug();
    final arch = _archSlug();
    if (platform == null || arch == null) return null;

    final assetPrefix = 'assets/bundled/$platform/$arch/';
    final assetPaths = await _bundledAssetPaths(assetPrefix);
    if (assetPaths.isEmpty) return null;

    final embeddedDir = Directory('${coreRoot.path}/embedded/$platform-$arch');
    if (!await embeddedDir.exists()) {
      await embeddedDir.create(recursive: true);
    }

    final existing = _resolveEmbeddedEntryPoint(embeddedDir);
    if (existing != null &&
        existing.existsSync() &&
        await _isUsableCoreEntryPoint(existing.path)) {
      await _restoreExecutableBits(embeddedDir);
      return existing.path;
    }

    for (final assetPath in assetPaths) {
      final relativePath = assetPath.substring(assetPrefix.length);
      if (relativePath.isEmpty) continue;

      final data = await rootBundle.load(assetPath);
      final outFile = File('${embeddedDir.path}/$relativePath');
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }

    await _restoreExecutableBits(embeddedDir);
    final executable = _resolveEmbeddedEntryPoint(embeddedDir);
    if (executable == null || !await _isUsableCoreEntryPoint(executable.path)) {
      await embeddedDir.delete(recursive: true);
      return null;
    }
    return executable.path;
  }

  Future<List<String>> _bundledAssetPaths(String prefix) async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final manifest = jsonDecode(manifestContent);
      if (manifest is! Map<String, dynamic>) return const [];
      final assets =
          manifest.keys
              .where((key) => key.startsWith(prefix) && !key.endsWith('/'))
              .toList()
            ..sort();
      return assets;
    } catch (_) {
      return const [];
    }
  }

  File? _resolveEmbeddedEntryPoint(Directory embeddedDir) {
    final candidates = Platform.isWindows
        ? const ['bin/pm3.exe', 'pm3.exe', 'bin/proxmark3.exe', 'proxmark3.exe']
        : const ['bin/pm3', 'pm3', 'bin/proxmark3', 'proxmark3'];
    for (final relative in candidates) {
      final file = File('${embeddedDir.path}/$relative');
      if (file.existsSync()) return file;
    }
    return null;
  }

  Future<void> _restoreExecutableBits(Directory root) async {
    if (Platform.isWindows || !await root.exists()) return;

    final executableMatchers = <RegExp>[
      RegExp(r'/bin/[^/]+$'),
      RegExp(r'/lib/[^/]+\.dylib$'),
      RegExp(r'/Frameworks/.+/Python$'),
    ];

    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final normalizedPath = entity.path.replaceAll('\\', '/');
      final shouldMarkExecutable = executableMatchers.any(
        (pattern) => pattern.hasMatch(normalizedPath),
      );
      if (shouldMarkExecutable) {
        await Process.run('chmod', ['+x', entity.path]);
      }
    }
  }

  Future<String?> _bootstrapFromSystem(Directory coreRoot) async {
    final candidate = await _findSystemCoreExecutable();
    if (candidate == null) return null;

    final platform = _platformSlug() ?? 'unknown';
    final arch = _archSlug() ?? 'unknown';
    final executableName = Platform.isWindows ? 'pm3.exe' : 'pm3';
    final embeddedDir = Directory('${coreRoot.path}/embedded/$platform-$arch');
    if (!await embeddedDir.exists()) {
      await embeddedDir.create(recursive: true);
    }
    final embeddedBinDir = Directory('${embeddedDir.path}/bin');
    if (!await embeddedBinDir.exists()) {
      await embeddedBinDir.create(recursive: true);
    }

    final outFile = File('${embeddedBinDir.path}/$executableName');
    await File(candidate).copy(outFile.path);
    await _copySiblingClientIfAvailable(File(candidate), embeddedDir);
    await _copyShareDirectoryIfAvailable(File(candidate).parent, embeddedDir);
    await _restoreExecutableBits(embeddedDir);
    if (!await _isUsableCoreEntryPoint(outFile.path)) {
      await embeddedDir.delete(recursive: true);
      return null;
    }
    return outFile.path;
  }

  Future<String?> _findSystemCoreExecutable() async {
    final candidates = <String>[
      if (Platform.isMacOS) '/opt/homebrew/opt/proxmark3/bin/pm3',
      if (Platform.isMacOS) '/usr/local/opt/proxmark3/bin/pm3',
      if (Platform.isLinux) '/usr/bin/pm3',
      if (Platform.isLinux) '/usr/local/bin/pm3',
      if (Platform.isWindows) r'C:\Program Files\Proxmark3\pm3.exe',
    ];

    for (final candidate in candidates) {
      if (await File(candidate).exists() &&
          SecurityUtils.isKnownSystemCoreExecutablePath(candidate)) {
        return candidate;
      }
    }
    return null;
  }

  String? guessWorkingDir(String? executablePath) {
    if (executablePath == null || executablePath.isEmpty) return null;
    final file = File(executablePath);
    if (!file.existsSync()) {
      return null;
    }

    final binDir = file.parent;
    if (_hasDataFolders(binDir)) {
      return binDir.path;
    }

    final parent = binDir.parent;
    final clientDir = Directory('${parent.path}/client');
    if (clientDir.existsSync() && _hasDataFolders(clientDir)) {
      return clientDir.path;
    }

    return binDir.path;
  }

  bool _hasDataFolders(Directory dir) {
    return Directory('${dir.path}/resources').existsSync() ||
        Directory('${dir.path}/dictionaries').existsSync() ||
        Directory('${dir.path}/share/proxmark3').existsSync() ||
        Directory('${dir.parent.path}/share/proxmark3').existsSync();
  }

  Future<void> _copySiblingClientIfAvailable(
    File sourceExecutable,
    Directory destinationRoot,
  ) async {
    final sourceName = sourceExecutable.uri.pathSegments.last.toLowerCase();
    if (!sourceName.startsWith('pm3')) {
      return;
    }

    final siblingName = Platform.isWindows ? 'proxmark3.exe' : 'proxmark3';
    final sibling = File('${sourceExecutable.parent.path}/$siblingName');
    if (!await sibling.exists()) {
      return;
    }

    final destinationBin = Directory('${destinationRoot.path}/bin');
    await destinationBin.create(recursive: true);
    await sibling.copy('${destinationBin.path}/$siblingName');
  }

  Future<void> _copyShareDirectoryIfAvailable(
    Directory sourceBinDir,
    Directory destinationRoot,
  ) async {
    final shareDir = Directory('${sourceBinDir.parent.path}/share/proxmark3');
    if (!await shareDir.exists()) {
      return;
    }

    final destinationShare = Directory(
      '${destinationRoot.path}/share/proxmark3',
    );
    if (await destinationShare.exists()) {
      await destinationShare.delete(recursive: true);
    }
    await destinationShare.parent.create(recursive: true);

    await for (final entity in shareDir.list(
      recursive: true,
      followLinks: false,
    )) {
      final relativePath = entity.path.substring(shareDir.path.length + 1);
      final outputPath = '${destinationShare.path}/$relativePath';
      if (entity is Directory) {
        await Directory(outputPath).create(recursive: true);
      } else if (entity is File) {
        await File(outputPath).parent.create(recursive: true);
        await entity.copy(outputPath);
      }
    }
  }

  /// Treats a core as valid only when the entry point can load the real PM3
  /// client, not just when a wrapper script happens to exist on disk.
  Future<bool> _isUsableCoreEntryPoint(String executablePath) async {
    final executable = File(executablePath);
    if (!await executable.exists()) {
      return false;
    }

    final fileName = executable.uri.pathSegments.last.toLowerCase();
    final arguments = fileName.startsWith('pm3') ? ['--helpclient'] : ['-h'];
    final workingDirectory =
        guessWorkingDir(executable.path) ?? executable.parent.path;

    try {
      final result = await Process.run(
        executable.path,
        arguments,
        workingDirectory: workingDirectory,
      ).timeout(const Duration(seconds: 5));
      final output = '${result.stdout}\n${result.stderr}'.toLowerCase();
      if (result.exitCode != 0) {
        return false;
      }
      return !output.contains('symbol not found') &&
          !output.contains('abort trap') &&
          !output.contains('dyld[') &&
          !output.contains('error while loading shared libraries');
    } catch (_) {
      return false;
    }
  }

  String? _platformSlug() {
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return null;
  }

  String? _archSlug() {
    switch (Abi.current()) {
      case Abi.macosArm64:
      case Abi.linuxArm64:
        return 'arm64';
      case Abi.macosX64:
      case Abi.linuxX64:
      case Abi.windowsX64:
        return 'x64';
      default:
        return null;
    }
  }
}
