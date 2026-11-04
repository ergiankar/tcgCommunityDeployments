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
- **Los datos de cartas del frontend viven en un volumen.** El volumen `tcg-data` se monta en `/app/data` y guarda el catálogo (`card-catalog.json`), las huellas visuales (`card-fingerprints.json`) y las imágenes oficiales que el servidor descarga solo (`card-images/`). Persiste entre despliegues, pero los dos ficheros JSON hay que copiarlos a mano la primera vez (ver abajo).
- **La cámara y la ubicación del navegador solo funcionan por `https`.** Es necesario un certificado en el dominio público.
- **El backend ejecuta tareas periódicas** (por ejemplo, marcar como caducadas las publicaciones), así que debe estar siempre encendido.
- **Las variables de entorno y los secretos** de cada pieza se describen en su propio repositorio.

## Copiar el catálogo y las huellas de cartas (a mano)

Los ficheros `card-catalog.json` y `card-fingerprints.json` los genera el proyecto del frontend en local (`npm run catalog` y
`npm run fingerprints`) y no van a Git. Con los contenedores levantados, se copian al volumen una vez, y de nuevo cuando salgan
sets nuevos:

```bash
docker compose --env-file Deployments/.env -f Deployments/docker-compose.yml cp ./card-catalog.json frontend:/app/data/card-catalog.json
docker compose --env-file Deployments/.env -f Deployments/docker-compose.yml cp ./card-fingerprints.json frontend:/app/data/card-fingerprints.json
docker compose --env-file Deployments/.env -f Deployments/docker-compose.yml restart frontend
```

El reinicio hace falta porque el servidor carga ambos ficheros en memoria la primera vez que los usa. Sin ellos la app sigue
funcionando, pero con un catálogo reducido y sin el reconocimiento visual de fotos.

## Reglas del repositorio

- **Nunca se suben secretos:** contraseñas, claves, cadenas de conexión ni tokens. El `.gitignore` bloquea los ficheros habituales, pero no sustituye al cuidado.
- La rama principal es `main`.
- Los commits son pequeños y con un mensaje que diga qué cambia.

## Comando de ejcución

- docker compose --env-file Deployments/.env -f Deployments/docker-compose.yml up -d