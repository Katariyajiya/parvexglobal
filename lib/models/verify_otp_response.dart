class VerifyOtpResponse {
  final String data;
  final String message;
  final String token;
  final int? userId;

  VerifyOtpResponse({
    required this.data,
    required this.message,
    required this.token,
    required this.userId,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      data: json['data'] ?? '',
      message: json['message'] ?? '',
      token: json['token'] ?? '',
      userId: json['user']?['id'],
    );
  }


}