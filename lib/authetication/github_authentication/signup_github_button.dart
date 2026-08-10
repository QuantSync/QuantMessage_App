import 'package:flutter/material.dart';
import '../../screens/animations/animated_buttons/github_button.dart';

class SignupGithubButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SignupGithubButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GithubButton.dark(
      label: 'Sign Up with GitHub',
      onPressed: onPressed,
      height: 56,
      borderRadius: 16,
    );
  }
}
