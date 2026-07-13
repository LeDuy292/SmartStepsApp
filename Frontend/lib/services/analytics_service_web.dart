import 'dart:js_interop';

// Bind to the gtag function in JS
@JS('gtag')
external void _gtag(JSString command, JSString eventName, [JSObject? parameters]);

class AnalyticsService {
  static void trackEvent(String eventName, [Map<String, dynamic>? parameters]) {
    try {
      if (parameters != null) {
        // Convert Dart Map to JSObject using dart:js_interop jsify extension
        final jsParams = parameters.jsify() as JSObject;
        _gtag('event'.toJS, eventName.toJS, jsParams);
      } else {
        _gtag('event'.toJS, eventName.toJS);
      }
    } catch (e) {
      // Fail-safe catch block
    }
  }
}
