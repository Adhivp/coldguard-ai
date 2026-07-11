import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:code_card_ai/core/utils/validators.dart';
import 'package:code_card_ai/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:code_card_ai/features/auth/presentation/bloc/auth_event.dart';
import 'package:code_card_ai/features/auth/presentation/bloc/auth_state.dart';
import 'package:code_card_ai/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:code_card_ai/shared_widgets/custom_button.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            controller: _emailController,
            labelText: 'Email Address',
            hintText: 'Enter your email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            validator: Validators.validatePassword,
          ),
          const SizedBox(height: 32),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return CustomButton(
                text: 'Login',
                isLoading: state is AuthLoading,
                onPressed: _submit,
              );
            },
          ),
        ],
      ),
    );
  }
}
