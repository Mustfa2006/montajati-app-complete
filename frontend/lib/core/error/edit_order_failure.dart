enum EditOrderErrorType { network, validation, unauthorized, notFound, unknown }

class EditOrderFailure {
  final EditOrderErrorType type;
  final String message;

  const EditOrderFailure({required this.type, required this.message});

  factory EditOrderFailure.network(String message) =>
      EditOrderFailure(type: EditOrderErrorType.network, message: message);

  factory EditOrderFailure.validation(String message) =>
      EditOrderFailure(type: EditOrderErrorType.validation, message: message);

  factory EditOrderFailure.unknown(String message) =>
      EditOrderFailure(type: EditOrderErrorType.unknown, message: message);

  @override
  String toString() => message;
}
