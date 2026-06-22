import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil"),
      ),

      body: Center(
        child: Card(
          margin: const EdgeInsets.all(30),

          child: Padding(
            padding: const EdgeInsets.all(30),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [

                const CircleAvatar(
                  radius: 50,
                  child: Icon(
                    Icons.person,
                    size: 50,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Santiago",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "usuario@ergovida.com",
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                  label: const Text(
                    "Editar Perfil",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}