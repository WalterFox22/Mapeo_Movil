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
            letterSpacing: 1.2, // Añade espaciado entre letras
          ),
        ),
        backgroundColor: Colors.blueGrey[900],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true, // Centra el título del AppBar
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueGrey[800]!, Colors.blueGrey[900]!], // Gradiente más oscuro para el drawer
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  'Topógrafo Profesional', // Título más descriptivo
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
                  backgroundColor: Colors.tealAccent[400], // Color vibrante para el avatar
                  child: Icon(Icons.person, color: Colors.blueGrey[900], size: 45), // Icono más grande
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal[700]!, Colors.blueGrey[700]!], // Degradado llamativo para el header
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                margin: const EdgeInsets.only(bottom: 10), // Pequeño margen inferior
              ),
              _buildDrawerItem(
                context,
                icon: Icons.alt_route, // Icono más moderno para rastreo
                label: 'Rastreo de Dispositivos',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrackingPageSimple()),
                  );
                },
                color: Colors.lightBlueAccent, // Color distintivo
              ),
              _buildDrawerItem(
                context,
                icon: Icons.map_outlined, // Icono claro de mapa
                label: 'Visualizar Mapa',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapaTopografosPage()),
                  );
                },
                color: Colors.greenAccent, // Otro color distintivo
              ),
              _buildDrawerItem(
                context,
                icon: Icons.area_chart, // Icono para áreas/terrenos
                label: 'Mis Terrenos y Áreas',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TerrenosPage()),
                  );
                },
                color: Colors.orangeAccent, // Otro color distintivo
              ),
              const Divider(color: Colors.white30, height: 30, indent: 20, endIndent: 20), // Divisor mejorado
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
                color: Colors.redAccent, // Color de peligro para cerrar sesión
                isLogout: true, // Indica que es un botón de cerrar sesión
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey[50]!, Colors.blueGrey[200]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView( // Permite el scroll si el contenido es mucho
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo de la Aplicación
                Hero( // Animación simple al navegar si se usa en LoginPage también
                  tag: 'app_logo',
                  child: Image.asset(
                    'assets/geomapper_logo.png', // Asegúrate de tener esta imagen en tu carpeta assets
                    height: 120,
                    width: 120,
                  ),
                ),
                const SizedBox(height: 20),

                // Título principal
                Text(
                  'GeoMapper Pro: Tu Aliado en Topografía',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),

                // Eslogan
                Text(
                  'Innovación en Mapeo de Terrenos y Cálculo de Áreas',
                  style: TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: Colors.blueGrey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Descripción de la App
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Con GeoMapper Pro, puedes:\n',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      _buildFeatureBullet(
                          'Rastrear la ubicación de hasta tres dispositivos en tiempo real.',
                          Icons.radar),
                      _buildFeatureBullet(
                          'Visualizar el recorrido de los dispositivos en un mapa interactivo.',
                          Icons.location_on),
                      _buildFeatureBullet(
                          'Mapear terrenos con precisión, marcando puntos clave.',
                          Icons.polyline),
                      _buildFeatureBullet(
                          'Calcular el área de los terrenos mapeados de forma automática.',
                          Icons.calculate),
                      _buildFeatureBullet(
                          'Gestionar y consultar todos tus terrenos guardados.',
                          Icons.storage),
                      const SizedBox(height: 15),
                      Text(
                        '¡Optimiza tu trabajo topográfico con una herramienta intuitiva y potente!',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.blueGrey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Imagen ilustrativa (ejemplo, reemplaza con una real)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/map_illustration.png', // Asegúrate de tener esta imagen en tu carpeta assets
                    fit: BoxFit.cover,
                    height: 200,
                    width: double.infinity,
                  ),
                ),
                const SizedBox(height: 30),

                // Mensaje de bienvenida del usuario
                Text(
                  '¡Listo para empezar, ${user?.email?.split('@').first ?? 'Topógrafo'}!', // Muestra solo el nombre de usuario
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Método auxiliar para construir elementos del Drawer
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
        color: isLogout ? color.withOpacity(0.2) : Colors.white.withOpacity(0.1), // Fondo semitransparente o rojo para logout
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isLogout ? color.withOpacity(0.5) : color.withOpacity(0.3)), // Borde sutil
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28), // Icono más grande y colorido
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

  // Método auxiliar para los puntos de la descripción de características
  Widget _buildFeatureBullet(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueGrey[600], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: Colors.blueGrey[700]),
            ),
          ),
        ],
      ),
    );
  }
}