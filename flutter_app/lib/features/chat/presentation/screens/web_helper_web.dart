import 'dart:js' as js;

void callJsMethodImpl(String method, [List<dynamic>? args]) {
  if (args == null) {
    js.context.callMethod(method);
  } else {
    js.context.callMethod(method, args);
  }
}
