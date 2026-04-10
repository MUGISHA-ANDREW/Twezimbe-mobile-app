import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  bool _isSaving = false;
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
      final selected = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1080,
      );
      if (selected == null) return;

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

      // Clean up old photos
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

      _showMessage('Profile photo updated and saved!');
    } on TimeoutException {
      _showMessage(
        'Photo uploaded, but profile save exceeded 2 seconds. Please try again.',
      );
    } on FirebaseException catch (error) {
      debugPrint(
        'Personal info profile photo upload failed [${error.code}]: ${error.message}',
      );
      _showMessage(_firebaseUploadErrorMessage(error));
    } catch (error, stackTrace) {
      debugPrint(
        'Personal info profile photo upload failed: $error\n$stackTrace',
      );
      _showMessage('Failed to upload profile photo.');
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
        return 'Upload blocked by storage access rules. Please update project rules and try again.';
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
        return 'Failed to upload profile photo.';
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

  Future<void> _openEditDialog(AppProfileData profile) async {
    final fullNameController = TextEditingController(text: profile.fullName);
    final phoneController = TextEditingController(text: profile.phoneNumber);
    final dobController = TextEditingController(text: profile.dateOfBirth);
    final nationalIdController = TextEditingController(
      text: profile.nationalId,
    );
    final addressController = TextEditingController(text: profile.address);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Information'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _inputField('Full Name', fullNameController),
                const SizedBox(height: 10),
                _inputField('Phone Number', phoneController),
                const SizedBox(height: 10),
                _inputField('Date of Birth', dobController),
                const SizedBox(height: 10),
                _inputField('National ID', nationalIdController),
                const SizedBox(height: 10),
                _inputField('Address', addressController, maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      if (fullNameController.text.trim().isEmpty) {
                        _showMessage('Full name is required.');
                        return;
                      }

                      setState(() => _isSaving = true);
                      try {
                        await AppDataRepository.updatePersonalInfoForCurrentUser(
                          fullName: fullNameController.text,
                          phoneNumber: phoneController.text,
                          dateOfBirth: dobController.text,
                          nationalId: nationalIdController.text,
                          address: addressController.text,
                        );
                        if (!mounted) return;
                        Navigator.of(this.context).pop();
                        _showMessage('Personal information updated.');
                      } catch (_) {
                        _showMessage('Failed to update personal information.');
                      } finally {
                        if (mounted) {
                          setState(() => _isSaving = false);
                        }
                      }
                    },
              child: _isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        );
      },
    );

    fullNameController.dispose();
    phoneController.dispose();
    dobController.dispose();
    nationalIdController.dispose();
    addressController.dispose();
  }

  Widget _inputField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: StreamBuilder<AppProfileData>(
          stream: AppDataRepository.watchProfileForCurrentUser(),
          builder: (context, snapshot) {
            final profile = snapshot.data ?? _fallbackProfileFor(user);

            return Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
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
                      color: AppColors.primaryBlue,
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: _isUploadingPhoto
                            ? null
                            : _uploadProfilePhoto,
                        icon: _isUploadingPhoto
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                _buildInfoField('Full Name', profile.fullName),
                _buildInfoField('Customer ID', profile.customerId),
                _buildInfoField('Phone Number', profile.phoneNumber),
                _buildInfoField('Email', profile.email),
                _buildInfoField('Date of Birth', profile.dateOfBirth),
                _buildInfoField('National ID', profile.nationalId),
                _buildInfoField('Address', profile.address),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _openEditDialog(profile),
                    child: const Text('Edit Information'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
