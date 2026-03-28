class UpdateInfo {
  const UpdateInfo({
    required this.tag,
    required this.name,
    required this.publishedAt,
    required this.assetName,
    required this.downloadUrl,
    required this.checksumAssetName,
    required this.checksumUrl,
  });

  final String tag;
  final String name;
  final DateTime? publishedAt;
  final String assetName;
  final String downloadUrl;
  final String checksumAssetName;
  final String checksumUrl;
}
