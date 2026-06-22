import 'package:dio/dio.dart';

class ApiService {

  static final Dio dio = Dio(
  BaseOptions(
  baseUrl: "http://35.154.42.122:5001/api/v1/",
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
  headers: {
  "Content-Type": "application/json",
  },
  )
  );
}