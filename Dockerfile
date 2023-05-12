# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine-nginx:3.17

# set version label
ARG BUILD_DATE
ARG VERSION
ARG LYCHEE_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="hackerman"

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
    composer && \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    exiftool \
    ffmpeg \
    gd \
    imagemagick \
    jpegoptim \
    php81-bcmath \
    php81-ctype \
    php81-dom \
    php81-exif \
    php81-gd \
    php81-intl \
    php81-mysqli \
    php81-pdo_mysql \
    php81-pecl-imagick \
    php81-phar \
    php81-tokenizer \
    php81-zip \
    rsync && \
  echo "**** configure php-fpm to pass env vars ****" && \
  sed -E -i 's/^;?clear_env ?=.*$/clear_env = no/g' /etc/php81/php-fpm.d/www.conf && \
  grep -qxF 'clear_env = no' /etc/php81/php-fpm.d/www.conf || echo 'clear_env = no' >> /etc/php81/php-fpm.d/www.conf && \
  echo "**** install lychee ****" && \
  if [ -z "${LYCHEE_VERSION}" ]; then \
    LYCHEE_VERSION=$(curl -sX GET "https://api.github.com/repos/LycheeOrg/Lychee/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  mkdir -p /app/www && \
  git clone --recurse-submodules https://github.com/sakshamchawla/Lychee.git /app/www && \
  cd /app/www && \
  git checkout "${LYCHEE_VERSION}" && \
  echo "**** install composer dependencies ****" && \
  composer install \
    -d /app/www \
    --no-dev \
    --no-interaction && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /root/.cache \
    /root/.composer \
    /tmp/*

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 80 443
VOLUME /config
