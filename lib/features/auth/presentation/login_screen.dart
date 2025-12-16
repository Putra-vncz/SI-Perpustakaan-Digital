import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../auth_provider.dart';

enum LoginMode { none, student, admin }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  LoginMode _loginMode = LoginMode.none;
  final _formKey = GlobalKey<FormState>();
  final _nimController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nimController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (!_formKey.currentState!.validate()) return;

    if (_loginMode == LoginMode.student) {
      ref.read(authProvider.notifier).loginStudent(
            _nimController.text.trim(),
            _passwordController.text,
          );
    } else {
      ref.read(authProvider.notifier).loginAdmin(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  void _backToSelection() {
    setState(() {
      _loginMode = LoginMode.none;
      _nimController.clear();
      _emailController.clear();
      _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }

      if (next.isLoggedIn) {
        if (next.isAdmin) {
          context.go('/admin');
        } else {
          context.go('/home');
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 60),
              _buildHeader(context),
              const SizedBox(height: 48),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _loginMode == LoginMode.none
                    ? _buildLoginSelection(authState)
                    : _buildLoginForm(authState),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(LucideIcons.library, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text(
          'University E-Library',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Your gateway to knowledge',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildLoginSelection(AuthState authState) {
    return Column(
      key: const ValueKey('selection'),
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: authState.isLoading
                ? null
                : () => setState(() => _loginMode = LoginMode.student),
            icon: const Icon(LucideIcons.graduationCap),
            label: const Text('Login as Student'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: authState.isLoading
                ? null
                : () => setState(() => _loginMode = LoginMode.admin),
            icon: const Icon(LucideIcons.shield),
            label: const Text('Login as Admin'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Belum punya akun?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.push('/register'),
          child: const Text('Daftar Sekarang'),
        ),
      ],
    );
  }


  Widget _buildLoginForm(AuthState authState) {
    final isStudent = _loginMode == LoginMode.student;

    return Column(
      key: ValueKey(_loginMode),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _backToSelection,
              icon: const Icon(LucideIcons.arrowLeft),
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              isStudent ? 'Login Mahasiswa' : 'Login Admin',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Role indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: (isStudent ? AppColors.secondary : AppColors.primary)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isStudent ? LucideIcons.graduationCap : LucideIcons.shield,
                color: isStudent ? AppColors.secondary : AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isStudent
                      ? 'Masuk dengan NIM dan Password'
                      : 'Masuk dengan Email dan Password',
                  style: TextStyle(
                    color: isStudent ? AppColors.secondary : AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Login Form
        Form(
          key: _formKey,
          child: Column(
            children: [
              // NIM field (student) or Email field (admin)
              if (isStudent)
                TextFormField(
                  controller: _nimController,
                  decoration: _inputDecoration(
                    label: 'NIM',
                    hint: 'Masukkan 9 digit NIM',
                    icon: LucideIcons.hash,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'NIM tidak boleh kosong';
                    }
                    if (value.length != 9) {
                      return 'NIM harus 9 digit';
                    }
                    return null;
                  },
                )
              else
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration(
                    label: 'Email',
                    hint: 'Masukkan email admin',
                    icon: LucideIcons.mail,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!value.contains('@')) {
                      return 'Email tidak valid';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),

              // Password field
              TextFormField(
                controller: _passwordController,
                decoration: _inputDecoration(
                  label: 'Password',
                  hint: 'Masukkan password',
                  icon: LucideIcons.lock,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? LucideIcons.eyeOff
                          : LucideIcons.eye,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submitLogin(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _submitLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isStudent ? AppColors.secondary : AppColors.primary,
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}
