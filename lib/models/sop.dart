import '../core/utils/data_parser.dart';

class ContentSection {
  final String heading;
  final List<String> items;

  const ContentSection({required this.heading, required this.items});

  ContentSection copyWith({String? heading, List<String>? items}) {
    return ContentSection(
      heading: heading ?? this.heading,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() {
    return {'heading': heading, 'items': items};
  }

  factory ContentSection.fromMap(Map<String, dynamic> map) {
    return ContentSection(
      heading: map['heading'] as String? ?? '',
      items: DataParser.parseStringList(map['items']),
    );
  }
}

class SOPDocument {
  final String id;
  final String code;
  final String title;
  final String category;
  final String version;
  final bool isUrgentMandatory;
  final bool isNewUpdate;
  final bool isBookmarked;
  final String? deadlineWarning;
  final String? complianceTag;
  final String? complianceRatioText;
  final int? readProgressPercent;
  final String? readTeamCount;
  final String lastUpdatedText;
  final String? fileInfo;
  final String? checkPoints;
  final String? duration;
  final String? description;
  final List<ContentSection> contentSections;
  final bool isReadByMe;

  const SOPDocument({
    required this.id,
    required this.code,
    required this.title,
    required this.category,
    required this.version,
    this.isUrgentMandatory = false,
    this.isNewUpdate = false,
    this.isBookmarked = false,
    this.deadlineWarning,
    this.complianceTag,
    this.complianceRatioText,
    this.readProgressPercent,
    this.readTeamCount,
    required this.lastUpdatedText,
    this.fileInfo,
    this.checkPoints,
    this.duration,
    this.description,
    this.contentSections = const [],
    this.isReadByMe = false,
  });

  SOPDocument copyWith({
    String? id,
    String? code,
    String? title,
    String? category,
    String? version,
    bool? isUrgentMandatory,
    bool? isNewUpdate,
    bool? isBookmarked,
    String? deadlineWarning,
    String? complianceTag,
    String? complianceRatioText,
    int? readProgressPercent,
    String? readTeamCount,
    String? lastUpdatedText,
    String? fileInfo,
    String? checkPoints,
    String? duration,
    String? description,
    List<ContentSection>? contentSections,
    bool? isReadByMe,
  }) {
    return SOPDocument(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      category: category ?? this.category,
      version: version ?? this.version,
      isUrgentMandatory: isUrgentMandatory ?? this.isUrgentMandatory,
      isNewUpdate: isNewUpdate ?? this.isNewUpdate,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      deadlineWarning: deadlineWarning ?? this.deadlineWarning,
      complianceTag: complianceTag ?? this.complianceTag,
      complianceRatioText: complianceRatioText ?? this.complianceRatioText,
      readProgressPercent: readProgressPercent ?? this.readProgressPercent,
      readTeamCount: readTeamCount ?? this.readTeamCount,
      lastUpdatedText: lastUpdatedText ?? this.lastUpdatedText,
      fileInfo: fileInfo ?? this.fileInfo,
      checkPoints: checkPoints ?? this.checkPoints,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      contentSections: contentSections ?? this.contentSections,
      isReadByMe: isReadByMe ?? this.isReadByMe,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'category': category,
      'version': version,
      'isUrgentMandatory': isUrgentMandatory,
      'isNewUpdate': isNewUpdate,
      'isBookmarked': isBookmarked,
      'deadlineWarning': deadlineWarning,
      'complianceTag': complianceTag,
      'complianceRatioText': complianceRatioText,
      'readProgressPercent': readProgressPercent,
      'readTeamCount': readTeamCount,
      'lastUpdatedText': lastUpdatedText,
      'fileInfo': fileInfo,
      'checkPoints': checkPoints,
      'duration': duration,
      'description': description,
      'contentSections': contentSections.map((s) => s.toMap()).toList(),
      'isReadByMe': isReadByMe,
    };
  }

  factory SOPDocument.fromMap(Map<String, dynamic> map) {
    return SOPDocument(
      id: map['id'] as String? ?? '',
      code: map['code'] as String? ?? '',
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? '',
      version: map['version'] as String? ?? '',
      isUrgentMandatory: map['isUrgentMandatory'] as bool? ?? false,
      isNewUpdate: map['isNewUpdate'] as bool? ?? false,
      isBookmarked: map['isBookmarked'] as bool? ?? false,
      deadlineWarning: map['deadlineWarning'] as String?,
      complianceTag: map['complianceTag'] as String?,
      complianceRatioText: map['complianceRatioText'] as String?,
      readProgressPercent: map['readProgressPercent'] as int?,
      readTeamCount: map['readTeamCount'] as String?,
      lastUpdatedText: map['lastUpdatedText'] as String? ?? 'Baru saja',
      fileInfo: map['fileInfo'] as String?,
      checkPoints: map['checkPoints'] as String?,
      duration: map['duration'] as String?,
      description: map['description'] as String?,
      contentSections: DataParser.parseList<ContentSection>(
        map['contentSections'],
        (s) => ContentSection.fromMap(s),
      ),
      isReadByMe: map['isReadByMe'] as bool? ?? false,
    );
  }
}
