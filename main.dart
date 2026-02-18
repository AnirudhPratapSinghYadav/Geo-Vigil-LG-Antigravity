import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lg_final_app/screens/home_screen.dart';
import 'package:lg_final_app/screens/settings_page.dart';
import 'package:lg_final_app/screens/splash_screen.dart'; 
import 'package:lg_final_app/services/lg_service.dart';

// Global theme notifier for light/dark mode switching
ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LGService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Liquid Galaxy Earth-Vigil',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          // Signature Competition Theme: Red and Dark Grey
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.black,
            primaryColor: Colors.red,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              elevation: 0,
            ),
            colorScheme: const ColorScheme.dark(
              primary: Colors.red,
              secondary: Colors.redAccent,
              surface: Color(0xFF1E1E1E),
            ),
          ),
          theme: ThemeData.light().copyWith(
            primaryColor: Colors.red,
            colorScheme: const ColorScheme.light(
              primary: Colors.red,
              secondary: Colors.redAccent,
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  
  // Pages for the navigation bar
  final List<Widget> _pages = [
    const HomeScreen(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.black,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.public), 
            label: 'Mission Control'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings), 
            label: 'Settings'
          ),
        ],
      ),
    );
  }
}