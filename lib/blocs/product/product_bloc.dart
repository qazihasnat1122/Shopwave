import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/product.dart';
import '../../repositories/product_repository.dart';

// ─── EVENTS ──────────────────────────────────────────────────

abstract class ProductEvent extends Equatable {
  @override List<Object?> get props => [];
}

class ProductsLoaded extends ProductEvent {
  final String? category;
  final String? searchQuery;
  final String? sortBy;
  final double? minPrice, maxPrice;
  ProductsLoaded({this.category, this.searchQuery, this.sortBy, this.minPrice, this.maxPrice});
  @override List<Object?> get props => [category, searchQuery, sortBy];
}

class ProductsLoadedMore extends ProductEvent {}

class ProductDetailLoaded extends ProductEvent {
  final String productId;
  ProductDetailLoaded({required this.productId});
  @override List<Object?> get props => [productId];
}

class CategoryChanged extends ProductEvent {
  final String category;
  CategoryChanged({required this.category});
  @override List<Object?> get props => [category];
}

// ─── STATES ──────────────────────────────────────────────────

abstract class ProductState extends Equatable {
  @override List<Object?> get props => [];
}

class ProductInitial extends ProductState {}
class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<Product> products;
  final List<Product> featured;
  final List<String> categories;
  final String selectedCategory;
  final bool hasMore;

  ProductLoaded({
    required this.products,
    required this.featured,
    required this.categories,
    this.selectedCategory = 'All',
    this.hasMore = true,
  });

  @override List<Object?> get props => [products, selectedCategory];

  ProductLoaded copyWith({
    List<Product>? products, List<Product>? featured,
    List<String>? categories, String? selectedCategory, bool? hasMore,
  }) => ProductLoaded(
    products: products ?? this.products,
    featured: featured ?? this.featured,
    categories: categories ?? this.categories,
    selectedCategory: selectedCategory ?? this.selectedCategory,
    hasMore: hasMore ?? this.hasMore,
  );
}

class ProductDetailState extends ProductState {
  final Product product;
  final List<Product> related;
  final List<Map<String, dynamic>> reviews;

  ProductDetailState({required this.product, this.related = const [], this.reviews = const []});
  @override List<Object?> get props => [product];
}

class ProductError extends ProductState {
  final String message;
  ProductError({required this.message});
  @override List<Object?> get props => [message];
}

// ─── BLOC ─────────────────────────────────────────────────────

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository productRepository;

  ProductBloc({required this.productRepository}) : super(ProductInitial()) {
    on<ProductsLoaded>(_onProductsLoaded);
    on<CategoryChanged>(_onCategoryChanged);
    on<ProductDetailLoaded>(_onProductDetailLoaded);
  }

  Future<void> _onProductsLoaded(ProductsLoaded event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      final results = await Future.wait([
        productRepository.getProducts(
          category: event.category,
          searchQuery: event.searchQuery,
          sortBy: event.sortBy,
          minPrice: event.minPrice,
          maxPrice: event.maxPrice,
        ),
        productRepository.getFeaturedProducts(),
        productRepository.getCategories(),
      ]);

      emit(ProductLoaded(
        products: results[0] as List<Product>,
        featured: results[1] as List<Product>,
        categories: ['All', ...(results[2] as List<String>)],
      ));
    } catch (e) {
      emit(ProductError(message: 'Failed to load products: ${e.toString()}'));
    }
  }

  Future<void> _onCategoryChanged(CategoryChanged event, Emitter<ProductState> emit) async {
    if (state is ProductLoaded) {
      final current = state as ProductLoaded;
      emit(current.copyWith(selectedCategory: event.category));

      try {
        final products = await productRepository.getProducts(
          category: event.category == 'All' ? null : event.category,
        );
        emit(current.copyWith(products: products, selectedCategory: event.category));
      } catch (e) {
        emit(ProductError(message: e.toString()));
      }
    }
  }

  Future<void> _onProductDetailLoaded(ProductDetailLoaded event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      final product = await productRepository.getProductById(event.productId);
      final related = await productRepository.getRelatedProducts(product);
      final reviews = await productRepository.getReviews(event.productId);

      emit(ProductDetailState(product: product, related: related, reviews: reviews));
    } catch (e) {
      emit(ProductError(message: 'Product not found'));
    }
  }
}
