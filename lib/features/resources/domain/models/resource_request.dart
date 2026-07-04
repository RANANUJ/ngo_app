class ResourceRequest {
  final String id;
  final String resourceId;
  final String? resourceName;
  final String? requestingNgoId;
  final String? ownerNgoId;
  final String? requesterId;
  final String? requesterEmail;
  final int quantity;
  final String? purpose;
  final String message;
  final String status;
  final DateTime createdAt;

  ResourceRequest({
    required this.id,
    required this.resourceId,
    this.resourceName,
    this.requestingNgoId,
    this.ownerNgoId,
    this.requesterId,
    this.requesterEmail,
    required this.quantity,
    this.purpose,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory ResourceRequest.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value.runtimeType.toString() == 'Timestamp') {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      if (value is DateTime) {
        return value;
      }
      return DateTime.now();
    }

    return ResourceRequest(
      id: id,
      resourceId: map['resourceId'] ?? '',
      resourceName: map['resourceName'] ?? map['resourceTitle'],
      requestingNgoId: map['requestingNgoId'],
      ownerNgoId: map['ownerNgoId'],
      requesterId: map['requesterId'],
      requesterEmail: map['requesterEmail'],
      quantity: (map['quantity'] ?? map['quantityRequested'] ?? 0).toInt(),
      purpose: map['purpose'],
      message: map['message'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'resourceId': resourceId,
    if (resourceName != null) 'resourceName': resourceName,
    if (requestingNgoId != null) 'requestingNgoId': requestingNgoId,
    if (ownerNgoId != null) 'ownerNgoId': ownerNgoId,
    if (requesterId != null) 'requesterId': requesterId,
    if (requesterEmail != null) 'requesterEmail': requesterEmail,
    'quantity': quantity,
    if (purpose != null) 'purpose': purpose,
    'message': message,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };
}
