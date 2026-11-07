# Permite al backend leer solo su configuración y la común, sin administrar
# secretos ni acceder a otros motores/rutas de OpenBao.
path "tcgcommunity/data/application" {
  capabilities = ["read"]
}

path "tcgcommunity/data/tcg-community-backend" {
  capabilities = ["read"]
}
