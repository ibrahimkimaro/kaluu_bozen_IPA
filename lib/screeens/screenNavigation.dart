import 'package:flutter/material.dart';
import 'package:shippng_management_app/screeens/homePage.dart';
import 'package:shippng_management_app/screeens/message.dart';
import 'package:shippng_management_app/screeens/useraccount.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class HomeScreeenNav extends StatefulWidget {
  const HomeScreeenNav({super.key});

  @override
  State<HomeScreeenNav> createState() => _HomepageState();
}

class _HomepageState extends State<HomeScreeenNav> {
  int _selectedIndex = 0;
  final _BottmTabColor = const Color.fromARGB(255, 130, 149, 190);
  static const List<Widget> _pages = <Widget>[
    HomePage(),
    // MessagesPage(),
    UserAccountPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Important for the "hanging" transparent effect
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
          child: GNav(
            gap: 8,
            activeColor: Colors.white,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: _BottmTabColor,
            color: Colors.black,
            tabs: const [
              GButton(icon: Icons.home, text: 'Home'),
              // GButton(icon: Icons.message_rounded, text: 'Messages'),
              GButton(icon: Icons.person, text: 'Profile'),
            ],
            selectedIndex: _selectedIndex,
            onTabChange: _onItemTapped,
          ),
        ),
      ),
    );
  }
}
