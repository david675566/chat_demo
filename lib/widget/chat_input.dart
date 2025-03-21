import 'package:flutter/material.dart';

class InputWidget extends StatefulWidget {
  const InputWidget({super.key, required this.onSendPressed});
  final void Function(String text) onSendPressed;

  @override
  createState() => _StateInputWidget();
}

class _StateInputWidget extends State<InputWidget> {
  final inputController = TextEditingController();

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double inputWidth = MediaQuery.sizeOf(context).width * 0.91;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: (inputController.text.isEmpty) ? inputWidth : inputWidth - 64),
          padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 3),
          child: TextFormField(
            decoration: InputDecoration(
              hintText: "Come say something...",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderSide: BorderSide(), borderRadius: BorderRadius.circular(30)),
            ),
            style: TextStyle(color: Colors.black),
            controller: inputController,
            maxLines: 3,
            onTapOutside: (event) => FocusScope.of(context).unfocus(), // Unfocus everything
            onChanged: (value) => setState(() {}),
          ),
        ),
        //
        // Send Button, only shows up when inputController has content.
        //
        Visibility(
          visible: inputController.text.isNotEmpty,
          child: IconButton(
            icon: Icon(Icons.send),
            onPressed:
                (inputController.text.isEmpty)
                    ? null
                    : () {
                      final text = inputController.text.trim();
                      inputController.clear();
                      widget.onSendPressed(text);
                    },
          ),
        ),
      ],
    );
  }
}
