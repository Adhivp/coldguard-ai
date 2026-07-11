import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:code_card_ai/core/routes/route_names.dart';
import 'package:code_card_ai/core/theme/app_text_styles.dart';
import 'package:code_card_ai/core/utils/extensions.dart';
import 'package:code_card_ai/core/utils/validators.dart';
import 'package:code_card_ai/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:code_card_ai/features/auth/presentation/bloc/auth_event.dart';
import 'package:code_card_ai/features/auth/presentation/bloc/auth_state.dart';
import 'package:code_card_ai/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:code_card_ai/shared_widgets/custom_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        context.showSnackBar('Passwords do not match', isError: true);
        return;
      }
      context.read<AuthBloc>().add(
            AuthRegisterRequested(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            context.showSnackBar(state.message, isError: true);
          } else if (state is AuthSuccess) {
            context.showSnackBar('Welcome, ${state.user.name}!');
            context.goNamed(RouteNames.homeName);
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Account',
                    style: AppTextStyles.heading1.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join us to manage your cards intelligently',
                    style: AppTextStyles.subtitle.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomTextField(
                              controller: _nameController,
                              labelText: 'Full Name',
                              hintText: 'Enter your full name',
                              prefixIcon: Icons.person_outline_rounded,
                              validator: (val) => Validators.validateRequired(val, 'Name'),
                            ),
                            const SizedBox(height: 18),
                            CustomTextField(
                              controller: _emailController,
                              labelText: 'Email Address',
                              hintText: 'Enter your email',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.validateEmail,
                            ),
                            const SizedBox(height: 18),
                            CustomTextField(
                              controller: _passwordController,
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: Icons.lock_outline_rounded,
                              isPassword: true,
                              validator: Validators.validatePassword,
                            ),
                            const SizedBox(height: 18),
                            CustomTextField(
                              controller: _confirmPasswordController,
                              labelText: 'Confirm Password',
                              hintText: 'Re-enter your password',
                              prefixIcon: Icons.lock_clock_outlined,
                              isPassword: true,
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                return CustomButton(
                                  text: 'Sign Up',
                                  isLoading: state is AuthLoading,
                                  onPressed: _submit,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: AppTextStyles.bodyFormat.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: Text(
                          'Login',
                          style: AppTextStyles.bodyFormat.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
