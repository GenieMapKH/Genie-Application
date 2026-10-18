import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/features/chat/e2ee/e2ee_setup_service.dart';
import 'package:genie/features/chat/e2ee/password_lock_migration.dart';
import 'package:genie/features/chat/e2ee/pin_check.dart';
import 'package:genie/features/chat/e2ee/pin_rules.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';

enum ChatPinSetupStep {
  /// Only for chats still locked with the account password.
  password,
  choosePin,
  confirmPin,
}

/// Why a PIN was not taken. The screen turns it into a message.
enum ChatPinSetupProblem { tooGuessable, mismatch, saveFailed }

class ChatPinSetupState {
  final ChatPinSetupStep step;
  final bool busy;

  /// How the last password typed was answered (password step only).
  final PinCheckResult? passwordResult;
  final ChatPinSetupProblem? problem;

  /// Grows with every refused entry, so the field shakes each time.
  final int shakes;
  final bool done;

  const ChatPinSetupState({
    required this.step,
    this.busy = false,
    this.passwordResult,
    this.problem,
    this.shakes = 0,
    this.done = false,
  });

  /// A refused password may be one that was reset since: starting over
  /// with new keys is the way out.
  bool get canStartOver =>
      step == ChatPinSetupStep.password && passwordResult is PinRejected;
}

/// The steps of creating the account's chat PIN: the account password first
/// for chats still locked with it, then the PIN, typed twice.
class ChatPinSetupController extends StateNotifier<ChatPinSetupState> {
  final String userId;
  final E2eeSetupService setupService;

  /// Null for an account that has no backup at all yet.
  final PasswordLockMigration? migration;

  String? _chosenPin;
  String? _lastPassword;

  ChatPinSetupController({
    required this.userId,
    required this.setupService,
    this.migration,
  }) : super(
         ChatPinSetupState(
           step: migration == null
               ? ChatPinSetupStep.choosePin
               : ChatPinSetupStep.password,
         ),
       );

  Future<void> submitPassword(String password) async {
    final migration = this.migration;
    if (migration == null || password.isEmpty || state.busy) return;
    _lastPassword = password;
    await _checkPassword(() => migration.unlock(password));
  }

  /// New keys in place of the password-locked ones, with the password that
  /// was just refused as proof (it may be the current one, reset since).
  Future<void> startOver() async {
    final migration = this.migration;
    final password = _lastPassword;
    if (migration == null || password == null || state.busy) return;
    await _checkPassword(() => migration.startOver(password));
  }

  void choosePin(String pin) {
    if (isGuessablePin(pin)) {
      _refuse(problem: ChatPinSetupProblem.tooGuessable);
      return;
    }
    _chosenPin = pin;
    _moveTo(ChatPinSetupStep.confirmPin);
  }

  Future<void> confirmPin(String pin) async {
    if (state.busy) return;
    if (pin != _chosenPin) {
      _refuse(
        step: ChatPinSetupStep.choosePin,
        problem: ChatPinSetupProblem.mismatch,
      );
      return;
    }

    _moveTo(state.step, busy: true);
    final saved = await _save(pin);
    if (!mounted) return;
    if (saved) {
      state = ChatPinSetupState(
        step: state.step,
        shakes: state.shakes,
        done: true,
      );
    } else {
      _refuse(
        step: ChatPinSetupStep.choosePin,
        problem: ChatPinSetupProblem.saveFailed,
      );
    }
  }

  /// Back from confirming to choosing another PIN.
  void back() {
    _chosenPin = null;
    _moveTo(ChatPinSetupStep.choosePin);
  }

  Future<bool> _save(String pin) async {
    final migration = this.migration;
    if (migration != null) {
      return await migration.moveToPin(pin) is PinAccepted;
    }
    final result = await setupService.createPin(userId, pin);
    // A PIN set on another device just now protects the account too.
    return result != CreatePinResult.failed;
  }

  Future<void> _checkPassword(Future<PinCheckResult> Function() check) async {
    _moveTo(ChatPinSetupStep.password, busy: true);
    final result = await check();
    if (!mounted) return;
    if (result is PinAccepted) {
      _moveTo(ChatPinSetupStep.choosePin);
    } else {
      _refuse(passwordResult: result);
    }
  }

  void _moveTo(ChatPinSetupStep step, {bool busy = false}) {
    state = ChatPinSetupState(step: step, busy: busy, shakes: state.shakes);
  }

  void _refuse({
    ChatPinSetupStep? step,
    PinCheckResult? passwordResult,
    ChatPinSetupProblem? problem,
  }) {
    state = ChatPinSetupState(
      step: step ?? state.step,
      passwordResult: passwordResult,
      problem: problem,
      shakes: state.shakes + 1,
    );
  }
}

final chatPinSetupProvider = StateNotifierProvider.autoDispose
    .family<
      ChatPinSetupController,
      ChatPinSetupState,
      ({String userId, bool fromPassword})
    >(
      (ref, args) => ChatPinSetupController(
        userId: args.userId,
        setupService: ref.watch(e2eeSetupServiceProvider),
        migration: args.fromPassword
            ? ref.watch(passwordLockMigrationProvider(args.userId))
            : null,
      ),
    );
