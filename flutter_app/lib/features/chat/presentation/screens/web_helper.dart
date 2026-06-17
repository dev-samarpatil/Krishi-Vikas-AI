import 'web_helper_stub.dart' if (dart.library.js) 'web_helper_web.dart';

void callJsMethod(String method, [List<dynamic>? args]) {
  callJsMethodImpl(method, args);
}
