import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/models.dart';
import '../../repositories/cart_repository.dart';

// ─── EVENTS ──────────────────────────────────────────────────

abstract class CartEvent extends Equatable {
  @override List<Object?> get props => [];
}

class CartStarted extends CartEvent {
  final String userId;
  CartStarted({required this.userId});
  @override List<Object?> get props => [userId];
}

class CartItemAdded extends CartEvent {
  final String userId;
  final CartItem item;
  CartItemAdded({required this.userId, required this.item});
  @override List<Object?> get props => [item];
}

class CartItemQuantityUpdated extends CartEvent {
  final String userId, itemId;
  final int quantity;
  CartItemQuantityUpdated({required this.userId, required this.itemId, required this.quantity});
  @override List<Object?> get props => [itemId, quantity];
}

class CartItemRemoved extends CartEvent {
  final String userId, itemId;
  CartItemRemoved({required this.userId, required this.itemId});
  @override List<Object?> get props => [itemId];
}

class CartCleared extends CartEvent {
  final String userId;
  CartCleared({required this.userId});
}

class CartCouponApplied extends CartEvent {
  final String userId, couponCode;
  CartCouponApplied({required this.userId, required this.couponCode});
}

class CartUpdated extends CartEvent {
  final List<CartItem> items;
  CartUpdated({required this.items});
  @override List<Object?> get props => [items];
}

// ─── STATES ──────────────────────────────────────────────────

abstract class CartState extends Equatable {
  @override List<Object?> get props => [];
}

class CartInitial extends CartState {}
class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<CartItem> items;
  final String? couponCode;
  final double couponDiscount;

  CartLoaded({
    required this.items,
    this.couponCode,
    this.couponDiscount = 0,
  });

  double get subtotal => items.fold(0, (sum, i) => sum + i.total);
  double get shipping => subtotal > 50 ? 0 : 9.99;
  double get total => subtotal + shipping - couponDiscount;
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  @override List<Object?> get props => [items, couponCode, couponDiscount];
}

class CartError extends CartState {
  final String message;
  CartError({required this.message});
  @override List<Object?> get props => [message];
}

class CartOperationSuccess extends CartState {
  final String message;
  final CartLoaded cartState;
  CartOperationSuccess({required this.message, required this.cartState});
  @override List<Object?> get props => [message];
}

// ─── BLOC ─────────────────────────────────────────────────────

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository cartRepository;
  StreamSubscription<List<CartItem>>? _cartSubscription;

  CartBloc({required this.cartRepository}) : super(CartInitial()) {
    on<CartStarted>(_onStarted);
    on<CartUpdated>(_onUpdated);
    on<CartItemAdded>(_onItemAdded);
    on<CartItemQuantityUpdated>(_onQuantityUpdated);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartCleared>(_onCleared);
    on<CartCouponApplied>(_onCouponApplied);
  }

  void _onStarted(CartStarted event, Emitter<CartState> emit) {
    emit(CartLoading());
    _cartSubscription?.cancel();
    _cartSubscription = cartRepository.watchCart(event.userId).listen(
      (items) => add(CartUpdated(items: items)),
      onError: (e) => emit(CartError(message: e.toString())),
    );
  }

  void _onUpdated(CartUpdated event, Emitter<CartState> emit) {
    final current = state is CartLoaded ? state as CartLoaded : null;
    emit(CartLoaded(
      items: event.items,
      couponCode: current?.couponCode,
      couponDiscount: current?.couponDiscount ?? 0,
    ));
  }

  Future<void> _onItemAdded(CartItemAdded event, Emitter<CartState> emit) async {
    try {
      await cartRepository.addItem(event.userId, event.item);
    } catch (e) {
      emit(CartError(message: 'Could not add item: ${e.toString()}'));
    }
  }

  Future<void> _onQuantityUpdated(CartItemQuantityUpdated event, Emitter<CartState> emit) async {
    try {
      await cartRepository.updateQuantity(event.userId, event.itemId, event.quantity);
    } catch (e) {
      emit(CartError(message: 'Could not update quantity'));
    }
  }

  Future<void> _onItemRemoved(CartItemRemoved event, Emitter<CartState> emit) async {
    try {
      await cartRepository.removeItem(event.userId, event.itemId);
    } catch (e) {
      emit(CartError(message: 'Could not remove item'));
    }
  }

  Future<void> _onCleared(CartCleared event, Emitter<CartState> emit) async {
    await cartRepository.clearCart(event.userId);
  }

  Future<void> _onCouponApplied(CartCouponApplied event, Emitter<CartState> emit) async {
    try {
      await cartRepository.applyCoupon(event.userId, event.couponCode);
    } catch (e) {
      emit(CartError(message: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _cartSubscription?.cancel();
    return super.close();
  }
}
