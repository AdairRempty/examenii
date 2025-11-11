import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database.dart';
import '../models/libro_model.dart';

class NetworkHelper {
  final String url = 'http://nrweb.com.mx/prueba_ws/libros.php';
  bool guardarSoloPares = false;
  bool guardarSoloImpares = false;

  Future<int?> getData() async {
    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);
    // Borra datos en cada instancia del boton
    await DatabaseHelper.clearAllData();
    final String accion = (data['accion_principal'] ?? '').toString();
    int? statusCode = data['estatus'] as int?;
    if (statusCode == 200 || statusCode == 500) {
      if(statusCode == 500){
        print("Error, mostrar y guardar información pero ignorar instrucciones y acciones");
      }
      else if(statusCode == 200)
      {
        print("OK");
        switch(accion) 
        {
          case("Guardar solo impares"):
            print("Guardar solo impares");
            guardarSoloPares = false;
            guardarSoloImpares = true;
            break;
          case("Guardar solo pares"):
            print("Guardar solo pares");
            guardarSoloPares = true;
            guardarSoloImpares = false;
            break;

          case("No guardar nada"):
            print("No guardar nada");
            return statusCode;
        }
      }
      final List<dynamic> libros = data['libro'];
      for (final l in libros) {
        final libro = Libro.fromJson(l as Map<String, dynamic>);

        final int idNumerico = primerNumero(libro.nomLibro);

        final bool esPar = idNumerico % 2 == 0;
        if (guardarSoloPares && !esPar) {
          continue;
        }
        if (!guardarSoloPares && esPar) {
          continue;
        }

        final int libroId = await DatabaseHelper.insertLibro({
          DatabaseHelper.columnLibroNombre: libro.nomLibro,
          DatabaseHelper.columnLibroHojas: libro.cantidadHojas,
          DatabaseHelper.columnLibroAutor: libro.autor,
        });

        for (final capitulo in libro.capitulos) {
          final int capituloId = await DatabaseHelper.insertCapitulo({
            DatabaseHelper.columnCapituloLibroId: libroId,
            DatabaseHelper.columnCapituloPersonaje: capitulo.personaje,

            DatabaseHelper.columnCapituloFontSize: statusCode == 500 ? 12 : capitulo.instrucciones.fontSize,
            DatabaseHelper.columnCapituloColor: statusCode == 500 ? '#000000' : capitulo.instrucciones.color,
            DatabaseHelper.columnCapituloEditable: statusCode == 500 ? 0 : (capitulo.instrucciones.acciones.editable ? 1 : 0),
            DatabaseHelper.columnCapituloEliminar: statusCode == 500 ? 0 : (capitulo.instrucciones.acciones.eliminar ? 1 : 0),
          });

          for (final historiaTexto in capitulo.historia) {
            await DatabaseHelper.insertHistoria({
              DatabaseHelper.columnHistoriaCapituloId: capituloId,
              DatabaseHelper.columnHistoriaTexto: historiaTexto,
            });
          }
        }
      }
    }
    return statusCode;
  }

  // Funcion extraida de una busqueda de google que obtiene la IA en stack overflow al buscar first int in string
  // En NetworkHelper.primerNumero:
  int primerNumero(String s) {
    final m = RegExp(r'\d+').firstMatch(s);
    if (m != null) {
      return int.tryParse(m.group(0)!) ?? -1;
    } else {
      return -1;
    }
  }


  int boolString(dynamic v) {
    final s = v?.toString();
    if(s == 'si') {
      return 1;
    }
    else {
      return 0;
    }
  }
}