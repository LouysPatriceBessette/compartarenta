class ExportBundle {
  const ExportBundle({
    required this.formatVersion,
    required this.plans,
    required this.participants,
  });

  final int formatVersion;
  final List<Map<String, Object?>> plans;
  final List<Map<String, Object?>> participants;

  Map<String, Object?> toJson() => {
        'formatVersion': formatVersion,
        'plans': plans,
        'participants': participants,
      };
}

