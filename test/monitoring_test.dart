import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adn_carwash_master/main.dart';
import 'package:adn_carwash_master/features/monitoring/monitoring_screen.dart';

void main() {
  group('ADN Publicidad Software Master - Monitoreo', () {
    testWidgets('El menu abre el modulo Monitoreo', (
      WidgetTester tester,
    ) async {
      // Configurar una pantalla de escritorio.
      await tester.binding.setSurfaceSize(const Size(1280, 950));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      // Iniciar Software Master.
      await tester.pumpWidget(const AdnCarWashMaster());

      await tester.pumpAndSettle();

      // Localizar el menu lateral.
      final sidebar = find.byType(MasterSidebar);

      expect(sidebar, findsOneWidget);

      // Localizar exclusivamente el Scrollable
      // que pertenece al menu lateral.
      final sidebarScrollable = find.descendant(
        of: sidebar,
        matching: find.byType(Scrollable),
      );

      expect(sidebarScrollable, findsOneWidget);

      // La opcion puede no estar construida
      // inicialmente debido a ListView.builder.
      final monitoringMenu = find.widgetWithText(InkWell, 'Monitoreo');

      // Desplazar el menu hasta que Flutter
      // construya y muestre Monitoreo.
      await tester.scrollUntilVisible(
        monitoringMenu,
        180.0,
        scrollable: sidebarScrollable,
        maxScrolls: 30,
      );

      await tester.pumpAndSettle();

      // Comprobar que ahora existe.
      expect(monitoringMenu, findsOneWidget);

      // Abrir el modulo.
      await tester.tap(monitoringMenu);

      await tester.pumpAndSettle();

      // Verificar la navegacion.
      expect(find.byType(MonitoringScreen), findsOneWidget);

      // Verificar los componentes principales.
      expect(find.text('Estado de los servicios'), findsOneWidget);

      expect(find.text('Registro de incidencias'), findsOneWidget);
    });

    testWidgets('No muestra resultados de monitoreo ficticios', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 950));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MonitoringScreen())),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sin verificaciones registradas'), findsOneWidget);

      expect(find.byKey(const Key('monitoring_incidents')), findsOneWidget);

      expect(find.text('No disponible'), findsOneWidget);
    });

    testWidgets('La pantalla funciona en telefonos', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MonitoringScreen())),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MonitoringScreen), findsOneWidget);

      expect(find.text('Estado de los servicios'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
