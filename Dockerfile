FROM node:6.10.1

MAINTAINER Kim Laï Trinh <kimlai@lrqdo.fr>

RUN npm install -g nodemon

WORKDIR /var/www

COPY . /var/www
RUN npm install
