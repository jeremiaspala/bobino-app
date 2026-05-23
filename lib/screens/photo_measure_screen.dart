import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../utils/constants.dart';

// ─── Result devuelto al llamador ─────────────────────────────────

class PhotoMeasureResult {
  final double pixelsPerCm;
  final double? bodyLengthCm;
  final double? bodyDepthCm;
  final double? estimatedHeartGirthCm;
  final double? withersHeightCm;
  final double? rumpAngleDeg;

  const PhotoMeasureResult({
    required this.pixelsPerCm,
    this.bodyLengthCm,
    this.bodyDepthCm,
    this.estimatedHeartGirthCm,
    this.withersHeightCm,
    this.rumpAngleDeg,
  });
}

// ─── Pasos del asistente ─────────────────────────────────────────

enum _Step {
  refA,
  refB,
  shoulder,
  rump,
  withers,
  sternum,
  groundFoot, // optional withers height
  tailhead,   // optional rump angle
  hookBone,
  done,
}

// ─── Datos internos ───────────────────────────────────────────────

class _Segment {
  final String a, b;
  final Color color;
  final String label;
  const _Segment(this.a, this.b, this.color, this.label);
}

class _MPoint {
  final String id;
  final Offset pos; // native image coords
  final Color color;
  final String label;
  const _MPoint({
    required this.id,
    required this.pos,
    required this.color,
    required this.label,
  });
}

// ─── Painter ─────────────────────────────────────────────────────

class _OverlayPainter extends CustomPainter {
  final List<_MPoint> points;
  final List<_Segment> segments;
  final Size imageSize;
  final Rect displayRect;

  const _OverlayPainter({
    required this.points,
    required this.segments,
    required this.imageSize,
    required this.displayRect,
  });

  Offset _toDisplay(Offset p) => Offset(
        displayRect.left + p.dx / imageSize.width * displayRect.width,
        displayRect.top + p.dy / imageSize.height * displayRect.height,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final byId = <String, Offset>{
      for (final p in points) p.id: _toDisplay(p.pos),
    };

    // Segments
    for (final seg in segments) {
      final a = byId[seg.a];
      final b = byId[seg.b];
      if (a == null || b == null) continue;
      _drawDashed(canvas, a, b, seg.color);
      // Distance badge at midpoint
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      _drawBadge(canvas, seg.label, mid, seg.color);
    }

    // Points
    for (final p in points) {
      final d = byId[p.id]!;
      canvas.drawCircle(d, 11, Paint()..color = Colors.white);
      canvas.drawCircle(
          d,
          11,
          Paint()
            ..color = p.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
      canvas.drawCircle(d, 4, Paint()..color = p.color);
      _drawText(canvas, p.label, d + const Offset(14, -9), p.color);
    }
  }

  void _drawDashed(Canvas canvas, Offset a, Offset b, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final dir = b - a;
    final total = dir.distance;
    if (total == 0) return;
    final unit = dir / total;
    double t = 0;
    bool on = true;
    while (t < total) {
      final end = (t + (on ? 9.0 : 5.0)).clamp(0.0, total);
      if (on) canvas.drawLine(a + unit * t, a + unit * end, paint);
      t = end;
      on = !on;
    }
  }

  void _drawBadge(Canvas canvas, String label, Offset pos, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos + const Offset(4, -6));
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: color, blurRadius: 5)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(_OverlayPainter _) => true;
}

// ─── Pantalla principal ──────────────────────────────────────────

class PhotoMeasureScreen extends StatefulWidget {
  final File imageFile;

  const PhotoMeasureScreen({super.key, required this.imageFile});

  @override
  State<PhotoMeasureScreen> createState() => _PhotoMeasureScreenState();
}

class _PhotoMeasureScreenState extends State<PhotoMeasureScreen> {
  Size _imageSize = Size.zero;
  bool _loaded = false;

  _Step _step = _Step.refA;
  bool _addingRump = false;
  bool _addingHeight = false;

  Offset? _refA, _refB;
  Offset? _shoulder, _rump;
  Offset? _withers, _sternum;
  Offset? _groundFoot;
  Offset? _tailhead, _hookBone;

  final _refLenCtrl = TextEditingController();
  double? _pixelsPerCm;

  // Resultados
  double? _bodyLengthCm;
  double? _bodyDepthCm;
  double? _estimatedHeartGirthCm;
  double? _withersHeightCm;
  double? _rumpAngleDeg;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  @override
  void dispose() {
    _refLenCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadImageSize() async {
    final bytes = await widget.imageFile.readAsBytes();
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    final img = await completer.future;
    if (mounted) {
      setState(() {
        _imageSize = Size(img.width.toDouble(), img.height.toDouble());
        _loaded = true;
      });
    }
  }

  Rect _displayRect(Size container) {
    if (_imageSize == Size.zero) return Rect.zero;
    final ia = _imageSize.width / _imageSize.height;
    final ca = container.width / container.height;
    if (ia > ca) {
      final h = container.width / ia;
      return Rect.fromLTWH(0, (container.height - h) / 2, container.width, h);
    } else {
      final w = container.height * ia;
      return Rect.fromLTWH((container.width - w) / 2, 0, w, container.height);
    }
  }

  Offset _toImageCoords(Offset tap, Rect dr) => Offset(
        ((tap.dx - dr.left) / dr.width * _imageSize.width)
            .clamp(0.0, _imageSize.width),
        ((tap.dy - dr.top) / dr.height * _imageSize.height)
            .clamp(0.0, _imageSize.height),
      );

  void _onTap(Offset tapDisplay, Rect dr) {
    final p = _toImageCoords(tapDisplay, dr);
    setState(() {
      if (_step == _Step.refA) {
        _refA = p;
        _step = _Step.refB;
      } else if (_step == _Step.refB) {
        _refB = p;
        WidgetsBinding.instance.addPostFrameCallback((_) => _askRefLen());
      } else if (_step == _Step.shoulder) {
        _shoulder = p;
        _step = _Step.rump;
      } else if (_step == _Step.rump) {
        _rump = p;
        _step = _Step.withers;
      } else if (_step == _Step.withers) {
        _withers = p;
        _step = _Step.sternum;
      } else if (_step == _Step.sternum) {
        _sternum = p;
        _computeMain();
      } else if (_step == _Step.groundFoot) {
        _groundFoot = p;
        _computeHeight();
        _step = _addingRump ? _Step.tailhead : _Step.done;
      } else if (_step == _Step.tailhead) {
        _tailhead = p;
        _step = _Step.hookBone;
      } else if (_step == _Step.hookBone) {
        _hookBone = p;
        _computeRumpAngle();
        _step = _Step.done;
      }
    });
  }

  Future<void> _askRefLen() async {
    _refLenCtrl.clear();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Longitud de la referencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresá la longitud real del segmento que marcaste '
              '(cinta métrica, palo, distancia entre postes, '
              'altura de una persona, etc.).',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _refLenCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Longitud real (cm)',
                suffixText: 'cm',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _refA = null;
                _refB = null;
                _step = _Step.refA;
              });
            },
            child: const Text('Volver a marcar'),
          ),
          FilledButton(
            onPressed: () {
              final cm =
                  double.tryParse(_refLenCtrl.text.replaceAll(',', '.'));
              if (cm == null || cm <= 0) return;
              final px = (_refB! - _refA!).distance;
              setState(() {
                _pixelsPerCm = px / cm;
                _step = _Step.shoulder;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _computeMain() {
    if (_pixelsPerCm == null) return;
    final ppc = _pixelsPerCm!;

    if (_shoulder != null && _rump != null) {
      _bodyLengthCm = (_rump! - _shoulder!).distance / ppc;
    }
    if (_withers != null && _sternum != null) {
      _bodyDepthCm = (_sternum! - _withers!).distance / ppc;
    }
    // Estimar PT desde profundidad torácica.
    // Sección transversal del tórax ≈ elipse con semieje b = profundidad/2.
    // Sin ancho frontal, tomamos relación anatómica típica en bovinos:
    // ancho ≈ 0.72 × profundidad (vista frontal).
    // PT ≈ π × √((a² + b²) / 2)  (Ramanujan approx)
    if (_bodyDepthCm != null) {
      final d = _bodyDepthCm!;
      final b = d / 2; // semieje vertical
      final a = (d * 0.72) / 2; // semieje horizontal (estimado)
      _estimatedHeartGirthCm = pi * sqrt((a * a + b * b) / 2) * 2;
    }

    // ¿Opcionales activos?
    if (_addingHeight) {
      _step = _Step.groundFoot;
    } else if (_addingRump) {
      _step = _Step.tailhead;
    } else {
      _step = _Step.done;
    }
  }

  void _computeHeight() {
    if (_withers == null || _groundFoot == null || _pixelsPerCm == null) return;
    _withersHeightCm = (_groundFoot! - _withers!).distance / _pixelsPerCm!;
  }

  void _computeRumpAngle() {
    if (_tailhead == null || _hookBone == null) return;
    // En imagen Y crece hacia abajo.
    // El ángulo es respecto a la horizontal.
    final dx = (_hookBone!.dx - _tailhead!.dx).abs();
    final dy = _tailhead!.dy - _hookBone!.dy; // positivo si hookBone está más arriba
    _rumpAngleDeg = atan2(dy.abs(), dx) * 180 / pi;
  }

  List<_MPoint> get _points {
    return [
      if (_refA != null)
        _MPoint(id: 'rA', pos: _refA!, color: Colors.yellow[700]!, label: 'Ref A'),
      if (_refB != null)
        _MPoint(id: 'rB', pos: _refB!, color: Colors.yellow[700]!, label: 'Ref B'),
      if (_shoulder != null)
        _MPoint(id: 'sh', pos: _shoulder!, color: Colors.blue[300]!, label: 'Hombro'),
      if (_rump != null)
        _MPoint(id: 'ru', pos: _rump!, color: Colors.blue[300]!, label: 'Isquión'),
      if (_withers != null)
        _MPoint(id: 'wi', pos: _withers!, color: const Color(0xFF66BB6A), label: 'Cruz'),
      if (_sternum != null)
        _MPoint(id: 'st', pos: _sternum!, color: const Color(0xFF66BB6A), label: 'Esternón'),
      if (_groundFoot != null)
        _MPoint(id: 'gf', pos: _groundFoot!, color: Colors.purple[300]!, label: 'Suelo'),
      if (_tailhead != null)
        _MPoint(id: 'th', pos: _tailhead!, color: Colors.orange[400]!, label: 'Rabija'),
      if (_hookBone != null)
        _MPoint(id: 'hb', pos: _hookBone!, color: Colors.orange[400]!, label: 'Anca'),
    ];
  }

  List<_Segment> get _segments {
    return [
      if (_refA != null && _refB != null)
        _Segment('rA', 'rB', Colors.yellow[700]!, 'REFERENCIA'),
      if (_shoulder != null && _rump != null)
        _Segment('sh', 'ru', Colors.blue[400]!, 'LARGO'),
      if (_withers != null && _sternum != null)
        _Segment('wi', 'st', const Color(0xFF43A047), 'PROFUNDIDAD'),
      if (_withers != null && _groundFoot != null)
        _Segment('wi', 'gf', Colors.purple[300]!, 'ALZADA'),
      if (_tailhead != null && _hookBone != null)
        _Segment('th', 'hb', Colors.orange[400]!, 'GRUPA'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Medir en foto'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_step != _Step.done && _step != _Step.refA)
            TextButton(
              onPressed: _undo,
              child: const Text('← Deshacer',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Imagen con overlay ─────────────────────────────────
          Expanded(
            flex: 3,
            child: _loaded
                ? LayoutBuilder(builder: (ctx, box) {
                    final cSz = Size(box.maxWidth, box.maxHeight);
                    final dr = _displayRect(cSz);
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: _step == _Step.done
                          ? null
                          : (d) => _onTap(d.localPosition, dr),
                      child: Stack(
                        children: [
                          Image.file(
                            widget.imageFile,
                            fit: BoxFit.contain,
                            width: box.maxWidth,
                            height: box.maxHeight,
                          ),
                          CustomPaint(
                            size: cSz,
                            painter: _OverlayPainter(
                              points: _points,
                              segments: _segments,
                              imageSize: _imageSize,
                              displayRect: dr,
                            ),
                          ),
                          // Indicador visual de espera de toque
                          if (_step != _Step.done)
                            Positioned(
                              top: 8,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.touch_app,
                                          color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text('Tocá el punto indicado',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  })
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
          ),

          // ── Panel de instrucciones ─────────────────────────────
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              child: _buildPanel(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel() {
    switch (_step) {
      case _Step.refA:
        return _StepPanel(
          step: '1/5',
          color: Colors.yellow[700]!,
          icon: Icons.straighten,
          title: 'Marcá la referencia de escala — Punto A',
          body: 'Tocá el INICIO de un objeto de longitud conocida que esté '
              'en la foto: cinta métrica, palo medido, distancia entre postes, '
              'o cualquier elemento cuya longitud real conozcas.',
          hint: 'El objeto de referencia debe estar en el mismo plano que el '
              'animal (no delante ni detrás) para evitar error de perspectiva.',
        );
      case _Step.refB:
        return _StepPanel(
          step: '1/5',
          color: Colors.yellow[700]!,
          icon: Icons.straighten,
          title: 'Referencia — Punto B',
          body: 'Ahora tocá el OTRO EXTREMO del mismo objeto de referencia.',
          hint: 'Intentá que los dos puntos estén bien separados: '
              'mayor longitud de referencia = mayor precisión de la escala.',
        );
      case _Step.shoulder:
        return _StepPanel(
          step: '2/5',
          color: Colors.blue,
          icon: Icons.arrow_forward,
          title: 'Punto anterior del hombro',
          body: 'Tocá el punto más ADELANTADO del hombro: donde el cuello '
              'se une al cuerpo (articulación escápulo-humeral).',
          hint: 'Es el punto de inicio del largo del cuerpo. '
              'En la vista lateral se ve como la prominencia ósea '
              'entre el cuello y el tronco.',
        );
      case _Step.rump:
        return _StepPanel(
          step: '3/5',
          color: Colors.blue,
          icon: Icons.arrow_back,
          title: 'Isquión (punto trasero de la cadera)',
          body: 'Tocá el punto MÁS TRASERO de la cadera: '
              'la tuberosidad isquiática, la protuberancia ósea visible '
              'en la parte trasera baja de la cadera.',
          hint: 'Junto con el hombro define el largo corporal, '
              'el parámetro más importante de la fórmula Anderson.',
        );
      case _Step.withers:
        return _StepPanel(
          step: '4/5',
          color: const Color(0xFF43A047),
          icon: Icons.arrow_upward,
          title: 'Cruz (punto más alto del lomo)',
          body: 'Tocá el punto MÁS ALTO del lomo, justo detrás de la nuca '
              '(vértebras dorsales 2–5). Es la referencia de alzada.',
          hint: 'La cruz es el punto más alto del esqueleto, '
              'antes de que el lomo empiece a bajar hacia los riñones.',
        );
      case _Step.sternum:
        return _StepPanel(
          step: '5/5',
          color: const Color(0xFF43A047),
          icon: Icons.arrow_downward,
          title: 'Esternón (punto más bajo del pecho)',
          body: 'Tocá el punto MÁS BAJO del pecho (esternón), '
              'visible entre las patas delanteras. '
              'La distancia cruz→esternón es la PROFUNDIDAD TORÁCICA, '
              'que usamos para estimar el perímetro torácico.',
          hint: 'Cuanto más precisa sea esta medida, más exacto será el '
              'perímetro torácico estimado y por lo tanto el peso.',
        );
      case _Step.groundFoot:
        return _StepPanel(
          step: 'Opcional',
          color: Colors.purple,
          icon: Icons.vertical_align_bottom,
          title: 'Suelo bajo las patas delanteras',
          body: 'Tocá el punto del SUELO justo debajo de las patas '
              'delanteras. Junto con la cruz calculamos la ALZADA real '
              'del animal.',
          hint: 'Para mayor precisión la cámara debería estar a la misma '
              'altura que la cruz (unos 130–140 cm del suelo).',
        );
      case _Step.tailhead:
        return _StepPanel(
          step: 'Opcional',
          color: Colors.orange,
          icon: Icons.change_history,
          title: 'Rabija (base de la cola)',
          body: 'Tocá la BASE DE LA COLA: donde nace la cola en la grupa '
              '(tuberosidad isquiática superior / cabeza de la cola).',
          hint: 'El ángulo de la grupa es clave para predecir facilidad de '
              'parto: < 2° muy plana, 2–8° ideal, > 8° muy inclinada.',
        );
      case _Step.hookBone:
        return _StepPanel(
          step: 'Opcional',
          color: Colors.orange,
          icon: Icons.change_history,
          title: 'Anca (gancho lateral de la cadera)',
          body: 'Tocá el punto más SALIENTE de la cadera lateral: '
              'la tuberosidad coxal. Junto con la rabija define el '
              'ángulo de la grupa.',
        );
      case _Step.done:
        return _ResultsPanel(
          bodyLengthCm: _bodyLengthCm,
          bodyDepthCm: _bodyDepthCm,
          heartGirthCm: _estimatedHeartGirthCm,
          withersHeightCm: _withersHeightCm,
          rumpAngleDeg: _rumpAngleDeg,
          canAddHeight: _withersHeightCm == null,
          canAddRump: _rumpAngleDeg == null,
          onAddHeight: () => setState(() {
            _addingHeight = true;
            _step = _Step.groundFoot;
          }),
          onAddRump: () => setState(() {
            _addingRump = true;
            _step = _Step.tailhead;
          }),
          onConfirm: () => Navigator.pop(
            context,
            PhotoMeasureResult(
              pixelsPerCm: _pixelsPerCm ?? 1,
              bodyLengthCm: _bodyLengthCm,
              bodyDepthCm: _bodyDepthCm,
              estimatedHeartGirthCm: _estimatedHeartGirthCm,
              withersHeightCm: _withersHeightCm,
              rumpAngleDeg: _rumpAngleDeg,
            ),
          ),
        );
    }
  }

  void _undo() {
    setState(() {
      if (_step == _Step.refB) {
        _refA = null;
        _step = _Step.refA;
      } else if (_step == _Step.shoulder) {
        _refB = null;
        _pixelsPerCm = null;
        _step = _Step.refB;
      } else if (_step == _Step.rump) {
        _shoulder = null;
        _step = _Step.shoulder;
      } else if (_step == _Step.withers) {
        _rump = null;
        _step = _Step.rump;
      } else if (_step == _Step.sternum) {
        _withers = null;
        _step = _Step.withers;
      } else if (_step == _Step.groundFoot) {
        _sternum = null;
        _bodyLengthCm = null;
        _bodyDepthCm = null;
        _estimatedHeartGirthCm = null;
        _step = _Step.sternum;
      } else if (_step == _Step.tailhead) {
        if (_addingHeight) {
          _groundFoot = null;
          _withersHeightCm = null;
          _step = _Step.groundFoot;
        } else {
          _sternum = null;
          _bodyLengthCm = null;
          _bodyDepthCm = null;
          _estimatedHeartGirthCm = null;
          _step = _Step.sternum;
        }
      } else if (_step == _Step.hookBone) {
        _tailhead = null;
        _step = _Step.tailhead;
      }
    });
  }
}

// ─── Panel de instrucciones ───────────────────────────────────────

class _StepPanel extends StatelessWidget {
  final String step;
  final Color color;
  final IconData icon;
  final String title;
  final String body;
  final String? hint;

  const _StepPanel({
    required this.step,
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(step,
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4)),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates_outlined,
                      size: 14, color: Colors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(hint!,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Panel de resultados ──────────────────────────────────────────

class _ResultsPanel extends StatelessWidget {
  final double? bodyLengthCm;
  final double? bodyDepthCm;
  final double? heartGirthCm;
  final double? withersHeightCm;
  final double? rumpAngleDeg;
  final bool canAddHeight;
  final bool canAddRump;
  final VoidCallback onAddHeight;
  final VoidCallback onAddRump;
  final VoidCallback onConfirm;

  const _ResultsPanel({
    this.bodyLengthCm,
    this.bodyDepthCm,
    this.heartGirthCm,
    this.withersHeightCm,
    this.rumpAngleDeg,
    required this.canAddHeight,
    required this.canAddRump,
    required this.onAddHeight,
    required this.onAddRump,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    double? schoorl, anderson;
    if (heartGirthCm != null) {
      schoorl = pow(heartGirthCm! + 22, 2) / 100;
      if (bodyLengthCm != null) {
        anderson = (heartGirthCm! * heartGirthCm! * bodyLengthCm!) / 10840;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              const Text('Medición completa',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 14)),
              const Spacer(),
              if (canAddHeight)
                _SmallButton(
                    Icons.height, 'Alzada', Colors.purple, onAddHeight),
              if (canAddRump)
                _SmallButton(
                    Icons.change_history, 'Grupa', Colors.orange, onAddRump),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (bodyLengthCm != null)
                _Chip('Largo corporal',
                    '${bodyLengthCm!.toStringAsFixed(1)} cm', Colors.blue,
                    measured: true),
              if (bodyDepthCm != null)
                _Chip('Profundidad torácica',
                    '${bodyDepthCm!.toStringAsFixed(1)} cm', Colors.green,
                    measured: true),
              if (heartGirthCm != null)
                _Chip('PT estimado ≈',
                    '${heartGirthCm!.toStringAsFixed(1)} cm', Colors.teal,
                    measured: false),
              if (withersHeightCm != null)
                _Chip('Alzada a la cruz',
                    '${withersHeightCm!.toStringAsFixed(1)} cm',
                    Colors.purple,
                    measured: true),
              if (rumpAngleDeg != null)
                _Chip('Ángulo de grupa',
                    '${rumpAngleDeg!.toStringAsFixed(1)}°', Colors.orange,
                    measured: true),
            ],
          ),
          if (schoorl != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _WeightCol('Schoorl', schoorl, 0.65),
                if (anderson != null)
                  _WeightCol('Anderson', anderson, 0.80),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              '* PT estimado desde profundidad torácica (±10–20%).\n'
              '  Para mayor exactitud medí el PT con cinta métrica y completalo a mano.',
              style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: onConfirm,
              icon: const Icon(Icons.check),
              label: const Text('Usar estos valores'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SmallButton(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text('+ $label', style: const TextStyle(fontSize: 12)),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool measured;

  const _Chip(this.label, this.value, this.color, {required this.measured});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(measured ? Icons.straighten : Icons.auto_fix_high,
                  size: 10, color: color.withOpacity(0.7)),
              const SizedBox(width: 3),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _WeightCol extends StatelessWidget {
  final String formula;
  final double kg;
  final double confidence;

  const _WeightCol(this.formula, this.kg, this.confidence);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(formula,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
        Text('${kg.toStringAsFixed(0)} kg',
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary)),
        Text('confianza ${(confidence * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}
