import 'package:flutter_test/flutter_test.dart';
import 'package:proxmark_studio/services/security_utils.dart';

void main() {
  group('SecurityUtils.isTrustedGitHubUrl', () {
    test('accepts known GitHub release hosts over HTTPS', () {
      expect(
        SecurityUtils.isTrustedGitHubUrl(
          'https://github.com/example-org/proxmark-studio/releases/download/v1/core.zip',
        ),
        isTrue,
      );
      expect(
        SecurityUtils.isTrustedGitHubUrl(
          'https://release-assets.githubusercontent.com/example',
        ),
        isTrue,
      );
    });

    test('rejects non-HTTPS and untrusted hosts', () {
      expect(
        SecurityUtils.isTrustedGitHubUrl('http://github.com/example'),
        isFalse,
      );
      expect(
        SecurityUtils.isTrustedGitHubUrl('https://example.com/core.zip'),
        isFalse,
      );
    });
  });

  group('SecurityUtils.safeArchiveOutputPath', () {
    test('keeps normal archive entries inside the extraction root', () {
      expect(
        SecurityUtils.safeArchiveOutputPath('/tmp/proxmark', 'bin/pm3'),
        '/tmp/proxmark/bin/pm3',
      );
    });

    test('rejects parent traversal and absolute paths', () {
      expect(
        SecurityUtils.safeArchiveOutputPath('/tmp/proxmark', '../pm3'),
        isNull,
      );
      expect(
        SecurityUtils.safeArchiveOutputPath('/tmp/proxmark', '/etc/passwd'),
        isNull,
      );
    });
  });

  group('SecurityUtils.parseSha256Checksum', () {
    test('extracts checksum from sha256sum formatted content', () {
      const digest =
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
      final parsed = SecurityUtils.parseSha256Checksum(
        '$digest  proxmark-core-macos-arm64.zip\n',
        'proxmark-core-macos-arm64.zip',
      );
      expect(parsed, digest);
    });

    test('extracts a single digest from checksum-only content', () {
      const digest =
          'abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd';
      final parsed = SecurityUtils.parseSha256Checksum(
        '$digest\n',
        'ignored.zip',
      );
      expect(parsed, digest);
    });
  });

  group('SecurityUtils.isTrustedManagedOrSystemExecutablePath', () {
    test('accepts files under the managed core root', () {
      expect(
        SecurityUtils.isTrustedManagedOrSystemExecutablePath(
          candidatePath: '/tmp/proxmark/core/releases/v1/pm3',
          managedRootPath: '/tmp/proxmark/core',
        ),
        isTrue,
      );
    });

    test('rejects files outside the managed root and system allowlist', () {
      expect(
        SecurityUtils.isTrustedManagedOrSystemExecutablePath(
          candidatePath: '/tmp/pm3',
          managedRootPath: '/tmp/proxmark/core',
        ),
        isFalse,
      );
    });
  });
}
