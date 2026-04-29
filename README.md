🔐 Santo y Seña – Flutter Local Gestor de contraseñas

Aplicación móvil desarrollada en Flutter que implementa un gestor de contraseñas 100% local con cifrado AES manual y arquitectura limpia.

Proyecto educativo orientado a practicar seguridad intermedia, separación de capas y buenas prácticas profesionales en desarrollo móvil.

⚠️ Aviso Importante
Esta aplicación es un proyecto de aprendizaje con fines educativos. 
No está diseñada para gestionar contraseñas de sistemas críticos sin una auditoría de seguridad profesional. 
El uso es bajo responsabilidad del usuario.

🎯 Objetivo del Proyecto

Construir una aplicación de gestión de credenciales que:

Funcione completamente offline

No utilice backend ni Firebase

No almacene datos en texto plano

Implemente cifrado AES manual

Use derivación de clave basada en PIN

Siga una arquitectura limpia y modular

🏗️ Arquitectura

Estructura del proyecto:

lib/
│
├── models/      → Entidades puras
├── screens/     → UI
├── services/    → Lógica de negocio (cifrado, almacenamiento, sesión)
├── widgets/     → Componentes reutilizables
└── utils/       → Helpers técnicos

Principios aplicados:

Separación estricta de responsabilidades

Sin estado global inseguro

Sin gestión de estado compleja

Navegación clásica con Navigator

Código modular y mantenible

🔐 Modelo de Seguridad (Nivel Intermedio)

La aplicación implementa:

Protección mediante PIN

Derivación de clave usando SHA-256

Cifrado AES con IV aleatorio

Archivo JSON completamente cifrado

Persistencia únicamente del contenido cifrado

Clave mantenida solo en memoria durante la sesión

No se almacena:

PIN en texto plano

Clave derivada

JSON sin cifrar

📦 Tecnologías Utilizadas

Flutter

Dart

AES (modo CBC)

SHA-256

Almacenamiento local mediante archivo cifrado

📱 Funcionalidades

Listado de credenciales

Alta de nuevas credenciales

Visualización detallada

Edición

Eliminación con confirmación

Búsqueda en tiempo real

Campos obligatorios:

Aplicación

Contraseña

⚠️ Alcance del Proyecto

Este proyecto tiene fines educativos y de portfolio.

No implementa:

Protección avanzada contra ataques de fuerza bruta offline

PBKDF2 o derivación con salt persistente

Timeout automático de sesión

Biometría

Sincronización en la nube

El diseño está intencionalmente acotado a un nivel intermedio para fines de aprendizaje.

🚀 Posibles Mejoras Futuras

Autenticación biométrica

Generador de contraseñas

Timeout automático de sesión

Backup cifrado manual

Exportación segura

🧠 Enfoque de Aprendizaje

Este proyecto está diseñado para practicar:

Arquitectura limpia en Flutter

Separación de capas

Cifrado AES e IV

Derivación de clave

Manejo seguro de datos locales

Buenas prácticas para repositorios públicos
