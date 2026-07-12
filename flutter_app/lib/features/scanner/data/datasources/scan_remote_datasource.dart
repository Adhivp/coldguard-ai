import 'package:dio/dio.dart';
import 'package:code_card_ai/core/constants/api_constants.dart';
import 'package:code_card_ai/core/network/dio_client.dart';
import 'package:code_card_ai/features/scanner/data/models/scan_result_model.dart';
import 'package:code_card_ai/features/scanner/data/models/telemetry_graph_model.dart';
import 'package:code_card_ai/features/scanner/data/models/product_summary_model.dart';

abstract class ScanRemoteDataSource {
  Future<ScanResultModel> scanProduct(String productId);
  Future<TelemetryGraphModel> getProductGraphData({
    required String productId,
    required String zoom,
    String? date,
    int? hour,
    int? minute,
    int page = 1,
    int pageSize = 30,
  });
  Future<List<ProductSummaryModel>> getAllProducts();
}

class ScanRemoteDataSourceImpl implements ScanRemoteDataSource {
  final DioClient client;

  ScanRemoteDataSourceImpl({required this.client});

  @override
  Future<ScanResultModel> scanProduct(String productId) async {
    try {
      // Fetch scan telemetry and product catalog in parallel
      final results = await Future.wait([
        client.get('${ApiConstants.scan}$productId'),
        client.get('/products'),
      ]);

      final scanResponse = results[0];
      final productsResponse = results[1];

      if (scanResponse.statusCode == 200) {
        final scanData = Map<String, dynamic>.from(
          scanResponse.data as Map<String, dynamic>,
        );

        // Merge product metadata from the catalog into the scan data
        if (productsResponse.statusCode == 200) {
          final productsList = productsResponse.data as List? ?? [];
          for (final p in productsList) {
            final product = p as Map<String, dynamic>;
            if (product['product_id'] == productId) {
              // Add catalog fields that the /scan endpoint doesn't include
              scanData['name'] ??= product['name'];
              scanData['category'] ??= product['category'];
              scanData['manufacturer'] ??= product['manufacturer'];
              scanData['batch_number'] ??= product['batch_number'];
              scanData['storage_req_min_c'] ??= product['storage_req_min_c'];
              scanData['storage_req_max_c'] ??= product['storage_req_max_c'];
              scanData['manufactured_at'] ??= product['manufactured_at'];
              scanData['expires_at'] ??= product['expires_at'];
              scanData['location'] ??= product['location'];
              break;
            }
          }
        }

        return ScanResultModel.fromJson(scanData);
      } else {
        throw Exception('Server returned status code: ${scanResponse.statusCode}');
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        throw Exception('404');
      }
      throw Exception('Failed to connect to scanner API: $e');
    }
  }

  @override
  Future<TelemetryGraphModel> getProductGraphData({
    required String productId,
    required String zoom,
    String? date,
    int? hour,
    int? minute,
    int page = 1,
    int pageSize = 30,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'zoom': zoom,
        'page': page,
        'page_size': pageSize,
      };
      if (date != null) queryParams['date'] = date;
      if (hour != null) queryParams['hour'] = hour;
      if (minute != null) queryParams['minute'] = minute;

      final response = await client.get(
        '/product/$productId/graph',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        return TelemetryGraphModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        throw Exception('404');
      }
      throw Exception('Failed to fetch telemetry graph data: $e');
    }
  }

  @override
  Future<List<ProductSummaryModel>> getAllProducts() async {
    try {
      final response = await client.get('/products');
      if (response.statusCode == 200) {
        final list = response.data as List?;
        return list
                ?.map(
                  (e) =>
                      ProductSummaryModel.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [];
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        throw Exception('404');
      }
      throw Exception('Failed to fetch products: $e');
    }
  }
}
