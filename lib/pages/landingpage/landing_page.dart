import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Stack so we can overlap the curved green bg and logo
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.35,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2d4f2b), // dark green
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(100),
                      bottomRight: Radius.circular(100),
                    ),
                    boxShadow: const [
                          BoxShadow(
                            color: Color(0x552d4f2b), // semi-transparent shadow
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                  ),
                ),
                Positioned(
                  bottom: -40, // overlap
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x552d4f2b), // semi-transparent shadow
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Transform.scale(
                        scale: 1.3, // 1.0 = normal, >1.0 = zoom in, <1.0 = zoom out
                        child: Image.asset(
                          "assets/images/2.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                      ),
                    ),
                    ),
                  ),
                ),
              ],
            ),

            // Middle branding image instead of text
            Column(
              children: [
                SizedBox(
                  height: 80,
                  width: 200,
                  child: Padding(
                      padding: const EdgeInsets.only(bottom: 50),
                      child: Transform.scale(
                        scale: 10, // 1.0 = normal, >1.0 = zoom in, <1.0 = zoom out
                  child: Image.asset(
                    "assets/images/3.png", // your NiceRice brand image
                    fit: BoxFit.contain,
                  ),
                ),
                ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Controlled from the palm of your hand",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            // Swipe Up Gesture Area
            // Swipe Up Gesture Area (replace your current bottom widget with this)
            Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque, // catch gestures even on empty space
                onTap: () => Navigator.pushReplacementNamed(context, '/login'), // optional tap fallback
                onVerticalDragUpdate: (details) {
                  // Trigger as soon as the user drags upward a bit
                  if (details.delta.dy < -6) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                onVerticalDragEnd: (details) {
                  // Also handle fast flicks upward
                  if ((details.primaryVelocity ?? 0) < -400) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                child: SizedBox(
                  width: double.infinity,
                  height: 120, // generous hit area for reliable gesture capture
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.keyboard_arrow_up,
                        color: Color(0xFF2d4f2b),
                        size: 30,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Swipe Up to Get Started",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2d4f2b),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )

          ],
        ),
      ),
    );
  }
}
