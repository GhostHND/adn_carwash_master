import 'package:adn_carwash_master/features/onboarding/master_onboarding.dart';
import 'package:adn_carwash_master/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Muestra el recorrido inicial, lo guarda y permite abrirlo luego',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(const AdnCarWashMaster(showFirstUseGuide: true));
      await tester.pumpAndSettle();

      expect(find.byType(MasterOnboardingDialog), findsOneWidget);
      expect(find.text('Guía de primer uso'), findsOneWidget);
      expect(find.text('Paso 1 de 8'), findsOneWidget);
      expect(find.textContaining('master.adnpublicidad.site'), findsOneWidget);

      for (var step = 1; step < masterOnboardingSteps.length; step++) {
        await tester.tap(find.text('Siguiente'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Paso 8 de 8'), findsOneWidget);
      expect(find.text('Revisa operación y auditoría'), findsOneWidget);

      await tester.tap(find.text('Terminar'));
      await tester.pumpAndSettle();

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getBool(masterOnboardingCompletedKey), isTrue);
      expect(find.byType(MasterOnboardingDialog), findsNothing);

      await tester.tap(find.byTooltip('Guía de uso'));
      await tester.pumpAndSettle();

      expect(find.byType(MasterOnboardingDialog), findsOneWidget);
      expect(find.text('Guía de Software Master'), findsOneWidget);
      expect(find.text('Paso 1 de 8'), findsOneWidget);
    },
  );

  testWidgets('Permite saltar la guía de primer uso', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(const AdnCarWashMaster(showFirstUseGuide: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saltar guía'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(masterOnboardingCompletedKey), isTrue);
    expect(find.byType(MasterOnboardingDialog), findsNothing);
  });
}
