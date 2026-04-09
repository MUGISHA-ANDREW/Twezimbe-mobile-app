import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
import 'package:twezimbeapp/core/data/local_user_session_store.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/auth/presentation/pages/sign_in_page.dart';
import 'package:twezimbeapp/features/profile/presentation/pages/personal_info_page.dart';
import 'package:twezimbeapp/features/profile/presentation/pages/security_settings_page.dart';
import 'package:twezimbeapp/features/profile/presentation/pages/help_support_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isUploadingPhoto = false;

  AppProfileData _fallbackProfileFor(User? user) {
    final email = user?.email ?? '';
    final displayName = user?.displayName?.trim();
    final fallbackName = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (email.isNotEmpty ? email.split('@').first : 'User');

    return AppProfileData(
      fullName: fallbackName,
      email: email,
      phoneNumber: user?.phoneNumber ?? 'Not set',
      dateOfBirth: 'Not set',
      nationalId: 'Not set',
      address: 'Not set',
      photoUrl: user?.photoURL,
      customerId: email.isNotEmpty
          ? 'CUST-${email.split('@').first.toUpperCase()}'
          : 'CUST-00000',
      kycStatus: 'KYC Verified',
      accountType: 'Savings Account',
      availableBalance: 'UGX 0',
      isAdmin: false,
    );
  }

  Future<void> _uploadProfilePhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('You must be signed in to upload a photo.');
      return;
    }

    final String? oldAuthPhotoUrl = user.photoURL;
    String? oldStoredPhotoUrl;
    try {
      oldStoredPhotoUrl =
          await AppDataRepository.getCurrentProfilePhotoUrlForCurrentUser();
    } catch (_) {
      oldStoredPhotoUrl = null;
    }

    try {
      final picker = ImagePicker();
      final selected = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1080,
      );

      if (selected == null) {
        return;
      }

      setState(() => _isUploadingPhoto = true);
      final bytes = await selected.readAsBytes();
      final extension = _normalizedExtension(selected.name);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child(user.uid)
          .child('avatar_${DateTime.now().millisecondsSinceEpoch}.$extension');

      await storageRef.putData(
        bytes,
        SettableMetadata(contentType: _contentTypeFor(extension)),
      );
      final photoUrl = await storageRef.getDownloadURL();
      await AppDataRepository.updateProfilePhotoUrlForCurrentUser(
        photoUrl,
      ).timeout(const Duration(seconds: 2));

      final oldPhotoUrls = <String>{
        if (oldAuthPhotoUrl != null) oldAuthPhotoUrl,
        if (oldStoredPhotoUrl != null) oldStoredPhotoUrl,
      };

      unawaited(
        _cleanupOldManagedPhotos(
          photoUrls: oldPhotoUrls,
          userId: user.uid,
          currentPhotoUrl: photoUrl,
        ),
      );

      _showMessage('Profile photo updated.');
    } on TimeoutException {
      _showMessage(
        'Photo uploaded, but profile save exceeded 2 seconds. Please try again.',
      );
    } on FirebaseException catch (error) {
      debugPrint(
        'Profile photo upload failed [${error.code}]: ${error.message}',
      );
      _showMessage(_firebaseUploadErrorMessage(error));
    } catch (error, stackTrace) {
      debugPrint('Profile photo upload failed: $error\n$stackTrace');
      _showMessage('Failed to upload photo. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _cleanupOldManagedPhotos({
    required Set<String> photoUrls,
    required String userId,
    required String currentPhotoUrl,
  }) async {
    for (final oldPhotoUrl in photoUrls) {
      if (_isManagedProfilePhotoUrl(oldPhotoUrl, userId) &&
          oldPhotoUrl != currentPhotoUrl) {
        try {
          await FirebaseStorage.instance.refFromURL(oldPhotoUrl).delete();
        } catch (_) {
          // Ignore cleanup failures (e.g., missing old object).
        }
      }
    }
  }

  String _normalizedExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) {
      return 'jpg';
    }

    final ext = fileName.substring(dotIndex + 1).toLowerCase();
    if (ext == 'jpeg') return 'jpg';
    if (ext == 'png' ||
        ext == 'jpg' ||
        ext == 'webp' ||
        ext == 'heic' ||
        ext == 'heif') {
      return ext;
    }
    return 'jpg';
  }

  String _contentTypeFor(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  String _firebaseUploadErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'unauthorized':
      case 'permission-denied':
        return 'Upload blocked by Firebase Storage/Firestore rules. Please update project rules and try again.';
      case 'canceled':
        return 'Upload was canceled.';
      case 'object-not-found':
        return 'Storage path not found. Please try again.';
      case 'network-request-failed':
      case 'unavailable':
        return 'Network issue while uploading. Check your connection and try again.';
      default:
        final details = error.message?.trim();
        if (details != null && details.isNotEmpty) {
          return 'Upload failed: $details';
        }
        return 'Failed to upload photo. Please try again.';
    }
  }

  bool _isManagedProfilePhotoUrl(String url, String userId) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }

    final hasStorageHost =
        uri.host.contains('firebasestorage.googleapis.com') ||
        uri.host.contains('firebasestorage.app');
    if (!hasStorageHost) {
      return false;
    }

    final decodedPath = Uri.decodeComponent(uri.path);
    return decodedPath.contains('/profile_photos/$userId/');
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    await LocalUserSessionStore.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInPage()),
      (route) => false,
    );
  }

  void _showLinkedAccounts(AppProfileData profile) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Linked Account Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _infoRow('Customer ID', profile.customerId),
                _infoRow('Account Type', profile.accountType),
                _infoRow('Email', profile.email),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<AppProfileData>(
      stream: AppDataRepository.watchProfileForCurrentUser(),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? _fallbackProfileFor(user);

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Avatar & Name
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: AppColors.primaryBlue.withValues(
                          alpha: 0.12,
                        ),
                        backgroundImage: profile.photoUrl != null
                            ? NetworkImage(profile.photoUrl!)
                            : null,
                        child: profile.photoUrl == null
                            ? Text(
                                profile.fullName.isNotEmpty
                                    ? profile.fullName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                ),
                              )
                            : null,
                      ),
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: IconButton(
                          iconSize: 18,
                          onPressed: _isUploadingPhoto
                              ? null
                              : _uploadProfilePhoto,
                          icon: _isUploadingPhoto
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  color: AppColors.primaryBlue,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  profile.fullName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? profile.customerId,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified,
                        color: AppColors.successGreen,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        profile.kycStatus,
                        style: TextStyle(
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Settings Options
                _buildProfileOption(
                  Icons.person_outline,
                  'Personal Information',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PersonalInfoPage(),
                      ),
                    );
                  },
                ),
                _buildProfileOption(Icons.security, 'Security Settings', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SecuritySettingsPage(),
                    ),
                  );
                }),
                _buildProfileOption(
                  Icons.account_balance,
                  'Linked Accounts',
                  () => _showLinkedAccounts(profile),
                ),
                _buildProfileOption(Icons.help_outline, 'Help & Support', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpSupportPage(),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Logout
                ListTile(
                  onTap: _logout,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.logout, color: Colors.red),
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryBlue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }
}
