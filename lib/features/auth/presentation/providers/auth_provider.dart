import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hop_eir/features/auth/domain/entities/user.dart';
import 'package:hop_eir/features/auth/domain/usecases/create_profile.dart';
import 'package:hop_eir/features/auth/domain/usecases/get_profile_by_id.dart';
import 'package:hop_eir/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:hop_eir/features/auth/domain/usecases/login_usecase.dart';
import 'package:hop_eir/features/auth/domain/usecases/logout_usecase.dart';
import 'package:hop_eir/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:hop_eir/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:hop_eir/features/auth/presentation/state/auth_notifier.dart';
import 'package:hop_eir/features/auth/presentation/state/auth_state.dart';

final signUpusecaseProvider = Provider<SignUpUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignUpUsecase(repository);
});

final loginUsecaseProvider = Provider<LoginUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUsecase(repository);
});

final createProfileUsecase = Provider<CreateProfile>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return CreateProfile(repository);
});

final getProfileUseCaseProvider = Provider<GetProfileUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetProfileUsecase(repository);
});

final logoutUsecaseProvider = Provider<LogoutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogoutUseCase(repository);
});

final getUserByIdProvider = Provider<GetProfileById>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetProfileById(repository);
});

final getUserByIdProviders = FutureProvider.family<User?, String>((
  ref,
  userId,
) async {
  final authNotifier = ref.read(authNotifierProvider.notifier);
  return await authNotifier.getUserByuserId(userId);
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier(
    getProfileById: ref.watch(getUserByIdProvider),
    signUpUsecase: ref.watch(signUpusecaseProvider),
    loginUsecase: ref.watch(loginUsecaseProvider),
    createProfileUsecase: ref.watch(createProfileUsecase),
    getProfileUseCase: ref.watch(getProfileUseCaseProvider),
    logoutUseCase: ref.watch(logoutUsecaseProvider),
  );
});
