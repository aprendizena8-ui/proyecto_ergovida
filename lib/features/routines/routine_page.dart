import 'package:flutter/material.dart';

class RoutinePage extends StatelessWidget {
  const RoutinePage({super.key});

  final List<RoutineItem> _routines = const [
    RoutineItem(
      nombre: 'Rutina Oficina',
      descripcion: 'Recupera postura y energía durante la jornada.',
      ejercicios: '5 ejercicios',
      tiempo: '10 minutos',
      nivel: 'Moderado',
    ),
    RoutineItem(
      nombre: 'Rutina Casa',
      descripcion: 'Relaja cuello, hombros y espalda tras el trabajo.',
      ejercicios: '4 ejercicios',
      tiempo: '8 minutos',
      nivel: 'Fácil',
    ),
    RoutineItem(
      nombre: 'Rutina de cuello y hombros',
      descripcion: 'Reduce tensión acumulada en la parte superior del cuerpo.',
      ejercicios: '3 ejercicios',
      tiempo: '6 minutos',
      nivel: 'Leve',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rutinas')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rutinas recomendadas',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10243A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Selecciona la rutina ideal para tu momento del día.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF5E7387),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: _routines.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final routine = _routines[index];
                    return _routineCard(context, routine);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _routineCard(BuildContext context, RoutineItem routine) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCF9F2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    routine.nivel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF116A5D),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  routine.tiempo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F7FC0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              routine.nombre,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              routine.descripcion,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5E7387),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF22C55E)),
                const SizedBox(width: 8),
                Text(routine.ejercicios),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Iniciando ${routine.nombre}'),
                      backgroundColor: const Color(0xFF0E2238),
                    ),
                  );
                },
                child: const Text('Iniciar rutina'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoutineItem {
  final String nombre;
  final String descripcion;
  final String ejercicios;
  final String tiempo;
  final String nivel;

  const RoutineItem({
    required this.nombre,
    required this.descripcion,
    required this.ejercicios,
    required this.tiempo,
    required this.nivel,
  });
}
