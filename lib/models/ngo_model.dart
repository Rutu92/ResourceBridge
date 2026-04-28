class NGOModel {
  final String id;
  final String name;
  final String registrationNumber;
  final String contactPerson;
  final String email;
  final String phone;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> acceptedCategories;
  final List<String> activeRequestIds;
  final int totalItemsReceived;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;

  NGOModel({
    required this.id,
    required this.name,
    required this.registrationNumber,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.acceptedCategories,
    this.activeRequestIds = const [],
    this.totalItemsReceived = 0,
    this.isActive = true,
    this.isVerified = false,
    required this.createdAt,
  });

  double distanceTo(double lat, double lng) {
    final dlat = latitude - lat;
    final dlng = longitude - lng;
    return (dlat * dlat + dlng * dlng);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'registrationNumber': registrationNumber,
      'contactPerson': contactPerson,
      'email': email,
      'phone': phone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'acceptedCategories': acceptedCategories,
      'activeRequestIds': activeRequestIds,
      'totalItemsReceived': totalItemsReceived,
      'isActive': isActive,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NGOModel.fromMap(Map<String, dynamic> map) {
    return NGOModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      registrationNumber: map['registrationNumber'] ?? '',
      contactPerson: map['contactPerson'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      acceptedCategories: List<String>.from(map['acceptedCategories'] ?? []),
      activeRequestIds: List<String>.from(map['activeRequestIds'] ?? []),
      totalItemsReceived: map['totalItemsReceived'] ?? 0,
      isActive: map['isActive'] ?? true,
      isVerified: map['isVerified'] ?? false,
      createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
