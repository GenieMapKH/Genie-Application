/// True for a 6-digit PIN an attacker would try first: one repeated digit
/// (000000), a straight run (123456, 987654) or a repeated group (121212,
/// 123123). The server allows only a few tries, so these must not be chosen.
bool isGuessablePin(String pin) {
  final digits = pin.codeUnits;
  if (digits.length < 2) return true;

  final step = digits[1] - digits[0];
  final isRun =
      step.abs() <= 1 &&
      Iterable.generate(
        digits.length - 1,
      ).every((i) => digits[i + 1] - digits[i] == step);

  final repeatsGroup = [2, 3].any(
    (size) =>
        pin.length % size == 0 &&
        pin == pin.substring(0, size) * (pin.length ~/ size),
  );

  return isRun || repeatsGroup;
}
