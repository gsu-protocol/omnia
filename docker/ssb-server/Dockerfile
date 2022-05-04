FROM node:10.24.1-alpine3.11

RUN apk add bash

# COPY ./docker/ssb-server/state/db /root/.ssb/db
COPY ./docker/ssb-server/config/manifest.json /root/.ssb/manifest.json

RUN npm install -g --no-optional ssb-server

# Disable 'sodium-native' warning message
ENV CHLORIDE_JS='1'

EXPOSE 8000

CMD [ "ssb-server", "start" ]
