import 'dart:math';
import 'package:lg_final_app/services/earthquake_service.dart';

class KMLGenerator {
  static String generateTourKML(List<Earthquake> quakes) {
    quakes.sort((a, b) => b.mag.compareTo(a.mag));
    
    String content = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
<Document>
  <name>Geo-Vigil Cinematic Tour</name>
  <open>1</open>

  <Style id="high_mag">
    <PolyStyle>
      <color>ff0000ff</color> <fill>1</fill> <outline>1</outline>
    </PolyStyle>
  </Style>
  
  <Style id="caution_icon">
    <IconStyle>
      <scale>1.5</scale>
      <Icon><href>http://maps.google.com/mapfiles/kml/shapes/caution.png</href></Icon>
    </IconStyle>
  </Style>

  <!-- Tectonic Plates NetworkLink -->
  <NetworkLink>
    <name>Tectonic Plates</name>
    <Link>
      <href>https://earthquake.usgs.gov/learn/kml/tectonic/PB2002_boundaries.kml</href>
    </Link>
  </NetworkLink>
''';

    for (var i = 0; i < quakes.length; i++) {
      var q = quakes[i];
      // Height proportional to magnitude (Mag 9.0 = 180,000m)
      double height = q.mag * 20000; 
      String lon = q.lon.toStringAsFixed(6);
      String lat = q.lat.toStringAsFixed(6);
      double offset = 0.15; // Width of pillar

      // 3D Extruded Pillar
      content += '''
  <Placemark>
    <name>M${q.mag.toStringAsFixed(1)}</name>
    <styleUrl>#high_mag</styleUrl>
    <Polygon>
      <extrude>1</extrude>
      <altitudeMode>absolute</altitudeMode>
      <outerBoundaryIs>
        <LinearRing>
          <coordinates>
            ${q.lon - offset},${q.lat - offset},$height 
            ${q.lon + offset},${q.lat - offset},$height 
            ${q.lon + offset},${q.lat + offset},$height 
            ${q.lon - offset},${q.lat + offset},$height 
            ${q.lon - offset},${q.lat - offset},$height
          </coordinates>
        </LinearRing>
      </outerBoundaryIs>
    </Polygon>
  </Placemark>
  
  <!-- Floating Hazard Icon at Top -->
  <Placemark>
    <name>HAZARD</name>
    <styleUrl>#caution_icon</styleUrl>
    <Point>
      <altitudeMode>absolute</altitudeMode>
      <coordinates>$lon,$lat,${height + 5000}</coordinates>
    </Point>
  </Placemark>
''';
    }

    // Cinematic Tour (Top 5)
    content += '''
  <gx:Tour>
    <name>Seismic Tour</name>
    <gx:Playlist>
''';

    final tourQuakes = quakes.take(5).toList();
    for (var q in tourQuakes) {
      content += '''
      <gx:FlyTo>
        <gx:duration>4.0</gx:duration>
        <gx:flyToMode>smooth</gx:flyToMode>
        <LookAt>
          <longitude>${q.lon}</longitude>
          <latitude>${q.lat}</latitude>
          <range>150000</range>
          <tilt>65</tilt>
          <heading>0</heading>
          <gx:altitudeMode>relativeToGround</gx:altitudeMode>
        </LookAt>
      </gx:FlyTo>
      
      <gx:Wait><gx:duration>1.0</gx:duration></gx:Wait>
      
      <gx:FlyTo>
        <gx:duration>3.0</gx:duration>
        <gx:flyToMode>smooth</gx:flyToMode>
        <LookAt>
          <longitude>${q.lon}</longitude>
          <latitude>${q.lat}</latitude>
          <range>150000</range>
          <tilt>65</tilt>
          <heading>180</heading>
          <gx:altitudeMode>relativeToGround</gx:altitudeMode>
        </LookAt>
      </gx:FlyTo>
''';
    }

    content += '''
    </gx:Playlist>
  </gx:Tour>
</Document>
</kml>''';

    return content;
  }
}