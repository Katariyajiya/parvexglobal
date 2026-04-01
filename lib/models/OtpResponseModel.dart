class OtpResponseModel {
  final String message;

  OtpResponseModel({required this.message});

  factory OtpResponseModel.fromJson(Map<String, dynamic> json) {
    return OtpResponseModel(
      message: json['message'] ?? '',
    );
  }
}