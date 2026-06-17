class KvkModel {
  final String name;
  final double distance;
  final String phone;
  final String address;

  const KvkModel({
    required this.name,
    required this.distance,
    required this.phone,
    required this.address,
  });

  factory KvkModel.fromJson(Map<String, dynamic> json) {
    return KvkModel(
      name: json['name'] as String? ?? 'KVK Center',
      distance: (json['distance'] as num? ?? json['distance_km'] as num? ?? 0.0).toDouble(),
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? json['location'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'distance': distance,
        'phone': phone,
        'address': address,
      };
}
