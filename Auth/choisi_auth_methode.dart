import 'package:flutter/material.dart';
import 'package:my_application/Auth/PhoneNumberScreen.dart';
import 'package:my_application/Auth/email_auth.dart';

class AuthMethodSelectionPage extends StatefulWidget {
  @override
  _AuthMethodSelectionPageState createState() =>
      _AuthMethodSelectionPageState();
}

class _AuthMethodSelectionPageState extends State<AuthMethodSelectionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Color.fromARGB(0, 161, 180, 145),
      appBar: AppBar(
        title: Text(
          'اختيار وسيلة ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Color.fromARGB(0, 233, 227, 227),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBackground(),
          ),
          FadeTransition(
            opacity: _animation,
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _animation,
                    child: Text(
                      'اختر وسيلة',
                      style: TextStyle(
                        fontSize: 32.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 80.0),
                  buildAuthMethodCard(
                    ' عبر رقم الهاتف',
                    Icons.phone,
                    Color.fromARGB(255, 112, 141, 103),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhoneNumberInputScreen(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20.0), // Réduit l'espace entre les boutons
                  buildAuthMethodCard(
                    ' عبر البريد الإلكتروني',
                    Icons.email,
                    Color.fromARGB(255, 69, 99, 131),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AuthPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAuthMethodCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.0),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.8),
              color,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              spreadRadius: 4,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 36.0,
              ),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 30.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class AnimatedBackground extends StatefulWidget {
  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 3, 3, 3).withOpacity(_controller.value),
                Color.fromARGB(255, 211, 215, 205)
                    .withOpacity(1 - _controller.value),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
