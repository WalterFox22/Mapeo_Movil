import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../login_page.dart';
import '../mapeo/mapa_topografos_page.dart';
import '../mapeo/terrenos_page.dart';
import '../mapeo/tracking_page.dart';
import '../testeo/prueba_terreno_page.dart';
import '../mapeo/galeria_terrenos_page.dart'; 
import 'mapa_area_topografos_page.dart'; 

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    // --- 1. NUEVA PALETA DE COLORES "TIERRA Y CIELO NOCTURNO" ---
    const Color colorTierra = Color(0xFF3E2723); // Marrón oscuro
    const Color colorCielo = Color(0xFF1A237E);  // Azul noche
    const Color colorAcento = Color(0xFFFFD54F); // Dorado/Arena pálido

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: _buildCustomDrawer(context, user, [colorTierra, colorCielo]),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [colorTierra, colorCielo],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: SafeArea(
          // Usamos un ListView para la estructura vertical y el scroll
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            children: [
              // --- 2. EL HÉROE VISUAL: ÍCONO CON AURA Y BIENVENIDA ---
              Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorAcento.withOpacity(0.15),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(160),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                          child: Container(width: 160, height: 160),
                        ),
                      ),
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.2),
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                        ),
                        child: Icon(Icons.shield_outlined, size: 70, color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Bienvenido',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'Administrador',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              
              const Divider(color: Colors.white24, height: 60, indent: 24, endIndent: 24),

              // --- 3. SECCIÓN INFORMATIVA "DATOS IMPORTANTES" ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PANEL DE CONTROL',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 24),
                    _buildFeatureInfo(
                      icon: Icons.map_outlined,
                      color: colorAcento,
                      title: 'Mapa de Topógrafos',
                      description: 'Supervisa la ubicación en tiempo real de todo el equipo en campo.',
                    ),
                    _buildFeatureInfo(
                      icon: Icons.photo_library_outlined,
                      color: colorAcento,
                      title: 'Galería de Terrenos',
                      description: 'Explora las imágenes capturadas de los polígonos mapeados.',
                    ),
                    _buildFeatureInfo(
                      icon: Icons.storage_outlined,
                      color: colorAcento,
                      title: 'Gestión de Terrenos',
                      description: 'Consulta los detalles, área y vértices de todos los terrenos guardados.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget de ayuda para la sección informativa
  Widget _buildFeatureInfo({required IconData icon, required Color color, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 15, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Drawer actualizado para usar la nueva paleta de colores
  Widget _buildCustomDrawer(BuildContext context, User? user, List<Color> gradientColors) {
    return Drawer(
      child: Container(
        color: const Color(0xFF1C1C1E),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.shield_outlined, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text('Administrador', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(user?.email ?? '', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(leading: const Icon(Icons.image_outlined), title: const Text('Galería de terrenos'), onTap: () => _navigateTo(context, const GaleriaTerrenosPage())),
                  ListTile(leading: const Icon(Icons.map_outlined), title: const Text('Mapa de topógrafos'), onTap: () => _navigateTo(context, const MapaTopografosPage())),
                  ListTile(leading: const Icon(Icons.landscape_outlined), title: const Text('Ver terrenos guardados'), onTap: () => _navigateTo(context, const TerrenosPage())),
                  ListTile(leading: const Icon(Icons.my_location), title: const Text('Probar rastreo'), onTap: () => _navigateTo(context, const TrackingPageSimple())),
                  ListTile(leading: const Icon(Icons.polyline_outlined), title: const Text('Probar polígono'), onTap: () => _navigateTo(context, const PruebaTerrenoPage())),
                  ListTile(leading: const Icon(Icons.select_all_outlined),title: const Text('Área entre topógrafos'),onTap: () => _navigateTo(context, const AreaTopografosPage()),),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}
