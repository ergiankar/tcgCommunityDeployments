# tcgCommunityDeployments

Repositorio para los **despliegues en Azure** de tcgCommunity: la infraestructura, la configuración de cada entorno y los pasos para publicar cada versión.

> Estado: **inicial**. Todavía no hay infraestructura definida; este repositorio solo deja preparado el sitio donde irá.

## Qué se despliega

| Pieza | Repositorio | Tecnología |
|---|---|---|
| Frontend | [tcgCommunity](https://github.com/ergiankar/tcgCommunity) | Next.js 16 (TypeScript). Trae su `Dockerfile` y `build-docker.sh`. |
| Backend | [tcgCommunityBackend](https://github.com/ergiankar/tcgCommunityBackend) | Java 21 con Spring Boot. Aplica las migraciones de Flyway al arrancar. |
| Base de datos | — | PostgreSQL |
| Secretos | — | OpenBao (KV v2) |

El navegador solo habla con el frontend. Es el servidor de Next.js quien llama al backend, y su dirección va en la variable `API_BASE_URL` del frontend.

## Por decidir

- Herramienta de infraestructura como código (Bicep, Terraform u otra).
- Entornos (por ejemplo, desarrollo y producción) y cómo se nombran.
- Cómo se publica: a mano, o con CI/CD desde GitHub Actions.
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

## Inicializar OpenBao

OpenBao se ejecuta con almacenamiento Raft persistente y solo es accesible desde
la red interna de Docker. En el primer despliegue hay que inicializarlo y
desbloquearlo antes de levantar el backend. Conserva las claves de desbloqueo y
el token raíz en un gestor de secretos externo; no los copies al archivo `.env`.

```sh
cd Deployments
docker compose up -d openbao
docker compose exec openbao bao operator init
# Ejecuta este comando tres veces, cada una con una clave distinta del paso anterior.
docker compose exec openbao bao operator unseal
```

Con el token raíz temporalmente disponible en la sesión, crea el motor KV v2, la
política del backend y un token de solo lectura. Sustituye los valores de ejemplo
por los secretos reales:

```sh
export BAO_TOKEN='token-raiz-guardado-fuera-del-repositorio'
docker compose exec -e BAO_ADDR=http://127.0.0.1:8200 -e BAO_TOKEN openbao \
  bao secrets enable -path=tcgcommunity kv-v2
docker compose cp openbao/backend-policy.hcl openbao:/tmp/backend-policy.hcl
docker compose exec -e BAO_ADDR=http://127.0.0.1:8200 -e BAO_TOKEN openbao \
  bao policy write tcg-community-backend /tmp/backend-policy.hcl
docker compose exec -e BAO_ADDR=http://127.0.0.1:8200 -e BAO_TOKEN openbao \
  bao token create -policy=tcg-community-backend -orphan -period=24h
```

Guarda el valor `token` del último comando como `OPENBAO_BACKEND_TOKEN` en
`Deployments/.env`. A continuación, carga los secretos del backend (las claves
usan los nombres de propiedad de Spring):

```sh
docker compose exec -e BAO_ADDR=http://127.0.0.1:8200 -e BAO_TOKEN openbao \
  bao kv put tcgcommunity/tcg-community-backend \
  spring.datasource.password='contraseña-postgres' \
  app.security.jwt.secret='secreto-jwt-de-al-menos-32-bytes' \
  app.photo-verification.secret='secreto-de-verificacion-de-fotos' \
  app.whatsapp.bird.api-key='bk_eu1_...' \
  spring.mail.password='contraseña-smtp'
```

Finalmente, arranca el conjunto completo. El backend espera a que OpenBao esté
inicializado y desbloqueado y luego importa esos secretos automáticamente:

```sh
docker compose up -d
```
