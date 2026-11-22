import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/form_validators.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import 'register_page.dart';

/// Màn hình đăng nhập email + mật khẩu.
///
/// Chỉ là giao diện tối thiểu để luồng #2 chạy được; phần trình bày/thiết kế
/// sẽ được thay khi issue #4 (UI/UX nền tảng) hoàn thành. Không có logic
/// nghiệp vụ ở đây — mọi thứ đi qua [AuthCubit].
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    await context.read<AuthCubit>().signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (BuildContext context, AuthState state) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'SmartNote',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Đăng nhập để đồng bộ ghi chú của bạn',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const <String>[AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: FormValidators.email,
                          onChanged: (_) =>
                              context.read<AuthCubit>().clearError(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const <String>[AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              tooltip: _obscurePassword
                                  ? 'Hiện mật khẩu'
                                  : 'Ẩn mật khẩu',
                            ),
                          ),
                          validator: FormValidators.password,
                          onFieldSubmitted: (_) => _submit(),
                          onChanged: (_) =>
                              context.read<AuthCubit>().clearError(),
                        ),
                        if (state.errorMessage != null) ...<Widget>[
                          const SizedBox(height: 16),
                          Text(
                            state.errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: state.isSubmitting ? null : _submit,
                          child: state.isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Đăng nhập'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: state.isSubmitting
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const RegisterPage(),
                                  ),
                                ),
                          child: const Text('Chưa có tài khoản? Đăng ký'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
