
#!/usr/bin/env bash

set -Eeuo pipefail

# Directorios
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Configuración del repositorio fuente
FRONTEND_REPO_URL="git@github.com:ergiankar/tcgCommunity.git"
GIT_BRANCH="${GIT_BRANCH:-main}"

# Configuración de la imagen
IMAGE_NAME="${IMAGE_NAME:-tcgcommunity-front-app}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

DOCKERFILE="${SCRIPT_DIR}/Dockerfile"
DOCKERIGNORE="${SCRIPT_DIR}/.dockerignore"

# Validaciones
for command in git docker; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "ERROR: No se encuentra el comando $command." >&2
    exit 1
  fi
done

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: No se puede acceder al motor Docker." >&2
  exit 1
fi

for file in "$DOCKERFILE" "$DOCKERIGNORE"; do
  if [[ ! -f "$file" ]]; then
    echo "ERROR: No se encuentra $file." >&2
    exit 1
  fi
done

# Checkout temporal: no modifica el repositorio CI/CD
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

SOURCE_DIR="${WORK_DIR}/frontend"

echo "========================================"
echo " Construcción de imagen del frontend"
echo "========================================"
echo "Repositorio: $FRONTEND_REPO_URL"
echo "Rama:        $GIT_BRANCH"

git clone \
  --depth 1 \
  --single-branch \
  --branch "$GIT_BRANCH" \
  "$FRONTEND_REPO_URL" \
  "$SOURCE_DIR"

# Validar estructura del proyecto
for file in package.json package-lock.json; do
  if [[ ! -f "${SOURCE_DIR}/${file}" ]]; then
    echo "ERROR: No se encuentra ${file} en el frontend." >&2
    exit 1
  fi
done

# Aplicar las reglas de exclusión del repositorio CI/CD
cp "$DOCKERIGNORE" "${SOURCE_DIR}/.dockerignore"

IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
COMMIT="$(git -C "$SOURCE_DIR" rev-parse --short HEAD)"

echo
echo "Construyendo imagen: $IMAGE"
echo "Commit del frontend: $COMMIT"

docker build \
  --pull \
  --file "$DOCKERFILE" \
  --tag "$IMAGE" \
  "$SOURCE_DIR"

echo
echo "========================================"
echo " Construcción completada"
echo "========================================"
echo "Imagen: $IMAGE"
echo "Commit: $COMMIT"
