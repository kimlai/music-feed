FROM node:6.10.1

MAINTAINER Kim Laï Trinh <kimlai@lrqdo.fr>

RUN npm install -g nodemon
RUN apt-get update && apt-get install --no-install-recommends -q -o Dpkg::Options::="--force-confold" --force-yes -y \
rubygems
RUN gem install sass

WORKDIR /var/www

COPY . /var/www
RUN npm install
