import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adn_carwash_master/main.dart';
import 'package:adn_carwash_master/features/auth/master_access_app.dart';

void main() {
  group('ADN Publicidad Software Master - Autenticacion', () {
    testWidgets('La aplicacion inicia mostrando el login', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        const MasterAccessApp(previewApp: AdnCarWashMaster()),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MasterAccessScreen), findsOneWidget);

      expect(find.byKey(const Key('master_login_email')), findsOneWidget);

      expect(find.byKey(const Key('master_login_password')), findsOneWidget);

      expect(find.text('Panel general'), findsNothing);
    });

    testWidgets('El login valida los campos obligatorios', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        const MasterAccessApp(previewApp: AdnCarWashMaster()),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('master_submit')));

      await tester.pumpAndSettle();

      expect(find.text('Ingresa tu correo electr\u00f3nico.'), findsOneWidget);

      expect(find.text('Ingresa tu contrase\u00f1a.'), findsOneWidget);
    });

    testWidgets('Permite abrir la recuperacion de acceso', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        const MasterAccessApp(previewApp: AdnCarWashMaster()),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('master_forgot_password')));

      await tester.pumpAndSettle();

      expect(find.text('Recuperar acceso'), findsOneWidget);

      expect(find.byKey(const Key('master_login_password')), findsNothing);

      await tester.tap(find.byKey(const Key('master_back_to_login')));

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('master_login_password')), findsOneWidget);
    });

    testWidgets('La vista previa funciona en modo desarrollo', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        const MasterAccessApp(previewApp: AdnCarWashMaster()),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('master_preview_access')));

      await tester.pumpAndSettle();

      expect(find.text('Panel general'), findsOneWidget);
    });

    testWidgets('El formulario se adapta a un telefono', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        const MasterAccessApp(previewApp: AdnCarWashMaster()),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MasterAccessScreen), findsOneWidget);

      expect(find.byKey(const Key('master_login_email')), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
