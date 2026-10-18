import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import 'login_screen.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key, this.redirectTo});

  final String? redirectTo;

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  static const _minPasswordLength = 8;
  static const _nicknameMin = 2;
  static const _nicknameMax = 50;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return '비밀번호를 입력해 주세요.';
    if (v.length < _minPasswordLength) {
      return '비밀번호는 $_minPasswordLength자 이상이어야 합니다.';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if ((value ?? '').isEmpty) return '비밀번호를 한 번 더 입력해 주세요.';
    if (value != _passwordController.text) return '비밀번호가 일치하지 않습니다.';
    return null;
  }

  String? _validateNickname(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < _nicknameMin) return '닉네임은 $_nicknameMin자 이상 입력해 주세요.';
    if (v.length > _nicknameMax) return '닉네임은 $_nicknameMax자 이하로 입력해 주세요.';
    return null;
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      final user = await ref.read(authProvider.notifier).signup(
            email: _emailController.text,
            password: _passwordController.text,
            nickname: _nicknameController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('가입 완료! ${user.nickname}님, 환영해요.')),
      );
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go(widget.redirectTo ?? RouteNames.home);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('회원가입', style: AppTypography.header2),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              children: [
                Text(
                  '이웃과 만나기 위해\n간단한 정보를 입력해 주세요.',
                  style: AppTypography.header1,
                ),
                const SizedBox(height: AppSpacing.xl),
                AuthTextField(
                  controller: _emailController,
                  label: '이메일',
                  hint: 'example@flatmate.app',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: validateEmail,
                ),
                const SizedBox(height: AppSpacing.md),
                AuthTextField(
                  controller: _passwordController,
                  label: '비밀번호',
                  hint: '$_minPasswordLength자 이상',
                  obscure: true,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: _validatePassword,
                ),
                const SizedBox(height: AppSpacing.md),
                AuthTextField(
                  controller: _confirmController,
                  label: '비밀번호 확인',
                  hint: '비밀번호 재입력',
                  obscure: true,
                  validator: _validateConfirm,
                ),
                const SizedBox(height: AppSpacing.md),
                AuthTextField(
                  controller: _nicknameController,
                  label: '닉네임',
                  hint: '동네에서 보일 이름 ($_nicknameMin~$_nicknameMax자)',
                  autofillHints: const [AutofillHints.nickname],
                  textInputAction: TextInputAction.done,
                  validator: _validateNickname,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            '가입하고 시작하기',
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
