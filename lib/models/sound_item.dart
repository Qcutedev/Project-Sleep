class SoundItem {
  final String id;
  final String name;
  final String icon;       // emoji แทนไอคอน ง่ายและไม่ต้องพึ่งไฟล์รูป
  final String assetPath;  // สำหรับเสียงพื้นฐานที่ติดมากับแอป
  final String? filePath;  // สำหรับเสียงที่ผู้ใช้นำเข้าเอง
  final bool isImported;

  SoundItem({
    required this.id,
    required this.name,
    required this.icon,
    this.assetPath = '',
    this.filePath,
    this.isImported = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'filePath': filePath,
      };

  factory SoundItem.fromJson(Map<String, dynamic> json) => SoundItem(
        id: json['id'],
        name: json['name'],
        icon: json['icon'],
        filePath: json['filePath'],
        isImported: true,
      );
}