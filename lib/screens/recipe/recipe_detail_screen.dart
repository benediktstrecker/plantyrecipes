import 'package:flutter/material.dart';

class RecipeDetailScreen extends StatelessWidget {
  final String title;
  const RecipeDetailScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              "https://via.placeholder.com/400x200.png?text=$title",
            ),
            const SizedBox(height: 16),
            const Text(
              "Zutaten:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text("- Zutat A\n- Zutat B"),
            const SizedBox(height: 16),
            const Text(
              "Zubereitung:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            ),
          ],
        ),
      ),
    );
  }
}
