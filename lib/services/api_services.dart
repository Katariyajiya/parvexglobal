import 'package:dio/dio.dart';

class ApiService {

  static final Dio dio = Dio(
  BaseOptions(
  baseUrl: "http://192.168.1.4:5001/api/v1/",
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
  headers: {
  "Content-Type": "application/json",
  },
  )
  );
}