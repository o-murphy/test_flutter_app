import 'dart:math' as math;

class Vector {
  final double x;
  final double y;
  final double z;

  const Vector(this.x, this.y, this.z);

  Vector copy() => Vector(x, y, z);

  double mag() => math.sqrt(x * x + y * y + z * z);

  Vector operator *(double a) => Vector(x * a, y * a, z * a);

  Vector operator +(Vector b) => Vector(x + b.x, y + b.y, z + b.z);

  Vector operator -(Vector b) => Vector(x - b.x, y - b.y, z - b.z);

  Vector operator -() => Vector(-x, -y, -z);

  double dot(Vector b) => x * b.x + y * b.y + z * b.z;

  Vector norm() {
    final double m = mag();
    if (m.abs() < 1e-10) {
      return Vector(x, y, z);
    }
    return this * (1.0 / m);
  }

  static Vector sum(Iterable<Vector> vectors) {
    double sumX = 0;
    double sumY = 0;
    double sumZ = 0;

    for (final v in vectors) {
      sumX += v.x;
      sumY += v.y;
      sumZ += v.z;
    }

    return Vector(sumX, sumY, sumZ);
  }

  @override
  String toString() =>
      'Vector(${x.toStringAsFixed(4)}, ${y.toStringAsFixed(4)}, ${z.toStringAsFixed(4)})';

  static const zero = Vector(0, 0, 0);
}
