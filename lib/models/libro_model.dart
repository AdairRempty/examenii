class Libro {
  // Modelo de la base de datos y sus datos
  final String nomLibro;
  final int cantidadHojas;
  final String autor;
  final List<Capitulo> capitulos;

  Libro({
    required this.nomLibro,
    required this.cantidadHojas,
    required this.autor,
    required this.capitulos,
  });

  factory Libro.fromJson(Map<String, dynamic> json) {
    var capitulosList = json['capitulos'] as List? ?? [];
    List<Capitulo> capitulos = capitulosList.map((c) => Capitulo.fromJson(c as Map<String, dynamic>)).toList();

    return Libro(
      nomLibro: (json['nom_libro'] ?? '').toString(),
      cantidadHojas: (json['cantidad_hojas'] ?? 0) as int,
      autor: (json['autor'] ?? '').toString(),
      capitulos: capitulos,
    );
  }
}

class Capitulo {
  final String personaje;
  final Instrucciones instrucciones;
  final List<String> historia;

  Capitulo({
    required this.personaje,
    required this.instrucciones,
    required this.historia,
  });

  factory Capitulo.fromJson(Map<String, dynamic> json) {
    var historiaList = json['historia'] as List? ?? [];
    List<String> historias = historiaList.map((h) => h.toString()).toList();

    var instruccionesJson = json['instrucciones'] as Map? ?? {};

    return Capitulo(
      personaje: (json['personaje'] ?? '').toString(),
      instrucciones: Instrucciones.fromJson(instruccionesJson as Map<String, dynamic>),
      historia: historias,
    );
  }
}

class Instrucciones {
  final int fontSize;
  final String color;
  final Acciones acciones;

  Instrucciones({
    required this.fontSize,
    required this.color,
    required this.acciones,
  });

  factory Instrucciones.fromJson(Map<String, dynamic> json) {
    var accionesJson = json['acciones'] as Map? ?? {};
    return Instrucciones(
      fontSize: (json['font_size'] ?? 0) as int,
      color: (json['color'] ?? '').toString(),
      acciones: Acciones.fromJson(accionesJson as Map<String, dynamic>),
    );
  }
}

class Acciones {
  final bool editable;
  final bool eliminar;

  Acciones({required this.editable, required this.eliminar});

  factory Acciones.fromJson(Map<String, dynamic> json) {
    bool siNoABool(dynamic v) {
      return v?.toString().toLowerCase().trim() == 'si';
    }

    return Acciones(
      editable: siNoABool(json['editable']),
      eliminar: siNoABool(json['eliminar']),
    );
  }
}
