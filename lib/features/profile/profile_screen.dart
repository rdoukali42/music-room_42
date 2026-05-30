import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.people_outlined),
            title: const Text('Friends'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/friends'),
          ),
        ],
      ),
    );
  }
}
