import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Acerca de Bobino App'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Logo + título
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/icon_preview.png',
                    width: 80,
                    height: 80,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.agriculture,
                          color: Colors.white, size: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bobino App',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'v1.0.0 · 2025',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Motivación
          _Section(
            icon: Icons.lightbulb_outline,
            title: 'Por qué existe esta app',
            child: const Text(
              'Soy Jeremías Palazzesi, un programador con muchos años de '
              'experiencia en tecnología que también tiene campo. En la '
              'Argentina la actividad ganadera es central, y siempre me '
              'preguntaba por qué los productores seguían evaluando a ojo '
              'el estado corporal de sus animales, cuando la IA que usamos '
              'para detectar objetos en fotos podría hacer ese trabajo de '
              'forma objetiva, repetible y sin necesidad de internet.\n\n'
              'Bobino App nació de esa pregunta. No es un proyecto '
              'académico: es una herramienta práctica para que un '
              'productor, parado al lado del corral con el teléfono en la '
              'mano, pueda obtener el ICC y el peso estimado de sus '
              'animales sin comprar equipamiento especial ni tener '
              'conexión.\n\n'
              'Todo lo que necesitás es el teléfono, una foto, y si querés '
              'peso preciso, una cinta métrica.',
              style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.55),
            ),
          ),

          const SizedBox(height: 16),

          // Qué mide y cómo
          _Section(
            icon: Icons.calculate_outlined,
            title: 'Qué mide y cómo',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow('ICC (Índice de Condición Corporal)',
                    'Escala 1–5 (estándar argentino AACREA/INTA), en pasos '
                        'de 0.5. La IA detecta al animal con YOLO y estima '
                        'proporciones; el resultado se puede ajustar manualmente '
                        'con la guía visual integrada.'),
                const SizedBox(height: 10),
                _InfoRow('Peso — Fórmula de Schoorl',
                    'P = (PT + 22)² / 100\n'
                        'Solo necesita el perímetro torácico (PT) en cm. '
                        'Precisión documentada: ±5–10%.'),
                const SizedBox(height: 10),
                _InfoRow('Peso — Fórmula de Anderson',
                    'P = PT² × Largo / 10.840  (carne)  ·  / 11.000  (lechería)\n'
                        'Necesita PT + largo del cuerpo. Más precisa: ±3–8%. '
                        'Es la fórmula recomendada.'),
                const SizedBox(height: 10),
                _InfoRow('Medición en foto',
                    'Herramienta interactiva para marcar 5 puntos anatómicos '
                        'sobre la foto lateral: hombro, isquión, cruz, esternón '
                        'y una referencia de escala. Calcula largo y profundidad '
                        'torácica en cm reales. Estima el PT con ±10–20% de '
                        'error (elipse desde la profundidad torácica). Para '
                        'resultados de peso de alta precisión, medí el PT con '
                        'cinta y cargalo a mano.'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Precisión honesta
          _Section(
            icon: Icons.bar_chart,
            title: 'Precisión real (sin filtros)',
            child: Column(
              children: const [
                _PrecisionRow('Largo corporal desde foto', '±3–8 cm', Colors.green),
                _PrecisionRow('Profundidad torácica desde foto', '±2–6 cm', Colors.green),
                _PrecisionRow('PT estimado (foto, sin cinta)', '±10–20%', Colors.orange),
                _PrecisionRow('Peso con PT medido — Schoorl', '±5–10%', Colors.green),
                _PrecisionRow('Peso con PT medido — Anderson', '±3–8%', Colors.green),
                _PrecisionRow('Peso con PT de foto — Schoorl', '±15–25%', Colors.red),
                _PrecisionRow('Peso con PT de foto — Anderson', '±12–20%', Colors.orange),
                _PrecisionRow('ICC estimado por IA (YOLO COCO)', 'orientativo, ±0.5–1.0', Colors.orange),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Literatura científica
          _Section(
            icon: Icons.science_outlined,
            title: 'Publicaciones relacionadas',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Esta app existe en el contexto de una literatura científica '
                  'creciente sobre evaluación automatizada de BCS (Body '
                  'Condition Score) con IA:',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 10),
                _PaperCard(
                  title: 'BCS-YOLO (2024)',
                  journal: 'Animals, MDPI · DOI: 10.3390/ani14243668',
                  what:
                      'Arquitectura YOLO especializada en BCS bovino. '
                      'Más liviana que YOLOv8n (+33% menos parámetros) '
                      'y 9.4% más precisa en scoring de condición corporal. '
                      'El modelo NO es público; dataset disponible bajo solicitud.',
                ),
                const SizedBox(height: 8),
                _PaperCard(
                  title: 'EdgeBCS-YOLO (2025)',
                  journal: 'Animals, MDPI · DOI: 10.3390/ani16081143',
                  what:
                      'Versión ultra-liviana de BCS-YOLO para dispositivos '
                      'edge (Jetson Orin). Solo 3.95 MB, 33 FPS en tiempo real. '
                      'Usa módulos PSFF + TASM + EGDH para preservar detalle '
                      'con muy bajo costo computacional. Tampoco es público.',
                ),
                const SizedBox(height: 8),
                _PaperCard(
                  title: 'Calves tracking con YOLOv8-pose (2025)',
                  journal: 'Frontiers in Animal Science · DOI: 10.3389/fanim.2025.1718641',
                  what:
                      'Fine-tuning de YOLOv8-pose para detectar keypoints '
                      'anatómicos en terneros (cabeza, cruz, cadera, etc.). '
                      'Permite medir distancias morfométricas automáticamente '
                      'desde video.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Lo que hacemos diferente en Bobino App:',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  '• Usamos modelos COCO públicos (YOLOv8n) sin fine-tuning, '
                  'porque los modelos especializados no están disponibles.\n'
                  '• Compensamos con la herramienta interactiva de marcado de '
                  'puntos: el productor hace el trabajo que el modelo especializado '
                  'haría automáticamente.\n'
                  '• Somos honestos con la precisión: cada valor muestra de dónde '
                  'viene y cuánto confiar en él.\n'
                  '• Todo corre offline, sin suscripción, sin nube.\n'
                  '• El código es abierto (MIT) para que otros puedan mejorar '
                  'el modelo y la herramienta.',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.55),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Qué necesitás
          _Section(
            icon: Icons.checklist_outlined,
            title: 'Qué necesitás para usarla',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _ReqRow(Icons.phone_android, 'Android 8.0 o superior (API 26+)'),
                _ReqRow(Icons.photo_camera, 'Cámara trasera (mínimo 8 MP recomendado)'),
                _ReqRow(Icons.wifi_off, 'Sin internet — todo funciona offline'),
                _ReqRow(Icons.straighten,
                    'Cinta métrica para máxima precisión en el peso '
                        '(la foto sola tiene ±15–25% de error)'),
                _ReqRow(Icons.wb_sunny,
                    'Buena iluminación y foto lateral completa del animal '
                        'para que YOLO detecte bien'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Créditos
          _Section(
            icon: Icons.person_outline,
            title: 'Autor',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jeremías Palazzesi',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                    children: [
                      const TextSpan(text: 'Programador, productor y curioso.\n'),
                      TextSpan(
                        text: 'https://www.nerdadas.com',
                        style: const TextStyle(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Clipboard.setData(const ClipboardData(
                                text: 'https://www.nerdadas.com'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('URL copiada al portapapeles'),
                                  duration: Duration(seconds: 2)),
                            );
                          },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Esta app se construyó en una sola sesión de trabajo con '
                  'Claude Code (Anthropic) como asistente de programación. '
                  'El resultado es código real, funcional, con modelos YOLO '
                  'reales, todo offline.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                      height: 1.5),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.code, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                        children: [
                          const TextSpan(text: 'Código abierto: '),
                          TextSpan(
                            text: 'github.com/jeremiaspala/bobino-app',
                            style: const TextStyle(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Clipboard.setData(const ClipboardData(
                                    text:
                                        'https://github.com/jeremiaspala/bobino-app'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('URL copiada'),
                                      duration: Duration(seconds: 2)),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Licencia
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Licencia MIT — libre para usar, modificar y distribuir con '
              'atribución. Los modelos YOLO son propiedad de Ultralytics '
              '(AGPL-3.0). Ver LICENSE en el repositorio.',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  height: 1.5),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _Section(
      {required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.4)),
      ],
    );
  }
}

class _PrecisionRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PrecisionRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  final String title;
  final String journal;
  final String what;

  const _PaperCard(
      {required this.title, required this.journal, required this.what});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(journal,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 4),
          Text(what,
              style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4)),
        ],
      ),
    );
  }
}

class _ReqRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ReqRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}
