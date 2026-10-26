
#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Repositorio fuente
BACKEND_REPO_URL="git@github.com:ergiankar/tcgCommunityBackend.git"
GIT_BRANCH="${GIT_BRANCH:-main}"

# Imagen Docker
IMAGE_NAME="${IMAGE_NAME:-tcgcommunity-backend-app}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

DOCKERFILE="${SCRIPT_DIR}/Dockerfile"
DOCKERIGNORE="${SCRIPT_DIR}/.dockerignore"

# Validar herramientas
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

# Checkout temporal
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

SOURCE_DIR="${WORK_DIR}/backend"

# Directorio del proyecto Maven dentro del repositorio clonado
BACKEND_PROJECT_DIR="${SOURCE_DIR}/backend"

echo "========================================"
echo " Construcción de imagen del backend"
echo "========================================"
echo "Repositorio: $BACKEND_REPO_URL"
echo "Rama:        $GIT_BRANCH"

git clone \
  --depth 1 \
  --single-branch \
  --branch "$GIT_BRANCH" \
  "$BACKEND_REPO_URL" \
  "$SOURCE_DIR"


# Validar estructura Maven
for file in pom.xml mvnw; do
  if [[ ! -f "${BACKEND_PROJECT_DIR}/${file}" ]]; then
    echo "ERROR: No se encuentra ${file} en ${BACKEND_PROJECT_DIR}." >&2
    exit 1
  fi
done

if [[ ! -d "${BACKEND_PROJECT_DIR}/.mvn" || ! -d "${BACKEND_PROJECT_DIR}/src" ]]; then
  echo "ERROR: El backend no contiene .mvn/ o src/." >&2
  exit 1
fi

# Aplicar las reglas de exclusión centralizadas
cp "$DOCKERIGNORE" "${BACKEND_PROJECT_DIR}/.dockerignore"

IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
COMMIT="$(git -C "$SOURCE_DIR" rev-parse --short HEAD)"

echo
echo "Construyendo imagen: $IMAGE"
echo "Directorio Maven: $BACKEND_PROJECT_DIR"
echo "Commit del backend: $COMMIT"

docker build \
  --pull \
  --file "$DOCKERFILE" \
  --tag "$IMAGE" \
  "$BACKEND_PROJECT_DIR"

echo
echo "========================================"
echo " Construcción completada"
echo "========================================"
echo "Imagen: $IMAGE"
echo "Commit: $COMMIT"
