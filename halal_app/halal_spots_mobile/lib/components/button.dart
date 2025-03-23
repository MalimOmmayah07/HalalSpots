import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final Function()? onTap;
  final String text;

  const MyButton({
    super.key,
    required this.onTap,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 45,
        margin: const EdgeInsets.fromLTRB(0, 10, 0, 20),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(90)),
        child: ElevatedButton(
          onPressed: onTap,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return const Color.fromARGB(255, 255, 202, 126);
              }
              return const Color.fromARGB(255, 17, 12, 96);
            }),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              // Customize the font style here
              fontSize: 20, // Example font size
              fontWeight: FontWeight.bold, // Example font weight
              color: Color.fromARGB(255, 252, 250, 250), // Example text color
            ),
          ),
        ),
      ),
    );
  }
}

class MyButton1 extends StatelessWidget {
  final Function()? onTap;
  final String text;

  const MyButton1({
    super.key,
    required this.onTap,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return const Color.fromARGB(255, 255, 202, 126); // Red when pressed
          }
          return const Color.fromARGB(255, 17, 12, 96); // Green by default
        }),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(90),
          ),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 252, 250, 250),
        ),
      ),
    );
  }
}
