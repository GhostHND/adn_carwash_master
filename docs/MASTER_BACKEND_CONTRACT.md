# ADN Publicidad Software Master
## Contrato inicial de arquitectura y persistencia

Estado: esquema base y autenticación implementados; contratos comerciales aún
requieren APIs y configuración de producción.

### 1. Objetivo

Software Master administra varios productos comerciales
de ADN Publicidad y las instalaciones contratadas.

ADN CarWash es el primer producto.

La aplicación Flutter se comunica con una API central.
Flutter no se conecta directamente a MySQL.

### 2. Separación de datos

BASE CENTRAL DE MASTER

Contendrá:
- Usuarios administrativos y autenticación.
- Productos de software.
- Clientes.
- Planes comerciales por producto.
- Instancias contratadas.
- Dominios y referencias al hosting.
- Suscripciones y condiciones económicas.
- Cargos emitidos.
- Pagos confirmados y sus aplicaciones.
- Licencias y decisiones de suspensión.
- Eventos de monitoreo.
- Auditoría administrativa.
- Metadatos de respaldos.
- Configuración general.

BASE OPERATIVA DE CADA INSTANCIA

Contendrá los datos propios del producto contratado.

Ejemplos:
- Servicios y vehículos de ADN CarWash.
- Citas de una futura barbería.
- Pedidos de un futuro restaurante.

Las bases operativas no deben mezclarse entre clientes.

### 3. Entidades centrales previstas

software_products
- id
- code
- name
- category
- status
- created_at
- updated_at

customers
- id
- legal_name
- trade_name
- email
- phone
- tax_identifier
- status
- created_at
- updated_at

product_plans
- id
- product_id
- code
- name
- status
- created_at
- updated_at

plan_features
- id
- plan_id
- feature_code
- limit_value

software_instances
- id
- customer_id
- product_id
- plan_id
- name
- domain
- administrative_status
- provisioning_status
- created_at
- updated_at

instance_infrastructure
- id
- instance_id
- hosting_provider
- hosting_reference
- database_reference
- domain_provider
- domain_renewal_date
- hosting_renewal_date
- currency
- hosting_cost_cents
- hosting_charge_cents
- domain_cost_cents
- domain_charge_cents

subscriptions
- id
- instance_id
- status
- starts_on
- ends_on
- grace_days
- currency
- created_at
- updated_at

subscription_items
- id
- subscription_id
- concept
- amount_cents
- billing_frequency
- effective_from
- effective_until

charges
- id
- subscription_id
- instance_id
- concept
- due_date
- amount_cents
- status
- issued_at
- created_at

payments
- id
- customer_id
- amount_cents
- currency
- payment_method
- external_reference
- confirmation_status
- confirmed_at
- created_at

payment_allocations
- id
- payment_id
- charge_id
- amount_cents

license_records
- id
- instance_id
- status
- contract_valid_until
- administrative_hold
- last_verified_at
- updated_at

license_authorizations
- id
- instance_id
- authorization_id
- issued_at
- expires_at
- revoked_at

monitoring_events
- id
- instance_id
- service_code
- observed_at
- status
- details

backup_jobs
- id
- scope
- instance_id
- requested_by
- status
- started_at
- completed_at
- integrity_verified_at
- storage_reference

audit_events
- id
- actor_id
- action
- resource_type
- resource_id
- occurred_at
- outcome
- request_reference
- metadata

system_settings
- id
- setting_key
- setting_value
- updated_at
- updated_by

Este inventario sigue siendo el contrato inicial. El backend ya cuenta con
migraciones para usuarios, roles, permisos, productos, versiones, planes,
clientes, instancias, infraestructura, suscripciones, cargos, pagos, licencias,
monitoreo, respaldos, auditoría y ajustes. Las pruebas actuales ejecutan estas
migraciones con SQLite; su verificación contra el MySQL de producción sigue
pendiente.

### 5. Integración de suscripciones con ADN Fidelidad

En producción, la API Master se publica bajo `https://master.adnpublicidad.site`
y Fidelidad bajo `https://fidelidad.adnpublicidad.site`. La aplicación pública y
el editor mantienen sus hosts separados (`app.adnpublicidad.site` y
`editor.adnpublicidad.site`); el dominio raíz `adnpublicidad.site` continúa
siendo el sitio público.

El UUID público de cada instancia Master es su identificador de negocio
compartido (`business.master_business_id`) en ADN Fidelidad. Fidelidad debe
tener previamente un negocio vinculado a ese UUID; la API actual no provisiona
ni modifica negocios remotos.

Master ofrece
`GET /api/v1/integrations/{product_code}/subscriptions/{instance_public_id}`
con Bearer API key y firma HMAC-SHA256 de
`timestamp + "\n" + idempotency_key + "\n" + raw_body`. Para GET, el body está
vacío. Master también reconcilia suscripciones y las emite a
`POST /api/v1/master/entitlements` con el mismo formato de firma y los campos
definidos en [API_SOFTWARE_MASTER.md](../../ADN%20Fidelidad/docs/API_SOFTWARE_MASTER.md).

Los cambios salientes se guardan en una outbox con `event_id` estable y
`event_version` creciente por instancia. Cada intento usa una clave de
idempotencia nueva; la entrega se confirma sólo ante `applied`, `duplicate` o
`ignored`. Los errores permanecen pendientes con backoff exponencial. El
comando `php artisan fidelidad:sync` se programa cada minuto; el entorno debe
ejecutar `php artisan schedule:run` por cron.

El contrato no crea planes ni precios. Los códigos de funcionalidad y límites
aceptados están coordinados con `config/fidelidad.php` del producto:
`wallet_apple`, `wallet_google`, `reports`, `export`,
`multiple_programs`, `staff`, y los límites `max_programs`, `max_branches`,
`max_staff`, `max_customers`. Cambios a ese catálogo requieren actualizar ambos
productos de forma coordinada. La integración no está activa hasta configurar
secretos/API keys y completar la vinculación de negocios.

### 4. Relaciones obligatorias

Un cliente puede tener varias instancias.

Un producto puede estar contratado en varias instancias.

Un plan pertenece a un producto.

Una instancia solo puede seleccionar un plan
del producto contratado.

Una suscripción pertenece a una instancia.

Los cargos pertenecen a una suscripción.

Los pagos pueden distribuirse entre distintos cargos,
mediante payment_allocations.

La licencia controla exclusivamente una instancia.

Suspender una instancia no suspende automáticamente
las demás instancias del mismo cliente.

### 5. Precios, costos y facturación

Todos los importes monetarios se almacenarán
en unidades mínimas de moneda, como centavos.

Debe identificarse la moneda.

Costo del proveedor y cargo al cliente son diferentes.

El software podrá cobrarse mensualmente.

El hosting podrá tener una frecuencia propia.

El dominio podrá tener renovación anual.

La frecuencia definitiva dependerá del contrato.

Las condiciones económicas históricas
no se recalcularán automáticamente cuando cambie
el catálogo de precios.

Las proyecciones no representan deuda exigible.

Solo los cargos emitidos y válidos
pueden contribuir a una cuenta por cobrar.

Solo los pagos confirmados
pueden reducir formalmente el saldo adeudado.

### 6. Licencias

El estado de una licencia debe calcularse
desde el servidor.

Deben distinguirse:
- Vigencia del contrato.
- Saldo pendiente confirmado.
- Plazo de gracia aplicable.
- Suspensión administrativa.
- Estado de comunicación.
- Autorización vigente de la instancia.

Las autorizaciones para instancias
deberán firmarse digitalmente.

Una falla temporal de comunicación
no debe interpretarse como falta de pago.

El backend del producto contratado
debe verificar la autorización.

Una suspensión no debe eliminar datos.

### 7. API central

Implementado:
GET  /api/v1/health
POST /api/v1/auth/login
POST /api/v1/auth/logout
GET  /api/v1/auth/me
POST /api/v1/auth/password/forgot
POST /api/v1/auth/password/reset

Productos (requiere `products.manage`):
GET  /api/v1/products
POST /api/v1/products
GET  /api/v1/products/{publicId}
PATCH /api/v1/products/{publicId}

Clientes (requiere `customers.manage`):
GET  /api/v1/customers
POST /api/v1/customers
GET  /api/v1/customers/{publicId}
PATCH /api/v1/customers/{publicId}

Pendiente de implementar:
GET  /api/v1/products/{productId}/plans

Instancias:
GET  /api/v1/instances
POST /api/v1/instances
GET  /api/v1/instances/{instanceId}

Suscripciones:
GET  /api/v1/subscriptions
POST /api/v1/subscriptions

Cargos:
GET  /api/v1/charges
POST /api/v1/charges

Pagos:
GET  /api/v1/payments
POST /api/v1/payments

Licencias:
GET  /api/v1/licenses
POST /api/v1/licenses/{instanceId}/suspend
POST /api/v1/licenses/{instanceId}/reactivate

Verificación entre servidores:
POST /api/v1/instance-authorization/verify

Monitoreo:
GET  /api/v1/monitoring

Respaldos:
GET  /api/v1/backups
POST /api/v1/backups

Auditoría:
GET  /api/v1/audit-events

Configuración:
GET  /api/v1/settings
PUT  /api/v1/settings

Las rutas pendientes son propuestas y no deben considerarse operativas.
La autenticación usa tokens Bearer de Sanctum con vencimiento configurable.
Los identificadores públicos de productos y clientes son UUID; las claves
numéricas internas no se exponen en esos recursos.

### 8. Reglas de seguridad

La API autentica y autoriza cada operación.

Flutter nunca contiene credenciales de MySQL.

No se guardan contraseñas de hosting
en tablas comerciales de texto plano.

Los secretos operativos se gestionan
en un almacenamiento seguro del servidor.

Las contraseñas de usuarios se almacenan
mediante hashes adecuados.

Las solicitudes que cambian pagos o licencias
requieren permisos específicos.

Los webhooks de pago deben verificar
su autenticidad y ser idempotentes.

La auditoría real se genera en el backend,
no en Flutter.

Los respaldos deben estar protegidos,
cifrados cuando corresponda y verificados.

La restauración debe probarse periódicamente.

### 9. Repositorios Flutter previstos

ProductRepository
CustomerRepository
PlanRepository
InstanceRepository
SubscriptionRepository
ChargeRepository
PaymentRepository
LicenseRepository
MonitoringRepository
BackupRepository
AuditRepository
SettingsRepository

Estos repositorios consumirán la API central.

Los ValueNotifier y registros en memoria
se sustituirán gradualmente por esos repositorios.

### 10. Orden de implementación del backend

1. Configuración de Laravel y MySQL.
2. Autenticación y permisos del Master.
3. Migraciones de productos, clientes y planes.
4. Migraciones de instancias e infraestructura.
5. Suscripciones y condiciones comerciales.
6. Cargos, pagos y conciliaciones.
7. Control de licencias entre servidores.
8. Monitoreo, auditoría y respaldos.
9. Integración de cada producto contratado.
10. Pruebas de seguridad y despliegue.

### 11. Despliegue

Primero se utilizará WAMP como entorno local.

El despliegue posterior se evaluará
según las capacidades disponibles en Hostinger.

No se presupone acceso remoto directo a MySQL.

No se presupone que todas las bases de datos
puedan administrarse desde un único alojamiento.

El aislamiento por instancia debe comprobarse
antes de contratar infraestructura definitiva.
