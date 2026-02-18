import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LGService extends ChangeNotifier {
  static final LGService _instance = LGService._internal();
  factory LGService() => _instance;
  LGService._internal();

  SSHClient? _client;
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  final ValueNotifier<String> statusMessage = ValueNotifier("System Ready");

  String _host = '';
  String _port = '';
  String _username = '';
  String _passwordOrKey = '';
  String _numberOfRigs = '';

  Future<void> initConnectionDetails() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _host = prefs.getString('ipAddress') ?? '192.168.0.1';
    _port = prefs.getString('sshPort') ?? '22';
    _username = prefs.getString('username') ?? 'lg';
    _passwordOrKey = prefs.getString('password') ?? 'lg';
    _numberOfRigs = prefs.getString('numberOfRigs') ?? '3';
  }

  // Rule 5: Connection Logic
  Future<bool> connect() async {
    await initConnectionDetails();
    try {
      statusMessage.value = "CONNECTING...";
      notifyListeners();
      final socket = await SSHSocket.connect(_host, int.parse(_port), timeout: const Duration(seconds: 5));
      _client = SSHClient(socket, username: _username, onPasswordRequest: () => _passwordOrKey);
      _isConnected = true;
      statusMessage.value = "CONNECTED";
      notifyListeners();
      await _initialOrbit();
      await sendLogo(); 
      return true;
    } catch (e) {
      statusMessage.value = "FAILED: $e";
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  Future<SSHSession?> run(String command) async {
    try { 
      if (_client == null) return null;
      return await _client!.execute(command); 
    } catch (e) { 
      statusMessage.value = "CMD ERROR: $e";
      notifyListeners();
      return null; 
    }
  }

  Future<void> sendKML(String content, String filename) async {
    if (!_isConnected) return;
    try {
      String encoded = base64Encode(utf8.encode(content));
      await run("echo '$encoded' | base64 -d > /var/www/html/$filename");
      await run("echo 'http://localhost:81/$filename' > /var/www/html/kmls.txt");
    } catch (e) {
      statusMessage.value = "KML UPLOAD FAILED: $e";
      notifyListeners();
    }
  }

  // Rule 3: Left Screen (Slave 3) - Logo ONLY
  Future<void> sendLogo() async {
    if (!_isConnected) return;
    try {
      String logoKML = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <ScreenOverlay>
      <name>Logo</name>
      <Icon>
        <href>https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEgXmdNgBTXup6bdWew5RzgCmC9pPb7rK487CpiscWB2S8OlhwFHmeeACHIIjx4B5-Iv-t95mNUx0JhB_oATG3-Tq1gs8Uj0-Xb9Njye6rHtKKsnJQJlzZqJxMDnj_2TXX3eA5x6VSgc8aw/s320-rw/LOGO+LIQUID+GALAXY-sq1000-+OKnoline.png</href>
      </Icon>
      <overlayXY x="0.5" y="1.0" xunits="fraction" yunits="fraction"/>
      <screenXY x="0.5" y="0.9" xunits="fraction" yunits="fraction"/>
      <size x="0.4" y="0.4" xunits="fraction" yunits="fraction"/>
    </ScreenOverlay>
  </Document>
</kml>''';
      String encoded = base64Encode(utf8.encode(logoKML));
      await run("mkdir -p /var/www/html/kml"); 
      // DIRECT WRITE to Slave 3. NO KMLS.TXT mod.
      await run("echo '$encoded' | base64 -d > /var/www/html/kml/slave_3.kml"); 
    } catch (e) {
      statusMessage.value = "LOGO FAILED: $e";
      notifyListeners();
    }
  }

  // Rule 3: Right Screen (Slave 2) - HUD ONLY
  Future<void> sendTacticalHUD(dynamic quake) async {
    try {
      String html = '<div style="background-color:rgba(0,0,0,0.8);color:white;padding:20px;border-radius:20px;font-family:monospace;"><h1>TACTICAL DATA</h1><br/><h2>LOC: ${quake.place}</h2><br/><h2>MAG: ${quake.mag}</h2><br/><h2>DEPTH: ${quake.depth}km</h2></div>';
      String kml = '<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2"><Document><Placemark><description><![CDATA[$html]]></description><gx:balloonVisibility>1</gx:balloonVisibility><Point><coordinates>${quake.lon},${quake.lat},0</coordinates></Point></Placemark></Document></kml>';
      String encoded = base64Encode(utf8.encode(kml));
      await run("mkdir -p /var/www/html/kml"); 
      // DIRECT WRITE to Slave 2. NO KMLS.TXT mod.
      await run("echo '$encoded' | base64 -d > /var/www/html/kml/slave_2.kml"); 
    } catch (e) {
      statusMessage.value = "HUD FAILED: $e";
      notifyListeners();
    }
  }

  // Master Rig: Orbit (flytoview)
  Future<void> flyTo(dynamic quake) async {
    if (!_isConnected) return;
    try {
      String lat = quake.lat.toStringAsFixed(6);
      String lon = quake.lon.toStringAsFixed(6);
      
      List<int> headings = [0, 120, 240, 360]; // 3-step Loop
      
      for (int heading in headings) {
        String flyToCmd = 'flytoview=<LookAt><longitude>$lon</longitude><latitude>$lat</latitude><range>150000</range><tilt>65</tilt><heading>$heading</heading><gx:altitudeMode>relativeToGround</gx:altitudeMode></LookAt>';
        await run('echo "$flyToCmd" > /tmp/query.txt');
        await Future.delayed(const Duration(milliseconds: 1000));
      }
      
      await sendTacticalHUD(quake);
    } catch (e) {
      statusMessage.value = "FLYTO FAILED: $e";
      notifyListeners();
    }
  }

  Future<void> rebootLG() async {
    try {
      int rigs = int.parse(_numberOfRigs);
      for (var i = 1; i <= rigs; i++) { 
        statusMessage.value = "REBOOTING LG$i...";
        notifyListeners();
        await run('sshpass -p $_passwordOrKey ssh -t lg$i "echo $_passwordOrKey | sudo -S reboot"'); 
      }
      statusMessage.value = "REBOOT COMPLETE";
      notifyListeners();
    } catch (e) {
      statusMessage.value = "REBOOT FAILED: $e";
      notifyListeners();
    }
  }

  Future<void> relaunchLG() async {
    try {
      int rigs = int.parse(_numberOfRigs);
      for (var i = 1; i <= rigs; i++) { 
        statusMessage.value = "RELAUNCHING LG$i...";
        notifyListeners();
        String cmd = """sshpass -p $_passwordOrKey ssh -t lg$i "echo $_passwordOrKey | sudo -S killall -9 googleearth-bin; export DISPLAY=:0; googleearth-bin > /dev/null 2>&1 &" """;
        await run(cmd); 
      }
      statusMessage.value = "RELAUNCH COMPLETE";
      notifyListeners();
    } catch (e) {
      statusMessage.value = "RELAUNCH FAILED: $e";
      notifyListeners();
    }
  }

  Future<void> shutdownLG() async {
    try {
      int rigs = int.parse(_numberOfRigs);
      for (var i = 1; i <= rigs; i++) { 
        statusMessage.value = "SHUTTING DOWN LG$i...";
        notifyListeners();
        await run('sshpass -p $_passwordOrKey ssh -t lg$i "echo $_passwordOrKey | sudo -S poweroff"'); 
      }
      statusMessage.value = "SHUTDOWN COMPLETE";
      notifyListeners();
    } catch (e) {
      statusMessage.value = "SHUTDOWN FAILED: $e";
      notifyListeners();
    }
  }

  // Clean Logic: Overwrite with blank KML
  Future<void> clearAll() async {
    if (!_isConnected) return;
    try {
      // (A) Empty kmls.txt (Master)
      await run("echo '' > /var/www/html/kmls.txt");
      
      // (B) Overwrite Slaves with Blank KML
      String blankKml = '<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://www.opengis.net/kml/2.2"><Document/></kml>';
      String encoded = base64Encode(utf8.encode(blankKml));
      await run("echo '$encoded' | base64 -d > /var/www/html/kml/slave_2.kml");
      await run("echo '$encoded' | base64 -d > /var/www/html/kml/slave_3.kml");
      
      // (C) Reset Master Camera
      await _initialOrbit();
    } catch (e) {
      statusMessage.value = "CLEAN FAILED: $e";
      notifyListeners();
    }
  }

  Future<void> _initialOrbit() async {
    try {
      await run('echo "flytoview=<LookAt><longitude>0</longitude><latitude>0</latitude><range>5000000</range><tilt>0</tilt><heading>0</heading></LookAt>" > /tmp/query.txt');
    } catch (e) {}
  }
}