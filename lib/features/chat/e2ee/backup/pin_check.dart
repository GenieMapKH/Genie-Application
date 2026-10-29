import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/chat/data/chat_backup_repository.dart';

/// What happened to one PIN the user typed. The PIN screen shows it while
/// the user is still typing, instead of closing and failing afterwards.
sealed class PinCheckResult {
  const PinCheckResult();
}

/// The PIN was right and did what it was typed for.
class PinAccepted extends PinCheckResult {
  const PinAccepted();
}

/// The server counted a wrong PIN. [attemptsLeft] are left before the
/// backup locks, when the server says.
class PinRejected extends PinCheckResult {
  final int? attemptsLeft;

  const PinRejected({this.attemptsLeft});
}

/// Too many wrong PINs: no PIN is checked for [retryAfter], when known.
class PinLockedOut extends PinCheckResult {
  final Duration? retryAfter;

  const PinLockedOut({this.retryAfter});
}

/// The PIN could not be checked (no connection, server error).
class PinCheckFailed extends PinCheckResult {
  const PinCheckFailed();
}

/// Tries one typed PIN.
typedef PinCheck = Future<PinCheckResult> Function(String pin);

/// Asks for the PIN and hands each one typed to the check, until one is
/// accepted (true) or the user gives up (false).
typedef PinPrompt = Future<bool> Function(PinCheck check);

/// Runs [attempt], which uses a typed PIN, and says how it went.
Future<PinCheckResult> checkPin(Future<void> Function() attempt) async {
  try {
    await attempt();
    return const PinAccepted();
  } on WrongPinException catch (e) {
    return PinRejected(attemptsLeft: e.attemptsLeft);
  } on BackupRateLimitedException catch (e) {
    return PinLockedOut(retryAfter: e.retryAfter);
  } catch (e, stackTrace) {
    AppLogger.error('Could not check the PIN', e, stackTrace);
    return const PinCheckFailed();
  }
}
