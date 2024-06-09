import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_application/Auth/user_type_screen_phonenumber.dart';

class UserInfoInputScreen extends StatefulWidget {
  final String phoneNumber;

  UserInfoInputScreen({required this.phoneNumber});

  @override
  _UserInfoInputScreenState createState() => _UserInfoInputScreenState();
}

class _UserInfoInputScreenState extends State<UserInfoInputScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  String? _selectedGender;

  Future<void> _openUserTypeSelection() async {
    if (_validateInputs()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserTypeSelectionScreen(
            name: _nameController.text,
            surname: _surnameController.text,
            gender: _selectedGender!,
            phoneNumber: widget.phoneNumber,
          ),
        ),
      );
    }
  }

  bool _validateInputs() {
    if (_nameController.text.isEmpty ||
        _surnameController.text.isEmpty ||
        _selectedGender == null) {
      _showError('Tous les champs sont obligatoires');
      return false;
    }

    if (_nameController.text.length < 3 || _surnameController.text.length < 3) {
      _showError('Le nom et le prénom doivent contenir au moins 3 caractères');
      return false;
    }

    if (_selectedGender == null) {
      _showError('Veuillez sélectionner un genre');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Informations personnelles'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Text(
                'Complétez vos informations',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        labelText: 'Nom',
                        icon: Icons.person,
                      ),
                      SizedBox(height: 10),
                      _buildTextField(
                        controller: _surnameController,
                        labelText: 'Prénom',
                        icon: Icons.person,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Genre',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGenderRadio('M', 'Male'),
                          _buildGenderRadio('F', 'Female'),
                        ],
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _openUserTypeSelection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Text('Continuer'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String labelText,
      required IconData icon}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }

  Widget _buildGenderRadio(String title, String value) {
    return Expanded(
      child: ListTile(
        title: Text(title),
        leading: Radio<String>(
          value: value,
          groupValue: _selectedGender,
          onChanged: (String? newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
        ),
      ),
    );
  }
}
