/// Runs an async rebuild so that calls arriving while one is running fold into
/// a single follow-up run: a burst of triggers (a dragged corner, data landing
/// mid-zoom) never stacks rebuilds, and the latest trigger is always drawn.
class CoalescedRebuild {
  final Future<void> Function() _rebuild;
  bool _running = false;
  bool _queued = false;

  CoalescedRebuild(this._rebuild);

  Future<void> call() async {
    if (_running) {
      _queued = true;
      return;
    }

    _running = true;
    try {
      do {
        _queued = false;
        await _rebuild();
      } while (_queued);
    } finally {
      _running = false;
    }
  }
}
