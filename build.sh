# Création de l'image
docker build -t img_alpine_rpi_guialarm_server:v1.0.4 .
# Création du container
docker run -d --restart unless-stopped --name server_alpine_rpi_guialarm-v1.0.4 -p 8090:8090 -v dataAlarm:/app/run img_alpine_rpi_guialarm_server:v1.0.4 .