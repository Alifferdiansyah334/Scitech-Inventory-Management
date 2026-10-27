import 'dart:js_interop';

@JS('simsApplyWebUpdate')
external JSPromise<JSAny?> _applyWebUpdate();
Future<void> reloadUpdatedApp() async {
  await _applyWebUpdate().toDart;
}
