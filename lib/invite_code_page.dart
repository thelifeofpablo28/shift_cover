import 'package:flutter/material.dart';

class InviteCodePage extends StatefulWidget {
  final String organisationId;

  const InviteCodePage({Key? key, required this.organisationId})
    : super(key: key);

  @override
  _InviteCodePageState createState() => _InviteCodePageState();
}

class _InviteCodePageState extends State<InviteCodePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();

  void _submitCode() {
    if (_formKey.currentState!.validate()) {
      final code = _codeController.text.trim();
      print(
        'Submitted invite code: $code for organisation ${widget.organisationId}',
      );
      // TODO: Validate invite code logic here

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invite code submitted')));
      _codeController.clear();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter Invite Code')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Enter the invite code for organisation: ${widget.organisationId}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Invite Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an invite code';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _submitCode, child: Text('Submit')),
            ],
          ),
        ),
      ),
    );
  }
}
