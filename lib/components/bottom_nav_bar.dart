import 'package:flutter/material.dart';
import 'package:timely/screens/add_notebook.dart';
import 'package:timely/screens/profile_page.dart';
import 'package:timely/screens/reminders_page.dart';
import 'package:timely/screens/todo_page.dart';
//import 'package:timely/screens/todo_page.dart';
import '../screens/home_page.dart';
import '../screens/shared_and_public_page.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const HomePage(),
    const TodoPage(),
    const RemindersPage(),
    const SharedAndPublicPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex =
        widget.currentIndex; // Initialize with the widget's currentIndex
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme
          .of(context)
          .colorScheme
          .inverseSurface,
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inverseSurface,
        currentIndex: _currentIndex,
        selectedItemColor: Theme
            .of(context)
            .colorScheme
            .tertiary,
        selectedFontSize: 15,
        // unselectedFontSize: 20,
        selectedIconTheme: IconThemeData(
          color: Theme
              .of(context)
              .colorScheme
              .primary,
          size: 32,
        ),
        unselectedItemColor: Colors.grey.shade600,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home', backgroundColor: Theme.of(context).colorScheme.inverseSurface),
          BottomNavigationBarItem(icon: Icon(Icons.task_alt_sharp), label: 'Todos', backgroundColor: Theme.of(context).colorScheme.inverseSurface),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Reminders',
            backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.share),
            label: 'Shared',
            backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
            backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          ),
        ],
      ),
    );
  }
}
