# API de ADN Publicidad Software Master

Backend central en Laravel 13, PHP 8.3+, MySQL y Laravel Sanctum. Flutter debe
comunicarse con esta API por HTTPS y nunca conectarse directamente a MySQL.

## Instalación local

1. Crea una base MySQL y un usuario dedicado.
2. Copia `.env.example` a `.env` y configura `DB_DATABASE`, `DB_USERNAME`,
   `DB_PASSWORD`, `APP_URL`, `MASTER_FRONTEND_URL` y
   `MASTER_CORS_ALLOWED_ORIGINS`. En producción, limita los orígenes permitidos
   a los dominios HTTPS que sirven el frontend.
3. Instala dependencias y genera la clave de la aplicación:

   ```powershell
   composer install
   php artisan key:generate
   ```

4. Aplica las migraciones y crea interactivamente el primer administrador:

   ```powershell
   php artisan migrate
   php artisan master:permissions:seed
   php artisan master:admin:create
   ```

   El catálogo de permisos es idempotente y también se inicializa al crear el
   primer administrador; el comando explícito permite actualizar instalaciones
   existentes. El alta solicita la contraseña sin incluirla en el historial del
   shell. No se crean usuarios de demostración ni datos comerciales
   automáticamente.

5. Inicia la API local:

   ```powershell
   php artisan serve
   ```

6. Para crear ADN CarWash y ADN Fidelidad como borradores del catálogo, ejecuta
   el comando idempotente:

   ```powershell
   php artisan master:catalog:seed-products
   ```

   No crea planes, precios ni instancias.

## API implementada

- `GET /api/v1/health` informa disponibilidad del proceso de la API; no
  comprueba productos ni servicios externos.
- `POST /api/v1/auth/login` emite un token Bearer Sanctum con vencimiento.
- `POST /api/v1/auth/logout` revoca el token presentado.
- `GET /api/v1/auth/me` devuelve el perfil administrativo autenticado.
- `POST /api/v1/auth/password/forgot` envía un enlace si la cuenta existe y
  mantiene el mismo mensaje para cuentas desconocidas.
- `POST /api/v1/auth/password/reset` cambia la contraseña y revoca los tokens
  vigentes.
- `GET /api/v1/products`, `POST /api/v1/products`,
  `GET /api/v1/products/{publicId}` y `PATCH /api/v1/products/{publicId}`
  administran productos con paginación, filtros e identificadores públicos.
  Los productos nuevos se crean como borradores en Flutter; en el catálogo
  autenticado usa «Activar» para habilitar la activación de sus planes.
- Los mismos métodos sobre `/api/v1/customers` administran clientes y validan
  identificadores tributarios únicos.
- `GET`, `POST`, `GET /{publicId}` y `PATCH /{publicId}` sobre
  `/api/v1/plans` administran planes por producto, incluidos sus códigos de
  funcionalidades. Los planes se crean como borradores sin precio; para
  activarlos se requieren precio, moneda, período, funcionalidades y producto
  activo.
- Los mismos métodos sobre `/api/v1/instances` administran instancias y
  persisten su relación con cliente, producto, plan e infraestructura. Cada
  alta queda como borrador y no contrata hosting/dominio ni provisiona
  servidores. Los dominios registrados son únicos.
- `GET /api/v1/integrations/{productCode}/subscriptions/{instancePublicId}`
  entrega a ADN Fidelidad la suscripción vigente mediante Bearer y firma HMAC.
- `php artisan fidelidad:sync` reconcilia cambios y entrega los eventos pendientes
  desde una outbox durable; el scheduler lo ejecuta cada minuto.
- `GET`, `POST`, `GET /{id}`, `PATCH /{id}` y `DELETE /{id}` sobre
  `/api/v1/users` permiten a un owner administrar cuentas. `GET`, `POST`,
  `GET /{id}`, `PATCH /{id}` y `DELETE /{id}` sobre `/api/v1/roles` permiten
  mantener roles y asignaciones del catálogo de permisos; el rol `owner` es
  inmutable y no se puede retirar o desactivar al último owner activo.
- `GET /api/v1/permissions` devuelve el catálogo paginado y
  `GET /api/v1/audit-events` consulta la bitácora inmutable con el permiso
  `audit.view`. Las mutaciones autenticadas se registran sin cuerpos, tokens ni
  contraseñas; si no se puede guardar la auditoría, la mutación se revierte y
  el error se hace visible.
- La API de facturación permite crear y consultar suscripciones y cargos en
  borrador, emitir cargos, registrar pagos pendientes, confirmarlos manualmente
  y asignarlos a cargos. `POST /api/v1/subscriptions/{id}/activate` sólo permite
  que un owner active una suscripción con fecha vigente y un cargo emitido
  totalmente cubierto por pagos confirmados. `POST
  /api/v1/subscriptions/{id}/cancel` cancela de inmediato y detiene cargos
  futuros; no revierte cargos ya emitidos ni crea reembolsos. Las suscripciones
  activas vencen al día siguiente de `ends_on`; el vencimiento deja un evento
  de auditoría del sistema. Al asignar pagos confirmados que cubren el importe
  completo, el cargo cambia a `paid` y registra `paid_at`. Un owner puede anular
  un cargo borrador o emitido sin pagos asignados, indicando el motivo: el cargo
  y la auditoría se conservan. No se anulan pagos ni se generan reembolsos.
  Los cargos anulados no impiden corregir partidas de una suscripción en
  borrador. El cargo inicial se emite bajo bloqueo de la suscripción y
  comprueba el importe y fecha confirmados para evitar duplicados o cambios
  inesperados.
- `php artisan billing:charges:generate` genera e emite cargos vencidos de
  suscripciones activas según la frecuencia de cada partida (`monthly`,
  `quarterly`, `yearly` o `one_time`). El scheduler lo ejecuta diariamente a
  las 00:10 y usa claves idempotentes para no duplicar cargos. La confirmación
  de pagos es manual por un owner; no hay pasarela conectada.

Las operaciones de directorio y facturación requieren token activo y el permiso
adecuado. El comando inicial asigna el rol reservado `owner`; únicamente un
owner activo puede administrar usuarios, roles y permisos.

## Cliente Flutter

Flutter se conecta a `https://master.adnpublicidad.site/api/v1` por defecto.
Para desarrollo local, configura la URL al compilar:

```powershell
flutter run -d edge --web-port=58080 --dart-define=MASTER_API_BASE_URL=http://127.0.0.1:8000/api/v1
```

El acceso, la recuperación de contraseña y los directorios de productos,
clientes, planes e instancias usan la API en el modo autenticado. El token
Bearer vive sólo en memoria y se pierde al recargar la aplicación. La vista
previa continúa siendo local. Las opciones autenticadas «Suscripciones» y
«Pagos» abren la facturación conectada a la API, que crea
suscripciones, emite cargos, registra y confirma pagos y solicita la activación
o cancelación mediante la API. Las pantallas autenticadas de usuarios, roles,
permisos y auditoría también consumen la API. Monitoreo, licencias, respaldos y
ajustes siguen pendientes.

## Integración con ADN Fidelidad

Configura `FIDELIDAD_API_URL`, `FIDELIDAD_PRODUCT_CODE`,
`FIDELIDAD_WEBHOOK_SECRET`, `FIDELIDAD_API_KEY` y `FIDELIDAD_API_SECRET` con
valores aleatorios compartidos según el sentido de cada conexión. En
Fidelidad, `MASTER_WEBHOOK_SECRET` debe coincidir con `FIDELIDAD_WEBHOOK_SECRET`;
`MASTER_API_KEY` y `MASTER_API_SECRET` deben coincidir con las credenciales
`FIDELIDAD_API_KEY` y `FIDELIDAD_API_SECRET` de Master.

En producción, Master debe responder en `https://master.adnpublicidad.site` y
Fidelidad en `https://fidelidad.adnpublicidad.site`. El `.env.example` usa
valores locales para desarrollo. En el `.env` de producción, configura:

```dotenv
APP_ENV=production
APP_DEBUG=false
APP_URL=https://master.adnpublicidad.site
MASTER_FRONTEND_URL=https://master.adnpublicidad.site
MASTER_CORS_ALLOWED_ORIGINS=https://master.adnpublicidad.site
FIDELIDAD_API_URL=https://fidelidad.adnpublicidad.site
```

Configura `MAIL_MAILER` y sus credenciales SMTP con el proveedor elegido; el
valor `log` de desarrollo no entrega correos de recuperación. Mantén
`APP_KEY`, credenciales MySQL y secretos de integración únicamente en el
administrador de variables del hosting, nunca en el repositorio ni en el chat.

El identificador `software_instances.public_id` es el
`business.master_business_id` del contrato. La opción «Vincular Fidelidad» en
Instancias permite a un owner buscar un negocio existente, seleccionarlo y
confirmar su vínculo. No crea negocios ni modifica su acceso al vincularlo.
Una instancia no puede asociarse a varios negocios, ni un negocio a otra
instancia; repetir la misma vinculación es seguro.

Para habilitarla, despliega ambos backends y configura un secreto aleatorio
independiente de al menos 32 bytes, idéntico en `FIDELIDAD_LINK_SECRET` de
Master y `MASTER_LINK_SECRET` de Fidelidad. No reutilices el secreto de
eventos ni compartas secretos por chat. Usa HTTPS; después de cambiar variables
actualiza la caché de configuración de Laravel según el despliegue. Fidelidad
necesita una caché compartida con `add` atómico entre todos sus procesos para
impedir repeticiones de solicitudes.

Antes de vincular un negocio cuyo acceso debe conservarse, revisa las
suscripciones existentes y los eventos pendientes de esa instancia: después
de vincularla, la sincronización programada puede aplicar eventos previamente
registrados. La vinculación por sí sola no confirma pagos, activa contratos ni
marca la instancia como provisionada. Tras verificar y confirmar el pago, un
owner puede activar la suscripción correspondiente y verificar la
sincronización. El sincronizador persiste eventos antes de enviarlos, conserva los
fallos para reintento y sólo marca como entregadas las respuestas reconocidas
(`applied`, `duplicate` o `ignored`).

El scheduler ejecuta `fidelidad:sync` cada minuto, vence contratos a las 00:05
y genera cargos a las 00:10. Configura un cron que ejecute
`php artisan schedule:run` cada minuto. La reconciliación envía las claves
`wallet_apple`, `wallet_google`, `reports`,
`export`, `multiple_programs`, `staff` y los límites `max_programs`,
`max_branches`, `max_staff`, `max_customers`. Los planes y precios no se
precargan. El mecanismo usa tareas programadas, no un worker persistente de cola.

La documentación oficial de Hostinger indica que SSH está disponible en
Premium Web o superior, que web hosting admite cron jobs y que Premium o
superior permite cron jobs ilimitados. Laravel 13 requiere PHP 8.3+, por lo
que hay que seleccionar una versión compatible en hPanel. Verifica los límites
exactos del producto/cuenta antes del despliegue: [SSH](https://www.hostinger.com/support/1583645-how-to-enable-ssh-access-in-hostinger/),
[cron jobs](https://www.hostinger.com/support/1583765-how-many-cron-jobs-can-you-set-up-in-hostinger/),
[versiones de PHP](https://www.hostinger.com/support/1575755-how-to-change-the-php-version-of-your-hostinger-hosting-plan/)
y [límites del plan](https://www.hostinger.com/support/6976044-parameters-and-limits-of-hosting-plans-in-hostinger/).
La conexión remota MySQL no se necesita para sincronizar Master con Fidelidad;
la integración usa HTTPS entre APIs.

Configura `MASTER_FRONTEND_URL` con el origen donde estará la pantalla para
restablecer contraseñas. `SANCTUM_EXPIRATION` establece la vigencia del token
en minutos. El valor de ejemplo es ocho horas para desarrollo y debe revisarse
antes de producción.

## Validación

Desde esta carpeta ejecuta:

```powershell
php artisan test
php vendor/bin/pint --test
```

Las pruebas usan SQLite en memoria. El `.env.example` configura MySQL para
desarrollo habitual; las migraciones de planes e instancias se aplicaron en el
MySQL local de WAMP. El esquema y el despliegue en el servidor de producción
aún deben verificarse.

La integración de suscripciones con ADN Fidelidad está implementada en código,
pero su uso real requiere completar las credenciales, vincular cada negocio y
configurar el scheduler. Falta definir renovaciones y reembolsos, e implementar
las funciones de licencias, monitoreo, respaldos y ajustes.
La conexión MySQL de producción, pruebas de restauración y despliegue en
Hostinger también siguen pendientes.
