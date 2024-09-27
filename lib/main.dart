import 'package:betreflutter/MainPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async{

  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Authentication',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SignInPage(),
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                // Check if passwords match before allowing sign in
                if (_passwordController.text != _confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Passwords do not match!"),
                  ));
                } else {
                  // Add authentication logic here (Firebase, etc.)
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainPage()),
                  );
                }
              },
              child: const Text('Sign In'),
            ),
            const SizedBox(height: 20.0),
            // TextButton(
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
            //     );
            //   },
            //   child: const Text('Forgot Password?'),
            // ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpPage()),
                );
              },
              child: const Text('Don\'t have an account? Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String _gender = 'Male';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text('Gender:'),
                  const SizedBox(width: 20),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _gender,
                      onChanged: (String? newValue) {
                        setState(() {
                          _gender = newValue!;
                        });
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'Male',
                          child: Text('Male'),
                        ),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  if (_passwordController.text != _confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Passwords do not match!"),
                    ));
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainPage()),
                    );
                  }
                },
                child: const Text('Sign Up'),
              ),
              const SizedBox(height: 20.0),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Already have an account? Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// class ResetPasswordPage extends StatefulWidget {
//   const ResetPasswordPage({super.key});
//
//   @override
//   State<ResetPasswordPage> createState() => _ResetPasswordPageState();
// }
//
// class _ResetPasswordPageState extends State<ResetPasswordPage> {
//   final TextEditingController _emailController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Reset Password'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               'Enter your email address to receive a password reset link.',
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 16.0),
//             TextField(
//               controller: _emailController,
//               decoration: const InputDecoration(
//                 labelText: 'Email',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 20.0),
//             ElevatedButton(
//               onPressed: () async {
//                 String email = _emailController.text.trim();
//
//                 if (email.isNotEmpty) {
//                   try {
//                     await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
//                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                       content: Text('Password reset link has been sent!'),
//                     ));
//                     Navigator.pop(context);  // Return to Sign In page
//                   } catch (e) {
//                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                       content: Text('Error: $e'),
//                     ));
//                   }
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                     content: Text('Please enter your email address!'),
//                   ));
//                 }
//               },
//               child: const Text('Send Password Reset Link'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// class ResetPasswordPage extends StatefulWidget {
//   const ResetPasswordPage({super.key});
//
//   @override
//   State<ResetPasswordPage> createState() => _ResetPasswordPageState();
// }
//
// class _ResetPasswordPageState extends State<ResetPasswordPage> {
//   final TextEditingController _emailController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Reset Password'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               'Enter your email address to receive a password reset link.',
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 16.0),
//             TextField(
//               controller: _emailController,
//               decoration: const InputDecoration(
//                 labelText: 'Email',
//                 border: OutlineInputBorder(),
//               ),
//               keyboardType: TextInputType.emailAddress,
//             ),
//             const SizedBox(height: 20.0),
//             ElevatedButton(
//               onPressed: () async {
//                 String email = _emailController.text.trim();
//
//                 if (email.isNotEmpty) {
//                   try {
//                     // Send password reset email
//                     await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
//                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                       content: Text('Password reset link has been sent! Check your email.'),
//                     ));
//                     Navigator.pop(context); // Return to Sign In page
//                   } catch (e) {
//                     // Improved error handling
//                     print('Error sending password reset email: $e'); // Log error
//                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                       content: Text('Error: ${e.toString()}'),
//                     ));
//                   }
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                     content: Text('Please enter your email address!'),
//                   ));
//                 }
//               },
//               child: const Text('Send Password Reset Link'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class ResetPasswordPage extends StatefulWidget {
//   const ResetPasswordPage({super.key});
//
//   @override
//   State<ResetPasswordPage> createState() => _ResetPasswordPageState();
// }
//
// class _ResetPasswordPageState extends State<ResetPasswordPage> {
//   final TextEditingController _emailController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Reset Password'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               'Enter your email address to receive a password reset link.',
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 16.0),
//             TextField(
//               controller: _emailController,
//               decoration: const InputDecoration(
//                 labelText: 'Email',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 20.0),
//             ElevatedButton(
//               onPressed: () async {
//                 String email = _emailController.text.trim();
//
//                 if (email.isNotEmpty) {
//                   try {
//                     // Attempt to send the password reset email
//                     await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
//                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                       content: Text('Password reset link has been sent!'),
//                     ));
//                     Navigator.pop(context);  // Return to Sign In page
//                   } catch (e) {
//                     // Catch and display any errors
//                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                       content: Text('Error sending password reset email: $e'),
//                     ));
//                   }
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                     content: Text('Please enter your email address!'),
//                   ));
//                 }
//               },
//               child: const Text('Send Password Reset Link'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



// class MainPage extends StatelessWidget {
//   const MainPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Main Page'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               'Welcome to the Main Page!',
//               style: TextStyle(fontSize: 24),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 // Logic to sign out or return to the Sign In page
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (context) => const SignInPage()),
//                 );
//               },
//               child: const Text('Sign Out'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

