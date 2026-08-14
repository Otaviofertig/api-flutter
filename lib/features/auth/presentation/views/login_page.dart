import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/send_password_reset.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_up_with_email.dart';
import '../controllers/login_controller.dart';
import '../widgets/animated_brand_mark.dart';

/// Tela de login e cadastro.
///
/// Não navega ao autenticar: quem reage à sessão é o `AuthGate`, observando
/// o `AuthController`. Assim o login por qualquer via (e-mail, Google, sessão
/// restaurada) leva ao mesmo caminho.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final LoginController _controller = LoginController(
    sl<SignInWithEmail>(),
    sl<SignUpWithEmail>(),
    sl<SignInWithGoogle>(),
    sl<SendPasswordReset>(),
  );

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    final AppUser? user = await _controller.submit();

    if (!mounted || user == null) return;
    _showMessage('Bem-vindo(a), ${user.label}!');
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    await _controller.signInWithGoogle();
  }

  Future<void> _resetPassword() async {
    final String message = await _controller.sendPasswordReset();
    if (!mounted || message.isEmpty) return;
    _showMessage(message);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double padding = Responsive.horizontalPadding(constraints.maxWidth);

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: AppSpacing.xxl,
                ),
                child: ConstrainedBox(
                  // Em tablets/desktop o formulário não estica: fica legível.
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (BuildContext context, Widget? _) => _LoginForm(
                      formKey: _formKey,
                      controller: _controller,
                      onSubmit: _submit,
                      onGoogle: _signInWithGoogle,
                      onResetPassword: _resetPassword,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.controller,
    required this.onSubmit,
    required this.onGoogle,
    required this.onResetPassword,
  });

  final GlobalKey<FormState> formKey;
  final LoginController controller;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;
  final VoidCallback onResetPassword;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool busy = controller.isSubmitting;
    final AuthMode mode = controller.mode;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const AnimatedBrandMark(),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            mode.title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            mode.isSignUp
                ? 'Crie sua conta para levar a estante para qualquer dispositivo.'
                : 'Entre para acessar a sua estante.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xl),

          // AnimatedSize evita o "salto" ao alternar login/cadastro.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: mode.isSignUp
                ? Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: TextFormField(
                      enabled: !busy,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const <String>[AutofillHints.name],
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: controller.validateName,
                      onChanged: controller.onNameChanged,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          TextFormField(
            enabled: !busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const <String>[AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            validator: controller.validateEmail,
            onChanged: controller.onEmailChanged,
          ),
          const SizedBox(height: AppSpacing.lg),

          TextFormField(
            enabled: !busy,
            obscureText: controller.obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                tooltip: controller.obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: controller.toggleObscurePassword,
              ),
            ),
            validator: controller.validatePassword,
            onChanged: controller.onPasswordChanged,
            onFieldSubmitted: (_) => onSubmit(),
          ),

          if (!mode.isSignUp)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: busy ? null : onResetPassword,
                child: const Text('Esqueci minha senha'),
              ),
            ),

          if (controller.errorMessage != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            _ErrorBanner(message: controller.errorMessage!),
          ],

          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: busy ? null : onSubmit,
            child: busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text(mode.submitLabel),
          ),
          const SizedBox(height: AppSpacing.lg),

          const _OrDivider(),
          const SizedBox(height: AppSpacing.lg),

          OutlinedButton.icon(
            onPressed: busy ? null : onGoogle,
            icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
            label: const Text('Continuar com Google'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              shape: const StadiumBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          TextButton(
            onPressed: busy ? null : controller.toggleMode,
            child: Text(mode.switchPrompt),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline_rounded, size: 20, color: scheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'ou',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
