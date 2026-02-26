import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'auth_repository.dart';
import 'user_model.dart';

part 'auth_provider.g.dart';

@riverpod
class Auth extends _$Auth {
  @override
  Future<User?> build() async {
    return ref.read(authRepositoryProvider).getMe();
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    final result = await ref.read(authRepositoryProvider).login(username, password);
    if (result != null) {
      state = AsyncValue.data(result.user);
    } else {
      state = AsyncValue.error('Login failed', StackTrace.current);
    }
  }

  Future<void> register(String username, String password) async {
    state = const AsyncValue.loading();
    final result = await ref.read(authRepositoryProvider).register(username, password);
    if (result != null) {
      state = AsyncValue.data(result.user);
    } else {
      state = AsyncValue.error('Registration failed', StackTrace.current);
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(null);
  }
}
