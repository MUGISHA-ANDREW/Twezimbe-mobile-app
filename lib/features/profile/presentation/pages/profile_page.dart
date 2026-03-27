import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
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

  Future<void> _uploadProfilePhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('You must be signed in to upload a photo.');
      return;
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
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child(user.uid)
          .child('avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final photoUrl = await storageRef.getDownloadURL();
      await AppDataRepository.updateProfilePhotoUrlForCurrentUser(photoUrl);
      _showMessage('Profile photo updated.');
    } catch (_) {
      _showMessage('Failed to upload photo. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
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
        final profile =
            snapshot.data ?? AppDataRepository.fallbackProfileForCurrentUser();

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
