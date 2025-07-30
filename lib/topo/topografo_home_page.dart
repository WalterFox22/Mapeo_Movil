import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../login_page.dart';
import '../mapeo/mapa_topografos_page.dart';
import '../mapeo/terrenos_page.dart';
import '../mapeo/tracking_page.dart';

class TopografoHomePage extends StatelessWidget {
  const TopografoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GeoMapper Pro',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.blueGrey[900],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueGrey[800]!, Colors.blueGrey[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: const Text(
                  'Topógrafo Profesional',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                accountEmail: Text(
                  user?.email ?? 'correo@ejemplo.com',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.tealAccent[400],
                  child: Icon(Icons.person, color: Colors.blueGrey[900], size: 45),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal[700]!, Colors.blueGrey[700]!],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                margin: const EdgeInsets.only(bottom: 10),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.alt_route,
                label: 'Rastreo de Dispositivos',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrackingPageSimple()),
                  );
                },
                color: Colors.lightBlueAccent,
              ),
              _buildDrawerItem(
                context,
                icon: Icons.map_outlined,
                label: 'Visualizar Mapa',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapaTopografosPage()),
                  );
                },
                color: Colors.greenAccent,
              ),
              _buildDrawerItem(
                context,
                icon: Icons.area_chart,
                label: 'Mis Terrenos y Áreas',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TerrenosPage()),
                  );
                },
                color: Colors.orangeAccent,
              ),
              const Divider(color: Colors.white30, height: 30, indent: 20, endIndent: 20),
              _buildDrawerItem(
                context,
                icon: Icons.logout,
                label: 'Cerrar Sesión',
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  }
                },
                color: Colors.redAccent,
                isLogout: true,
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Sección de Bienvenida (Banner Principal)
            _buildHeroSection(context, user),
            
            // Sección de Características (About Us)
            _buildFeaturesSection(),

            // Sección de Servicios (Nuestros Servicios)
            _buildServicesSection(context),

            // Sección de Testimonios (opcional, para dar credibilidad)
            _buildTestimonialsSection(),
          ],
        ),
      ),
    );
  }

  // Métodos auxiliares para la construcción del Drawer y la página
  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
        required Color color,
        bool isLogout = false,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isLogout ? color.withOpacity(0.2) : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isLogout ? color.withOpacity(0.5) : color.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: isLogout ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }

  // --- Widgets del nuevo cuerpo de la página ---

  // Hero Section (sección principal)
  Widget _buildHeroSection(BuildContext context, User? user) {
    return Container(
      height: 350,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/background_topo.png'), // Agrega una imagen de fondo
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black54, // Oscurece la imagen para que el texto resalte
            BlendMode.darken,
          ),
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '¡Bienvenido, ${user?.email?.split('@').first ?? 'Topógrafo'}!',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Topografía Inteligente al Alcance de tu Mano',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Rastrea, mapea y calcula áreas de terrenos en tiempo real con precisión.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    // Acción al presionar el botón principal
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TrackingPageSimple()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent[700], // Color de acento
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Empezar a Mapear Ahora',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Sección de Características/Acerca de
  Widget _buildFeaturesSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Text(
            'Acerca de GeoMapper',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Una solución moderna para topógrafos y agrimensores que buscan eficiencia.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blueGrey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFeatureIcon(
                  icon: Icons.satellite_alt,
                  title: 'GPS Preciso',
                  description: 'Ubicación en tiempo real con alta fiabilidad.'),
              _buildFeatureIcon(
                  icon: Icons.calculate_outlined,
                  title: 'Cálculo Automático',
                  description: 'Áreas de terrenos calculadas al instante.'),
              _buildFeatureIcon(
                  icon: Icons.devices,
                  title: 'Multidispositivo',
                  description: 'Monitorea hasta 3 dispositivos a la vez.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureIcon({required IconData icon, required String title, required String description}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Icon(icon, size: 50, color: Colors.teal[700]),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blueGrey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  // Sección de Servicios (llamada a la acción y explicación)
  Widget _buildServicesSection(BuildContext context) {
    return Container(
      color: Colors.blueGrey[50],
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Text(
            'Nuestros Servicios',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          const SizedBox(height: 20),
          _buildServiceCard(
            context,
            icon: Icons.track_changes,
            title: 'Rastreo de Dispositivos',
            description: 'Inicia el rastreo en tiempo real para obtener las coordenadas exactas de tus equipos.',
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackingPageSimple()));
            }
          ),
          _buildServiceCard(
            context,
            icon: Icons.map_sharp,
            title: 'Visualización de Mapa',
            description: 'Observa en un mapa dinámico la posición actual de todos los topógrafos en el campo.',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MapaTopografosPage()));
            }
          ),
          _buildServiceCard(
            context,
            icon: Icons.terrain,
            title: 'Gestión de Terrenos',
            description: 'Accede a tus proyectos anteriores, visualiza áreas calculadas y gestiona tus registros.',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TerrenosPage()));
            }
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, {required IconData icon, required String title, required String description, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, size: 40, color: Colors.teal[700]),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.blueGrey),
      ),
    );
  }

  // Sección de Testimonios (para dar credibilidad, opcional pero profesional)
  Widget _buildTestimonialsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Text(
            'Lo que dicen nuestros usuarios',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          const SizedBox(height: 20),
          // Un carrusel de testimonios o simplemente un par de ellos
          _buildTestimonialCard(
            'La precisión del rastreo me ahorra horas en cada proyecto. ¡Impresionante!',
            'Carlos J., Topógrafo',
          ),
          _buildTestimonialCard(
            'La interfaz es tan intuitiva que pude usar la app desde el primer día sin problemas.',
            'María L., Agrimensora',
          ),
        ],
      ),
    );
  }
  
  Widget _buildTestimonialCard(String quote, String author) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.format_quote, size: 30, color: Colors.blueGrey),
            const SizedBox(height: 10),
            Text(
              quote,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.blueGrey[800],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              author,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.teal[700],
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }
}