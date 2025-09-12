// ignore_for_file: unnecessary_null_comparison, avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hop_eir/features/auth/data/models/user_model.dart';
import 'package:hop_eir/features/auth/domain/entities/user.dart';
import 'package:hop_eir/features/auth/domain/usecases/create_profile.dart';
import 'package:hop_eir/features/auth/domain/usecases/get_profile_by_id.dart';
import 'package:hop_eir/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:hop_eir/features/auth/domain/usecases/login_usecase.dart';
import 'package:hop_eir/features/auth/domain/usecases/logout_usecase.dart';
import 'package:hop_eir/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:hop_eir/features/auth/presentation/pages/first_last_name_screen.dart';
import 'package:hop_eir/features/auth/presentation/pages/login_screen.dart';
import 'package:hop_eir/features/auth/presentation/state/auth_state.dart';
import 'package:hop_eir/features/rides/presentation/widgets/message_banner.dart';
import 'package:hop_eir/features/vehicles/presentation/provider/vehicle_providers.dart';
import 'package:hop_eir/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final SignUpUsecase signUpUsecase;
  final LoginUsecase loginUsecase;
  final CreateProfile createProfileUsecase;
  final GetProfileUsecase getProfileUseCase;
  final LogoutUseCase logoutUseCase;
  final GetProfileById getProfileById;

  AuthNotifier({
    required this.getProfileById,
    required this.getProfileUseCase,
    required this.logoutUseCase,
    required this.signUpUsecase,
    required this.loginUsecase,
    required this.createProfileUsecase,
  }) : super(AuthState.initial());

  Future<void> checkLoginStatus(
    String email,
    String password,
    BuildContext context,
  ) async {
    print('🔍 Checking login status for email: $email');
    print('🔍 Checking login status for password: $password');

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Optional: Validate credentials by logging in silently
      final loginResponse = await loginUsecase(
        email: email,
        password: password,
      );

      if (loginResponse == null || loginResponse['status'] != "OK") {
        print("❌ Invalid credentials or session expired.");

        state = state.copyWith(
          isLoading: false,
          errorMessage: "Session expired or invalid credentials.",
        );
        return;
      }

      // Get user profile
      final user = await getProfileUseCase(email: email);

      print("👤 Fetched user ID: ${user?.userId}");

      state = state.copyWith(isLoading: false);

      if (user!.userId.isEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }

      if (user != null &&
          user.userId != null &&
          user.userId.isNotEmpty &&
          user.firstname != null &&
          user.firstname.isNotEmpty) {
        // Profile is complete, go to main screen
        state = state.copyWith(user: user);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          }
        });
      } else {
        // Incomplete profile, go to name input screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const FirstLastNameScreen()),
            );
          }
        });
      }
    } catch (e, stacktrace) {
      print("🚨 Error while checking login status: $e");
      print(stacktrace);
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Something went wrong while checking login status.",
      );
    }
  }

  Future<void> logout(WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    await prefs.remove('user_password');

    // Reset auth and vehicle state
    state = AuthState.initial();
    ref.read(vehicleControllerProvider.notifier).reset();
  }

  Future<void> signUp(
    String email,
    String password,
    BuildContext context,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await signUpUsecase(email: email, password: password);

      if (response['status'] == 'OK') {
        final user = UserModel.fromSuperTokensJson(response['user']);
        state = state.copyWith(user: user, isLoading: false);

        if (context.mounted) {
          showPopUp(
            context,
            icon: FontAwesomeIcons.checkCircle,
            message: "Sign Up successful. Please log in.",
          );

          // Wait briefly to let the popup show
          await Future.delayed(const Duration(seconds: 1));

          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        }
      } else if (response['status'] == 'FIELD_ERROR') {
        final error = response['formFields'][0]['error'];
        state = state.copyWith(isLoading: false, errorMessage: error);

        if (context.mounted) {
          showPopUp(
            context,
            icon: FontAwesomeIcons.triangleExclamation,
            message: error,
          );
        }
      } else {
        throw Exception("Unexpected sign-up response.");
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());

      if (context.mounted) {
        showPopUp(
          context,
          icon: FontAwesomeIcons.triangleExclamation,
          message: "Sign_Up_Failed",
        );
      }
    }
  }

  Future<User?> getUserByuserId(String userId) async {
    final user = await getProfileById(userId: userId);
    return user;
  }

  Future<bool> login(
    String email,
    String password,
    BuildContext context,
  ) async {
    // Set loading state
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      password: password,
    );

    try {
      final response = await loginUsecase(email: email, password: password);

      if (response == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: "No response from server.",
        );
        showPopUp(
          context,
          icon: FontAwesomeIcons.triangleExclamation,
          message: "No response from server.",
        );
        return false;
      }

      if (response['status'] == "WRONG_CREDENTIALS_ERROR") {
        state = state.copyWith(
          isLoading: false,
          errorMessage: "Incorrect email or password.",
        );
        showPopUp(
          context,
          icon: FontAwesomeIcons.triangleExclamation,
          message: "Incorrect email or password.",
        );
        return false;
      }

      if (response['status'] == "OK") {
        // Parse user from login response
        final loggedInUser = UserModel.fromSuperTokensJson(response["user"]);

        // Save email and password in local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', email);
        await prefs.setString('user_password', password);

        // Fetch full profile
        final profileUser = await getProfileUseCase(email: email);

        if (profileUser == null ||
            profileUser.firstname == null ||
            profileUser.firstname.isEmpty) {
          state = state.copyWith(isLoading: false, user: loggedInUser);

          if (!context.mounted) return false;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const FirstLastNameScreen()),
          );
          return true;
        }

        // If profile is complete
        state = state.copyWith(user: profileUser, isLoading: false);

        if (!context.mounted) return false;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
        return true;
      }

      // Fallback for unexpected status
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Unexpected error. Please try again.",
      );
      return false;
    } catch (e, stacktrace) {
      print("Login error: $e");
      print(stacktrace);
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Something went wrong. Please try again.",
      );
      return false;
    }
  }

  void setToIdle() {
    state = AuthState(isLoading: false);
  }

  Future<bool> createProfile({
    required String number,
    required String email,
    required String password,
    required String firstname,
    required String lastname,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final user = await createProfileUsecase(
        number: number,
        email: email,
        password: password,
        firstname: firstname,
        lastname: lastname,
      );
      print(user);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      print(e);
      state = state.copyWith(isLoading: false);
      return false;
    }
  }
}
