FROM resin/resin-base:v4.3.0

EXPOSE 1337

COPY package.json package-lock.json /usr/src/app/
RUN npm ci --unsafe-perm --production && npm cache clean --force

COPY . /usr/src/app

RUN apt-get update
RUN apt-get install postgresql-9.6

COPY pinejs-example-server.service /etc/systemd/system/

RUN systemctl enable pinejs-example-server.service
