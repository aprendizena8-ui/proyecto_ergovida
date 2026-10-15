import 'dart:async';
import 'package:flutter/material.dart';

class ExerciseGuidePage extends StatefulWidget {
  final String nombre;
  final String duracion;
  final IconData icono;

  const ExerciseGuidePage({
    super.key,
    required this.nombre,
    required this.duracion,
    required this.icono,
  });

  @override
  State<ExerciseGuidePage> createState() => _ExerciseGuidePageState();
}

class _ExerciseGuidePageState extends State<ExerciseGuidePage> {
  late int totalSeconds;
  late int remainingSeconds;
  Timer? timer;
  bool isRunning = false;
  bool isFinished = false;

  @override
  void initState() {
    super.initState();
    // Convertir "2 min" → 120 segundos
    totalSeconds = int.parse(widget.duracion.split(" ")[0]) * 60;
    remainingSeconds = totalSeconds;
  }

  void startTimer() {
    if (isRunning) return;

    setState(() {
      isRunning = true;
      isFinished = false;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          isRunning = false;
          isFinished = true;
        });
      }
    });
  }

  void resetTimer() {
    timer?.cancel();
    setState(() {
      remainingSeconds = totalSeconds;
      isRunning = false;
      isFinished = false;
    });
  }

  String get formattedTime {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  List<String> getInstrucciones() {
    switch (widget.nombre) {
      case "Estiramiento de Cuello":
        return [
          "Siéntate derecho con la espalda recta.",
          "Inclina suavemente la cabeza hacia la derecha.",
          "Mantén la posición 15-20 segundos.",
          "Regresa al centro y repite hacia la izquierda.",
          "Luego inclina la cabeza hacia adelante y atrás suavemente.",
          "Respira profundo durante todo el ejercicio.",
        ];
      case "Movilidad de Hombros":
        return [
          "Siéntate o párate con la espalda recta.",
          "Eleva ambos hombros hacia las orejas.",
          "Mantén 3 segundos y suelta.",
          "Haz círculos hacia adelante con los hombros (10 veces).",
          "Luego haz círculos hacia atrás (10 veces).",
          "Relaja los brazos al finalizar.",
        ];
      case "Descanso Visual":
        return [
          "Aparta la mirada de la pantalla.",
          "Enfoca un objeto lejano (mínimo 6 metros) durante 20 segundos.",
          "Cierra los ojos y relájalos 10 segundos.",
          "Parpadea varias veces de forma consciente.",
          "Repite el ciclo hasta que termine el tiempo.",
          "Evita mirar pantallas durante este descanso.",
        ];
      case "Movilidad de Muñecas":
        return [
          "Extiende los brazos hacia adelante.",
          "Haz círculos con ambas muñecas hacia afuera (10 veces).",
          "Luego haz círculos hacia adentro (10 veces).",
          "Flexiona las muñecas hacia arriba y abajo.",
          "Entrelaza los dedos y estira suavemente hacia adelante.",
          "Sacude las manos suavemente al terminar.",
        ];
      default:
        return ["Sigue las indicaciones del ejercicio."];
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombre),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Icono grande
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icono,
                size: 80,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),

            // Nombre
            Text(
              widget.nombre,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Duración: ${widget.duracion}",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),

            // Temporizador
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              decoration: BoxDecoration(
                color: isFinished ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFinished ? Colors.green : Colors.grey.shade300,
                ),
              ),
              child: Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: isFinished ? Colors.green : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botones del timer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: isRunning ? null : startTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Iniciar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: resetTimer,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Reiniciar"),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Instrucciones
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Cómo hacerlo:",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 12),

            ...getInstrucciones().asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.green,
                      child: Text(
                        "${entry.key + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 30),

            // Botón Finalizar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  timer?.cancel();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFinished
                            ? "¡Excelente! Completaste el ejercicio."
                            : "Ejercicio finalizado.",
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Finalizar ejercicio",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}