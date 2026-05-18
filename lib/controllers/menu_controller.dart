import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:food_run/controllers/order_controller.dart';
import 'package:food_run/controllers/settings_controller.dart';
import 'package:food_run/models/category.dart';
import 'package:food_run/models/product.dart';
import 'package:food_run/network/api_exception.dart';
import 'package:food_run/network/apis.dart';

class MenuController extends GetxController {
  final menuScrollController = ScrollController();

  List<Category> categoriesList = [];
  List<ProductListForMenu> allProductsList = [];

  bool isMenuLoading = false;
  bool areCategoriesLoading = false;

  int selectedCategoryIndex = 0;

  List<int> tabIndexes = [];

  List<int> selectedFiltersIdList = [];
  List<int> selectedFiltersIndexList = [];

  List<int> emptyCategotyIndexes = [];

  Future<void> init() async {
    final shopCode = _currentShopCode();
    await fetchMenuForShop(shopCode);
  }

  String _currentShopCode() {
    return Get.find<SettingsController>().currentShopCode ?? 'main';
  }

  void generateTabIndexes() {
    tabIndexes = List<int>.generate(categoriesList.length, (i) => i);
  }

  void addFilter(int index, int filterId) {
    selectedFiltersIndexList.add(index);
    selectedFiltersIdList.add(filterId);
    update(['filters']);
    update(['products']);
  }

  void removeFilter(int index, int filterId) {
    selectedFiltersIndexList.remove(index);
    selectedFiltersIdList.remove(filterId);
    update(['filters']);
    update(['products']);
  }

  void removeAllFilters() {
    selectedFiltersIndexList.clear();
    selectedFiltersIdList.clear();
    update(['filters']);
    update(['products']);
  }

  // Загружает фильтры для указанного магазина
  Future<void> fetchFilters(String shopCode) async {
    try {
      final shopCode = _currentShopCode();

      await Api().fetchFilters(shopCode);
      update(['filters']);
    } on Exception catch (_) {
      return;
    }
  }

  Future<void> changeCategory(int index) async {
    selectedCategoryIndex = index;
    update(['cats']);
  }

  void changeMenuLoadingStatus(bool isLoaing) {
    isMenuLoading = isLoaing;
    update(['products']);
  }

  void changeCategoriesLoadingStatus(bool isLoaing) {
    areCategoriesLoading = isLoaing;
    update(['cats']);
  }

  Future<void> jumpToCategory(int categoryId) async {
    final idx = categoriesList.indexWhere((c) => c.id == categoryId);
    if (idx == -1) return;

    await changeCategory(idx);

    // прокручиваем дважды, иначе иногда список не докручивает до нужной позиции
    for (int i = 0; i < 2; i++) {
      await menuScrollController.animateTo(
        idx * 300.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> fetchMenuForShop(String shopCode) async {
    changeCategoriesLoadingStatus(true);
    final categories = await _fetchCategories(shopCode);
    changeCategoriesLoadingStatus(false);

    if (categories.isEmpty) return;

    await fetchAllCategoryProducts(shopCode, categories);
  }

  Future<List<Category>> _fetchCategories(String shopCode) async {
    try {
      final categories = await Api().fetchCategories(shopCode);
      categoriesList
        ..clear()
        ..addAll(categories);

// убрали 12.11.2024 (сезонное меню, вернуть к лету)
      // final seasonalCategory = Category(id: 0, name: 'Сезонное', image: null);
      // categoriesList.insert(0, seasonalCategory);

      changeCategory(0);
      generateTabIndexes();
      return categories;
    } on Exception catch (_) {
      return [];
    }
  }

  Future<void> fetchAllCategoryProducts(
      String shopCode, List<Category> categories) async {
    try {
      final proxyList = <ProductListForMenu>[];

      changeMenuLoadingStatus(true);

      for (int i = 0; i < categories.length; i++) {
        final products = await _fetchCategoryProducts(
          shopCode,
          categoryId: categories[i].id,
        );

        proxyList.add(ProductListForMenu(shopCode, products, categories[i].id));

        final currentShop = _currentShopCode();
        if (currentShop != proxyList.first.shopCode) continue;

        allProductsList
          ..clear()
          ..addAll(proxyList);

        changeMenuLoadingStatus(false);
        update(['cats']);
        Get.find<OrderController>().refreshLeftovers();
      }
    } on Exception catch (_) {
      allProductsList.clear();
      changeMenuLoadingStatus(false);
    }
  }

  Future<List<Product>> _fetchCategoryProducts(
    String shopCode, {
    required int categoryId,
  }) async {
    try {
      return await Api().fetchCategoryProducts(
        categoryId,
        shopCode,
        selectedFiltersIdList,
        'by_pickup',
      );
    } on ClientErrorException catch (_) {
      return [];
    } on Exception catch (_) {
      return [];
    }
  }

  void buildEmptyCategoryIndexes() {
    emptyCategotyIndexes.clear();
    for (int i = 0; i < allProductsList.length; i++) {
      if (allProductsList[i].productList.isNotEmpty) continue;
      emptyCategotyIndexes.add(i);
    }
  }

  @override
  void onClose() {
    menuScrollController.dispose();
    super.onClose();
  }
}

class ProductListForMenu {
  final String shopCode;
  final List<Product> productList;
  final int categoryId;

  const ProductListForMenu(this.shopCode, this.productList, this.categoryId);
}
