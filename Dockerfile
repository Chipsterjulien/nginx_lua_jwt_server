# FROM alpine:3.11
FROM arm64v8/alpine:3.11
LABEL maintainer="julien"

# Installation des bon paquets
RUN apk update && \
    apk add --no-cache luarocks5.1 nginx nginx-mod-http-lua lua5.1-socket git make gcc musl-dev && \
    luarocks-5.1 install lua-resty-core && \
    apk del git make gcc musl-dev luarocks5.1 && \
    rm /var/cache/apk/*

# Créer l'utilisateur www
RUN adduser -H -D -g 'www' -G tty -s /bin/false www

# Se placer dans le répertoire /app
WORKDIR /app

# Création du répertoire /app/cfg
RUN mkdir /app/cfg && \
    # Création du répertoire pour la base de données
    mkdir /app/db && \
    # Supprime la configuration de nginx par défaut
    rm /etc/nginx/nginx.conf && rm /etc/nginx/conf.d/default.conf

# Ajout de ma configuration personnel nginx
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./nginx/conf.d/guiAlarm.conf /etc/nginx/conf.d/guiAlarm.conf

# Ajout des programmes lua pour gérer l'authentification et le reste de l'API REST
COPY *.lua /app/
COPY external/ /app/external
COPY third-party/ /app/third-party
COPY *.db /app/db/
COPY ./cfg/guiAlarm.toml /app/cfg/

# Mettre les bonnes permissions
RUN mkdir /run/nginx && touch /run/nginx/nginx.pid && \
    # mkdir -p /var/lib/nginx/tmp/client_body && \
    chown -R www: /app && chmod -R 744 /app && \
    chown -R www: /run/nginx && \
    chown -R www: /var/lib/nginx && \
    chown -R www: /var/log/nginx && \
    chown -R www: /etc/nginx/nginx.conf && \
    chown -R www: /etc/nginx/conf.d/

# On rend accessible le port 8090 vers l'extérieur
EXPOSE 8090

# Passage sous l'utilisateur www
USER www

# Lancer nginx avec l'utilisateur www
ENTRYPOINT ["nginx"]
