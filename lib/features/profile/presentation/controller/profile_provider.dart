import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/api/profile_api.dart';
import '../../data/repository/profile_repository_impl.dart';
import '../../domain/repository/profile_repository.dart';
import '../model/profile_model.dart';
import '../../../user/presentation/controller/user_provider.dart';

final profileApiProvider = Provider((ref) => ProfileApi(ref.read(apiClientProvider)));

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ref.read(profileApiProvider)),
);

class ProfileState {
  final ProfileModel? profile;
  final bool isLoading;
  final bool isUpdating;
  final String? error;

  ProfileState({
    this.profile,
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
  });

  ProfileState copyWith({
    ProfileModel? profile,
    bool? isLoading,
    bool? isUpdating,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error ?? this.error,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    // Load from userProvider if available for immediate UI response
    final userState = ref.watch(userProvider);
    ProfileModel? initialProfile;
    
    if (userState.currentUser != null) {
      final user = userState.currentUser!;
      initialProfile = ProfileModel(
        userId: user.userId,
        username: user.username,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        mobileNumber: user.mobileNumber,
        companyId: user.companyId,
        companyName: user.companyName,
        addresses: [], // Wait for full profile load for addresses
      );
    }
    
    Future.microtask(() => loadProfile());
    return ProfileState(profile: initialProfile);
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(profileRepositoryProvider);
      final profile = await repository.getProfile();
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateProfile(ProfileUpdateRequest request) async {
    state = state.copyWith(isUpdating: true, error: null);
    try {
      final repository = ref.read(profileRepositoryProvider);
      
      // Update User profile
      if (state.profile?.userId != null) {
        await repository.updateProfile(state.profile!.userId, request);
      }
      
      // Update Company profile if company details are provided
      if (state.profile?.companyId != null && 
          (request.companyName != null || request.addresses != null)) {
        
        final companyData = {
          if (request.companyName != null) 'name': request.companyName,
          if (request.addresses != null) 'addresses': request.addresses!.map((e) => e.toJson()).toList(),
        };
        
        await repository.updateCompanyProfile(state.profile!.companyId!, companyData);
      }
      
      await loadProfile();
      
      // Also trigger refresh of current user in userProvider if needed
      // ref.read(userProvider.notifier).loadCurrentUser();
      
      state = state.copyWith(isUpdating: false);
      return true;
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
      return false;
    }
  }
}

final profileNotifierProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
