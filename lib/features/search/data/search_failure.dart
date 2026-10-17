import 'package:dio/dio.dart';

/// Why a search could not be answered, in the terms the screen explains it.
enum SearchFailureReason {
  offline,
  tooManyRequests,
  unavailable,
  notFound,
  unknown,
}

class SearchFailure implements Exception {
  final SearchFailureReason reason;

  const SearchFailure(this.reason);

  factory SearchFailure.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const SearchFailure(SearchFailureReason.offline);
      default:
        break;
    }
    return switch (error.response?.statusCode) {
      429 => const SearchFailure(SearchFailureReason.tooManyRequests),
      503 => const SearchFailure(SearchFailureReason.unavailable),
      404 => const SearchFailure(SearchFailureReason.notFound),
      _ => const SearchFailure(SearchFailureReason.unknown),
    };
  }

  @override
  String toString() => 'SearchFailure($reason)';
}
