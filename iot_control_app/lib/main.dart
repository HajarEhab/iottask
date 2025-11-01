import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

// ============================================================================
// CONSTANTS - App-wide color scheme and spacing
// ============================================================================
const kPrimaryColor = Color(0xFF6F35A5);        // Purple primary color
const kPrimaryLightColor = Color(0xFFF1E6FF);  // Light purple for backgrounds
const double defaultPadding = 16.0;            // Standard spacing unit

// ============================================================================
// MAIN ENTRY POINT - Initialize Firebase and start the app
// ============================================================================
void main() async {
  // Ensure Flutter binding is initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific configuration
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Start the Flutter application
  runApp(const MyApp());
}

// ============================================================================
// MyApp - Root widget that defines app theme and navigation
// ============================================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Control App',
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: Colors.white,

        // Custom styling for all elevated buttons in the app
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        // Custom styling for all text input fields in the app
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kPrimaryLightColor,
          iconColor: kPrimaryColor,
          prefixIconColor: kPrimaryColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: defaultPadding,
            vertical: defaultPadding,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const AuthWrapper(), // Start with authentication check
    );
  }
}

// ============================================================================
// AuthWrapper - Checks if user is logged in and shows appropriate screen
// ============================================================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to Firebase authentication state changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading spinner while checking authentication
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is logged in, show dashboard
        if (snapshot.hasData) {
          return const DashboardPage();
        }

        // If user is not logged in, show login page
        return const LoginPage();
      },
    );
  }
}

// ============================================================================
// LoginPage - User authentication screen
// ============================================================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers to get text from input fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Loading state to show spinner during sign in
  bool _isLoading = false;

  /// Signs in user with email and password
  Future<void> _signIn() async {
    // Validate form inputs first
    if (!_formKey.currentState!.validate()) return;

    // Show loading indicator
    setState(() => _isLoading = true);

    try {
      // Attempt to sign in with Firebase Authentication
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // If successful, AuthWrapper will automatically navigate to Dashboard

    } on FirebaseAuthException catch (e) {
      // Show error message if login fails
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Failed to sign in")),
      );
    } finally {
      // Hide loading indicator
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock icon at the top
              const Icon(
                Icons.lock_outline,
                size: 100,
                color: kPrimaryColor,
              ),
              const SizedBox(height: defaultPadding * 2),

              // LOGIN title
              const Text(
                'LOGIN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: defaultPadding * 2),

              // Login form with email and password fields
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email input field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: "Your email",
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(defaultPadding),
                          child: Icon(Icons.person),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),

                    // Password input field
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: defaultPadding),
                      child: TextFormField(
                        controller: _passwordController,
                        textInputAction: TextInputAction.done,
                        obscureText: true, // Hide password text
                        decoration: const InputDecoration(
                          hintText: "Your password",
                          prefixIcon: Padding(
                            padding: EdgeInsets.all(defaultPadding),
                            child: Icon(Icons.lock),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: defaultPadding),

                    // Login button or loading spinner
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Hero(
                      tag: "login_btn",
                      child: ElevatedButton(
                        onPressed: _signIn,
                        child: Text("Login".toUpperCase()),
                      ),
                    ),

                    const SizedBox(height: defaultPadding),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an Account? ",
                          style: TextStyle(color: kPrimaryColor),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Navigate to Sign Up page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              color: kPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SignUpPage - New user registration screen
// ============================================================================
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Controllers for input fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  /// Creates new user account and initializes database structure
  Future<void> _signUp() async {
    // Validate form inputs
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create new user account with Firebase Authentication
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user != null) {
        // Initialize database structure for new user
        // This creates the user's data node in Realtime Database
        DatabaseReference userRef = FirebaseDatabase.instance.ref("users/${user.uid}");
        await userRef.set({
          "sensor_data": {
            "temperature": 0.0,  // Initial temperature value
            "humidity": 0.0,     // Initial humidity value
            "last_updated": 0    // Timestamp placeholder
          },
          "controls": {
            "led_status": false  // LED initially OFF
          }
        });

        // Sign out the user immediately after signup
        await FirebaseAuth.instance.signOut();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Please login.'),
              backgroundColor: Colors.green,
            ),
          );

          // Go back to login page after successful signup
          Navigator.of(context).pop();
        }
      }
    } on FirebaseAuthException catch (e) {
      // Show error message if signup fails
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Failed to sign up")),
      );
    } finally {
      // Hide loading indicator
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Person add icon at the top
              const Icon(
                Icons.person_add_outlined,
                size: 100,
                color: kPrimaryColor,
              ),
              const SizedBox(height: defaultPadding * 2),

              // SIGN UP title
              const Text(
                'SIGN UP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: defaultPadding * 2),

              // Sign up form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email input field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: "Your email",
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(defaultPadding),
                          child: Icon(Icons.person),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),

                    // Password input field with length validation
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: defaultPadding),
                      child: TextFormField(
                        controller: _passwordController,
                        textInputAction: TextInputAction.done,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: "Your password",
                          prefixIcon: Padding(
                            padding: EdgeInsets.all(defaultPadding),
                            child: Icon(Icons.lock),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: defaultPadding),

                    // Sign up button or loading spinner
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Hero(
                      tag: "signup_btn",
                      child: ElevatedButton(
                        onPressed: _signUp,
                        child: Text("Sign Up".toUpperCase()),
                      ),
                    ),

                    const SizedBox(height: defaultPadding),

                    // Sign in link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an Account? ",
                          style: TextStyle(color: kPrimaryColor),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            "Sign In",
                            style: TextStyle(
                              color: kPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DashboardPage - Main app screen showing sensor data and LED control
// ============================================================================
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Sensor data variables
  double _temperature = 0.0;
  double _humidity = 0.0;
  bool _ledStatus = false;

  // Stream subscriptions for real-time database updates
  late StreamSubscription _sensorSubscription;
  late StreamSubscription _controlSubscription;

  // Database reference for LED control
  late DatabaseReference _ledRef;

  // User information
  String? _currentUserId;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  /// Gets current user info and sets up database listeners
  void _initializeUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
        _userEmail = user.email;
      });
      _activateListeners(); // Start listening to database
    }
  }

  /// Sets up real-time listeners for sensor data and LED control
  void _activateListeners() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final db = FirebaseDatabase.instance;

      // Reference to LED control in database
      _ledRef = db.ref("users/${user.uid}/controls/led_status");

      // Listen to sensor data changes (temperature and humidity)
      _sensorSubscription = db.ref("users/${user.uid}/sensor_data").onValue.listen((event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null && mounted) {
          setState(() {
            // Update temperature and humidity from database
            _temperature = (data['temperature'] ?? 0.0).toDouble();
            _humidity = (data['humidity'] ?? 0.0).toDouble();
          });
        }
      });

      // Listen to LED status changes
      _controlSubscription = _ledRef.onValue.listen((event) {
        final status = event.snapshot.value as bool?;
        if (status != null && mounted) {
          setState(() {
            _ledStatus = status; // Update LED status
          });
        }
      });
    }
  }

  /// Toggles LED status in database (ON ↔ OFF)
  Future<void> _toggleLed() async {
    await _ledRef.set(!_ledStatus); // Write opposite value to database
  }

  /// Shows logout confirmation dialog and signs out user
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // Sign out if user confirmed
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      // AuthWrapper will automatically navigate back to login
    }
  }

  @override
  void dispose() {
    // Cancel subscriptions to prevent memory leaks
    _sensorSubscription.cancel();
    _controlSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Home',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          // Logout button in app bar
          IconButton(
            icon: const Icon(Icons.logout, color: kPrimaryColor),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            // User Info Card - Shows current user ID
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(defaultPadding),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '👤 User Info',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'User ID: ${_currentUserId ?? "null"}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: defaultPadding),

            // Welcome Section - Shows user email
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(defaultPadding * 1.5),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome Back! 👋',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userEmail ?? 'User',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: defaultPadding * 2),

            // Sensor Data Section - Shows temperature and humidity
            Row(
              children: [
                // Temperature Card
                Expanded(
                  child: _buildSensorCard(
                    label: 'Temperature',
                    value: _temperature.toStringAsFixed(1), // Show 1 decimal place
                    unit: '°C',
                    icon: Icons.thermostat,
                  ),
                ),
                const SizedBox(width: defaultPadding),

                // Humidity Card
                Expanded(
                  child: _buildSensorCard(
                    label: 'Humidity',
                    value: _humidity.toStringAsFixed(1), // Show 1 decimal place
                    unit: '%',
                    icon: Icons.water_drop,
                  ),
                ),
              ],
            ),

            const SizedBox(height: defaultPadding * 2),

            // LED Control Button - Toggles LED on/off
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleLed,
                icon: Icon(_ledStatus ? Icons.lightbulb : Icons.lightbulb_outline),
                label: Text(_ledStatus ? 'Turn LED OFF' : 'Turn LED ON'),
                style: ElevatedButton.styleFrom(
                  // Button color changes based on LED status
                  backgroundColor: _ledStatus ? Colors.amber[700] : kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ),

            const Spacer(),

            // Info Note at bottom
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(defaultPadding),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Real-time sensor data from Firebase',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: defaultPadding),
          ],
        ),
      ),
    );
  }

  /// Builds a sensor data card widget
  /// Used for displaying temperature and humidity
  Widget _buildSensorCard({
    required String label,   // "Temperature" or "Humidity"
    required String value,   // Numeric value as string
    required String unit,    // "°C" or "%"
    required IconData icon,  // Icon to display
  }) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon at top
          Icon(icon, color: kPrimaryColor, size: 32),
          const SizedBox(height: 8),

          // Label (Temperature/Humidity)
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Value with unit
          Text(
            '$value$unit',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}