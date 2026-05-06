import 'package:flutter/material.dart';

class CoachPendingView extends StatelessWidget {
  const CoachPendingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.hourglass_top,
                size: 80,
                color: Colors.orange,
              ),
              SizedBox(height: 24),
              Text(
                "Approval Pending",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Your credentials are under review.\nPlease wait until admin approves your account.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}