import 'package:flutter/material.dart';
import 'utils/get_api.dart';
import 'utils/database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'widgets/name_widget.dart';
import 'widgets/message_widget.dart';
import 'widgets/button_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await DatabaseHelper.init();
  runApp(const MyApp());
}

int? statusCode;

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Examen II Aplicaciones Moviles',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> _historias = [];
  String _estado = 'No hay datos que mostrar, da clic en el botón para cargar la información';
  final Map<int, bool> _editingStates = {};
  final Map<int, TextEditingController> _textControllers = {};

  @override
  void initState() {
    super.initState();
    _loadHistoria();
  }

  @override
  void dispose() {
    _textControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadHistoria() async {
    final data = await DatabaseHelper.getAllHistoriasCompletas();
    setState(() {
      _historias = data;
      _editingStates.clear();
      _textControllers.values.forEach((controller) => controller.dispose());
      _textControllers.clear();
      if (data.isEmpty) {
        _estado = 'No hay historia para mostrar.';
      }
    });
  }

  Future<void> _deleteCapitulo(int id) async {
    await DatabaseHelper.deleteCapitulo(id);
    await _loadHistoria();
  }

  Future<void> _editCapitulo(int id, String historia) async {
    await DatabaseHelper.updateCapitulo(id, historia);
    await _loadHistoria();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Examen II Aplicaciones Moviles')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Widget para mi nombre
            const NameWidget(name: 'Ricardo Adair Vidal Araujo'),
            const SizedBox(height: 20),
            Text(
              _estado,
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
            // Desde aqui es para mostrar los capitulos de la historia con fuente personalizada
            // por capitulo y personaje
            const SizedBox(height: 20),
            Expanded(  
              child: ListView.builder(
                itemCount: _historias.length,
                itemBuilder: (context, index) {
                  final historia = _historias[index];
                  final int id = historia['id'];
                  // Condiciones y widgets para poder editar las historias
                  // Es bastante grande esta seccion pero solo es un text editor sacado de internet
                  // y respuestas de ia de google search
                  final bool isEditing = _editingStates[id] ?? false;
                  if (isEditing) {
                    if (!_textControllers.containsKey(id)) {
                      _textControllers[id] = TextEditingController(
                        text: historia['historia'],
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _textControllers[id],
                            maxLines: null,
                            style: TextStyle(
                              fontSize: (historia['font_size'] as int).toDouble(),
                              color: Color(
                                int.parse(historia['color'].substring(1, 7),radix: 16,) + 0xFF000000,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  final newText = _textControllers[id]!.text;
                                  _editCapitulo(id, newText);
                                  setState(() {
                                    _editingStates[id] = false;
                                    _textControllers[id]!.dispose();
                                    _textControllers.remove(id);
                                  });
                                },
                                // Un pequeño botón para guardar los cambios realizados
                                child: const Text('Guardar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MessageWidget(
                            message: historia['historia'],
                            fontSize: historia['font_size'],
                            color: historia['color'],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (historia['editable'] as bool)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _editingStates[id] = true;
                                    });
                                  },
                                  child: const Text('Editar'),
                                ),
                                // Aqui acaba la seccion de edicion
                              // Un boton que directamente elimina de la base de datos
                              if (historia['eliminar'] as bool)
                                TextButton(
                                  onPressed: () => _deleteCapitulo(id),
                                  child: const Text(
                                    'Eliminar',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            // Boton de llamada a la api
            ButtonWidget(
              text: 'Llamar API',
              onPressed: () async {
                final statusCode = await NetworkHelper().getData();
                setState(() {
                  if (statusCode == 200) {
                    _estado = 'OK';
                    _loadHistoria();
                  } else if (statusCode == 500) {
                    _estado =
                        'Error, mostrar y guardar información pero ignorar instrucciones y acciones';
                    _loadHistoria();
                  } else if (statusCode == 400) {
                    _estado = 'Error, no mostrar ni guardar información';
                    _historias = [];
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
