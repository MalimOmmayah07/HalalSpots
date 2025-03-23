import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final String text;
  final IconData icon;
  final Widget? suffixIcon;  // New property for suffixIcon

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.icon,
    required this.text,
    this.suffixIcon,  // Optional suffixIcon parameter
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: Colors.black54,
        ),
        labelText: text,
        labelStyle: TextStyle(color: Colors.black54.withOpacity(0.9)),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color.fromARGB(255, 255, 202, 126)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color.fromARGB(255, 17, 12, 96)),  // Yellow border on focus
        ),
        suffixIcon: suffixIcon,  // Use suffixIcon here
      ),
    );
  }
}



class MyTextField1 extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final String text;
  final IconData icon;
  final int maxLines; // Add maxLines property

  const MyTextField1({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.icon,
    required this.text,
    this.maxLines = 1, // Default to 1 if not specified
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines, // Use maxLines here
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: Colors.black54,
        ),
        labelText: text,
        labelStyle: TextStyle(color: Colors.black54.withOpacity(0.9)),
        filled: true,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(width: 0, style: BorderStyle.none),
        ),
      ),
    );
  }
}

class CustomDropdownButtonFormField extends StatelessWidget {
  final String value;
  final List<String> items;
  final String hintText;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  const CustomDropdownButtonFormField({super.key, 
    required this.value,
    required this.items,
    required this.hintText,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(5), // Remove content padding
        prefixIcon: Icon(
          icon,
          color: Colors.black54,
        ),
        labelStyle: TextStyle(color: Colors.black54.withOpacity(0.9)),
        filled: true,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(width: 0, style: BorderStyle.none),
        ),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: Container(),
        onChanged: onChanged,
// Set the item height
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
      ),
    );
  }
}

class MyTextBox extends StatelessWidget {
  final String text;
  final String sectionName;
  final void Function()? onPressed;
  const MyTextBox({
    super.key,
    required this.sectionName,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 202, 126).withOpacity(0.9),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: const Color.fromARGB(255, 17, 12, 96), // Border color added here
          width: 1.5, // Adjust the border width as desired
        ),
      ),
      padding: const EdgeInsets.only(
        left: 15,
        bottom: 15,
      ),
      margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // section name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sectionName,
                style: const TextStyle(color: Color.fromARGB(167, 0, 0, 0)),
              ),

              // edit button
              IconButton(
                onPressed: onPressed,
                icon: const Icon(
                  Icons.settings,
                  color: Color.fromARGB(166, 0, 0, 0),
                ),
              ),
            ],
          ),

          // text
          Text(text),
        ],
      ),
    );
  }
}


class MyTextBoxs extends StatelessWidget {
  final String text;
  final String sectionName;
  final void Function()? onPressed;
  const MyTextBoxs({
    super.key,
    required this.sectionName,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 215, 216, 221).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(width: 0, style: BorderStyle.none),
      ),
      padding: const EdgeInsets.only(
        left: 15,
        bottom: 15,
      ),
      margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // section name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sectionName,
                style: const TextStyle(color: Colors.black38),
              ),

              // edit button
              IconButton(
                  onPressed: onPressed,
                  icon: Icon(
                    Icons.settings,
                    color: const Color.fromARGB(255, 215, 216, 221).withOpacity(0.01),
                  ))
            ],
          ),

          //text
          Text(text),
        ],
      ),
    );
  }
}

class MyTextBoxshw extends StatefulWidget {
  final String text;
  final String sectionName;
  final void Function()? onPressed;

  const MyTextBoxshw({
    super.key,
    required this.sectionName,
    required this.text,
    required this.onPressed,
  });

  @override
  _MyTextBoxState createState() => _MyTextBoxState();
}

class _MyTextBoxState extends State<MyTextBoxshw> {
  bool hidePIN = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 215, 216, 221).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(width: 0, style: BorderStyle.none),
      ),
      padding: const EdgeInsets.only(
        left: 15,
        bottom: 15,
      ),
      margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // section name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.sectionName,
                style: const TextStyle(color: Colors.black38),
              ),

              // edit button
              IconButton(
                onPressed: () {
                  if (widget.onPressed != null) {
                    widget.onPressed!();
                  }
                },
                icon: const Icon(
                  Icons.settings,
                  color: Colors.black38,
                ),
                padding: EdgeInsets.zero, // Remove padding around the icon
              ),
            ],
          ),

          // text (conditionally hide/show)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  hidePIN
                      ? widget.text.replaceAll(RegExp(r'.'),
                          '*') // Show '*' instead of actual characters
                      : widget.text,
                ),
              ),

              // hide/show button
              IconButton(
                onPressed: () {
                  setState(() {
                    hidePIN = !hidePIN; // Toggle the visibility of the PIN
                  });
                },
                icon: Icon(
                  hidePIN ? Icons.visibility_off : Icons.visibility,
                  color: Colors.black38,
                ),
                padding: EdgeInsets.zero, // Remove padding around the icon
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class primaryTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final String text;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator; // Validator function

  const primaryTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.text,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator, // Allow passing custom validator
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        maxLines: maxLines,
        keyboardType: keyboardType, // Set keyboardType here
        validator: validator, // Add the validator
        decoration: InputDecoration(
          labelText: text,
          alignLabelWithHint: true,
          hintText: hintText,
          labelStyle: TextStyle(color: Colors.black54.withOpacity(0.9)),
          filled: true,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Color.fromARGB(255, 255, 202, 126)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Color.fromARGB(255, 17, 12, 96)),
          ),
        ),
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }
}


class PrimaryDropdown extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String labelText;
  final List<String> options;
  final String? Function(String?)? validator;

  const PrimaryDropdown({
    super.key,
    required this.controller,
    required this.hintText,
    required this.labelText,
    required this.options,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: DropdownButtonFormField<String>(
        value: controller.text.isNotEmpty ? controller.text : null,
        decoration: InputDecoration(
          labelText: labelText,
          alignLabelWithHint: true,
          hintText: hintText,
          labelStyle: TextStyle(color: Colors.black54.withOpacity(0.9)),
          filled: true,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Color.fromARGB(255, 255, 202, 126)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Color.fromARGB(255, 17, 12, 96)),
          ),
        ),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: (value) {
          controller.text = value ?? '';
        },
        validator: validator,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }
}
