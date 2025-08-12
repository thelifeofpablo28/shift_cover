import 'package:flutter/material.dart';

class EmailInvitePage extends StatefulWidget {
  final String organisationId;
  final String invitedBy;

  const EmailInvitePage({
    Key? key,
    required this.organisationId,
    required this.invitedBy,
  }) : super(key: key);

  @override
  _EmailInvitePageState createState() => _EmailInvitePageState();
}

class _EmailInvitePageState extends State<EmailInvitePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  void _sendInvite() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      // Use widget.organisationId and widget.invitedBy here for logic, e.g.:
      print(
        'Sending invite to $email for organisation ${widget.organisationId} invited by ${widget.invitedBy}',
      );
      // TODO: Add your invite sending logic here

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invite sent to $email')));
      _emailController.clear();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Email Invite')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Invite a new user to organisation: ${widget.organisationId}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _sendInvite,
                child: Text('Send Invite'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
