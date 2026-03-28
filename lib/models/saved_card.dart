enum SavedCardSource { scan, imported, manual }

class SavedCard {
  const SavedCard({
    required this.id,
    required this.label,
    required this.createdAt,
    required this.source,
    this.type,
    this.uid,
    this.sak,
    this.atqa,
    this.notes,
    this.writeCommands = const [],
  });

  final String id;
  final String label;
  final DateTime createdAt;
  final SavedCardSource source;
  final String? type;
  final String? uid;
  final String? sak;
  final String? atqa;
  final String? notes;
  final List<String> writeCommands;

  bool get hasWritePlan => normalizedWriteCommands.isNotEmpty;

  List<String> get normalizedWriteCommands => writeCommands
      .map((command) => command.trim())
      .where((command) => command.isNotEmpty)
      .toList(growable: false);

  SavedCard copyWith({
    String? id,
    String? label,
    DateTime? createdAt,
    SavedCardSource? source,
    String? type,
    String? uid,
    String? sak,
    String? atqa,
    String? notes,
    List<String>? writeCommands,
  }) {
    return SavedCard(
      id: id ?? this.id,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
      source: source ?? this.source,
      type: type ?? this.type,
      uid: uid ?? this.uid,
      sak: sak ?? this.sak,
      atqa: atqa ?? this.atqa,
      notes: notes ?? this.notes,
      writeCommands: writeCommands ?? this.writeCommands,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'createdAt': createdAt.toIso8601String(),
    'source': source.name,
    'type': type,
    'uid': uid,
    'sak': sak,
    'atqa': atqa,
    'notes': notes,
    'writeCommands': normalizedWriteCommands,
  };

  factory SavedCard.fromJson(Map<String, dynamic> json) {
    final rawCommands = json['writeCommands'];
    return SavedCard(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      label: json['label'] as String? ?? 'Imported Card',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      source: _sourceFromName(json['source'] as String?),
      type: json['type'] as String?,
      uid: json['uid'] as String?,
      sak: json['sak'] as String?,
      atqa: json['atqa'] as String?,
      notes: json['notes'] as String?,
      writeCommands: rawCommands is List
          ? rawCommands.whereType<String>().toList(growable: false)
          : const [],
    );
  }

  static SavedCard fromScannedRead({
    required String label,
    required DateTime timestamp,
    String? type,
    String? uid,
    String? sak,
    String? atqa,
  }) {
    return SavedCard(
      id: timestamp.microsecondsSinceEpoch.toString(),
      label: label,
      createdAt: timestamp,
      source: SavedCardSource.scan,
      type: type,
      uid: uid,
      sak: sak,
      atqa: atqa,
    );
  }

  static SavedCardSource _sourceFromName(String? value) {
    return switch (value) {
      'scan' => SavedCardSource.scan,
      'manual' => SavedCardSource.manual,
      _ => SavedCardSource.imported,
    };
  }
}
