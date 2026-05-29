import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final meta = user?.userMetadata;
    final displayName = (meta?['full_name'] ?? meta?['display_name'])
        ?.toString()
        .trim();
    final fallbackName = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (email.isNotEmpty ? email.split('@').first : 'User');

    return AppProfileData(
      fullName: fallbackName,
      email: email,
      phoneNumber: user?.phone ?? 'Not set',
      dateOfBirth: 'Not set',
      nationalId: 'Not set',
      address: 'Not set',
      photoUrl: user?.userMetadata?['photo_url'],
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
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showMessage('You must be signed in to upload a photo.');
      return;
    }

    final String? oldAuthPhotoUrl = user.userMetadata?['photo_url'];
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

      if (!mounted) return;
      setState(() => _isUploadingPhoto = true);

      debugPrint('📸 Starting photo upload for user: ${user.id}');

      final bytes = await selected.readAsBytes();
      debugPrint('📸 Image loaded: ${bytes.length} bytes');

      final extension = _normalizedExtension(selected.name);
      final storagePath =
          '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';

      debugPrint('📸 Upload path: $storagePath');
      debugPrint('📸 Uploading to bucket: avatars');

      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _contentTypeFor(extension),
              upsert: false,
            ),
          );

      debugPrint('📸 Upload successful!');

      final photoUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(storagePath);

      debugPrint('📸 Public URL: $photoUrl');

      await AppDataRepository.updateProfilePhotoUrlForCurrentUser(photoUrl);

      debugPrint('📸 Database updated with photo URL');

      // Clean up old photos
      final oldPhotoUrls = <String>{
        if (oldAuthPhotoUrl != null) oldAuthPhotoUrl,
        if (oldStoredPhotoUrl != null) oldStoredPhotoUrl,
      };

      unawaited(
        _cleanupOldManagedPhotos(
          photoUrls: oldPhotoUrls,
          userId: user.id,
          currentPhotoUrl: photoUrl,
        ),
      );

      _showMessage('Profile photo updated and saved!');
    } catch (error, stackTrace) {
      debugPrint('❌ Personal info profile photo upload failed: $error');
      debugPrint('❌ Stack trace: $stackTrace');

      // Provide more specific error messages
      String errorMessage = 'Failed to upload photo. ';
      if (error.toString().contains('404')) {
        errorMessage +=
            'Bucket "avatars" not found. Please create it in Supabase.';
      } else if (error.toString().contains('403') ||
          error.toString().contains('permission')) {
        errorMessage += 'Permission denied. Please set up storage policies.';
      } else if (error.toString().contains('401')) {
        errorMessage += 'Authentication error. Please sign in again.';
      } else {
        errorMessage += 'Please try again.';
      }

      _showMessage(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
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

  Future<void> _cleanupOldManagedPhotos({
    required Set<String> photoUrls,
    required String userId,
    required String currentPhotoUrl,
  }) async {
    for (final oldPhotoUrl in photoUrls) {
      if (oldPhotoUrl == currentPhotoUrl) continue;
      final path = _extractStoragePath(oldPhotoUrl, 'avatars');
      if (path != null && path.contains(userId)) {
        try {
          await Supabase.instance.client.storage.from('avatars').remove([path]);
        } catch (_) {}
      }
    }
  }

  String? _extractStoragePath(String url, String bucket) {
    final marker = '/storage/v1/object/public/$bucket/';
    final idx = url.indexOf(marker);
    if (idx < 0) return null;
    return url.substring(idx + marker.length);
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
    final user = Supabase.instance.client.auth.currentUser;
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
