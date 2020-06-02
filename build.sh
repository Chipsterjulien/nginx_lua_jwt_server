# Création de l'image
docker build -t img_alpine_rpi_guialarm:v1.0 .
# Création du container
docker run -d --restart unless-stopped --name container_alpine_rpi_guialarm -p 8090:8090 img_alpine_rpi_guialarm:v1.0