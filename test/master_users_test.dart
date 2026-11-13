import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adn_carwash_master/main.dart';
import 'package:adn_carwash_master/features/master_users/master_users_screen.dart';

void main() {
  group('ADN Publicidad Software Master - Usuarios Master', () {
    Future<void> openUsers(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(const AdnCarWashMaster());

      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(InkWell, 'Usuarios Master'));

      await tester.pumpAndSettle();
    }

    testWidgets('Permite abrir el directorio de usuarios', (
      WidgetTester tester,
    ) async {
      await openUsers(tester);

      expect(find.byType(MasterUsersScreen), findsOneWidget);

      expect(find.text('Directorio de usuarios Master'), findsOneWidget);

      expect(find.text('Nuevo usuario'), findsOneWidget);
    });

    testWidgets('Permite abrir el formulario de nuevo usuario', (
      WidgetTester tester,
    ) async {
      await openUsers(tester);

      await tester.tap(find.text('Nuevo usuario'));

      await tester.pumpAndSettle();

      expect(find.byType(MasterUserFormDialog), findsOneWidget);

      expect(find.byKey(const Key('master_user_name')), findsOneWidget);

      expect(find.byKey(const Key('master_user_email')), findsOneWidget);

      expect(find.text('Rol preliminar *'), findsOneWidget);
    });

    testWidgets('Valida campos obligatorios y formato de correo', (
      WidgetTester tester,
    ) async {
      await openUsers(tester);

      await tester.tap(find.text('Nuevo usuario'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Validar datos'));
      await tester.pumpAndSettle();

      expect(find.text('Este campo es obligatorio.'), findsOneWidget);

      expect(find.text('Ingresa un correo electr\u00f3nico.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('master_user_name')),
        'Usuario de Prueba',
      );

      await tester.enterText(
        find.byKey(const Key('master_user_email')),
        'correo-invalido',
      );

      await tester.tap(find.text('Validar datos'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ingresa un correo electr\u00f3nico v\u00e1lido.'),
        findsOneWidget,
      );

      expect(find.byType(MasterUserFormDialog), findsOneWidget);
    });

    testWidgets('Validar datos no registra un usuario', (
      WidgetTester tester,
    ) async {
      await openUsers(tester);

      await tester.tap(find.text('Nuevo usuario'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('master_user_name')),
        'Usuario de Prueba',
      );

      await tester.enterText(
        find.byKey(const Key('master_user_email')),
        'prueba@ejemplo.com',
      );

      await tester.tap(find.text('Validar datos'));
      await tester.pumpAndSettle();

      expect(find.byType(MasterUserFormDialog), findsNothing);

      expect(find.text('No hay usuarios para mostrar'), findsOneWidget);
    });
  });
}
