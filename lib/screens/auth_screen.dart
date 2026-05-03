import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../widgets/modern_ui.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _creatingAccount = false;
  bool _submitting = false;
  bool _googleSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PurpleHero(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AutoHireLogo(size: 58),
                    const SizedBox(height: 18),
                    Text(
                      'AutoHire AI',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _creatingAccount ? 'Create account' : 'Welcome back',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Discover jobs, tailor resumes, and track every application.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ModernCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_creatingAccount) ...[
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person_outline),
                            labelText: 'Name',
                          ),
                          validator: (value) {
                            if (!_creatingAccount) return null;
                            if (value == null || value.trim().length < 2) {
                              return 'Enter your name.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.mail_outline),
                          labelText: 'Email',
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (!email.contains('@') || !email.contains('.')) {
                            return 'Enter a valid email.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline),
                          labelText: 'Password',
                        ),
                        validator: (value) {
                          if ((value ?? '').length < 6) {
                            return 'Use at least 6 characters.';
                          }
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _busy ? null : _submit,
                        icon: _submitting
                            ? const SizedBox.square(
                                dimension: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _creatingAccount
                                    ? Icons.person_add_alt
                                    : Icons.login,
                              ),
                        label: Text(
                          _creatingAccount ? 'Create account' : 'Sign in',
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _submitGoogle,
                        icon: _googleSubmitting
                            ? const SizedBox.square(
                                dimension: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.g_mobiledata),
                        label: const Text('Continue with Google'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () {
                                setState(() {
                                  _creatingAccount = !_creatingAccount;
                                  _error = null;
                                });
                              },
                        child: Text(
                          _creatingAccount
                              ? 'I already have an account'
                              : 'Create a new account',
                        ),
                      ),
                      TextButton(
                        onPressed: _busy ? null : _resetPassword,
                        child: const Text('Reset password'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _busy => _submitting || _googleSubmitting;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final state = context.read<AppState>();
      if (_creatingAccount) {
        await state.createAccount(
          email: _emailController.text,
          password: _passwordController.text,
          name: _nameController.text,
        );
      } else {
        await state.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } catch (error) {
      setState(() => _error = _cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter your email first.');
      return;
    }

    try {
      await context.read<AppState>().sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent')),
      );
    } catch (error) {
      setState(() => _error = _cleanError(error));
    }
  }

  Future<void> _submitGoogle() async {
    setState(() {
      _googleSubmitting = true;
      _error = null;
    });

    try {
      await context.read<AppState>().signInWithGoogle();
    } catch (error) {
      setState(() => _error = _cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _googleSubmitting = false);
      }
    }
  }

  String _cleanError(Object error) {
    final message = error.toString();
    return message.replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
  }
}
