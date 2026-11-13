# ADN Publicidad Software Master

Aplicación administrativa central de ADN Publicidad. El frontend está
construido con Flutter y el backend API se encuentra en [`backend/`](./backend).
ADN CarWash y ADN Fidelidad son productos administrados por Master, no el nombre
del sistema central.

## Dominios

| Dirección | Uso |
| --- | --- |
| `https://adnpublicidad.site` | Sitio público |
| `https://app.adnpublicidad.site` | Aplicación pública |
| `https://editor.adnpublicidad.site` | Editor |
| `https://master.adnpublicidad.site` | Administración central Software Master |
| `https://fidelidad.adnpublicidad.site` | Producto ADN Fidelidad |

Master consume la API de Fidelidad por HTTPS en ese subdominio. La configuración
de DNS, certificados TLS, hosting y publicación de Flutter/Laravel debe hacerse
en el proveedor; documentar estos destinos no realiza cambios en dichos servicios.

## Desarrollo Flutter

Para trabajar con la API local, inicia Laravel desde `backend` y ejecuta
Flutter desde la raíz del proyecto:

```powershell
flutter run -d edge --web-port=58080 --dart-define=MASTER_API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Inicia sesión con un administrador de Master. Los orígenes locales deben estar
permitidos por `MASTER_CORS_ALLOWED_ORIGINS` en el backend. Para abrir sólo la
vista previa temporal, utiliza `flutter run -d edge -t lib/main_dev.dart`.

Para ejecutar el conjunto de pruebas y revisar el análisis estático:

```powershell
flutter test
flutter analyze
dart format --output=none --set-exit-if-changed lib test
```

El punto de entrada de producción es `lib/main.dart`. `lib/main_dev.dart` es
exclusivo para desarrollo.

En la primera apertura se muestra una guía paso a paso. El botón «Guía de uso»
en la barra superior permite volver a abrirla; la preferencia de finalización
se guarda en el dispositivo/navegador.

## Backend

Consulta [`backend/README.md`](./backend/README.md) para instalar Laravel,
configurar MySQL, crear el primer administrador y ejecutar las pruebas del API.

En el modo autenticado, productos, clientes, planes e instancias se consultan y
guardan mediante la API. La vista previa de desarrollo sigue siendo local;
suscripciones, pagos, monitoreo, licencias, respaldos, auditoría y otros
módulos aún no están completos para producción. Consulta
[`backend/README.md`](./backend/README.md) para el estado y las limitaciones.
