import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CrudUsuariosPage extends StatefulWidget {
  const CrudUsuariosPage({super.key});

  @override
  State<CrudUsuariosPage> createState() => _CrudUsuariosPageState();
}

class _CrudUsuariosPageState extends State<CrudUsuariosPage> {
  List<Map<String, dynamic>> usuarios = [];
  bool loading = true;
  String filtro = '';
  final TextEditingController _buscarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarUsuarios();
  }

  Future<void> cargarUsuarios() async {
    setState(() => loading = true);
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('id, email, rol');
      setState(() {
        usuarios = List<Map<String, dynamic>>.from(response);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar usuarios: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> crearUsuarioDialog() async {
    final emailController = TextEditingController();
    final passController = TextEditingController();
    String rol = 'topografo';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Correo')),
            TextField(controller: passController, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
            DropdownButton<String>(
              value: rol,
              items: const [
                DropdownMenuItem(value: 'topografo', child: Text('Topógrafo')),
                DropdownMenuItem(value: 'admin', child: Text('Administrador')),
              ],
              onChanged: (v) => rol = v!,
            )
          ],
        ),
        actions: [
          TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            child: const Text('Crear'),
            onPressed: () async {
              final email = emailController.text.trim();
              final pass = passController.text.trim();
              if (email.isEmpty || pass.isEmpty) return;
              try {
                final res = await Supabase.instance.client.auth.admin.createUser(AdminUserAttributes(email: email, password: pass, userMetadata: {'rol': rol}));
                // También guarda el usuario en la tabla "users" (ajusta si tu tabla se llama diferente)
                await Supabase.instance.client.from('users').insert({
                  'id': res.user!.id,
                  'email': email,
                  'rol': rol,
                });
                Navigator.pop(context);
                cargarUsuarios();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario creado')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> editarRolUsuario(Map<String, dynamic> user) async {
    String rol = user['rol'];
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cambiar rol'),
        content: DropdownButton<String>(
          value: rol,
          items: const [
            DropdownMenuItem(value: 'topografo', child: Text('Topógrafo')),
            DropdownMenuItem(value: 'admin', child: Text('Administrador')),
          ],
          onChanged: (v) {
            rol = v!;
            setState(() {});
          },
        ),
        actions: [
          TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            child: const Text('Guardar'),
            onPressed: () async {
              await Supabase.instance.client.from('users').update({'rol': rol}).eq('id', user['id']);
              Navigator.pop(context);
              cargarUsuarios();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rol actualizado')));
            },
          ),
        ],
      ),
    );
  }

  Future<void> eliminarUsuario(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Seguro que deseas eliminar a ${user['email']}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(child: const Text('Eliminar'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (confirm != true) return;
    await Supabase.instance.client.from('users').delete().eq('id', user['id']);
    cargarUsuarios();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario eliminado')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Crear usuario',
            onPressed: crearUsuarioDialog,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: _buscarController,
                    decoration: InputDecoration(
                      labelText: 'Buscar por correo...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _buscarController.clear();
                          setState(() => filtro = '');
                        },
                      ),
                    ),
                    onChanged: (value) => setState(() => filtro = value.toLowerCase()),
                  ),
                ),
                Expanded(
                  child: usuarios.isEmpty
                      ? const Center(child: Text('No hay usuarios registrados'))
                      : ListView.separated(
                          itemCount: usuarios.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final u = usuarios[i];
                            if (filtro.isNotEmpty && !(u['email'] as String).toLowerCase().contains(filtro)) {
                              return const SizedBox.shrink();
                            }
                            return ListTile(
                              leading: Icon(u['rol'] == 'admin' ? Icons.shield : Icons.person_pin_circle, color: u['rol'] == 'admin' ? Colors.amber : Colors.indigo),
                              title: Text(u['email'], style: const TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: Text('Rol: ${u['rol']}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Editar rol',
                                    onPressed: () => editarRolUsuario(u),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Eliminar usuario',
                                    onPressed: () => eliminarUsuario(u),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
