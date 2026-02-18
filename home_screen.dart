import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lg_final_app/services/lg_service.dart';
import 'package:lg_final_app/services/earthquake_service.dart';
import 'package:lg_final_app/utils/kml_generator.dart';
import 'package:lg_final_app/components/glass_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<Earthquake> _earthquakes = [];
  bool _isLoading = false;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 1)
    )..repeat(reverse: true);
    _loadEarthquakes();
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> _loadEarthquakes() async {
    setState(() => _isLoading = true);
    final quakes = await EarthquakeService().getMajorEarthquakes();
    setState(() {
      _earthquakes = quakes;
      _isLoading = false;
    });
  }

  // GSoC WINNING LOGO: Cinematic Tour Logic
  Future<void> _startTour(LGService lgService) async {
    if (_earthquakes.isEmpty) return;
    
    // 1. Generate KML with 3D Pillars + Tectonic Plates
    String tourKML = KMLGenerator.generateTourKML(_earthquakes);
    
    // 2. Upload to Master Rig
    await lgService.sendKML(tourKML, "earthquake_tour.kml");
    
    // 3. Trigger the Tour (Command: playtour=Seismic Tour)
    await lgService.run('echo "playtour=Seismic Tour" > /tmp/query.txt');
  }

  @override
  Widget build(BuildContext context) {
    final lgService = Provider.of<LGService>(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: const Text('MISSION CONTROL', style: TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, letterSpacing: 3)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.blueAccent),
            onPressed: () => _showGSoCDialog(context),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF000000)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusBadge("SSH UPLINK", lgService.isConnected ? Colors.green : Colors.red),
                  _buildStatusBadge("DATA STREAM", _isLoading ? Colors.orange : Colors.blue),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Colors.red))
                  : ListView.builder(
                      itemCount: _earthquakes.length,
                      itemBuilder: (context, index) {
                        final q = _earthquakes[index];
                         return Container(
                           margin: const EdgeInsets.only(bottom: 10),
                           child: GlassCard(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:Colors.red.withOpacity(0.2),
                                child: Text("${q.mag.toStringAsFixed(1)}", style: const TextStyle(color: Colors.redAccent)),
                              ),
                              title: Text(q.place.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              trailing: IconButton(
                                icon: const Icon(Icons.flight_takeoff, color: Colors.blueAccent),
                                onPressed: () async {
                                  // FIX: Move Rig + Update HUD simultaneously
                                  await lgService.flyTo(q);
                                  await lgService.sendTacticalHUD(q);
                                },
                              ),
                            ),
                          ),
                         );
                      },
                    ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _startTour(lgService),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFB00000), Color(0xFF600000)]),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: const Center(
                    child: Text("INITIATE CINEMATIC TOUR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGSoCDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("GSoC 2026 Submission"),
        content: const Text("Project: Geo-Vigil Real-Time Seismic Monitor\nLead: Anirudh Pratap Singh Yadav\nOfficial Submission for Gemini Summer of Code."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE"))],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}