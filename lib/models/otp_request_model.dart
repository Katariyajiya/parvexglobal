class OtpRequestModel {
  final String email;

  OtpRequestModel({required this.email});

  Map<String, dynamic> toJson() {
    return {
      "email": email,
    };
  }
}