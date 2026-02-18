---
name: lg_kml_generator
description: Expert skill for generating dynamic 3D KMLs and managing Liquid Galaxy systems according to Master Specification.
---
# Liquid Galaxy Master Specification

When generating KMLs or managing Liquid Galaxy systems, strictly adhere to these protocols:

## 1. The 'Panoramic' UX Protocol
*   **Slave 3 (Left Rig)**: Dedicated to **Brand Identity**.
    *   Command: Upload ScreenOverlay KML to `/var/www/html/kml/slave_3.kml`.
    *   Content: Liquid Galaxy and Project logos.
*   **Slave 2 (Right Rig)**: Dedicated to **Real-time Telemetry**.
    *   Command: Upload ScreenOverlay/Balloon KML to `/var/www/html/kml/slave_2.kml`.
    *   Content: 'Data HUD' showing Magnitude, Depth, and Time (High Contrast).
*   **Master (Center Rig)**: The **Interactive Layer**.
    *   Command: Upload main KML to `/var/www/html/kmls/earthquakes.kml`.
    *   Content: 3D Globe with extruded data.

## 2. KML Visualization Standards
*   **3D Extrusion**: NEVER use flat points.
    *   Use `<Polygon>` with `<extrude>1</extrude>` and `<altitudeMode>absolute</altitudeMode>`.
    *   **Height**: `magnitude * 15000` (Creates massive 3D towers).
*   **Cinematic Camera**:
    *   Use `gx:FlyTo` with `<tilt>65</tilt>` (Winning View) and `<range>1500</range>`.
    *   NEVER use a tilt of 0.
*   **Area Coverage**:
    *   Draw a `<LineString>` or `<Polygon>` around the epicenter to represent the impact zone.

## 3. System Communication (The Handshake)
*   **Connection Shake**: On SSH success, trigger a high-altitude orbit (`range: 5000000`) to visually confirm the link.
*   **Cache Busting**: Append `?v=${timestamp}` to all KML URLs in `/var/www/html/kmls.txt` to force refresh.
*   **System Commands**:
    *   Reboot: `echo 'lg' | sudo -S reboot`
    *   Shutdown: `echo 'lg' | sudo -S poweroff`
    *   Relaunch: `echo 'lg' | sudo -S killall -9 googleearth-bin; ...`

## 4. UX & Performance
*   **Asynchronous Handshake**: Delay SSH connection for **5 seconds** during SplashScreen to prioritizing intro video.
*   **Audio Power**:
    *   Set `flutter_tts` volume to `1.0`.
    *   Set `pitch` to `0.8` (Command Center aesthetic).
    *   Set `rate` to `0.4` (Slow, deliberate delivery).