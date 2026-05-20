import 'package:dio/dio.dart';
import 'package:food_run/network/api/dio_client.dart';
import 'package:retrofit/retrofit.dart';
import 'package:food_run/models/category.dart';
import 'package:food_run/models/product.dart';
import 'package:food_run/dto/category_dto.dart';
import 'package:food_run/dto/product_dto.dart';

part 'menu_api.g.dart';

@RestApi()
abstract class MenuApiClient {
  factory MenuApiClient(Dio dio, {String baseUrl}) = _MenuApiClient;

  @GET("/shops/{shopCode}/categories/")
  Future<dynamic> fetchCategoriesRaw(
    @Path("shopCode") String shopCode,
  );

  @GET("/shops/{shopCode}/products/")
  Future<dynamic> fetchCategoryProductsRaw(
    @Path("shopCode") String shopCode,
    @Query("category") int categoryId,
    @Query("tag") List<int> filterIds,
    @Query("available") String deliveryType,
  );

  @GET("/shops/{shopCode}/filters/")
  Future<dynamic> fetchFilters(@Path("shopCode") String shopCode);

  @GET("/shops/{shopCode}/products/{productId}/")
  Future<dynamic> fetchProductRaw(
    @Path("shopCode") String shopCode,
    @Path("productId") int productId,
    @Query("available") String deliveryType,
  );
}

class MenuApi {
  final MenuApiClient _client;

  MenuApi(Dio dio) : _client = MenuApiClient(dio);

  Future<List<Category>> fetchCategories(String shopCode) async {
    final response =
        await DioClient.runSafe(() => _client.fetchCategoriesRaw(shopCode));
    final results = response['results'] as List;
    return results
        .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  Future<List<Product>> fetchCategoryProducts(
    int categoryId,
    String shopCode,
    List<int> filterIds,
    String deliveryType,
  ) async {
    final response =
        await DioClient.runSafe(() => _client.fetchCategoryProductsRaw(
              shopCode,
              categoryId,
              filterIds,
              deliveryType,
            ));
    final results = response['results'] as List;
    return results
        .map((e) => ProductDto.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  Future<List<int>> fetchFilters(String shopCode) async {
    final response =
        await DioClient.runSafe(() => _client.fetchFilters(shopCode));
    return List<int>.from(response as List);
  }

  Future<Product?> fetchProduct(
      String shopCode, int productId, String deliveryType) async {
    try {
      final response = await DioClient.runSafe(() => _client.fetchProductRaw(
            shopCode,
            productId,
            deliveryType,
          ));
      return ProductDto.fromJson(response as Map<String, dynamic>).toEntity();
    } on Exception catch (_) {
      return null;
    }
  }
}
