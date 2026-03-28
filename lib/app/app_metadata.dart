class AppMetadata {
  static const appName = 'Proxmark Studio';
  static const appVersion = '0.2.0';
  static const appLicense = 'GPL-3.0-only';

  static const documentationUrl =
      'https://github.com/RfidResearchGroup/proxmark3/wiki';
  static const supportUrl = 'https://buymeacoffee.com/einnovoeg';

  // Official release builds can set these with --dart-define so the updater
  // pulls bundled core archives from the published GitHub releases without
  // hard-coding a personal repository in the source tree.
  static const releaseOwner = String.fromEnvironment(
    'PROXMARK_STUDIO_RELEASE_OWNER',
  );
  static const releaseRepo = String.fromEnvironment(
    'PROXMARK_STUDIO_RELEASE_REPO',
  );

  static bool get hasConfiguredReleaseSource =>
      releaseOwner.isNotEmpty && releaseRepo.isNotEmpty;
}
