import 'package:flutter/material.dart';
import '../../screens/animations/animated_buttons/github_button.dart';

class SigninGithubButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SigninGithubButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GithubButton.dark(
      label: 'Sign In with GitHub',
      onPressed: onPressed,
      height: 56,
      borderRadius: 16,
    );
  }
}
