class AvatarOption {
  final String id;
  final String emoji;

  const AvatarOption({required this.id, required this.emoji});
}

class AvatarCatalog {
  static const String defaultId = 'a01';

  static const List<AvatarOption> all = [
    AvatarOption(id: 'a01', emoji: '👨‍💻'),
    AvatarOption(id: 'a02', emoji: '👩‍💻'),
    AvatarOption(id: 'a03', emoji: '👨‍🔧'),
    AvatarOption(id: 'a04', emoji: '👩‍🔬'),
    AvatarOption(id: 'a05', emoji: '👨‍🎨'),
    AvatarOption(id: 'a06', emoji: '👩‍🎨'),
    AvatarOption(id: 'a07', emoji: '👨‍🚀'),
    AvatarOption(id: 'a08', emoji: '👩‍🚀'),
    AvatarOption(id: 'a09', emoji: '👨‍🏫'),
    AvatarOption(id: 'a10', emoji: '👩‍🏫'),
    AvatarOption(id: 'a11', emoji: '👨‍⚕️'),
    AvatarOption(id: 'a12', emoji: '👩‍⚕️'),
    AvatarOption(id: 'a13', emoji: '🧑‍🌾'),
    AvatarOption(id: 'a14', emoji: '🧑‍🍳'),
    AvatarOption(id: 'a15', emoji: '🧑‍🎤'),
    AvatarOption(id: 'a16', emoji: '🧑‍🚒'),
    AvatarOption(id: 'a17', emoji: '🕵️'),
    AvatarOption(id: 'a18', emoji: '💂'),
    AvatarOption(id: 'a19', emoji: '🦸'),
    AvatarOption(id: 'a20', emoji: '🦹'),
    AvatarOption(id: 'a21', emoji: '🧙'),
    AvatarOption(id: 'a22', emoji: '🧚'),
    AvatarOption(id: 'a23', emoji: '🧜'),
    AvatarOption(id: 'a24', emoji: '🧞'),
    AvatarOption(id: 'a25', emoji: '🐱'),
    AvatarOption(id: 'a26', emoji: '🐶'),
    AvatarOption(id: 'a27', emoji: '🐼'),
    AvatarOption(id: 'a28', emoji: '🦊'),
    AvatarOption(id: 'a29', emoji: '🐯'),
    AvatarOption(id: 'a30', emoji: '🐨'),
    AvatarOption(id: 'a31', emoji: '🐵'),
    AvatarOption(id: 'a32', emoji: '🦁'),
    AvatarOption(id: 'a33', emoji: '🐸'),
    AvatarOption(id: 'a34', emoji: '🐧'),
    AvatarOption(id: 'a35', emoji: '🦄'),
    AvatarOption(id: 'a36', emoji: '🐙'),
    AvatarOption(id: 'a37', emoji: '🐝'),
    AvatarOption(id: 'a38', emoji: '🦉'),
    AvatarOption(id: 'a39', emoji: '🐢'),
    AvatarOption(id: 'a40', emoji: '🐬'),
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
