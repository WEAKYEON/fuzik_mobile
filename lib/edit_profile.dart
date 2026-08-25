import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instrumentController = TextEditingController();
  final _genreController = TextEditingController();

  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();

    // just Mockup
    _firstNameController.text = '';
    _lastNameController.text = '';
    _displayNameController.text = '';
    _phoneController.text = '';
    _instrumentController.text = '';
    _genreController.text = '';

    _updateFormValidity();
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

  void _updateFormValidity() {
    setState(() {
      _isFormValid =
          _firstNameController.text.trim().isNotEmpty &&
              _lastNameController.text.trim().isNotEmpty &&
              _displayNameController.text.trim().isNotEmpty &&
              _phoneController.text.trim().isNotEmpty &&
              _instrumentController.text.trim().isNotEmpty &&
              _genreController.text.trim().isNotEmpty;
    });
  }

  void _saveChanges() {
    if (!_isFormValid) return;

    //  profile update logic goes here.

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Profile changes saved.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showProfilePictureOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Profile Picture',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

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
                    Navigator.pop(context);

                    // need to Open device camera.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Camera will be connected later.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

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
                    Navigator.pop(context);

                    // need to Open device gallery.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Gallery will be connected later.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

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
                  onTap: () {
                    Navigator.pop(context);

                    // need to Remove profile pic from backend.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Profile picture removed.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
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
  Widget build(BuildContext context) {
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFFFFD600),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/background_login.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Dark overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Profile picture
                    Center(
                      child: GestureDetector(
                        onTap: _showProfilePictureOptions,
                        child: Stack(
                          children: [
                            const CircleAvatar(
                              radius: 48,
                              backgroundColor: Colors.grey,
                              child: Icon(
                                Icons.person,
                                size: 52,
                                color: Colors.white,
                              ),
                            ),

                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFD600),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),


                    const SizedBox(height: 16),

                    _buildLabel('First Name'),
                    _buildInput(
                      _firstNameController,
                      'Enter your first name',
                    ),

                    const SizedBox(height: 16),

                    _buildLabel('Last Name'),
                    _buildInput(
                      _lastNameController,
                      'Enter your last name',
                    ),

                    const SizedBox(height: 16),

                    _buildLabel('Display Name'),
                    _buildInput(
                      _displayNameController,
                      'Enter your display name',
                    ),

                    const SizedBox(height: 16),

                    _buildLabel('Phone Number'),
                    _buildInput(
                      _phoneController,
                      'Enter your phone number',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),

                    const SizedBox(height: 16),

                    _buildLabel('Instrument Type'),
                    _buildInput(
                      _instrumentController,
                      'e.g. Guitar, Piano, Drums',
                    ),

                    const SizedBox(height: 16),

                    _buildLabel('Music Genre'),
                    _buildInput(
                      _genreController,
                      'e.g. Pop, Rock, Jazz',
                    ),

                    const SizedBox(height: 28),

                    // Save button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _isFormValid
                            ? [
                          BoxShadow(
                            color: const Color(0xFFFFD600)
                                .withValues(alpha: 0.6),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ]
                            : [],
                      ),
                      child: ElevatedButton(
                        onPressed: _isFormValid ? _saveChanges : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD600),
                          disabledBackgroundColor:
                          Colors.grey.shade400,
                          minimumSize: const Size(
                            double.infinity,
                            50,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInput(
      TextEditingController controller,
      String hint, {
        TextInputType keyboardType = TextInputType.text,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: (_) => _updateFormValidity(),
      cursorColor: Colors.black,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
        filled: true,
        fillColor: const Color(0xFFF4F7FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}