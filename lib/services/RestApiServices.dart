import 'package:dio/dio.dart';

import '../models/OtpResponseModel.dart';
import '../models/otp_request_model.dart';
import '../models/search_instrument_model.dart';
import '../models/verify_otp_request.dart';
import '../models/verify_otp_response.dart';
import '../utils/user_session.dart';
import 'api_services.dart';
import 'package:dio/dio.dart';

import '../models/OtpResponseModel.dart';
import '../models/otp_request_model.dart';
import 'api_services.dart';

import 'package:dio/dio.dart';

class RestApiService {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: "http://MarketWatch-env.eba-i9huczsw.eu-north-1.elasticbeanstalk.com", // update if needed
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        "Content-Type": "application/json",
      },
    ),
  )..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        print("➡️ REQUEST");
        print("URL: ${options.baseUrl}${options.path}");
        print("METHOD: ${options.method}");
        print("HEADERS: ${options.headers}");
        print("BODY: ${options.data}");
        return handler.next(options);
      },

      onResponse: (response, handler) {
        print("✅ RESPONSE");
        print("STATUS: ${response.statusCode}");
        print("DATA: ${response.data}");
        return handler.next(response);
      },

      onError: (DioException e, handler) {
        print("❌ ERROR");
        print("MESSAGE: ${e.message}");
        print("STATUS: ${e.response?.statusCode}");
        print("DATA: ${e.response?.data}");

        return handler.next(e);
      },
    ),
  );

  Future<OtpResponseModel> requestOtp(OtpRequestModel request) async {
    try {
      final response = await dio.post(
        "/api/v1/auth/request-otp",
        data: request.toJson(),
      );

      return OtpResponseModel.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to request OTP: $e");
    }
  }
  Future<VerifyOtpResponse> verifyOtp(VerifyOtpRequest request) async {
    try {
      final response = await dio.post(
        "/api/v1/auth/verify-otp",
        data: request.toJson(),
      );

      return VerifyOtpResponse.fromJson(response.data);

    } on DioException catch (e) {
      final errorMessage =
          e.response?.data['message'] ??
              e.response?.data.toString() ??
              "Verification failed";

      throw Exception(errorMessage);
    }
  }
  Future<List<SearchInstrumentModel>> searchInstruments({
    required String query,
    required String exchange,
  }) async {
    try {
      print("exchange "+ exchange);
      final response = await dio.get(
        "/api/v1/instruments/search",
        queryParameters: {
          "exchange": exchange == 'All'? '' : exchange,
          "query": query,
        },
        options: Options(
          headers: {
            "userId": 3,
          },
        ),
      );

      final List data = response.data;

      return data.map((e) => SearchInstrumentModel.fromJson(e)).toList();

    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? "Search failed",
      );
    }
  }

  Future<bool> addToWatchlist({
    required int instrumentId,
  }) async {
    print("Request reached to api");
    try {
      final response = await dio.post(
        '/api/v1/watchlist',
        data: {
          "instrumentId": instrumentId,
        },
        options: Options(
          headers: {
            "userId":3,
            "Content-Type": "application/json",
          },
        ),
      );

      return response.statusCode == 200 ||
          response.statusCode == 201;

    } on DioException catch (e) {

      final message = e.response?.data['message'];

      /// 🔥 ADD THIS BLOCK HERE
      if (message == "Symbol already in watchlist") {
        return true; // treat as success
      }

      print("❌ Add error => ${e.response?.data}");
      return false;
    }
  }

  Future<bool> removeFromWatchlist({
    required int instrumentId,
  }) async {
    try {
      final response = await dio.delete(
        '/api/v1/watchlist/$instrumentId',
        options: Options(
          headers: {
            "userId": 3,
            "Content-Type": "application/json",
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Remove watchlist error: $e");
      return false;
    }
  }
}

/*
* ticker subscribes only once per token
unlimited users can watch same token
memory usage is 10x lower
ticks are O(1) broadcast
*
* */