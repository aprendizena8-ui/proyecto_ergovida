import 'package:flutter/material.dart';

import '../auth/login_page.dart';
import '../exercises/exercises_page.dart';
import '../routines/routine_page.dart';
import '../settings/settings_page.dart';
import '../statistics/statistics_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      body: Row(
        children: [

          // MENÚ LATERAL
          Container(
            width: 250,
            color: const Color(0xFF1E293B),

            child: Column(
              children: [

                const SizedBox(height: 30),

                const Icon(
                  Icons.accessibility_new,
                  color: Colors.green,
                  size: 70,
                ),

                const SizedBox(height: 10),

                const Text(
                  "ErgoVida",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),

                _menuItem(
                  context,
                  Icons.dashboard,
                  "Dashboard",
                  () {},
                ),

                _menuItem(
                  context,
                  Icons.fitness_center,
                  "Ejercicios",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ExercisesPage(),
                      ),
                    );
                  },
                ),

                _menuItem(
                  context,
                  Icons.repeat,
                  "Rutinas",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const RoutinePage(),
                      ),
                    );
                  },
                ),

                _menuItem(
                  context,
                  Icons.bar_chart,
                  "Estadísticas",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const StatisticsPage(),
                      ),
                    );
                  },
                ),

                _menuItem(
                  context,
                  Icons.settings,
                  "Configuración",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const SettingsPage(),
                      ),
                    );
                  },
                ),

                const Spacer(),

                const Divider(
                  color: Colors.white24,
                ),

                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: Colors.red,
                  ),

                  title: const Text(
                    "Cerrar Sesión",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),

                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const LoginPage(),
                      ),
                      (route) => false,
                    );
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          // CONTENIDO PRINCIPAL
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(
                    "Bienvenido a ErgoVida",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Gestiona tus pausas activas y mejora tu bienestar laboral.",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    children: [

                      Expanded(
                        child: _statCard(
                          "Pausas realizadas",
                          "24",
                          Icons.timer,
                          Colors.green,
                        ),
                      ),

                      const SizedBox(width: 20),

                      Expanded(
                        child: _statCard(
                          "Ejercicios completados",
                          "58",
                          Icons.fitness_center,
                          Colors.blue,
                        ),
                      ),

                      const SizedBox(width: 20),

                      Expanded(
                        child: _statCard(
                          "Tiempo activo",
                          "12h",
                          Icons.access_time,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    "Acciones rápidas",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 20,
                    runSpacing: 20,

                    children: [

                      _actionButton(
                        context,
                        "Iniciar Pausa Activa",
                        Icons.play_circle_fill,
                        Colors.green,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const RoutinePage(),
                            ),
                          );
                        },
                      ),

                      _actionButton(
                        context,
                        "Ver Ejercicios",
                        Icons.fitness_center,
                        Colors.blue,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ExercisesPage(),
                            ),
                          );
                        },
                      ),

                      _actionButton(
                        context,
                        "Consultar Estadísticas",
                        Icons.bar_chart,
                        Colors.orange,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const StatisticsPage(),
                            ),
                          );
                        },
                      ),

                      _actionButton(
                        context,
                        "Configuración",
                        Icons.settings,
                        Colors.purple,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const SettingsPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _menuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.white,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
      onTap: onTap,
    );
  }

  static Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,

      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            Icon(
              icon,
              size: 40,
              color: color,
            ),

            const SizedBox(height: 10),

            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(title),
          ],
        ),
      ),
    );
  }

  static Widget _actionButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: 220,
      height: 100,

      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
        ),

        onPressed: onPressed,

        icon: Icon(icon),

        label: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}