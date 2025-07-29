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
        title: const Text('Panel Topógrafo'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('Topógrafo'),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.person, color: Colors.white, size: 40),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.location_searching),
              title: const Text('Rastreo de ubicación'),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrackingPageSimple()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Mapa de topógrafos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapaTopografosPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.terrain),
              title: const Text('Mis Terrenos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TerrenosPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Text(
          '¡Bienvenido, ${user?.email ?? ''}!',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
