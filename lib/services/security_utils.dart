import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

/// Centralizes small security-sensitive helpers so process launching, downloads,
/// and archive extraction all apply the same validation rules.
class SecurityUtils {
  static const Set<String> trustedGitHubHosts = {
    'api.github.com',
    'github.com',
    'github-releases.githubusercontent.com',
    'objects.githubusercontent.com',
    'release-assets.githubusercontent.com',
  };

  static const List<String> _knownSystemCoreDirectories = [
    '/opt/homebrew/opt/proxmark3/bin',
    '/usr/local/opt/proxmark3/bin',
    '/usr/bin',
    '/usr/local/bin',
    r'C:\Program Files\Proxmark3',
  ];

  /// Only HTTPS GitHub release endpoints are trusted for automatic downloads.
  static bool isTrustedGitHubUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return false;
    }

    final host = uri.host.toLowerCase();
    return trustedGitHubHosts.contains(host);
  }

  /// External links opened in the browser are restricted to normal HTTPS URLs.
  static bool isSafeExternalHttpsUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty;
  }

  /// Release-provided filenames are sanitized before writing into temp or
  /// support directories so archive metadata cannot smuggle path separators.
  static String sanitizeFileName(
    String rawName, {
    String fallback = 'download',
  }) {
    final trimmed = rawName.trim();
    final baseName = trimmed.split(RegExp(r'[\\/]')).last;
    final cleaned = baseName
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'^\.{1,}'), '');
    if (cleaned.isEmpty || cleaned == '.' || cleaned == '..') {
      return fallback;
    }
    return cleaned.length > 120 ? cleaned.substring(0, 120) : cleaned;
  }

  /// Tags and other archive-derived path fragments are normalized to a single
  /// safe path component before they become folders on disk.
  static String sanitizePathComponent(
    String rawValue, {
    String fallback = 'item',
  }) {
    final cleaned = rawValue
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'^\.{1,}'), '');
    if (cleaned.isEmpty || cleaned == '.' || cleaned == '..') {
      return fallback;
    }
    return cleaned.length > 80 ? cleaned.substring(0, 80) : cleaned;
  }

  /// Archive entries must stay inside the extraction root and may not use
  /// absolute paths or parent-directory traversal.
  static String? safeArchiveOutputPath(String rootPath, String entryName) {
    final normalizedEntry = path.normalize(entryName.replaceAll('\\', '/'));
    if (normalizedEntry.isEmpty ||
        normalizedEntry == '.' ||
        normalizedEntry == '..' ||
        path.isAbsolute(normalizedEntry)) {
      return null;
    }

    final normalizedRoot = path.normalize(rootPath);
    final outputPath = path.normalize(
      path.join(normalizedRoot, normalizedEntry),
    );
    if (!path.isWithin(normalizedRoot, outputPath)) {
      return null;
    }
    return outputPath;
  }

  /// Auto-updates prefer checksum sidecars that either contain a single digest
  /// or a standard `sha256sum` line that references the downloaded asset.
  static String? parseSha256Checksum(String content, String assetName) {
    final digestPattern = RegExp(r'\b([a-f0-9]{64})\b', caseSensitive: false);
    final assetBaseName = sanitizeFileName(assetName).toLowerCase();
    final lines = const LineSplitter()
        .convert(content)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    for (final line in lines) {
      final match = digestPattern.firstMatch(line);
      if (match == null) continue;
      if (line.toLowerCase().contains(assetBaseName)) {
        return match.group(1)!.toLowerCase();
      }
    }

    final matches = digestPattern
        .allMatches(content)
        .map((match) => match.group(1)!.toLowerCase())
        .toSet()
        .toList(growable: false);
    if (matches.length == 1) {
      return matches.first;
    }
    return null;
  }

  /// The app only auto-trusts binaries it manages under its support directory
  /// or well-known system package locations. It intentionally does not trust
  /// arbitrary PATH lookups.
  static bool isTrustedManagedOrSystemExecutablePath({
    required String candidatePath,
    required String managedRootPath,
  }) {
    if (candidatePath.trim().isEmpty) {
      return false;
    }

    final normalizedCandidate = _canonicalizeIfPossible(candidatePath);
    final normalizedManagedRoot = _canonicalizeIfPossible(managedRootPath);
    if (path.isWithin(normalizedManagedRoot, normalizedCandidate)) {
      return true;
    }

    return isKnownSystemCoreExecutablePath(candidatePath);
  }

  /// System-package fallbacks are limited to a short allowlist of locations so
  /// a manipulated PATH cannot silently redirect the app to a different binary.
  static bool isKnownSystemCoreExecutablePath(String candidatePath) {
    final normalizedCandidate = _canonicalizeIfPossible(candidatePath);
    return _knownSystemCoreDirectories.any((directory) {
      final normalizedDirectory = _canonicalizeIfPossible(directory);
      return path.isWithin(normalizedDirectory, normalizedCandidate);
    });
  }

  static String _canonicalizeIfPossible(String rawPath) {
    try {
      return File(rawPath).resolveSymbolicLinksSync();
    } catch (_) {
      return path.normalize(rawPath);
    }
  }
}
