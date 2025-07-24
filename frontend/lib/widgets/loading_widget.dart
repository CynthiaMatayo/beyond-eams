// COPY THIS TO: lib/widgets/loading_widget.dart

import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String message;
  final Color? color;

  const LoadingWidget({super.key, this.message = 'Loading...', this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: color ?? Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
