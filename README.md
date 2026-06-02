# Objetos Perdidos UdeA - Frontend

Aplicación web desarrollada en Flutter para la gestión de objetos perdidos en la Universidad de Antioquia. Este frontend permite a estudiantes reportar objetos perdidos, consultar objetos publicados, crear solicitudes de reclamo y recibir notificaciones. También incluye un panel administrativo para gestionar inventario, solicitudes, reportes, coincidencias, estudiantes y entregas.

## URL de despliegue

Frontend desplegado en Netlify:

https://objetos-perdidos-udea.netlify.app/

## Backend conectado

Este frontend consume la API REST del backend desplegado en Render:

https://objetos-perdidos-udea-back.onrender.com

La URL base se configura en:

```dart
lib/Constants/api_config.dart

Ejemplo:

class ApiConfig {
  static const String baseUrl =
      'https://objetos-perdidos-udea-back.onrender.com';
}
Tecnologías utilizadas
Flutter
Dart
Supabase Auth
Supabase Storage
API REST con backend Spring Boot
Netlify para despliegue web
Arquitectura general

El proyecto está separado en frontend, backend y base de datos:

Flutter Web
→ API REST Spring Boot
→ Supabase PostgreSQL
→ Supabase Storage

El frontend no realiza operaciones principales directamente sobre la base de datos. La lógica de negocio se gestiona desde el backend mediante endpoints REST.

Supabase se utiliza para:

Autenticación de usuarios.
Almacenamiento público de imágenes en Storage.
Módulos principales
1. Autenticación

La aplicación permite iniciar sesión con cuenta institucional de la Universidad de Antioquia.

Condición de acceso:

@udea.edu.co

El frontend obtiene la sesión activa desde Supabase Auth y envía el token al backend cuando se requiere validar el usuario autenticado.

2. Perfil de usuario

Cuando el usuario inicia sesión, el sistema valida si su perfil está completo.

Datos gestionados:

Nombre
Celular
Número de documento
Tipo de documento
Correo institucional
Rol
Estado

La información se consulta y actualiza a través del backend.

3. Objetos publicados

Los usuarios pueden consultar los objetos disponibles para reclamo.

Se muestra información como:

Nombre del objeto
Categoría
Descripción general
Fotografía
Fecha de hallazgo

Por privacidad, algunos datos internos como ubicación exacta o lugar actual no se muestran públicamente.

4. Detalle de objeto

El usuario puede abrir el detalle de un objeto publicado para revisar su información y crear una solicitud de reclamo.

Desde esta pantalla se puede iniciar el flujo de solicitud si el usuario cree que el objeto le pertenece.

5. Solicitudes de reclamo

Los usuarios pueden crear solicitudes de reclamo sobre objetos publicados.

Cada solicitud puede tener estados como:

Pendiente
Aprobada
Rechazada
Anulada
Entregada

El usuario puede consultar el estado de sus solicitudes desde la sección “Mis solicitudes”.

6. Reportes de pérdida

Los usuarios pueden reportar un objeto perdido cuando no aparece publicado en el sistema.

El reporte incluye:

Descripción del objeto perdido
Fecha aproximada de pérdida
Lugar aproximado de pérdida

El administrador puede revisar estos reportes y buscar coincidencias con objetos registrados.

7. Coincidencias

Desde el panel administrativo, el administrador puede encontrar una coincidencia entre un reporte de pérdida y un objeto registrado.

Cuando se encuentra una coincidencia:

Se crea una solicitud asociada al reporte.
Se notifica al usuario.
El reporte cambia de estado.
El usuario puede ver el resultado en sus reportes o notificaciones.
8. Notificaciones

La aplicación incluye notificaciones para usuarios y administradores.

El usuario recibe notificaciones cuando:

Su solicitud fue aprobada.
Su solicitud fue rechazada.
Se encontró una coincidencia con su reporte.
Su objeto fue entregado.

El administrador recibe notificaciones cuando:

Un usuario crea una solicitud de reclamo.
Un usuario crea un reporte de pérdida.

Las notificaciones pueden marcarse como leídas y eliminarse desde el frontend usando endpoints del backend.

9. Panel administrativo

El administrador tiene acceso a módulos especiales:

Registrar objeto
Inventario completo
Objetos publicados
Solicitudes de reclamo
Reportes de pérdida
Objetos vencidos
Directorio de estudiantes
Notificaciones

Estas pantallas están diseñadas principalmente para uso en computador.

10. Registro de objetos

El administrador puede registrar objetos encontrados.

Puede:

Registrar objeto sin publicar.
Registrar y publicar objeto.
Adjuntar fotografía.
Definir categoría.
Definir lugar.
Agregar descripción.

Las imágenes se guardan en Supabase Storage y la URL pública se almacena para que pueda ser mostrada en el frontend.

Ejemplo de URL válida:

https://qzqvvdnjizhaewbizoit.supabase.co/storage/v1/object/public/objetos-imagenes/objetos/17-1780348640572.jpg
11. Entrega de objetos

Cuando una solicitud es aprobada, el administrador puede registrar la entrega del objeto.

Al registrar la entrega:

La solicitud cambia a estado entregada.
El objeto cambia de estado.
La publicación se oculta.
Se crea una notificación para el usuario.
12. Directorio de estudiantes

El administrador puede consultar el directorio de estudiantes registrados en el sistema.

Este módulo consume datos desde el backend y permite revisar información básica de usuarios.

Flujo principal del sistema
1. Usuario inicia sesión con correo institucional.
2. Usuario consulta objetos publicados.
3. Usuario crea solicitud de reclamo o reporte de pérdida.
4. Administrador revisa solicitudes y reportes.
5. Administrador aprueba, rechaza o encuentra coincidencias.
6. Usuario recibe notificaciones.
7. Administrador registra entrega.
8. El proceso queda finalizado.
Instalación local

Clonar el repositorio:

git clone <URL_DEL_REPOSITORIO_FRONTEND>
cd Objetos-perdidos-Udea-Front

Instalar dependencias:

flutter pub get

Ejecutar en navegador:

flutter run -d chrome --web-port 3000
Configuración del backend

Para desarrollo local:

class ApiConfig {
  static const String baseUrl = 'http://localhost:8080';
}

Para producción:

class ApiConfig {
  static const String baseUrl =
      'https://objetos-perdidos-udea-back.onrender.com';
}
Generar build web

Antes de desplegar en Netlify:

flutter clean
flutter pub get
flutter build web

El resultado queda en:

build/web

Esa carpeta es la que se despliega en Netlify.

Despliegue en Netlify

El frontend fue desplegado manualmente en Netlify usando el build generado por Flutter.

Pasos:

1. Ejecutar flutter build web.
2. Ir a Netlify.
3. Crear nuevo sitio.
4. Subir o arrastrar la carpeta build/web.
5. Netlify genera la URL pública.
Estructura general del proyecto
lib/
├── Constants/
│   └── api_config.dart
├── Repositories/
├── Screens/
├── models/
├── services/
└── main.dart
Separación frontend-backend

El proyecto está separado en dos repositorios:

Frontend:
Flutter Web desplegado en Netlify.

Backend:
Spring Boot desplegado en Render.

El frontend no contiene la lógica principal del negocio. Su función es mostrar la interfaz, capturar acciones del usuario y consumir los endpoints del backend.

El backend se encarga de:

Procesar solicitudes.
Consultar y modificar la base de datos.
Crear notificaciones.
Cambiar estados.
Validar usuarios.
Gestionar reportes, objetos y entregas.
Principios aplicados
Separación de responsabilidades

Cada parte del sistema tiene una responsabilidad clara:

Pantallas: interfaz de usuario.
Repositorios frontend: llamadas HTTP.
Backend: lógica de negocio.
Base de datos: persistencia.
Storage: almacenamiento de imágenes.
Cliente-servidor

El frontend actúa como cliente y el backend como servidor API.

Reutilización

Se usan componentes visuales reutilizables como headers, tarjetas y estilos comunes para mantener consistencia visual.

Mantenibilidad

La configuración de la URL del backend se centraliza en ApiConfig, evitando repetir URLs en múltiples archivos.

Estado actual del proyecto

El frontend se encuentra funcional e integrado con el backend desplegado.

Funcionalidades completadas:

Inicio de sesión.
Validación de usuario institucional.
Perfil de usuario.
Consulta de objetos publicados.
Registro de solicitudes.
Reportes de pérdida.
Notificaciones.
Panel administrativo.
Inventario.
Directorio de estudiantes.
Coincidencias.
Entrega de objetos.
Despliegue en Netlify.
Recomendaciones futuras

Autores

Emmanuel Duque Restrepo
Luciana Alvarez Tellez

Proyecto desarrollado como solución para la gestión de objetos perdidos en la Universidad de Antioquia.