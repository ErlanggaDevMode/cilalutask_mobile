enum UserRole {
  admin('Admin / Manager'),
  user('User (Karyawan)');

  final String label;
  const UserRole(this.label);

  bool get isAdmin => this == UserRole.admin;
  bool get isUser => this == UserRole.user;
}
