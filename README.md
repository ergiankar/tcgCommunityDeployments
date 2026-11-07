# tcgCommunityDeployments

Repositorio para los **despliegues en Azure** de tcgCommunity: la infraestructura, la configuración de cada entorno y los pasos para publicar cada versión.

> Estado: **inicial**. Todavía no hay infraestructura definida; este repositorio solo deja preparado el sitio donde irá.

## Qué se despliega

| Pieza | Repositorio | Tecnología |
|---|---|---|
| Frontend | [tcgCommunity](https://github.com/ergiankar/tcgCommunity) | Next.js 16 (TypeScript). Trae su `Dockerfile` y `build-docker.sh`. |
| Backend | [tcgCommunityBackend](https://github.com/ergiankar/tcgCommunityBackend) | Java 21 con Spring Boot. Aplica las migraciones de Flyway al arrancar. |
| Base de datos | — | PostgreSQL |

El navegador solo habla con el frontend. Es el servidor de Next.js quien llama al backend, y su dirección va en la variable `API_BASE_URL` del frontend.

## Por decidir

- Herramienta de infraestructura como código (Bicep, Terraform u otra).
- Entornos (por ejemplo, desarrollo y producción) y cómo se nombran.
- Cómo se publica: a mano, o con CI/CD desde GitHub Actions.
- Dónde se guardan los secretos (por ejemplo, Azure Key Vault).
- Dónde se guardan las fotos de las cartas (hoy, dentro de la base de datos).

## A tener en cuenta al desplegar

Cosas que ya sabemos de la aplicación y que afectan al despliegue:

- **Solo una instancia del backend por ahora.** El límite de peticiones por minuto vive en la memoria del backend; con varias instancias haría falta un almacén compartido (por ejemplo, Redis).
- **Las imágenes de cartas descargadas por el frontend viven en un volumen.** El volumen `tcg-data` se monta en `/app/data/card-images` y persiste entre despliegues. El catálogo (`card-catalog.json`) y las huellas visuales (`card-fingerprints.json`) se generan al construir la imagen del frontend y viajan dentro de ella.
- **La cámara y la ubicación del navegador solo funcionan por `https`.** Es necesario un certificado en el dominio público.
- **El backend ejecuta tareas periódicas** (por ejemplo, marcar como caducadas las publicaciones), así que debe estar siempre encendido.
- **Las variables de entorno y los secretos** de cada pieza se describen en su propio repositorio.

## Generar el catálogo y las huellas de cartas

Los ficheros `card-catalog.json` y `card-fingerprints.json` los genera el proyecto del frontend en local (`npm run catalog` y
`npm run fingerprints`) y no van a Git. El `Dockerfile` los ejecuta durante la construcción de la imagen, antes de compilar
Next.js. El script de construcción invalida esa capa en cada imagen, por lo que al publicar una imagen nueva también se
publica el catálogo y las huellas actualizados, sin ejecutar comandos ni copiar ficheros en el servidor.

La construcción necesita acceso a las páginas públicas de Bandai. Si la generación falla, la imagen no se publica para evitar
un despliegue sin catálogo completo o sin reconocimiento visual.

## Reglas del repositorio

- **Nunca se suben secretos:** contraseñas, claves, cadenas de conexión ni tokens. El `.gitignore` bloquea los ficheros habituales, pero no sustituye al cuidado.
- La rama principal es `main`.
- Los commits son pequeños y con un mensaje que diga qué cambia.

## Comando de ejcución

- docker compose --env-file Deployments/.env -f Deployments/docker-compose.yml up -d
