import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/core.dart';

class FavoriteState {
  final List<String> favoriteBookIds;
  final bool isLoading;
  final String? error;

  const FavoriteState({
    this.favoriteBookIds = const [],
    this.isLoading = false,
    this.error,
  });

  FavoriteState copyWith({
    List<String>? favoriteBookIds,
    bool? isLoading,
    String? error,
  }) {
    return FavoriteState(
      favoriteBookIds: favoriteBookIds ?? this.favoriteBookIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool isFavorite(String bookId) => favoriteBookIds.contains(bookId);
}

class FavoriteNotifier extends Notifier<FavoriteState> {
  @override
  FavoriteState build() {
    return const FavoriteState();
  }

  Future<void> loadFavorites(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final favorites = await HiveDataService.instance.getUserFavorites(userId);
      state = state.copyWith(favoriteBookIds: favorites, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleFavorite(String userId, String bookId) async {
    try {
      final isFav = state.isFavorite(bookId);
      if (isFav) {
        await HiveDataService.instance.removeFavorite(userId, bookId);
        state = state.copyWith(
          favoriteBookIds: state.favoriteBookIds.where((id) => id != bookId).toList(),
        );
      } else {
        await HiveDataService.instance.addFavorite(userId, bookId);
        state = state.copyWith(
          favoriteBookIds: [...state.favoriteBookIds, bookId],
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final favoriteProvider = NotifierProvider<FavoriteNotifier, FavoriteState>(
  FavoriteNotifier.new,
);
