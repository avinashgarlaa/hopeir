import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';

Future<void> errorDialog({
  required BuildContext context,
  required String message,
  required String heading,
  VoidCallback? onClose,
}) {
  return showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Text(heading, style: GoogleFonts.poppins()),
            ],
          ),
          content: Text(message, style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onClose != null) onClose();
              },
              child: Text("OK", style: GoogleFonts.poppins()),
            ),
          ],
        ),
  );
}

void showToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: Colors.black87,
    textColor: Colors.white,
  );
}

void showOverlayMessage(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder:
        (context) => Positioned(
          top: 100,
          left: MediaQuery.of(context).size.width * 0.1,
          width: MediaQuery.of(context).size.width * 0.8,
          child: Material(
            color: Colors.transparent,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 500),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
  );

  overlay.insert(overlayEntry);

  Future.delayed(Duration(seconds: 2)).then((value) => overlayEntry.remove());
}
