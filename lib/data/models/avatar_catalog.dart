class AvatarOption {
  final String id;
  final String seed;
  final String style;

  const AvatarOption({
    required this.id,
    required this.seed,
    required this.style,
  });

  String get imageUrl =>
      'https://api.dicebear.com/9.x/$style/png?seed=$seed&size=256&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf';
}

class AvatarCatalog {
  static const String defaultId = 'a01';

  static const List<AvatarOption> all = [
    // Estilo Lorelei (Anime moderno)
    AvatarOption(id: 'a01', seed: 'Felix', style: 'lorelei'),
    AvatarOption(id: 'a02', seed: 'Aneka', style: 'lorelei'),
    AvatarOption(id: 'a03', seed: 'Jasper', style: 'lorelei'),
    AvatarOption(id: 'a04', seed: 'Luna', style: 'lorelei'),
    AvatarOption(id: 'a05', seed: 'Oliver', style: 'lorelei'),
    AvatarOption(id: 'a06', seed: 'Mia', style: 'lorelei'),
    AvatarOption(id: 'a07', seed: 'Leo', style: 'lorelei'),
    AvatarOption(id: 'a08', seed: 'Sofia', style: 'lorelei'),
    AvatarOption(id: 'a09', seed: 'Mateo', style: 'lorelei'),
    AvatarOption(id: 'a10', seed: 'Valentina', style: 'lorelei'),

    // Estilo Adventurer (3D/Caricatura)
    AvatarOption(id: 'a11', seed: 'Alexander', style: 'adventurer'),
    AvatarOption(id: 'a12', seed: 'Isabella', style: 'adventurer'),
    AvatarOption(id: 'a13', seed: 'Daniel', style: 'adventurer'),
    AvatarOption(id: 'a14', seed: 'Camila', style: 'adventurer'),
    AvatarOption(id: 'a15', seed: 'Gabriel', style: 'adventurer'),
    AvatarOption(id: 'a16', seed: 'Valeria', style: 'adventurer'),
    AvatarOption(id: 'a17', seed: 'Samuel', style: 'adventurer'),
    AvatarOption(id: 'a18', seed: 'Mariana', style: 'adventurer'),
    AvatarOption(id: 'a19', seed: 'David', style: 'adventurer'),
    AvatarOption(id: 'a20', seed: 'Lucia', style: 'adventurer'),

    AvatarOption(id: 'a21', seed: 'Elena', style: 'lorelei'),
    AvatarOption(id: 'a22', seed: 'Pablo', style: 'lorelei'),
    AvatarOption(id: 'a23', seed: 'Carmen', style: 'lorelei'),
    AvatarOption(id: 'a24', seed: 'Andres', style: 'lorelei'),
    AvatarOption(id: 'a25', seed: 'Natalia', style: 'lorelei'),
    AvatarOption(id: 'a26', seed: 'Diego', style: 'lorelei'),
    AvatarOption(id: 'a27', seed: 'Paula', style: 'lorelei'),
    AvatarOption(id: 'a28', seed: 'Javier', style: 'lorelei'),
    AvatarOption(id: 'a29', seed: 'Sara', style: 'lorelei'),
    AvatarOption(id: 'a30', seed: 'Carlos', style: 'lorelei'),

    AvatarOption(id: 'a31', seed: 'Felipe', style: 'adventurer'),
    AvatarOption(id: 'a32', seed: 'Daniela', style: 'adventurer'),
    AvatarOption(id: 'a33', seed: 'Santiago', style: 'adventurer'),
    AvatarOption(id: 'a34', seed: 'Mariana', style: 'adventurer'),
    AvatarOption(id: 'a35', seed: 'Sebastian', style: 'adventurer'),
    AvatarOption(id: 'a36', seed: 'Juliana', style: 'adventurer'),
    AvatarOption(id: 'a37', seed: 'Alejandro', style: 'adventurer'),
    AvatarOption(id: 'a38', seed: 'Catalina', style: 'adventurer'),
    AvatarOption(id: 'a39', seed: 'Nicolas', style: 'adventurer'),
    AvatarOption(id: 'a40', seed: 'Gabriela', style: 'adventurer'),
  ];

  static AvatarOption byId(String? id) {
    final buscado = (id ?? '').trim();
    return all.firstWhere(
      (avatar) => avatar.id == buscado,
      orElse: () => all.first,
    );
  }

  static bool isValid(String? id) {
    final buscado = (id ?? '').trim();
    return buscado.isNotEmpty && all.any((avatar) => avatar.id == buscado);
  }
}
