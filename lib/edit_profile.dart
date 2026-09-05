
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const String baseUrl =
      'https://engine01.fuzikapp.com';

  static const String mediaBaseUrl =
      'https://media05.fuzikapp.com';

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instrumentController = TextEditingController();
  final _genreController = TextEditingController();

  bool _isFormValid = false;
  bool _isLoading = false;

  File? _selectedImage;

  String? _profilePicturePath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }


  String? _getProfileImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) {
      return null;
    }

    final cleanPath = path.trim();

    if (cleanPath == 'None' ||
        cleanPath.toLowerCase() == 'null' ||
        cleanPath.toLowerCase() == 'false') {
      return null;
    }

    if (cleanPath.startsWith('http://') ||
        cleanPath.startsWith('https://')) {
      return cleanPath;
    }

    final normalizedPath = cleanPath.startsWith('/')
        ? cleanPath.substring(1)
        : cleanPath;

    return '$mediaBaseUrl/$normalizedPath';
  }


  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null || user.email == null) {
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/musician2_detail'
              '?email=${Uri.encodeComponent(user.email!)}',
        ),
      );

      print('Profile status: ${response.statusCode}');
      print('Profile response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          final profile = data[0];

          final profilePic =
          profile['profile_pic']?.toString();

          print('PROFILE PIC FROM API: $profilePic');

          print(
            'PROFILE PIC FULL URL: '
                '${_getProfileImageUrl(profilePic)}',
          );

          if (!mounted) return;

          setState(() {
            _firstNameController.text =
                profile['first_name']?.toString() ?? '';

            _lastNameController.text =
                profile['last_name']?.toString() ?? '';

            _displayNameController.text =
                profile['display_name']?.toString() ?? '';

            _phoneController.text =
                profile['tel']?.toString() ?? '';

            _instrumentController.text =
                profile['music_inst']?.toString() ?? '';

            _genreController.text =
                profile['music_genre']?.toString() ?? '';

            _profilePicturePath = profilePic;
          });

          _updateFormValidity();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile not found.'),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to load profile. '
                    'Status: ${response.statusCode}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('LOAD PROFILE ERROR: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load profile: $e',
            ),
          ),
        );
      }
    }
  }


  Future<bool> _updateField(
      String field,
      String value,
      ) async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null || user.email == null) {
      print(
        'UPDATE ERROR: No logged-in user/email',
      );
      return false;
    }

    try {
      final url = Uri.parse(
        '$baseUrl/modify_musician2'
            '?email=${Uri.encodeComponent(user.email!)}'
            '&field=${Uri.encodeComponent(field)}'
            '&new_value=${Uri.encodeComponent(value)}',
      );

      print('UPDATE URL: $url');

      final response = await http.get(url);

      print(
        'UPDATE STATUS: ${response.statusCode}',
      );

      print(
        'UPDATE RESPONSE: ${response.body}',
      );

      if (response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(response.body);

      if (data is List && data.isNotEmpty) {
        print(
          'UPDATE RESULT: ${data[0]['result']}',
        );

        print(
          'UPDATE DESCRIPTION: '
              '${data[0]['description']}',
        );

        return data[0]['result'] == 'Success';
      }

      return false;
    } catch (e) {
      print(
        'UPDATE EXCEPTION: $e',
      );

      return false;
    }
  }


  MediaType _getImageContentType(
      String path,
      ) {
    final extension =
    path.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');

      case 'png':
        return MediaType('image', 'png');

      case 'webp':
        return MediaType('image', 'webp');

      case 'gif':
        return MediaType('image', 'gif');

      default:
        return MediaType('image', 'jpeg');
    }
  }


  Future<String?> _uploadProfileImage(
      File imageFile,
      ) async {
    try {
      print('Uploading profile image...');

      print(
        'IMAGE PATH: ${imageFile.path}',
      );

      final exists =
      await imageFile.exists();

      print(
        'IMAGE EXISTS: $exists',
      );

      if (!exists) {
        print(
          'IMAGE UPLOAD FAILED: '
              'File does not exist',
        );
        return null;
      }

      final fileSize =
      await imageFile.length();

      print(
        'IMAGE SIZE: $fileSize',
      );

      if (fileSize > 5 * 1024 * 1024) {
        print(
          'IMAGE UPLOAD FAILED: '
              'Image is larger than 5 MB',
        );
        return null;
      }

      final uri = Uri.parse(
        '$mediaBaseUrl/ajax.php',
      );

      final request =
      http.MultipartRequest(
        'POST',
        uri,
      );

      final contentType =
      _getImageContentType(
        imageFile.path,
      );

      print(
        'IMAGE CONTENT TYPE: $contentType',
      );

      final filename =
          imageFile.path.split('/').last;

      final multipartFile =
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: filename,
        contentType: contentType,
      );

      request.files.add(
        multipartFile,
      );

      request.headers['Accept'] = '*/*';

      print(
        'UPLOAD URL: $uri',
      );

      print(
        'UPLOAD FIELD: file',
      );

      print(
        'UPLOAD FILENAME: $filename',
      );

      print(
        'UPLOAD CONTENT TYPE: '
            '${multipartFile.contentType}',
      );

      print(
        'Sending multipart request...',
      );

      final response =
      await request.send();

      final responseBody =
      await response.stream
          .bytesToString();

      print(
        'IMAGE UPLOAD STATUS: '
            '${response.statusCode}',
      );

      print(
        'IMAGE UPLOAD RESPONSE: '
            '$responseBody',
      );

      if (response.statusCode != 200) {
        print(
          'IMAGE UPLOAD FAILED: '
              'HTTP ${response.statusCode}',
        );
        return null;
      }

      final uploadedPath =
      responseBody.trim();

      if (uploadedPath.isEmpty) {
        print(
          'IMAGE UPLOAD FAILED: '
              'Empty response',
        );
        return null;
      }

      if (uploadedPath.toLowerCase() ==
          'false') {
        print(
          'IMAGE UPLOAD FAILED: '
              'Server returned false',
        );
        return null;
      }

      if (uploadedPath
          .toLowerCase()
          .startsWith('error')) {
        print(
          'IMAGE UPLOAD FAILED: '
              '$uploadedPath',
        );
        return null;
      }

      print(
        'IMAGE UPLOAD SUCCESS',
      );

      print(
        'UPLOADED IMAGE PATH: '
            '$uploadedPath',
      );

      print(
        'UPLOADED IMAGE FULL URL: '
            '${_getProfileImageUrl(uploadedPath)}',
      );

      return uploadedPath;
    } catch (e) {
      print(
        'IMAGE UPLOAD ERROR: $e',
      );

      return null;
    }
  }


  void _updateFormValidity() {
    final isValid =
        _firstNameController.text
            .trim()
            .isNotEmpty &&
            _lastNameController.text
                .trim()
                .isNotEmpty &&
            _displayNameController.text
                .trim()
                .isNotEmpty &&
            _phoneController.text
                .trim()
                .isNotEmpty &&
            _instrumentController.text
                .trim()
                .isNotEmpty &&
            _genreController.text
                .trim()
                .isNotEmpty;

    if (mounted) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }


  Future<void> _saveChanges() async {
    if (!_isFormValid || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool allSuccess = true;

    try {
      //  UPDATE EDITABLE TEXT FIELDS

      final fields = {
        'first_name':
        _firstNameController.text.trim(),

        'last_name':
        _lastNameController.text.trim(),

        'tel':
        _phoneController.text.trim(),

        'music_inst':
        _instrumentController.text.trim(),

        'music_genre':
        _genreController.text.trim(),
      };

      for (final entry in fields.entries) {
        final success = await _updateField(
          entry.key,
          entry.value,
        );

        if (!success) {
          allSuccess = false;
        }
      }

      // UPLOAD PROFILE IMAGE

      if (_selectedImage != null) {
        final uploadedPath =
        await _uploadProfileImage(
          _selectedImage!,
        );

        if (uploadedPath != null) {
          print(
            'Updating database with '
                'profile picture: $uploadedPath',
          );

          final success =
          await _updateField(
            'profile_pic',
            uploadedPath,
          );

          if (success) {
            print(
              'PROFILE PICTURE DATABASE '
                  'UPDATE SUCCESS',
            );

            if (mounted) {
              setState(() {
                _profilePicturePath =
                    uploadedPath;

                _selectedImage = null;
              });
            }
          } else {
            print(
              'PROFILE PICTURE DATABASE '
                  'UPDATE FAILED',
            );

            allSuccess = false;
          }
        } else {
          allSuccess = false;
        }
      }

      //  SHOW RESULT

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            allSuccess
                ? 'Profile changes saved.'
                : 'Some profile changes failed.',
          ),
          backgroundColor: allSuccess
              ? const Color(0xFF2E7D32)
              : Colors.redAccent,
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print(
        'SAVE PROFILE ERROR: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save profile: $e',
            ),
            backgroundColor:
            Colors.redAccent,
            behavior:
            SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // PICK IMAGE FROM GALLERY

  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker =
      ImagePicker();

      final XFile? image =
      await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        setState(() {
          _selectedImage =
              File(image.path);
        });

        print(
          'Selected image: ${image.path}',
        );

        print(
          'Selected image exists: '
              '${await File(image.path).exists()}',
        );
      }
    } catch (e) {
      print(
        'PROFILE IMAGE ERROR: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Failed to select image: $e',
            ),
          ),
        );
      }
    }
  }


  // TAKE PHOTO

  Future<void> _takeProfilePhoto() async {
    try {
      final ImagePicker picker =
      ImagePicker();

      final XFile? image =
      await picker.pickImage(
        source: ImageSource.camera,
      );

      if (image != null) {
        setState(() {
          _selectedImage =
              File(image.path);
        });

        print(
          'Taken image: ${image.path}',
        );
      }
    } catch (e) {
      print(
        'CAMERA ERROR: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Failed to take photo: $e',
            ),
          ),
        );
      }
    }
  }

  // PROFILE PICTURE OPTIONS

  void _showProfilePictureOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
      const Color(0xFF1E1E1E),
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.symmetric(
              vertical: 16,
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                const Text(
                  'Profile Picture',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                // TAKE PHOTO

                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: Colors.white70,
                  ),
                  title: const Text(
                    'Take Photo',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(
                      bottomSheetContext,
                    );

                    _takeProfilePhoto();
                  },
                ),

                // GALLERY

                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Colors.white70,
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(
                      bottomSheetContext,
                    );

                    _pickProfileImage();
                  },
                ),

                // REMOVE PROFILE PICTURE

                ListTile(
                  leading: const Icon(
                    Icons.delete,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Remove Profile Picture',
                    style: TextStyle(
                      color: Colors.redAccent,
                    ),
                  ),
                  onTap: () async {
                    // IMPORTANT:
                    // Capture the ScaffoldMessenger BEFORE
                    // closing the bottom sheet.
                    final messenger =
                    ScaffoldMessenger.of(
                      this.context,
                    );

                    Navigator.pop(
                      bottomSheetContext,
                    );

                    final success =
                    await _updateField(
                      'profile_pic',
                      'None',
                    );

                    if (!mounted) return;

                    if (success) {
                      setState(() {
                        _selectedImage = null;
                        _profilePicturePath =
                        null;
                      });

                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Profile picture removed.',
                          ),
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Failed to remove profile picture.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    _instrumentController.dispose();
    _genreController.dispose();

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final profileImageUrl =
    _getProfileImageUrl(
      _profilePicturePath,
    );

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () =>
              Navigator.pop(context),
        ),

        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFFFFD600),
            fontSize: 20,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),

      body: Stack(
        children: [

          Positioned.fill(
            child: Image.asset(
              'assets/images/background_login.jpg',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(
                alpha: 0.45,
              ),
            ),
          ),

          // FORM

          Center(
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),

              child: Container(
                padding:
                const EdgeInsets.all(32),

                decoration:
                BoxDecoration(
                  color:
                  Colors.white.withValues(
                    alpha: 0.7,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .stretch,

                  children: [
                    const Text(
                      'Profile',
                      textAlign:
                      TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                        FontWeight.bold,
                        color:
                        Colors.black87,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // PROFILE PICTURE

                    Center(
                      child:
                      GestureDetector(
                        onTap:
                        _showProfilePictureOptions,

                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor:
                              Colors.grey,

                              backgroundImage:
                              _selectedImage !=
                                  null
                                  ? FileImage(
                                _selectedImage!,
                              )
                                  : profileImageUrl !=
                                  null
                                  ? NetworkImage(
                                profileImageUrl,
                              )
                                  : null,

                              child:
                              _selectedImage ==
                                  null &&
                                  profileImageUrl ==
                                      null
                                  ? const Icon(
                                Icons.person,
                                size: 52,
                                color:
                                Colors.white,
                              )
                                  : null,
                            ),

                            Positioned(
                              bottom: 0,
                              right: 0,

                              child:
                              Container(
                                padding:
                                const EdgeInsets
                                    .all(8),

                                decoration:
                                const BoxDecoration(
                                  color: Color(
                                    0xFFFFD600,
                                  ),
                                  shape:
                                  BoxShape
                                      .circle,
                                ),

                                child:
                                const Icon(
                                  Icons
                                      .camera_alt,
                                  size: 18,
                                  color:
                                  Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    _buildLabel(
                      'First Name',
                    ),

                    _buildInput(
                      _firstNameController,
                      'Enter your first name',
                    ),

                    const SizedBox(
                      height: 16,
                    ),


                    _buildLabel(
                      'Last Name',
                    ),

                    _buildInput(
                      _lastNameController,
                      'Enter your last name',
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    _buildLabel(
                      'Display Name',
                    ),

                    _buildInput(
                      _displayNameController,
                      'Display Name',
                      readOnly: true,
                    ),

                    const SizedBox(
                      height: 16,
                    ),


                    _buildLabel(
                      'Phone Number',
                    ),

                    _buildInput(
                      _phoneController,
                      'Enter your phone number',
                      keyboardType:
                      TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .digitsOnly,
                      ],
                    ),

                    const SizedBox(
                      height: 16,
                    ),


                    _buildLabel(
                      'Instrument Type',
                    ),

                    _buildInput(
                      _instrumentController,
                      'e.g. Guitar, Piano, Drums',
                    ),

                    const SizedBox(
                      height: 16,
                    ),


                    _buildLabel(
                      'Music Genre',
                    ),

                    _buildInput(
                      _genreController,
                      'e.g. Pop, Rock, Jazz',
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    // SAVE BUTTON

                    Container(
                      decoration:
                      BoxDecoration(
                        borderRadius:
                        BorderRadius
                            .circular(
                          8,
                        ),

                        boxShadow:
                        _isFormValid &&
                            !_isLoading
                            ? [
                          BoxShadow(
                            color:
                            const Color(
                              0xFFFFD600,
                            ).withValues(
                              alpha: 0.6,
                            ),
                            blurRadius:
                            20,
                            spreadRadius:
                            2,
                          ),
                        ]
                            : [],
                      ),

                      child:
                      ElevatedButton(
                        onPressed:
                        _isFormValid &&
                            !_isLoading
                            ? _saveChanges
                            : null,

                        style:
                        ElevatedButton
                            .styleFrom(
                          backgroundColor:
                          const Color(
                            0xFFFFD600,
                          ),

                          disabledBackgroundColor:
                          Colors.grey
                              .shade400,

                          minimumSize:
                          const Size(
                            double.infinity,
                            50,
                          ),

                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              8,
                            ),
                          ),
                        ),

                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                            Colors.black,
                          ),
                        )
                            : const Text(
                          'Save Changes',
                          style:
                          TextStyle(
                            color:
                            Colors.black,
                            fontWeight:
                            FontWeight
                                .bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLabel(
      String text,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 8,
      ),

      child: Text(
        text,
        style: const TextStyle(
          fontWeight:
          FontWeight.bold,
          color:
          Colors.black87,
        ),
      ),
    );
  }


  Widget _buildInput(
      TextEditingController controller,
      String hint, {
        TextInputType keyboardType =
            TextInputType.text,
        List<TextInputFormatter>?
        inputFormatters,
        bool readOnly = false,
      }) {
    return TextField(
      controller: controller,

      readOnly: readOnly,

      keyboardType:
      keyboardType,

      inputFormatters:
      inputFormatters,

      onChanged: (_) {
        _updateFormValidity();
      },

      cursorColor:
      Colors.black,

      style: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontWeight:
        FontWeight.w500,
      ),

      decoration:
      InputDecoration(
        hintText: hint,

        hintStyle:
        const TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),

        filled: true,

        fillColor:
        const Color(
          0xFFF4F7FC,
        ),

        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            8,
          ),

          borderSide:
          BorderSide.none,
        ),

        contentPadding:
        const EdgeInsets
            .symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

