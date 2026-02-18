import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SSH {
  late String _host;
  late String _port;
  late String _username;
  late String _passwordOrKey;
  late String _numberOfRigs;
  SSHClient? _client;

  Future<void> initConnectionDetails() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _host = prefs.getString('ipAddress') ?? '192.168.0.1';
    _port = prefs.getString('sshPort') ?? '22';
    _username = prefs.getString('username') ?? 'lg';
    _passwordOrKey = prefs.getString('password') ?? 'lg';
    _numberOfRigs = prefs.getString('numberOfRigs') ?? '3';
  }

  Future<bool?> connectToLG() async {
    await initConnectionDetails();
    try {
      final socket = await SSHSocket.connect(_host, int.parse(_port), timeout: const Duration(seconds: 5));
      _client = SSHClient(
        socket,
        username: _username,
        onPasswordRequest: () => _passwordOrKey,
      );
      return true;
    } on SocketException catch (e) {
      print('Failed to connect: $e');
      return false;
    }
  }

  Future<SSHSession?> run(String command) async {
    try {
      if (_client == null) return null;
      return await _client!.execute(command);
    } catch (e) {
      return null;
    }
  }

  Future<void> _uploadFile(String content, String filename) async {
    String encoded = base64Encode(utf8.encode(content));
    await run("echo '$encoded' | base64 -d > /var/www/html/kml/$filename");
    await run("chmod 777 /var/www/html/kml/$filename");
  }

  // --- TASK 1: CHANDIGARH (Blue Pins) ---
  Future<void> flyToChandigarh() async {
    await connectToLG();
    await run('echo "flytoview=<LookAt><longitude>76.7794</longitude><latitude>30.7333</latitude><altitude>0</altitude><heading>0</heading><tilt>45</tilt><range>3000</range><gx:altitudeMode>relativeToGround</gx:altitudeMode></LookAt>" > /tmp/query.txt');

    String content = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
  <name>Chandigarh Points</name>
  <Style id="blue_pin">
    <IconStyle><scale>3.0</scale><Icon><href>http://maps.google.com/mapfiles/kml/pushpin/blue-pushpin.png</href></Icon></IconStyle>
  </Style>
  <Placemark><name>Center</name><styleUrl>#blue_pin</styleUrl><Point><coordinates>76.7794,30.7333,0</coordinates></Point></Placemark>
  <Placemark><name>North</name><styleUrl>#blue_pin</styleUrl><Point><coordinates>76.7794,30.7360,0</coordinates></Point></Placemark>
  <Placemark><name>South</name><styleUrl>#blue_pin</styleUrl><Point><coordinates>76.7794,30.7306,0</coordinates></Point></Placemark>
  <Placemark><name>East</name><styleUrl>#blue_pin</styleUrl><Point><coordinates>76.7830,30.7333,0</coordinates></Point></Placemark>
  <Placemark><name>West</name><styleUrl>#blue_pin</styleUrl><Point><coordinates>76.7758,30.7333,0</coordinates></Point></Placemark>
</Document>
</kml>''';

    await _uploadFile(content, 'chandigarh.kml');
    await _linkToMaster('chandigarh.kml');
  }

  // --- TASK 2: PYRAMIDS (Yellow Pins + 3D) ---
  Future<void> sendPyramids() async {
    await connectToLG();
    await run('echo "flytoview=<LookAt><longitude>31.1342</longitude><latitude>29.9792</latitude><altitude>0</altitude><heading>0</heading><tilt>60</tilt><range>4000</range><gx:altitudeMode>relativeToGround</gx:altitudeMode></LookAt>" > /tmp/query.txt');

    String content = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
  <name>Red 3D Pyramids</name>
  <Style id="red_poly">
    <LineStyle><color>ff0000ff</color><width>2</width></LineStyle>
    <PolyStyle><color>7f0000ff</color><fill>1</fill><outline>1</outline></PolyStyle>
  </Style>
  <Style id="yellow_pin">
    <IconStyle><scale>3.0</scale><Icon><href>http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png</href></Icon></IconStyle>
  </Style>''';

    for (int i = 0; i < 3; i++) {
      double lat = 29.976 + (i * 0.005);
      double lon = 31.131 + (i * 0.005);
      
      content += '''<Placemark><name>Pyramid ${i+1}</name><styleUrl>#yellow_pin</styleUrl><Point><coordinates>$lon,$lat,300</coordinates></Point></Placemark>''';
      
      content += _buildBlock(lat, lon, 0.003, 0, 100);
      content += _buildBlock(lat, lon, 0.002, 100, 200);
      content += _buildBlock(lat, lon, 0.001, 200, 300);
    }
    
    content += '</Document></kml>';

    await _uploadFile(content, 'pyramids.kml');
    await _linkToMaster('pyramids.kml');
  }

  String _buildBlock(double centerLat, double centerLon, double width, int lowerAlt, int upperAlt) {
    double half = width / 2;
    return '''
    <Placemark>
      <styleUrl>#red_poly</styleUrl>
      <Polygon>
        <extrude>1</extrude>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>${centerLon - half},${centerLat - half},$upperAlt ${centerLon + half},${centerLat - half},$upperAlt ${centerLon + half},${centerLat + half},$upperAlt ${centerLon - half},${centerLat + half},$upperAlt ${centerLon - half},${centerLat - half},$upperAlt ${centerLon - half},${centerLat - half},$upperAlt</coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>''';
  }

  // --- TASK 3: FOOTBALL MATCH (The "Insane" Player Version) ---
  Future<void> sendFootballs() async {
    await connectToLG();
    
    // Tilt camera to look like we are on the field
    await run('echo "flytoview=<LookAt><longitude>0.6200</longitude><latitude>41.6176</latitude><altitude>0</altitude><heading>0</heading><tilt>75</tilt><range>500</range><gx:altitudeMode>relativeToGround</gx:altitudeMode></LookAt>" > /tmp/query.txt');

    // USING "MAN" ICONS for Players
    String content = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
  <name>Football Match</name>
  
  <Style id="player_icon">
    <IconStyle>
      <scale>2.5</scale>
      <Icon><href>http://maps.google.com/mapfiles/kml/shapes/man.png</href></Icon>
    </IconStyle>
    <LabelStyle><scale>1.5</scale></LabelStyle>
  </Style>

  <Style id="ball_icon">
    <IconStyle>
      <scale>1.5</scale>
      <Icon><href>http://maps.google.com/mapfiles/kml/shapes/target.png</href></Icon>
    </IconStyle>
  </Style>

  <Placemark><name>Goalie</name><styleUrl>#player_icon</styleUrl><Point><coordinates>0.6200,41.6176,0</coordinates></Point></Placemark>
  <Placemark><name>Defender</name><styleUrl>#player_icon</styleUrl><Point><coordinates>0.6205,41.6178,0</coordinates></Point></Placemark>
  <Placemark><name>Midfielder</name><styleUrl>#player_icon</styleUrl><Point><coordinates>0.6210,41.6180,0</coordinates></Point></Placemark>
  <Placemark><name>Striker</name><styleUrl>#player_icon</styleUrl><Point><coordinates>0.6215,41.6182,0</coordinates></Point></Placemark>
  <Placemark><name>The Ball</name><styleUrl>#ball_icon</styleUrl><Point><coordinates>0.6212,41.6181,0</coordinates></Point></Placemark>

</Document>
</kml>''';

    await _uploadFile(content, 'footballs.kml');
    await _linkToMaster('footballs.kml');
  }

  // --- LOGO ---
  Future<void> showLogo() async {
    await connectToLG();
    String logoKML = '''<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
<Document><Folder><name>Logos</name><ScreenOverlay>
<name>Logo</name><Icon><href>https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEgXmdNgBTXup6bdWew5RzgCmC9pPb7rK487CpiscWB2S8OlhwFHmeeACHIIjx4B5-Iv-t95mNUx0JhB_oATG3-Tq1gs8Uj0-Xb9Njye6rHtKKsnJQJlzZqJxMDnj_2TXX3eA5x6VSgc8aw/s320-rw/LOGO+LIQUID+GALAXY-sq1000-+OKnoline.png</href></Icon>
<overlayXY x="0.5" y="0.5" xunits="fraction" yunits="fraction"/><screenXY x="0.5" y="0.5" xunits="fraction" yunits="fraction"/><rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/><size x="0.5" y="0.5" xunits="fraction" yunits="fraction"/>
</ScreenOverlay></Folder></Document></kml>''';
    await _uploadFile(logoKML, 'slave_3.kml');
    await _setRefresh(); 
  }

  // --- HELPERS ---
  Future<void> _linkToMaster(String filename) async {
    String masterLink = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2"><Document><NetworkLink><name>Master Link</name>
<Link><href>http://localhost:81/kml/$filename</href><refreshMode>onInterval</refreshMode><refreshInterval>1</refreshInterval></Link>
</NetworkLink></Document></kml>''';
    String encoded = base64Encode(utf8.encode(masterLink));
    await run("echo '$encoded' | base64 -d > /var/www/html/kmls.txt");
    await run("chmod 777 /var/www/html/kmls.txt");
  }

  // --- RESTORED FUNCTIONS TO FIX ERRORS ---
  Future<void> clearKMLMain() async {
    await connectToLG();
    await run('echo "" > /tmp/query.txt');
    String blank = '<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://www.opengis.net/kml/2.2"><Document></Document></kml>';
    await run("echo '$blank' > /var/www/html/kmls.txt");
  }

  Future<void> clearLogo() async {
    await connectToLG();
    String blank = '<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://www.opengis.net/kml/2.2"><Document></Document></kml>';
    await _uploadFile(blank, 'slave_3.kml');
  }

  // --- DEEP CLEANING (Updated Logic) ---
  Future<void> clearAll() async {
    await connectToLG();
    // Stop Orbit
    await run('echo "" > /tmp/query.txt');
    // Clear Link
    String blank = '<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://www.opengis.net/kml/2.2"><Document></Document></kml>';
    await run("echo '$blank' > /var/www/html/kmls.txt");
    
    // DELETE FILES TO FIX CACHE
    await run("rm /var/www/html/kml/chandigarh.kml");
    await run("rm /var/www/html/kml/pyramids.kml");
    await run("rm /var/www/html/kml/footballs.kml");
    await run("rm /var/www/html/kml/slave_3.kml");
    
    await _uploadFile(blank, 'slave_3.kml');
  }

  // --- SYSTEM TOOLS ---
  Future<void> relaunchLG() async {
     await connectToLG();
     int rigs = int.parse(_numberOfRigs);
     for (var i = 1; i <= rigs; i++) {
        String cmd = """RELAUNCH_CMD="\\
          if [ -f /etc/init/lxdm.conf ]; then export SERVICE=lxdm; elif [ -f /etc/init/lightdm.conf ]; then export SERVICE=lightdm; else exit 1; fi
          if  [[ \\\$(service \\\$SERVICE status) =~ 'stop' ]]; then echo $_passwordOrKey | sudo -S service \\\${SERVICE} start; else echo $_passwordOrKey | sudo -S service \\\${SERVICE} restart; fi
          " && sshpass -p $_passwordOrKey ssh -x -t lg@lg$i "\$RELAUNCH_CMD\"""";
        await run(cmd);
     }
  }

  Future<void> rebootLG() async {
    await connectToLG();
    int rigs = int.parse(_numberOfRigs);
    for (var i = 1; i <= rigs; i++) {
      await run('sshpass -p $_passwordOrKey ssh -t lg$i "echo $_passwordOrKey | sudo -S reboot"');
    }
  }

  Future<void> shutdownLG() async {
    await connectToLG();
    int rigs = int.parse(_numberOfRigs);
    for (var i = 1; i <= rigs; i++) {
      await run('sshpass -p $_passwordOrKey ssh -t lg$i "echo $_passwordOrKey | sudo -S poweroff"');
    }
  }

  Future<void> _setRefresh() async {
    int rigs = int.parse(_numberOfRigs);
    for (var i = 2; i <= rigs; i++) {
      String search = '<href>##LG_PHPIFACE##kml\\/slave_$i.kml<\\/href>';
      String replace = '<href>##LG_PHPIFACE##kml\\/slave_$i.kml<\\/href><refreshMode>onInterval<\\/refreshMode><refreshInterval>2<\\/refreshInterval>';
      await run('sshpass -p $_passwordOrKey ssh -t lg$i \'echo $_passwordOrKey | sudo -S sed -i "s/$replace/$search/" ~/earth/kml/slave/myplaces.kml\'');
      await run('sshpass -p $_passwordOrKey ssh -t lg$i \'echo $_passwordOrKey | sudo -S sed -i "s/$search/$replace/" ~/earth/kml/slave/myplaces.kml\'');
    }
  }
  // --- GEO ALERT CENTER ---
  Future<void> sendTourKML(String content) async {
    await connectToLG();
    // 1. Upload the content to a file
    await _uploadFile(content, 'earthquakes.kml');
    
    // 2. Point the Master Node to this file (Updates kmls.txt)
    await _linkToMaster('earthquakes.kml');
    
    // 3. Start the Tour (Experimental: auto-play if supported, otherwise user presses play)
    // For now, we rely on the user to press 'Play Tour' in Google Earth, OR we can try to force it.
    // But properly, we just load the KML. The KML contains the tour.
  }

  Future<void> stopTour() async {
     await clearAll();
  }
}