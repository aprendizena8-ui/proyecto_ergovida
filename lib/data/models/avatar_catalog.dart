class AvatarOption {
  final String id;
  final String assetPath;

  const AvatarOption({
    required this.id,
    required this.assetPath,
  });
}

class AvatarCatalog {
  static const String defaultId = 'a01';

  static const List<AvatarOption> all = [
    AvatarOption(id: 'a01', assetPath: 'assets/images/avatares/a01.png'),
    AvatarOption(id: 'a02', assetPath: 'assets/images/avatares/a02.png'),
    AvatarOption(id: 'a03', assetPath: 'assets/images/avatares/a03.png'),
    AvatarOption(id: 'a04', assetPath: 'assets/images/avatares/a04.png'),
    AvatarOption(id: 'a05', assetPath: 'assets/images/avatares/a05.png'),
    AvatarOption(id: 'a06', assetPath: 'assets/images/avatares/a06.png'),
    AvatarOption(id: 'a07', assetPath: 'assets/images/avatares/a07.png'),
    AvatarOption(id: 'a08', assetPath: 'assets/images/avatares/a08.png'),
    AvatarOption(id: 'a09', assetPath: 'assets/images/avatares/a09.png'),
    AvatarOption(id: 'a10', assetPath: 'assets/images/avatares/a10.png'),
    AvatarOption(id: 'a11', assetPath: 'assets/images/avatares/a11.png'),
    AvatarOption(id: 'a12', assetPath: 'assets/images/avatares/a12.png'),
    AvatarOption(id: 'a13', assetPath: 'assets/images/avatares/a13.png'),
    AvatarOption(id: 'a14', assetPath: 'assets/images/avatares/a14.png'),
    AvatarOption(id: 'a15', assetPath: 'assets/images/avatares/a15.png'),
    AvatarOption(id: 'a16', assetPath: 'assets/images/avatares/a16.png'),
    AvatarOption(id: 'a17', assetPath: 'assets/images/avatares/a17.png'),
    AvatarOption(id: 'a18', assetPath: 'assets/images/avatares/a18.png'),
    AvatarOption(id: 'a19', assetPath: 'assets/images/avatares/a19.png'),
    AvatarOption(id: 'a20', assetPath: 'assets/images/avatares/a20.png'),
    AvatarOption(id: 'a21', assetPath: 'assets/images/avatares/a21.png'),
    AvatarOption(id: 'a22', assetPath: 'assets/images/avatares/a22.png'),
    AvatarOption(id: 'a23', assetPath: 'assets/images/avatares/a23.png'),
    AvatarOption(id: 'a24', assetPath: 'assets/images/avatares/a24.png'),
    AvatarOption(id: 'a25', assetPath: 'assets/images/avatares/a25.png'),
    AvatarOption(id: 'a26', assetPath: 'assets/images/avatares/a26.png'),
    AvatarOption(id: 'a27', assetPath: 'assets/images/avatares/a27.png'),
    AvatarOption(id: 'a28', assetPath: 'assets/images/avatares/a28.png'),
    AvatarOption(id: 'a29', assetPath: 'assets/images/avatares/a29.png'),
    AvatarOption(id: 'a30', assetPath: 'assets/images/avatares/a30.png'),
    AvatarOption(id: 'a31', assetPath: 'assets/images/avatares/a31.png'),
    AvatarOption(id: 'a32', assetPath: 'assets/images/avatares/a32.png'),
    AvatarOption(id: 'a33', assetPath: 'assets/images/avatares/a33.png'),
    AvatarOption(id: 'a34', assetPath: 'assets/images/avatares/a34.png'),
    AvatarOption(id: 'a35', assetPath: 'assets/images/avatares/a35.png'),
    AvatarOption(id: 'a36', assetPath: 'assets/images/avatares/a36.png'),
    AvatarOption(id: 'a37', assetPath: 'assets/images/avatares/a37.png'),
    AvatarOption(id: 'a38', assetPath: 'assets/images/avatares/a38.png'),
    AvatarOption(id: 'a39', assetPath: 'assets/images/avatares/a39.png'),
    AvatarOption(id: 'a40', assetPath: 'assets/images/avatares/a40.png'),
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
