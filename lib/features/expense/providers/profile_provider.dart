import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:expenseofflineapp/core/database/app_database.dart';

class ProfileProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Cached profile in memory — UI reads from here
  Profile? _profile;
  Profile? get profile => _profile;

  /// Loads profile from DB into memory. Call this on app start.
  Future<void> loadProfile(AppDatabase db) async {
    final profileList = await db.select(db.profiles).get();
    _profile = profileList.isNotEmpty ? profileList.first : null;
    notifyListeners();
  }

  /// Saves a new profile OR updates the existing one.
  /// Always checks DB directly to avoid stale cache issues.
  Future<void> saveProfile(AppDatabase db, String name, String? email, String? mobile, String? profileImage) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Always check DB directly for existing profile (don't rely on cache)
      final existingProfiles = await db.select(db.profiles).get();

      if (existingProfiles.isNotEmpty) {
        // UPDATE existing profile
        final existingId = existingProfiles.first.profileId;
        await (db.update(db.profiles)
          ..where((p) => p.profileId.equals(existingId))
        ).write(
          ProfilesCompanion(
            name: drift.Value(name),
            email: drift.Value(email),
            mobile: drift.Value(mobile),
            profileImage: drift.Value(profileImage),
          ),
        );
      } else {
        // INSERT new profile
        await db.into(db.profiles).insert(
          ProfilesCompanion(
            name: drift.Value(name),
            email: drift.Value(email),
            mobile: drift.Value(mobile),
            profileImage: drift.Value(profileImage),
            createdAt: drift.Value(DateTime.now()),
          ),
        );
      }

      // Reload profile into cache after saving
      final updatedList = await db.select(db.profiles).get();
      _profile = updatedList.isNotEmpty ? updatedList.first : null;
    } catch (e) {
      debugPrint("Error saving profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners(); // This triggers ALL Consumer<ProfileProvider> widgets to rebuild
    }
  }
}
