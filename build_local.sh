# Création du répertoire db en y plaçant la base de donnée dedans
mkdir db && cp *.db db
# Création de l'image
docker build -f Dockerfile_local -t img_testing_guialarm:v0.9 .
# Création du container
docker run -tid --name testing_guialarm -p 8090:8090 -v "$(pwd):/app" img_testing_guialarm:v0.9