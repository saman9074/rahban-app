class Trip {
  final int id;
  final String status;
  final String? shareToken;
  final DateTime createdAt;
  final DateTime? completedAt;

  Trip({
    required this.id,
    required this.status,
    this.shareToken,
    required this.createdAt,
    this.completedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'unknown',
      shareToken: json['share_token'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
    );
  }
}