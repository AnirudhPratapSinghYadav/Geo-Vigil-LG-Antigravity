import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lg_final_app/services/lg_service.dart';
import 'package:lg_final_app/main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = false;

  final _ipController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _sshPortController = TextEditingController();
  final _rigsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('ipAddress') ?? '';
      _usernameController.text = prefs.getString('username') ?? 'lg';
      _passwordController.text = prefs.getString('password') ?? 'lg';
      _sshPortController.text = prefs.getString('sshPort') ?? '22';
      _rigsController.text = prefs.getString('numberOfRigs') ?? '3';
    });
  }

  Future<void> _saveAndConnect() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ipAddress', _ipController.text);
    await prefs.setString('username', _usernameController.text);
    await prefs.setString('password', _passwordController.text);
    await prefs.setString('sshPort', _sshPortController.text);
    await prefs.setString('numberOfRigs', _rigsController.text);

    final lgService = Provider.of<LGService>(context, listen: false);
    await lgService.connect();
    
    setState(() => _isLoading = false);
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Geo-Vigil Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Lead: Anirudh Pratap Singh Yadav", style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 10),
            Text("Official Submission for Gemini Summer of Code 2026 by Liquid Galaxy."),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lgService = Provider.of<LGService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showAboutDialog,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Monitor
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: lgService.isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: lgService.isConnected ? Colors.green : Colors.red),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, size: 12, color: lgService.isConnected ? Colors.green : Colors.red),
                      const SizedBox(width: 10),
                      Text(
                        lgService.isConnected ? "CLUSTER ONLINE" : "CLUSTER DISCONNECTED",
                        style: TextStyle(color: lgService.isConnected ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    lgService.statusMessage.value,
                    style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'monospace'),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            _buildTextField(_ipController, 'IP Address', Icons.wifi),
            _buildTextField(_usernameController, 'Username', Icons.person),
            _buildTextField(_passwordController, 'Password', Icons.lock, obscure: true),
            _buildTextField(_sshPortController, 'SSH Port', Icons.settings_ethernet, keyboard: TextInputType.number),
            _buildTextField(_rigsController, 'No. of Rigs', Icons.monitor, keyboard: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveAndConnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.cast_connected),
              label: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text('SAVE & UPLINK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 35),
            const Divider(),
            const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text("CRITICAL SYSTEM CONTROLS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.blueGrey)))),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 2.2,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSysBtn("REBOOT RIG", Colors.orange[800]!, Icons.restart_alt, () {
                  lgService.rebootLG();
                  _showSnack("Reboot command sent to cluster");
                }),
                _buildSysBtn("RELAUNCH", Colors.blue[800]!, Icons.refresh, () {
                  lgService.relaunchLG();
                  _showSnack("Relaunching Google Earth...");
                }),
                _buildSysBtn("SHUTDOWN", Colors.red[900]!, Icons.power_settings_new, () {
                  lgService.shutdownLG();
                  _showSnack("Shutdown command sent to cluster");
                }),
                _buildSysBtn("CLEAN KML", Colors.purple[800]!, Icons.delete_forever, () {
                  lgService.clearAll();
                  _showSnack("KML and Logo cache cleared");
                }),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false, TextInputType? keyboard}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          filled: true,
          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildSysBtn(String title, Color color, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      icon: Icon(icon, size: 20),
      label: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}