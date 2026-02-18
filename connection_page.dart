import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lg_final_app/services/lg_service.dart';
import 'package:lg_final_app/main.dart'; // For MainLayout

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key});

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  bool _hasError = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    // Trigger connection immediately upon mounting this page
    _connect();
  }

  Future<void> _connect() async {
    if (_isConnecting) return;
    
    setState(() {
      _hasError = false;
      _isConnecting = true;
    });

    final lgService = Provider.of<LGService>(context, listen: false);
    
    // Attempt the '180-line' Master Connect logic
    bool success = await lgService.connect();
    
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainLayout()), 
      );
    } else {
      setState(() {
        _hasError = true;
        _isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.public, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 40),
            
            if (!_hasError) ...[
               const CircularProgressIndicator(color: Colors.red),
               const SizedBox(height: 20),
               const Text(
                 "ESTABLISHING SECURE UPLINK...",
                 style: TextStyle(
                   color: Colors.white, 
                   letterSpacing: 3, 
                   fontFamily: 'Courier', 
                   fontWeight: FontWeight.bold
                 ),
               ),
               const SizedBox(height: 10),
               Consumer<LGService>(
                 builder: (context, lg, _) => Text(
                   lg.statusMessage.value,
                   style: const TextStyle(color: Colors.grey, fontSize: 12),
                 ),
               ),
            ] else ...[
               const Icon(Icons.error_outline, color: Colors.red, size: 50),
               const SizedBox(height: 20),
               const Text(
                 "CONNECTION FAILED",
                 style: TextStyle(color: Colors.red, letterSpacing: 3, fontWeight: FontWeight.bold),
               ),
               const SizedBox(height: 10),
               Consumer<LGService>(
                 builder: (context, lg, _) => Text(
                   lg.statusMessage.value,
                   textAlign: TextAlign.center,
                   style: const TextStyle(color: Colors.grey, fontSize: 12),
                 ),
               ),
               const SizedBox(height: 30),
               ElevatedButton(
                 onPressed: _isConnecting ? null : _connect,
                 style: ElevatedButton.styleFrom(backgroundColor: Colors.white24),
                 child: const Text("RETRY UPLINK"),
               ),
               TextButton(
                 onPressed: () {
                    // Force navigation even if SSH fails
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MainLayout()), 
                    );
                 },
                 child: const Text("ENTER OFFLINE MODE", style: TextStyle(color: Colors.white30, fontSize: 10)),
               )
            ]
          ],
        ),
      ),
    );
  }
}