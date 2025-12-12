class UpdateOrderRequest {
  final String orderId;
  final String customerName;
  final String primaryPhone;
  final String? secondaryPhone;
  final String province;
  final String city;
  final String? notes;
  final bool isScheduled;
  final DateTime? scheduledDate;

  const UpdateOrderRequest({
    required this.orderId,
    required this.customerName,
    required this.primaryPhone,
    this.secondaryPhone,
    required this.province,
    required this.city,
    this.notes,
    required this.isScheduled,
    this.scheduledDate,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'customerName': customerName,
      'primaryPhone': primaryPhone,
      'secondaryPhone': secondaryPhone,
      'province': province,
      'city': city,
      'notes': notes,
    };

    if (isScheduled && scheduledDate != null) {
      data['scheduledDate'] = scheduledDate!.toIso8601String().split('T')[0];
    }

    return data;
  }
}
