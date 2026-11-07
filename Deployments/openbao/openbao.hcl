# OpenBao opera dentro de la red privada de Docker. No se publica el puerto 8200
# en el host. Para un clúster de más de un nodo, sustituir este almacenamiento
# Raft local por una configuración de alta disponibilidad antes de escalar.
ui = true
disable_mlock = false

storage "raft" {
  path    = "/openbao/data"
  node_id = "tcg-community-1"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  # El tráfico queda limitado a tcg-network. Si OpenBao se expone fuera de esa
  # red, configurar TLS antes de publicar el puerto.
  tls_disable = true
}

api_addr     = "http://openbao:8200"
cluster_addr = "https://openbao:8201"
