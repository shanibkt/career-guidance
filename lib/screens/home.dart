import 'package:flutter/material.dart';

import '../models/user.dart';

class HomeScreen extends StatelessWidget {
  final User? user;

  const HomeScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final displayName = user?.fullName ?? user?.username ?? 'User';
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(child: Text('Welcome, $displayName!')),
    );
  }
}
