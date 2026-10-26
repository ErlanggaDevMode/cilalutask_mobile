import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_colors.dart';
import '../../models/company.dart';
import '../../models/employee.dart';
import '../../models/user_role.dart';
import '../../state/app_state_scope.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 0: Masuk (Login), 1: Daftar Perusahaan (Admin Baru), 2: Gabung Tim (Karyawan)
  int _activeAuthTab = 0;

  // Loading state
  bool _isLoading = false;

  // Login state
  UserRole _selectedRole = UserRole.admin;
  final TextEditingController _loginCompanyCodeController =
      TextEditingController();
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();
  bool _obscureLoginPassword = true;

  // Register Company state
  final TextEditingController _regCompanyNameController =
      TextEditingController();
  final TextEditingController _regCompanyCodeController =
      TextEditingController();
  final TextEditingController _regAdminNameController = TextEditingController();
  final TextEditingController _regAdminEmailController =
      TextEditingController();
  final TextEditingController _regAdminPasswordController =
      TextEditingController();
  String _selectedIndustry = 'Teknologi & Operasional';

  // Join Request state
  final TextEditingController _joinCompanyCodeController =
      TextEditingController();
  final TextEditingController _joinNameController = TextEditingController();
  final TextEditingController _joinEmailController = TextEditingController();
  final TextEditingController _joinPasswordController = TextEditingController();
  final TextEditingController _joinRoleController = TextEditingController();
  String _selectedJoinDivision = 'IT & Engineering';
  JoinRequest? _submittedJoinRequest;

  @override
  void initState() {
    super.initState();
    _loginCompanyCodeController.text = 'CILALU-88';
    _loginEmailController.text = 'sarah.pratama@cilulataks.id';
    _loginPasswordController.text = 'password123';
  }

  @override
  void dispose() {
    _loginCompanyCodeController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regCompanyNameController.dispose();
    _regCompanyCodeController.dispose();
    _regAdminNameController.dispose();
    _regAdminEmailController.dispose();
    _regAdminPasswordController.dispose();
    _joinCompanyCodeController.dispose();
    _joinNameController.dispose();
    _joinEmailController.dispose();
    _joinPasswordController.dispose();
    _joinRoleController.dispose();
    super.dispose();
  }

  void _onRoleChanged(UserRole role) {
    setState(() {
      _selectedRole = role;
      if (role == UserRole.user) {
        _loginEmailController.text = 'kevin.maulana@cilulataks.id';
      } else {
        _loginEmailController.text = 'sarah.pratama@cilulataks.id';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final employees = state.employees;
    final currentCompany = state.currentCompany;

    // Check if submitted join request has been approved by admin
    if (_submittedJoinRequest != null) {
      final updated = state.joinRequests.firstWhere(
        (r) => r.id == _submittedJoinRequest!.id,
        orElse: () => _submittedJoinRequest!,
      );
      if (updated.status != _submittedJoinRequest!.status) {
        _submittedJoinRequest = updated;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Brand Logo & Header
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF4F46E5)],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'CILALUTASK',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Platform Manajemen Tugas Multi-Perusahaan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Auth Tabs Switcher: Masuk | Daftar PT | Gabung Tim
                  Container(
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _buildAuthTabItem(0, 'Masuk', Icons.login_rounded),
                        _buildAuthTabItem(
                          1,
                          'Daftar PT',
                          Icons.domain_add_rounded,
                        ),
                        _buildAuthTabItem(
                          2,
                          'Gabung Tim',
                          Icons.group_add_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Main Container Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _buildCurrentTabContent(
                        context,
                        state,
                        employees,
                        currentCompany,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthTabItem(int index, String label, IconData icon) {
    final isSelected = _activeAuthTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeAuthTab = index;
            if (index == 2) {
              _joinCompanyCodeController.text = '';
            }
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(
    BuildContext context,
    dynamic state,
    List<Assignee> employees,
    Company currentCompany,
  ) {
    switch (_activeAuthTab) {
      case 0:
        return _buildLoginTab(context, state, employees, currentCompany);
      case 1:
        return _buildRegisterCompanyTab(context, state);
      case 2:
        return _buildJoinTeamTab(context, state);
      default:
        return const SizedBox.shrink();
    }
  }

  // TAB 1: LOGIN SCREEN
  Widget _buildLoginTab(
    BuildContext context,
    dynamic state,
    List<Assignee> employees,
    Company currentCompany,
  ) {
    return Column(
      key: const ValueKey('tab-login'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Masuk',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Masukkan ID Perusahaan, email, dan password untuk melanjutkan.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 18),

        // Company ID Field
        const Text(
          'ID Perusahaan',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _loginCompanyCodeController,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          decoration: const InputDecoration(
            hintText: 'Contoh: CILALU-88',
            prefixIcon: Icon(
              Icons.corporate_fare_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Role Switcher (Admin vs Karyawan)
        const Text(
          'Masuk Sebagai',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _buildRoleButton(
                role: UserRole.admin,
                label: 'Admin (Manager)',
                icon: Icons.admin_panel_settings_rounded,
              ),
              _buildRoleButton(
                role: UserRole.user,
                label: 'User (Karyawan)',
                icon: Icons.person_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Email Field
        const Text(
          'Email',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Email',
            prefixIcon: Icon(
              Icons.email_outlined,
              size: 18,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Password Field
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _loginPasswordController,
          obscureText: _obscureLoginPassword,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLoginPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: AppColors.textMuted,
              ),
              onPressed: () => setState(
                () => _obscureLoginPassword = !_obscureLoginPassword,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    final companyCode = _loginCompanyCodeController.text
                        .trim()
                        .toUpperCase();
                    final email = _loginEmailController.text.trim();
                    final password = _loginPasswordController.text;

                    // --- Validasi input ---
                    if (companyCode.isEmpty ||
                        email.isEmpty ||
                        password.isEmpty) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'ID Perusahaan, Email, dan Password tidak boleh kosong.',
                          ),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    if (!email.contains('@') || !email.contains('.')) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Format email tidak valid. Masukkan email yang benar.',
                          ),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    if (password.length < 6) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password minimal 6 karakter.'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    setState(() => _isLoading = true);
                    try {
                      await state.loginWithCredentials(
                        companyCode: companyCode,
                        email: email,
                        password: password,
                        role: _selectedRole,
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      final message = AuthService.getReadableAuthError(e);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e is FirebaseAuthException
                                ? message
                                : e.toString().replaceAll('Exception: ', ''),
                          ),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _selectedRole == UserRole.admin
                        ? 'Masuk sebagai Admin'
                        : 'Masuk sebagai Karyawan',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 18),

        // Navigation below form (Belum punya akun saja)
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [
            const Text(
              'Belum punya akun? ',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            InkWell(
              onTap: () => setState(() => _activeAuthTab = 1),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Text(
                  'Daftar PT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const Text(
              '•',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            InkWell(
              onTap: () => setState(() {
                _activeAuthTab = 2;
                _joinCompanyCodeController.text = '';
              }),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Text(
                  'Gabung Tim',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // TAB 2: REGISTER NEW COMPANY (BLANK SLATE)
  Widget _buildRegisterCompanyTab(BuildContext context, dynamic state) {
    return Column(
      key: const ValueKey('tab-register'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_business_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daftar Perusahaan Baru',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Mulai dengan data Baru',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Company Name Field
        const Text(
          'Nama Perusahaan / Organisasi',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _regCompanyNameController,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Contoh: PT Nusantara Logistik',
            prefixIcon: Icon(
              Icons.business_outlined,
              size: 18,
              color: AppColors.textMuted,
            ),
          ),
          onChanged: (val) {
            // Auto generate code suggestion
            if (val.trim().isNotEmpty) {
              final words = val
                  .trim()
                  .split(' ')
                  .where((w) => w.length > 2)
                  .toList();
              final prefix = words.isNotEmpty
                  ? words.last.toUpperCase().replaceAll(
                      RegExp(r'[^A-Z0-9]'),
                      '',
                    )
                  : 'CORP';
              _regCompanyCodeController.text =
                  '$prefix-${DateTime.now().millisecond % 90 + 10}';
            }
          },
        ),
        const SizedBox(height: 12),

        // Company Unique ID / Code
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Kode Unik ID Perusahaan',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            Text(
              'Digunakan karyawan untuk join',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.primary.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _regCompanyCodeController,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
          decoration: const InputDecoration(
            hintText: 'Contoh: SINERGI-01',
            prefixIcon: Icon(
              Icons.qr_code_2_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Industry Dropdown
        const Text(
          'Bidang / Industri',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedIndustry,
              isExpanded: true,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Teknologi & Operasional',
                  child: Text('Teknologi & Operasional Cloud'),
                ),
                DropdownMenuItem(
                  value: 'Logistik & Pergudangan',
                  child: Text('Logistik, Distribusi & Pergudangan'),
                ),
                DropdownMenuItem(
                  value: 'Manufaktur & Pabrik',
                  child: Text('Manufaktur & Pabrik'),
                ),
                DropdownMenuItem(
                  value: 'Retail & E-Commerce',
                  child: Text('Retail & E-Commerce'),
                ),
                DropdownMenuItem(
                  value: 'Keuangan & Fintech',
                  child: Text('Keuangan & Fintech'),
                ),
                DropdownMenuItem(
                  value: 'Kreatif & Media Digital',
                  child: Text('Kreatif, Agensi & Media Digital'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedIndustry = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Admin Info Section
        const Text(
          'Nama Lengkap Admin Pengelola',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _regAdminNameController,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Nama Anda sebagai pemilik/admin',
            prefixIcon: Icon(
              Icons.person_outline,
              size: 18,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 12),

        const Text(
          'Email Admin & Kata Sandi',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _regAdminEmailController,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'admin@email.com',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _regAdminPasswordController,
                obscureText: true,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Kata Sandi',
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.cleaning_services_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Note : Sistem akan otomatis dimulai dalam kondisi Bersih (blank). Anda dapat menambahkan tugas, SOP, dan divisi secara manual.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    if (_regCompanyNameController.text.trim().isEmpty ||
                        _regCompanyCodeController.text.trim().isEmpty ||
                        _regAdminNameController.text.trim().isEmpty ||
                        _regAdminEmailController.text.trim().isEmpty ||
                        _regAdminPasswordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Mohon isi semua data perusahaan dan kata sandi admin.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    if (!_regAdminEmailController.text.trim().contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Format email admin tidak valid.'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    if (_regAdminPasswordController.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kata sandi minimal 6 karakter.'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    setState(() => _isLoading = true);
                    try {
                      await state.registerCompany(
                        name: _regCompanyNameController.text.trim(),
                        code: _regCompanyCodeController.text
                            .trim()
                            .toUpperCase(),
                        adminName: _regAdminNameController.text.trim(),
                        adminEmail: _regAdminEmailController.text.trim(),
                        adminPassword: _regAdminPasswordController.text,
                        industry: _selectedIndustry,
                      );

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Perusahaan ${_regCompanyNameController.text} berhasil dibuat!',
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      final message = AuthService.getReadableAuthError(e);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e is FirebaseAuthException
                                ? message
                                : e.toString().replaceAll('Exception: ', ''),
                          ),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.rocket_launch_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Buat Perusahaan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            const Text(
              'Sudah punya akun? ',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            InkWell(
              onTap: () => setState(() => _activeAuthTab = 0),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Text(
                  'Masuk',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // TAB 3: JOIN COMPANY AS EMPLOYEE
  Widget _buildJoinTeamTab(BuildContext context, dynamic state) {
    if (_submittedJoinRequest != null) {
      final req = _submittedJoinRequest!;
      final isApproved = req.status == JoinRequestStatus.approved;
      final isRejected = req.status == JoinRequestStatus.rejected;

      return Column(
        key: const ValueKey('tab-join-submitted'),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isApproved
                  ? AppColors.successLight
                  : isRejected
                  ? AppColors.errorLight
                  : Colors.amber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isApproved
                  ? Icons.check_circle_rounded
                  : isRejected
                  ? Icons.cancel_rounded
                  : Icons.hourglass_top_rounded,
              size: 48,
              color: isApproved
                  ? AppColors.success
                  : isRejected
                  ? AppColors.error
                  : Colors.amber.shade800,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            isApproved
                ? 'Permohonan Diterima!'
                : isRejected
                ? 'Permohonan Ditolak'
                : 'Menunggu Persetujuan Admin',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isApproved
                  ? AppColors.successDark
                  : isRejected
                  ? AppColors.errorDark
                  : Colors.amber.shade900,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            isApproved
                ? 'Admin telah menyetujui permohonan Anda untuk bergabung di ${req.companyName} (${req.companyCode}). Anda dapat langsung masuk!'
                : isRejected
                ? 'Permohonan bergabung Anda di ${req.companyName} belum dapat disetujui oleh admin saat ini.'
                : 'Permintaan atas nama ${req.userName} untuk bergabung di ${req.companyName} (${req.companyCode}) telah terkirim. Admin sedang meninjau data Anda.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Details Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildJoinSummaryRow('Kode Perusahaan', req.companyCode),
                const Divider(height: 14),
                _buildJoinSummaryRow('Nama Karyawan', req.userName),
                const Divider(height: 14),
                _buildJoinSummaryRow(
                  'Divisi & Role',
                  '${req.role} (${req.division})',
                ),
                const Divider(height: 14),
                _buildJoinSummaryRow(
                  'Status Saat Ini',
                  isApproved
                      ? 'DITERIMA (APPROVED)'
                      : isRejected
                      ? 'DITOLAK'
                      : 'MENUNGGU (PENDING)',
                  highlight: true,
                  color: isApproved
                      ? AppColors.success
                      : (isRejected ? AppColors.error : Colors.amber.shade800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (isApproved) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  final targetEmp = state.employees.firstWhere(
                    (e) => e.name == req.userName,
                    orElse: () => Assignee(
                      id: 'emp-new',
                      name: req.userName,
                      shortName: req.userName.split(' ').first,
                      avatar: req.avatar,
                      division: req.division,
                      role: req.role,
                      hasTeamBadge: true,
                      teamCount: 1,
                    ),
                  );
                  state.loginAsEmployee(targetEmp);
                },
                icon: const Icon(Icons.login_rounded, color: Colors.white),
                label: const Text(
                  'Masuk ke Dashboard Sekarang',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          OutlinedButton(
            onPressed: () {
              setState(() {
                _submittedJoinRequest = null;
                _activeAuthTab = 0;
              });
            },
            child: const Text('Kembali ke Halaman Masuk'),
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey('tab-join-form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gabung Perusahaan / Tim',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Masukkan ID Perusahaan dan tunggu verifikasi Admin',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Company ID input
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ID / Kode Perusahaan',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            Text(
              'Contoh: ${state.currentCompany.code}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _joinCompanyCodeController,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
          decoration: const InputDecoration(
            hintText: 'Masukkan ID Perusahaan (misal: CILALU-88)',
            prefixIcon: Icon(
              Icons.domain_verification_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Full Name
        const Text(
          'Nama Lengkap Karyawan',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _joinNameController,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Nama lengkap Anda',
            prefixIcon: Icon(
              Icons.badge_outlined,
              size: 18,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Division Dropdown
        const Text(
          'Divisi Kerja',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedJoinDivision,
              isExpanded: true,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'IT & Engineering',
                  child: Text('IT & Engineering'),
                ),
                DropdownMenuItem(
                  value: 'Operasional & Gudang',
                  child: Text('Operasional & Gudang'),
                ),
                DropdownMenuItem(
                  value: 'Pemasaran & Kreatif',
                  child: Text('Pemasaran & Kreatif'),
                ),
                DropdownMenuItem(
                  value: 'Finance & Akuntansi',
                  child: Text('Finance & Akuntansi'),
                ),
                DropdownMenuItem(
                  value: 'HR & Legal',
                  child: Text('HR & Legal'),
                ),
                DropdownMenuItem(
                  value: 'Operasional Lapangan',
                  child: Text('Operasional Lapangan'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedJoinDivision = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Role / Title
        const Text(
          'Jabatan / Posisi',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _joinRoleController,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Contoh: Frontend Engineer, Staff Gudang',
            prefixIcon: Icon(
              Icons.work_outline_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Email & Password
        const Text(
          'Email Akun & Kata Sandi',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _joinEmailController,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'email@anda.com',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _joinPasswordController,
                obscureText: true,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Kata Sandi',
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Submit Request Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    if (_joinCompanyCodeController.text.trim().isEmpty ||
                        _joinNameController.text.trim().isEmpty ||
                        _joinEmailController.text.trim().isEmpty ||
                        _joinPasswordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Mohon lengkapi ID Perusahaan, Nama, Email, dan Kata Sandi.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    if (!_joinEmailController.text.trim().contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Format email tidak valid.'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    setState(() => _isLoading = true);
                    try {
                      final req = await state.submitJoinRequest(
                        companyCode: _joinCompanyCodeController.text
                            .trim()
                            .toUpperCase(),
                        name: _joinNameController.text.trim(),
                        email: _joinEmailController.text.trim(),
                        password: _joinPasswordController.text,
                        division: _selectedJoinDivision,
                        role: _joinRoleController.text.trim(),
                      );

                      setState(() {
                        _submittedJoinRequest = req;
                      });

                      HapticFeedback.mediumImpact();
                    } catch (e) {
                      if (!context.mounted) return;
                      final message = AuthService.getReadableAuthError(e);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e is FirebaseAuthException
                                ? message
                                : e.toString().replaceAll('Exception: ', ''),
                          ),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Kirim Permohonan Bergabung',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            const Text(
              'Sudah punya akun? ',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            InkWell(
              onTap: () => setState(() => _activeAuthTab = 0),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Text(
                  'Masuk',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJoinSummaryRow(
    String label,
    String value, {
    bool highlight = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleButton({
    required UserRole role,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;

    return Expanded(
      child: InkWell(
        onTap: () => _onRoleChanged(role),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
