import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../login_page.dart';
import '../mapeo/mapa_topografos_page.dart';
import '../mapeo/terrenos_page.dart';
import '../mapeo/tracking_page.dart';
import '../mapeo/galeria_terrenos_page.dart'; // ← ¡Importa tu galería!
// ← ¡Importa la lista (código abajo)!

class TopografoHomePage extends StatelessWidget {
  const TopografoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    const Color colorVerdeProfundo = Color(0xFF1B5E20);
    const Color colorAmarilloClaro = Color(0xFFFFECB3);
    const Color colorAzulCieloClaro = Color(0xFF81D4FA);
    const Color colorAcentoPrimario = Color(0xFF69F0AE);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'GeoMapper Pro',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      drawer: _buildCustomDrawer(context, user, [colorVerdeProfundo, colorAzulCieloClaro]),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [colorVerdeProfundo, colorAzulCieloClaro],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            children: [
              _buildHeroSection(context, user, colorAcentoPrimario, colorAmarilloClaro),

              const Divider(color: Colors.white24, height: 60, indent: 24, endIndent: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACCIONES RÁPIDAS',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 24),
                    _buildFeatureInfo(
                      icon: Icons.track_changes_outlined,
                      color: colorAcentoPrimario,
                      title: 'Iniciar Nuevo Rastreo',
                      description: 'Comienza a capturar datos de ubicación en tiempo real para un nuevo terreno.',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackingPageSimple())),
                    ),
                    _buildFeatureInfo(
                      icon: Icons.photo_library_outlined,
                      color: colorAcentoPrimario,
                      title: 'Galería de Terrenos',
                      description: 'Mira todos los terrenos mapeados visualmente con sus imágenes.',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GaleriaTerrenosPage())),
                    ),
                  
                    _buildFeatureInfo(
                      icon: Icons.location_on_outlined,
                      color: colorAcentoPrimario,
                      title: 'Ver Mapa de Topógrafos',
                      description: 'Visualiza la ubicación de otros topógrafos en el campo (si tienes permisos).',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapaTopografosPage())),
                    ),
                
                  ],
                ),
              ),

              const Divider(color: Colors.white24, height: 60, indent: 24, endIndent: 24),

              _buildQuoteSection(colorAmarilloClaro),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDrawer(BuildContext context, User? user, List<Color> gradientColors) {
    const Color colorVerdeProfundoDrawer = Color(0xFF1B5E20);
    const Color colorAzulCieloClaroDrawer = Color(0xFF81D4FA);
    const Color colorAcentoPrimarioDrawer = Color(0xFF69F0AE);

    return Drawer(
      child: Container(
        color: Colors.grey[900],
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
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: colorAcentoPrimarioDrawer.withOpacity(0.4),
                    child: Icon(Icons.person_pin_circle_outlined, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text('Topógrafo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(user?.email ?? '', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.track_changes,
                    label: 'Rastreo Activo',
                    onTap: () => _navigateTo(context, const TrackingPageSimple()),
                    color: colorAcentoPrimarioDrawer,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.photo_library,
                    label: 'Galería de Terrenos',
                    onTap: () => _navigateTo(context, const GaleriaTerrenosPage()),
                    color: colorAcentoPrimarioDrawer,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.grid_on,
                    label: 'Lista de Terrenos',
                    onTap: () => _navigateTo(context, const TerrenosPage()),
                    color: colorAcentoPrimarioDrawer,
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
                }
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

  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap, required Color color}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, User? user, Color accentColor, Color secondaryAccent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(0.15),
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
                child: Icon(Icons.location_on_sharp, size: 70, color: Colors.white.withOpacity(0.9)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Hola, ${user?.email?.split('@').first ?? 'Topógrafo'}!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tu Panel de Campo Personalizado',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Accede rápidamente a tus herramientas de mapeo y gestión de proyectos.',
            style: TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackingPageSimple()));
            },
            icon: const Icon(Icons.add_location_alt, color: Colors.white),
            label: Text(
              'Iniciar Nueva Medición',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          const SizedBox(height: 30),
          _buildQuickStats(secondaryAccent),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Color secondaryAccent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: secondaryAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.leaderboard_outlined, '52', 'Terrenos', secondaryAccent),
          _buildStatItem(Icons.timeline_outlined, '120h', 'Rastreo', secondaryAccent),
          _buildStatItem(Icons.groups_outlined, '3', 'Equipos', secondaryAccent),
        ],
      ),
    );
  }

  Widget _buildFeatureInfo({required IconData icon, required Color color, required String title, required String description, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              leading: Icon(icon, color: color, size: 32),
              title: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              subtitle: Text(description, style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.7))),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.6), size: 20),
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteSection(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(Icons.lightbulb_outline, size: 40, color: accentColor),
            const SizedBox(height: 15),
            Text(
              '“La precisión no es un acto, sino un hábito.”',
              style: TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: Colors.white.withOpacity(0.9),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              '– GeoMapper Pro',
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color iconColor) {
    return Column(
      children: [
        Icon(icon, size: 30, color: iconColor),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
        ),
      ],
    );
  }
}
