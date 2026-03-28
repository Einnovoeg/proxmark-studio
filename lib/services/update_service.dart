import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/update_info.dart';
import 'security_utils.dart';

/// Downloads pre-packaged PM3 core bundles from this app's GitHub releases.
class UpdateService {
  UpdateService({String? owner, String? repo})
    : owner = owner ?? '',
      repo = repo ?? '';

  static const int _maxDownloadBytes = 512 * 1024 * 1024;
  static const int _maxChecksumBytes = 64 * 1024;
  static const int _maxArchiveEntries = 4096;
  static const int _maxExtractedBytes = 1024 * 1024 * 1024;

  final String owner;
  final String repo;

  bool get hasConfiguredReleaseSource => owner.isNotEmpty && repo.isNotEmpty;

  Future<UpdateInfo?> fetchLatestStable() async {
    if (!hasConfiguredReleaseSource) return null;
    return _fetchRelease(prerelease: false);
  }

  Future<UpdateInfo?> fetchLatestExperimental() async {
    if (!hasConfiguredReleaseSource) return null;
    return _fetchRelease(prerelease: true);
  }

  Future<String?> install(
    UpdateInfo info, {
    void Function(int received, int total)? onProgress,
  }) async {
    if (info.downloadUrl.isEmpty ||
        info.checksumUrl.isEmpty ||
        !SecurityUtils.isTrustedGitHubUrl(info.downloadUrl) ||
        !SecurityUtils.isTrustedGitHubUrl(info.checksumUrl)) {
      return null;
    }

    final tempDir = await getTemporaryDirectory();
    final downloadFile = File(
      '${tempDir.path}/${SecurityUtils.sanitizeFileName(info.assetName, fallback: 'pm3-core')}',
    );
    if (await downloadFile.exists()) {
      await downloadFile.delete();
    }

    final client = http.Client();
    try {
      final response = await _openTrustedStream(
        client,
        Uri.parse(info.downloadUrl),
      );
      if (response == null || response.statusCode != 200) {
        return null;
      }

      await _writeDownloadToFile(
        response,
        downloadFile,
        maxBytes: _maxDownloadBytes,
        onProgress: onProgress,
      );

      final expectedSha256 = await _fetchChecksum(
        client,
        checksumUrl: info.checksumUrl,
        assetName: info.assetName,
      );
      if (expectedSha256 == null) {
        await _deleteIfPresent(downloadFile);
        return null;
      }

      final actualSha256 = await _sha256ForFile(downloadFile);
      if (actualSha256 != expectedSha256) {
        await _deleteIfPresent(downloadFile);
        return null;
      }
    } finally {
      client.close();
    }

    final supportDir = await getApplicationSupportDirectory();
    final safeTag = SecurityUtils.sanitizePathComponent(
      info.tag,
      fallback: 'release',
    );
    final releaseDir = Directory('${supportDir.path}/core/releases/$safeTag');
    if (await releaseDir.exists()) {
      await releaseDir.delete(recursive: true);
    }
    await releaseDir.create(recursive: true);

    try {
      final extractedDir = await _extract(downloadFile, releaseDir);
      if (extractedDir == null) {
        return null;
      }

      final executable = _findExecutable(extractedDir);
      if (executable == null) {
        return null;
      }

      await _restoreExecutableBits(extractedDir);
      return executable.path;
    } finally {
      if (await downloadFile.exists()) {
        await _deleteIfPresent(downloadFile);
      }
    }
  }

  Future<UpdateInfo?> _fetchRelease({required bool prerelease}) async {
    try {
      final uri = Uri.parse(
        'https://api.github.com/repos/$owner/$repo/releases?per_page=20',
      );
      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'Proxmark Studio',
            },
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return null;

      final releases = (jsonDecode(response.body) as List<dynamic>)
          .whereType<Map<String, dynamic>>();
      for (final release in releases) {
        final isPrerelease = release['prerelease'] == true;
        final isDraft = release['draft'] == true;
        if (isDraft || isPrerelease != prerelease) continue;

        final assets = (release['assets'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
        final asset = _pickAsset(assets);
        if (asset == null) continue;
        final checksumAsset = _pickChecksumAsset(assets, asset);
        if (checksumAsset == null) continue;

        final tag = release['tag_name'] as String? ?? 'latest';
        final name = release['name'] as String? ?? tag;
        final publishedAt = DateTime.tryParse(
          release['published_at'] as String? ?? '',
        );
        return UpdateInfo(
          tag: tag,
          name: name,
          publishedAt: publishedAt,
          assetName: asset['name'] as String? ?? 'release',
          downloadUrl: asset['browser_download_url'] as String? ?? '',
          checksumAssetName:
              checksumAsset['name'] as String? ?? 'release.sha256',
          checksumUrl: checksumAsset['browser_download_url'] as String? ?? '',
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _pickAsset(List<Map<String, dynamic>> assets) {
    if (assets.isEmpty) return null;

    final platform = _platformSlug();
    final arch = _archSlug();

    final platformMatchers = <RegExp>[
      RegExp(platform, caseSensitive: false),
      if (platform == 'macos') RegExp('darwin|osx', caseSensitive: false),
      if (platform == 'windows') RegExp('win', caseSensitive: false),
    ];

    final archMatchers = <RegExp>[
      RegExp(arch, caseSensitive: false),
      if (arch == 'x64') RegExp('x86_64|amd64', caseSensitive: false),
      if (arch == 'arm64') RegExp('aarch64', caseSensitive: false),
    ];

    final sorted =
        assets
            .where((asset) => _isReleaseAsset((asset['name'] as String? ?? '')))
            .toList()
          ..sort((a, b) {
            final scoreA = _assetScore(
              name: (a['name'] as String? ?? '').toLowerCase(),
              platformMatchers: platformMatchers,
              archMatchers: archMatchers,
            );
            final scoreB = _assetScore(
              name: (b['name'] as String? ?? '').toLowerCase(),
              platformMatchers: platformMatchers,
              archMatchers: archMatchers,
            );
            return scoreB.compareTo(scoreA);
          });

    if (sorted.isEmpty) return null;
    final topName = (sorted.first['name'] as String? ?? '').toLowerCase();
    final topScore = _assetScore(
      name: topName,
      platformMatchers: platformMatchers,
      archMatchers: archMatchers,
    );
    if (topScore < 60) return null;
    return sorted.first;
  }

  Map<String, dynamic>? _pickChecksumAsset(
    List<Map<String, dynamic>> assets,
    Map<String, dynamic> targetAsset,
  ) {
    final targetName = (targetAsset['name'] as String? ?? '').toLowerCase();
    if (targetName.isEmpty) {
      return null;
    }

    final exactMatches = <String>{
      '$targetName.sha256',
      '$targetName.sha256.txt',
      '$targetName.sha256sum',
      '$targetName.sha256sum.txt',
    };
    final genericMatches = <String>{
      'sha256sums',
      'sha256sums.txt',
      'checksums.sha256',
      'checksums.sha256.txt',
    };

    final candidates = assets
        .where((asset) {
          final name = (asset['name'] as String? ?? '').toLowerCase();
          if (name.isEmpty || name == targetName || !name.contains('sha256')) {
            return false;
          }
          return exactMatches.contains(name) ||
              genericMatches.contains(name) ||
              name.contains(targetName);
        })
        .toList(growable: false);

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort((a, b) {
      final left = (a['name'] as String? ?? '').toLowerCase();
      final right = (b['name'] as String? ?? '').toLowerCase();
      final leftExact = exactMatches.contains(left) ? 1 : 0;
      final rightExact = exactMatches.contains(right) ? 1 : 0;
      return rightExact.compareTo(leftExact);
    });
    return candidates.first;
  }

  Future<Directory?> _extract(File archiveFile, Directory releaseDir) async {
    final name = archiveFile.path.toLowerCase();
    if (name.endsWith('.zip')) {
      final archive = ZipDecoder().decodeBytes(await archiveFile.readAsBytes());
      await _extractArchiveSafely(archive, releaseDir);
      return releaseDir;
    }

    if (name.endsWith('.tar.gz') || name.endsWith('.tgz')) {
      final bytes = await archiveFile.readAsBytes();
      final tarData = GZipDecoder().decodeBytes(bytes);
      final archive = TarDecoder().decodeBytes(tarData);
      await _extractArchiveSafely(archive, releaseDir);
      return releaseDir;
    }

    if (name.endsWith('.tar')) {
      final bytes = await archiveFile.readAsBytes();
      final archive = TarDecoder().decodeBytes(bytes);
      await _extractArchiveSafely(archive, releaseDir);
      return releaseDir;
    }

    final target = File('${releaseDir.path}/${_executableName()}');
    await archiveFile.copy(target.path);
    return releaseDir;
  }

  Future<void> _extractArchiveSafely(
    Archive archive,
    Directory releaseDir,
  ) async {
    var entries = 0;
    var totalExtractedBytes = 0;

    try {
      for (final entry in archive) {
        entries += 1;
        if (entries > _maxArchiveEntries) {
          throw const FileSystemException('Archive contains too many files.');
        }

        if (entry.isSymbolicLink) {
          throw const FileSystemException(
            'Symbolic links are not allowed in release archives.',
          );
        }

        final outputPath = SecurityUtils.safeArchiveOutputPath(
          releaseDir.path,
          entry.name,
        );
        if (outputPath == null) {
          throw const FileSystemException('Unsafe archive path detected.');
        }

        if (entry.isDirectory) {
          await Directory(outputPath).create(recursive: true);
          continue;
        }

        totalExtractedBytes += entry.size;
        if (entry.size < 0 || totalExtractedBytes > _maxExtractedBytes) {
          throw const FileSystemException('Archive extraction limit exceeded.');
        }

        final outputFile = File(outputPath);
        await outputFile.parent.create(recursive: true);
        final bufferSize = entry.size <= 0
            ? OutputFileStream.kDefaultBufferSize
            : entry.size < OutputFileStream.kDefaultBufferSize
            ? entry.size
            : OutputFileStream.kDefaultBufferSize;
        final output = OutputFileStream(outputPath, bufferSize: bufferSize);
        try {
          entry.writeContent(output);
        } finally {
          await output.close();
        }
      }
    } finally {
      await archive.clear();
    }
  }

  File? _findExecutable(Directory releaseDir) {
    final executableNames = _candidateExecutableNames();
    final matches = releaseDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) {
          final base = file.uri.pathSegments.isEmpty
              ? file.path
              : file.uri.pathSegments.last;
          return executableNames.contains(base);
        })
        .toList(growable: false);
    if (matches.isEmpty) return null;
    for (final name in executableNames) {
      for (final match in matches) {
        final base = match.uri.pathSegments.isEmpty
            ? match.path
            : match.uri.pathSegments.last;
        if (base == name) {
          return match;
        }
      }
    }
    return matches.first;
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
      if (executableMatchers.any(
        (pattern) => pattern.hasMatch(normalizedPath),
      )) {
        await Process.run('chmod', ['+x', entity.path]);
      }
    }
  }

  Future<http.StreamedResponse?> _openTrustedStream(
    http.Client client,
    Uri uri,
  ) async {
    if (!SecurityUtils.isTrustedGitHubUrl(uri.toString())) {
      return null;
    }

    var current = uri;
    for (var redirectCount = 0; redirectCount < 5; redirectCount += 1) {
      final request = http.Request('GET', current);
      request.followRedirects = false;
      request.headers['User-Agent'] = 'Proxmark Studio';

      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 20));

      final status = response.statusCode;
      if (status >= 300 && status < 400) {
        final location = response.headers['location'];
        await response.stream.drain<void>();
        if (location == null) {
          return null;
        }

        final next = current.resolve(location);
        if (!SecurityUtils.isTrustedGitHubUrl(next.toString())) {
          return null;
        }
        current = next;
        continue;
      }

      final finalUri = response.request?.url ?? current;
      if (!SecurityUtils.isTrustedGitHubUrl(finalUri.toString())) {
        await response.stream.drain<void>();
        return null;
      }

      return response;
    }

    return null;
  }

  Future<void> _writeDownloadToFile(
    http.StreamedResponse response,
    File downloadFile, {
    required int maxBytes,
    void Function(int received, int total)? onProgress,
  }) async {
    final total = response.contentLength ?? -1;
    if (total > maxBytes) {
      await response.stream.drain<void>();
      throw const FileSystemException('Download exceeds safety limit.');
    }

    final sink = downloadFile.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 20),
      )) {
        received += chunk.length;
        if (received > maxBytes) {
          throw const FileSystemException('Download exceeds safety limit.');
        }
        sink.add(chunk);
        onProgress?.call(received, total);
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  Future<String?> _fetchChecksum(
    http.Client client, {
    required String checksumUrl,
    required String assetName,
  }) async {
    final response = await _openTrustedStream(client, Uri.parse(checksumUrl));
    if (response == null || response.statusCode != 200) {
      return null;
    }

    final buffer = BytesBuilder(copy: false);
    var received = 0;
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 20),
    )) {
      received += chunk.length;
      if (received > _maxChecksumBytes) {
        return null;
      }
      buffer.add(chunk);
    }

    final content = utf8.decode(buffer.takeBytes(), allowMalformed: false);
    return SecurityUtils.parseSha256Checksum(content, assetName);
  }

  Future<String> _sha256ForFile(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  Future<void> _deleteIfPresent(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best effort cleanup for temporary artifacts.
    }
  }

  String _platformSlug() {
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  String _archSlug() {
    switch (Abi.current()) {
      case Abi.macosArm64:
      case Abi.linuxArm64:
        return 'arm64';
      case Abi.macosX64:
      case Abi.linuxX64:
      case Abi.windowsX64:
        return 'x64';
      default:
        return 'unknown';
    }
  }

  String _executableName() => Platform.isWindows ? 'pm3.exe' : 'pm3';

  List<String> _candidateExecutableNames() {
    if (Platform.isWindows) {
      return const ['pm3.exe', 'proxmark3.exe'];
    }
    return const ['pm3', 'proxmark3'];
  }

  bool _isReleaseAsset(String name) {
    final lower = name.toLowerCase();
    return (lower.endsWith('.zip') ||
            lower.endsWith('.tar.gz') ||
            lower.endsWith('.tgz') ||
            lower.endsWith('.tar')) &&
        lower.contains('core');
  }

  int _assetScore({
    required String name,
    required List<RegExp> platformMatchers,
    required List<RegExp> archMatchers,
  }) {
    var score = 0;
    if (name.contains('core')) {
      score += 40;
    }
    if (name.contains('pm3') || name.contains('proxmark')) {
      score += 20;
    }
    if (platformMatchers.any((rx) => rx.hasMatch(name))) {
      score += 25;
    }
    if (archMatchers.any((rx) => rx.hasMatch(name))) {
      score += 20;
    }
    if (name.contains('bundle')) {
      score += 10;
    }
    return score;
  }
}
