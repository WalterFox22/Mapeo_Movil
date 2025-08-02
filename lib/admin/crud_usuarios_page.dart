import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CrudUsuariosPage extends StatefulWidget {
  const CrudUsuariosPage({super.key});

  @override
  State<CrudUsuariosPage> createState() => _CrudUsuariosPageState();
}

class _CrudUsuariosPageState extends State<CrudUsuariosPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> usuarios = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarUsuarios();
  }

  Future<void> cargarUsuarios() async {
    setState(() => cargando = true);
    final res = await supabase.from('users').select('id, email, rol');
    setState(() {
      usuarios = res;
      cargando = false;
    });
  }

  Future<void> editarRol(String id, String nuevoRol) async {
    await supabase.from('users').update({'rol': nuevoRol}).eq('id', id);
    await cargarUsuarios();
  }

  Future<void> eliminarUsuario(String id) async {
    await supabase.from('users').delete().eq('id', id);
    await cargarUsuarios();
  }

  void mostrarEditarDialogo(BuildContext context, String id, String rolActual) {
    String nuevoRol = rolActual;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar rol del usuario'),
        content: DropdownButton<String>(
          value: nuevoRol,
          items: const [
            DropdownMenuItem(value: 'topografo', child: Text('Topógrafo')),
            DropdownMenuItem(value: 'admin', child: Text('Administrador')),
          ],
          onChanged: (value) {
            setState(() => nuevoRol = value!);
            Navigator.pop(context);
            editarRol(id, nuevoRol);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Usuarios')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: usuarios.length,
              itemBuilder: (context, index) {
                final u = usuarios[index];
                return ListTile(
                  title: Text(u['email'] ?? 'Sin correo'),
                  subtitle: Text('Rol: ${u['rol']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.amber),
                        onPressed: () => mostrarEditarDialogo(context, u['id'], u['rol']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => eliminarUsuario(u['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
