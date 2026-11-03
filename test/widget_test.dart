// Smoke test de la app con sesión restaurada por un repositorio falso.
// (La demo del contador fue reemplazada por el login real.)

import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/main.dart';

import 'fakes_auth.dart';

void main() {
  testWidgets('la app arranca en el splash y termina en el login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(SceiQrApp(authRepository: FakeAuthRepository()));

    // Splash: muestra logo y spinner mientras restaura la sesión.
    expect(find.text('SCEI QR'), findsOneWidget);

    await tester.pump();
    await tester.pumpAndSettle();

    // Sin sesión persistida → formulario de login.
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
  });
}
