import '../core/utils/data_parser.dart';

enum JoinRequestStatus { pending, approved, rejected }

class Company {
  final String id;
  final String name;
  final String code; // Unique Company Code (e.g. CILALU-88, CORP-4821)
  final String adminName;
  final String adminEmail;
  final String adminUid; // Firebase Auth UID of company admin
  final DateTime createdAt;
  final String industry;

  const Company({
    required this.id,
    required this.name,
    required this.code,
    required this.adminName,
    required this.adminEmail,
    this.adminUid = '',
    required this.createdAt,
    this.industry = 'Teknologi & Operasional',
  });

  Company copyWith({
    String? id,
    String? name,
    String? code,
    String? adminName,
    String? adminEmail,
    String? adminUid,
    DateTime? createdAt,
    String? industry,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      adminName: adminName ?? this.adminName,
      adminEmail: adminEmail ?? this.adminEmail,
      adminUid: adminUid ?? this.adminUid,
      createdAt: createdAt ?? this.createdAt,
      industry: industry ?? this.industry,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'adminName': adminName,
      'adminEmail': adminEmail,
      'adminUid': adminUid,
      'createdAt': createdAt.toIso8601String(),
      'industry': industry,
    };
  }

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      code: map['code'] as String? ?? '',
      adminName: map['adminName'] as String? ?? '',
      adminEmail: map['adminEmail'] as String? ?? '',
      adminUid: map['adminUid'] as String? ?? map['adminId'] as String? ?? '',
      createdAt: DataParser.parseDateTime(map['createdAt']),
      industry: map['industry'] as String? ?? 'Teknologi & Operasional',
    );
  }
}

class JoinRequest {
  final String id;
  final String companyCode;
  final String companyName;
  final String userId; // Firebase Auth UID
  final String userName;
  final String userEmail;
  final String division;
  final String role;
  final String avatar;
  final JoinRequestStatus status;
  final DateTime requestedAt;

  const JoinRequest({
    required this.id,
    required this.companyCode,
    required this.companyName,
    this.userId = '',
    required this.userName,
    required this.userEmail,
    required this.division,
    required this.role,
    required this.avatar,
    this.status = JoinRequestStatus.pending,
    required this.requestedAt,
  });

  JoinRequest copyWith({
    String? id,
    String? companyCode,
    String? companyName,
    String? userId,
    String? userName,
    String? userEmail,
    String? division,
    String? role,
    String? avatar,
    JoinRequestStatus? status,
    DateTime? requestedAt,
  }) {
    return JoinRequest(
      id: id ?? this.id,
      companyCode: companyCode ?? this.companyCode,
      companyName: companyName ?? this.companyName,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      division: division ?? this.division,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyCode': companyCode,
      'companyName': companyName,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'division': division,
      'role': role,
      'avatar': avatar,
      'status': status.name,
      'requestedAt': requestedAt.toIso8601String(),
    };
  }

  factory JoinRequest.fromMap(Map<String, dynamic> map) {
    JoinRequestStatus parseStatus(String? val) {
      switch (val) {
        case 'approved':
          return JoinRequestStatus.approved;
        case 'rejected':
          return JoinRequestStatus.rejected;
        case 'pending':
        default:
          return JoinRequestStatus.pending;
      }
    }

    return JoinRequest(
      id: map['id'] as String? ?? '',
      companyCode: map['companyCode'] as String? ?? '',
      companyName: map['companyName'] as String? ?? '',
      userId: map['userId'] as String? ?? map['uid'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userEmail: map['userEmail'] as String? ?? '',
      division: map['division'] as String? ?? '',
      role: map['role'] as String? ?? '',
      avatar: map['avatar'] as String? ?? '',
      status: parseStatus(map['status'] as String?),
      requestedAt: DataParser.parseDateTime(map['requestedAt']),
    );
  }
}
