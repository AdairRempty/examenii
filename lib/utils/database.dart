import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "Books.db";
  static const _databaseVersion = 1;

  // Tabla de libros
  static const tableLibros = 'libros';
  static const columnLibroId = 'id';
  static const columnLibroNombre = 'nom_libro';
  static const columnLibroHojas = 'cantidad_hojas';
  static const columnLibroAutor = 'autor';

  // Tabla de capitulos
  static const tableCapitulos = 'capitulos';
  static const columnCapituloId = 'id';
  static const columnCapituloLibroId = 'libro_id';
  static const columnCapituloPersonaje = 'personaje';
  static const columnCapituloFontSize = 'font_size';
  static const columnCapituloColor = 'color';
  static const columnCapituloEditable = 'editable';
  static const columnCapituloEliminar = 'eliminar';

  // Tabla de historias
  static const tableHistorias = 'historias';
  static const columnHistoriaId = 'id';
  static const columnHistoriaCapituloId = 'capitulo_id';
  static const columnHistoriaTexto = 'texto_historia';

  static late Database _db;

  static Future<void> init() async {
    final String path;

    if (kIsWeb) {
      path = "/assets/db";
    } else {
      final documentsDirectory =
          (await getApplicationDocumentsDirectory()).path;
      path = join(documentsDirectory, _databaseName);
    }
    print(path);

    _db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // Tengo que usar el db execute para crear las tablas
  static Future _onCreate(Database db, int version) async {
    await db.execute('''
            CREATE TABLE $tableLibros (
                $columnLibroId INTEGER PRIMARY KEY AUTOINCREMENT,
                $columnLibroNombre TEXT NOT NULL,
                $columnLibroHojas INTEGER NOT NULL,
                $columnLibroAutor TEXT NOT NULL
            )
        ''');

    await db.execute('''
            CREATE TABLE $tableCapitulos (
                $columnCapituloId INTEGER PRIMARY KEY AUTOINCREMENT,
                $columnCapituloLibroId INTEGER NOT NULL,
                $columnCapituloPersonaje TEXT NOT NULL,
                $columnCapituloFontSize INTEGER NOT NULL,
                $columnCapituloColor TEXT NOT NULL,
                $columnCapituloEditable INTEGER NOT NULL,
                $columnCapituloEliminar INTEGER NOT NULL,
                FOREIGN KEY ($columnCapituloLibroId)
                  REFERENCES $tableLibros ($columnLibroId) 
                  ON DELETE CASCADE
            )
        ''');

    await db.execute('''
            CREATE TABLE $tableHistorias (
                $columnHistoriaId INTEGER PRIMARY KEY AUTOINCREMENT,
                $columnHistoriaCapituloId INTEGER NOT NULL,
                $columnHistoriaTexto TEXT NOT NULL,
                FOREIGN KEY ($columnHistoriaCapituloId) 
                  REFERENCES $tableCapitulos ($columnCapituloId)
                  ON DELETE CASCADE
            )
        ''');
  }

  static Future<int> insertLibro(Map<String, dynamic> row) async {
    return await _db.insert(tableLibros, row);
  }

  static Future<int> insertCapitulo(Map<String, dynamic> row) async {
    return await _db.insert(tableCapitulos, row);
  }

  static Future<int> insertHistoria(Map<String, dynamic> row) async {
    return await _db.insert(tableHistorias, row);
  }

  static Future<void> clearAllData() async {
    await _db.delete(tableLibros);
  }

  static Future<int> queryRowCount(String table) async {
    final results = await _db.rawQuery('SELECT COUNT(*) FROM $table');
    return Sqflite.firstIntValue(results) ?? 0;
  }

  static Future<List<Map<String, dynamic>>> getAllHistoriasCompletas() async {
    // Para que regrese todas las historias completas con su formato
    // Primero se obtiene la informacion de todos los capitulos
    final List<Map<String, dynamic>> capitulos = await _db.query(
      tableCapitulos,
      columns: [
        columnCapituloId,
        columnCapituloFontSize,
        columnCapituloColor,
        columnCapituloEditable,
        columnCapituloEliminar,
      ],
      orderBy: '$columnCapituloId ASC',
    );

    // Ahora por cada capitulo se obtienen sus parrafos de la tabla historias
    final List<Map<String, dynamic>> historias = [];
    for (final capitulo in capitulos) {
      final int capituloId = capitulo[columnCapituloId] as int;
      final historiaData = await _db.query(
        tableHistorias,
        columns: [columnHistoriaTexto],
        where: '$columnHistoriaCapituloId = ?',
        whereArgs: [capituloId],
      );
      // Ahora se unen los parrafos para formar la historia completa
      final parrafos = historiaData
          .map((row) => row[columnHistoriaTexto] as String)
          .toList();
      final historiaCompleta = parrafos.join('\n');
      // Se envia de regreso la historia completa como una lista de capitulos y formatos
      historias.add({
        'id': capituloId,
        'historia': historiaCompleta,
        'font_size': capitulo[columnCapituloFontSize],
        'color': capitulo[columnCapituloColor],
        'editable': capitulo[columnCapituloEditable] == 1,
        'eliminar': capitulo[columnCapituloEliminar] == 1,
      });
    }

    return historias;
  }

  static Future<void> deleteCapitulo(int id) async {
    await _db.delete(
      tableCapitulos,
      where: '$columnCapituloId = ?',
      whereArgs: [id],
    );
  }

  static Future<void> updateCapitulo(int id, String historia) async {
    await _db.delete(
      tableHistorias,
      where: '$columnHistoriaCapituloId = ?',
      whereArgs: [id],
    );

    // al parecer ocupo esta funcion si o si, para que no añada saltos de linea cada vez que anexo otro capitulo
    final parrafos = historia.split('\n').where((p) => p.isNotEmpty).toList();
    for (final parrafo in parrafos) {
      await insertHistoria({
        columnHistoriaCapituloId: id,
        columnHistoriaTexto: parrafo,
      });
    }
  }
}
