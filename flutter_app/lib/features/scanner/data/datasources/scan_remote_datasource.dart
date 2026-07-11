import 'package:code_card_ai/core/constants/api_constants.dart';
import 'package:code_card_ai/core/network/dio_client.dart';
import 'package:code_card_ai/features/scanner/data/models/scan_result_model.dart';

abstract class ScanRemoteDataSource {
  Future<ScanResultModel> scanProduct(String productId);
}

class ScanRemoteDataSourceImpl implements ScanRemoteDataSource {
  final DioClient client;

  ScanRemoteDataSourceImpl({required this.client});

  @override
  Future<ScanResultModel> scanProduct(String productId) async {
    try {
      final response = await client.get('${ApiConstants.scan}$productId');
      if (response.statusCode == 200) {
        return ScanResultModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to scanner API: $e');
    }
  }
}
