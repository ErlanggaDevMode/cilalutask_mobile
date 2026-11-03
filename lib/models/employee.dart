class Assignee {
  final String id;
  final String name;
  final String shortName;
  final String avatar;
  final String division;
  final String role;
  final bool hasTeamBadge;
  final int teamCount;
  final String email;

  const Assignee({
    required this.id,
    required this.name,
    required this.shortName,
    required this.avatar,
    required this.division,
    required this.role,
    this.hasTeamBadge = false,
    this.teamCount = 0,
    this.email = '',
  });

  Assignee copyWith({
    String? id,
    String? name,
    String? shortName,
    String? avatar,
    String? division,
    String? role,
    bool? hasTeamBadge,
    int? teamCount,
    String? email,
  }) {
    return Assignee(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      avatar: avatar ?? this.avatar,
      division: division ?? this.division,
      role: role ?? this.role,
      hasTeamBadge: hasTeamBadge ?? this.hasTeamBadge,
      teamCount: teamCount ?? this.teamCount,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'shortName': shortName,
      'avatar': avatar,
      'division': division,
      'role': role,
      'hasTeamBadge': hasTeamBadge,
      'teamCount': teamCount,
      'email': email,
    };
  }

  factory Assignee.fromMap(Map<String, dynamic> map) {
    return Assignee(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      shortName: map['shortName'] as String? ?? '',
      avatar: map['avatar'] as String? ?? '',
      division: map['division'] as String? ?? '',
      role: map['role'] as String? ?? '',
      hasTeamBadge: map['hasTeamBadge'] as bool? ?? false,
      teamCount: map['teamCount'] as int? ?? 0,
      email: map['email'] as String? ?? '',
    );
  }
}

class CurrentUser {
  final String name;
  final String role;
  final String email;
  final String avatar;
  final String division;
  final int targetQuarterPercent;
  final int teamEfficiencyPercent;

  const CurrentUser({
    required this.name,
    required this.role,
    required this.email,
    required this.avatar,
    required this.division,
    required this.targetQuarterPercent,
    required this.teamEfficiencyPercent,
  });
}
