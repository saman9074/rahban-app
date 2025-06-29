class Guardian {
  final int id;
  final String name;
  final String phoneNumber;
  final bool isDefault;

  Guardian({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.isDefault,
  });

  factory Guardian.fromJson(Map<String, dynamic> json) {
    return Guardian(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      isDefault: json['is_default'] == true || json['is_default'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone_number': phoneNumber,
  };
}
