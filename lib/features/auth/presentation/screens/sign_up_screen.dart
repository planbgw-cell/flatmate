import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../location/domain/models/location_item.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../../location/presentation/widgets/gps_feedback.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import 'login_screen.dart';

/// Two-step onboarding: ① account ② 내 동네 (GPS or map) → signup with
/// `location_id` → auto login.
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
  static const _stepCount = 2;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nicknameController = TextEditingController();

  int _step = 0;
  LocationItem? _location;
  bool _locating = false;
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

  void _next() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = 1);
  }

  Future<void> _findByGps() async {
    setState(() => _locating = true);
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(locationServiceProvider);
    try {
      final result = await resolveLocationFromGps(ref);
      if (!mounted) return;
      final location = result.location;
      if (location == null) {
        messenger.showSnackBar(gpsFailureSnackBar(result.status, service));
        return;
      }
      setState(() => _location = location);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException ? e.message : '내 위치로 동네를 찾지 못했어요.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickOnMap() async {
    final picked =
        await context.push<LocationItem>(RouteNames.locationMapPickerResult);
    if (picked != null && mounted) setState(() => _location = picked);
  }

  Future<void> _submit() async {
    final location = _location;
    if (_submitting || location == null) return;
    setState(() => _submitting = true);
    try {
      final user = await ref.read(authProvider.notifier).signup(
            email: _emailController.text,
            password: _passwordController.text,
            nickname: _nicknameController.text,
            location: location,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '가입 완료! ${user.nickname}님, ${location.dongName} 이웃이 되었어요.',
          ),
        ),
      );
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go(widget.redirectTo ?? RouteNames.home);
      }
    } catch (e) {
      if (!mounted) return;
      // Account problems (e.g. duplicate email) are fixed on step 1.
      if (e is ApiException && e.statusCode == 409) setState(() => _step = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step = 0);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step = 0);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: _step > 0 || context.canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _back,
                )
              : null,
          title: Text('회원가입', style: AppTypography.header2),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Text(
                  '${_step + 1}/$_stepCount',
                  style: AppTypography.bodyMedium,
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: LinearProgressIndicator(
              value: (_step + 1) / _stepCount,
              minHeight: 3,
              color: AppColors.primary,
              backgroundColor: AppColors.border,
            ),
          ),
        ),
        body: SafeArea(
          child: IndexedStack(
            index: _step,
            children: [
              _buildAccountStep(),
              _buildLocationStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountStep() {
    return Form(
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
              onSubmitted: (_) => _next(),
            ),
            const SizedBox(height: AppSpacing.xl),
            _PrimaryButton(label: '다음', onPressed: _next),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStep() {
    final location = _location;
    final busy = _locating || _submitting;
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      children: [
        Text('우리 동네를 설정해 주세요', style: AppTypography.header1),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '내 동네를 인증하면 가까운 이웃의 자취·알바·생활 정보를 바로 볼 수 있어요.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (location != null) ...[
          _SelectedDongCard(location: location),
          const SizedBox(height: AppSpacing.lg),
        ],
        _OutlineAction(
          icon: Icons.my_location,
          label: _locating ? '위치 확인 중…' : '현재 위치로 동네 찾기',
          loading: _locating,
          onPressed: busy ? null : _findByGps,
        ),
        const SizedBox(height: AppSpacing.sm),
        _OutlineAction(
          icon: Icons.map_outlined,
          label: '지도에서 동네 선택',
          onPressed: busy ? null : _pickOnMap,
        ),
        const SizedBox(height: AppSpacing.xl),
        _PrimaryButton(
          label: '가입 완료',
          loading: _submitting,
          onPressed: location == null || busy ? null : _submit,
        ),
      ],
    );
  }
}

class _SelectedDongCard extends StatelessWidget {
  const _SelectedDongCard({required this.location});

  final LocationItem location;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('선택한 동네', style: AppTypography.caption),
                const SizedBox(height: 2),
                Text(
                  location.fullName,
                  key: const ValueKey('signup-selected-dong'),
                  style: AppTypography.titleMedium,
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 20),
        label: Text(label, style: AppTypography.titleMedium),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
      ),
    );
  }
}
