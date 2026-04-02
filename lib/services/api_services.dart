import 'package:dio/dio.dart';

class ApiService {

  static final Dio dio = Dio(
  BaseOptions(
  baseUrl: "http://MarketWatch-env.eba-i9huczsw.eu-north-1.elasticbeanstalk.com/api/v1/",
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
  headers: {
  "Content-Type": "application/json",
  },
  )
  );
}