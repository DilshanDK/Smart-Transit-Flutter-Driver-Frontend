class DriverProfile {
  final String id;
  final String fullName;
  final String email;
  final String driverId;
  final String? busRegistration;
  final String role;
  final bool isOnShift;

  const DriverProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.driverId,
    this.busRegistration,
    required this.role,
    required this.isOnShift,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? 'Driver',
      email: json['email'] ?? '',
      driverId: json['driverId'] ?? json['id'] ?? json['_id'] ?? '',
      busRegistration: json['busRegistration'] ?? json['currentBusRegistration'],
      role: json['role'] ?? 'driver',
      isOnShift: json['isOnShift'] ?? false,
    );
  }

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'D';
  }

  String get firstName => fullName.trim().split(' ').first;
}
