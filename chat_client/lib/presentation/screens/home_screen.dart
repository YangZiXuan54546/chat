import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/chat_provider.dart';
import '../../data/providers/contacts_provider.dart';
import '../widgets/common/bottom_nav_bar.dart';
import 'chat/chat_list_screen.dart';
import 'contacts/contacts_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    ChatListScreen(),
    ContactsScreen(),
    SizedBox(), // Placeholder for calls
    SizedBox(), // Placeholder for settings
  ];

  @override
  void initState() {
    super.initState();
    // Load initial data
    Future.microtask(() {
      ref.read(authProvider.notifier).checkAuthStatus();
      ref.read(chatListProvider.notifier).loadChats();
      ref.read(contactsProvider.notifier).loadFriends();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState.status == AuthStatus.loading || authState.status == AuthStatus.initial) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authState.status == AuthStatus.unauthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            // Settings
            context.push('/settings');
          } else if (index == 3) {
            // Settings
            context.push('/settings');
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }
}
