import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../services/profile_service.dart';
import 'help_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late SharedPreferences _prefs;
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  Uint8List? _profileImageBytes;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    _prefs = await SharedPreferences.getInstance();
    
    final imageString = _prefs.getString('user_profile_image');
    Uint8List? imageBytes;
    if (imageString != null) {
      try {
        imageBytes = base64Decode(imageString);
      } catch (e) {
        // Production: removed debug print
      }
    }
    
    setState(() {
      _nameController.text = _prefs.getString('user_name') ?? '';
      _profileImageBytes = imageBytes;
      _isLoading = false;
    });
  }

  Future<void> _saveProfileData() async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      final name = _nameController.text.trim();
      
      // Update profile through service
      await ProfileService().updateProfile(
        name: name,
        imageBytes: _profileImageBytes,
      );
      
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate changes were made
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  Future<void> _pickImage() async {
    // Production: removed debug print
    final result = await showDialog<Uint8List?>(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (context) => _ImagePickerDialog(),
    );
    
    // Production: removed debug print
    
    if (result != null) {
      setState(() {
        _profileImageBytes = result;
      });
      
      // Update through profile service
      await ProfileService().updateProfile(imageBytes: result);
    }
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary,
            image: _profileImageBytes != null
                ? DecorationImage(
                    image: MemoryImage(_profileImageBytes!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _profileImageBytes == null
              ? Center(
                  child: Text(
                    _nameController.text.isNotEmpty 
                        ? _nameController.text[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: 48,
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: IconButton(
              icon: Icon(
                Icons.camera_alt,
                size: 20,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
              onPressed: _pickImage,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Profile Image
            _buildProfileImage(),
            const SizedBox(height: 32),
            
            // Name Field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter your name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}), // Update avatar letter
            ),
            const SizedBox(height: 32),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveProfileData,
                icon: _isSaving 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save Profile'),
              ),
            ),
            const SizedBox(height: 16),
            
            // Help Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.help_outline),
                label: const Text('How to Use Zishu'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerDialog extends StatefulWidget {
  @override
  State<_ImagePickerDialog> createState() => _ImagePickerDialogState();
}

class _ImagePickerDialogState extends State<_ImagePickerDialog> {
  Uint8List? _tempImageBytes;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Profile Picture'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_tempImageBytes != null) ...[
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: MemoryImage(_tempImageBytes!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () async {
              setState(() {
                _isLoading = true;
              });
              
              try {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                  allowMultiple: false,
                  withData: true, // Important: ensures bytes are loaded
                );
                
                if (result != null && result.files.isNotEmpty) {
                  final file = result.files.first;
                  
                  // With withData: true, bytes should always be available
                  if (file.bytes != null) {
                    setState(() {
                      _tempImageBytes = file.bytes;
                      _isLoading = false;
                    });
                    // Production: removed debug print
                  } else {
                    // Production: removed debug print
                    setState(() {
                      _isLoading = false;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error: Could not load image data'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else {
                  setState(() {
                    _isLoading = false;
                  });
                }
              } catch (e) {
                // Production: removed debug print
                setState(() {
                  _isLoading = false;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error selecting image: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: _isLoading ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ) : const Icon(Icons.folder_open),
            label: Text(_isLoading ? 'Loading...' : 'Choose from Files'),
          ),
          const SizedBox(height: 8),
          Text(
            _tempImageBytes != null 
                ? 'Image selected' 
                : 'No image selected',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Production: removed debug print
            Navigator.pop(context, null);
          },
          child: const Text('Cancel'),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: _tempImageBytes != null
              ? FilledButton(
                  onPressed: () {
                    // Production: removed debug print
                    Navigator.pop(context, _tempImageBytes);
                  },
                  child: const Text('Submit'),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}