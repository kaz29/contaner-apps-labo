FROM php:8.3.24-cli

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		xz-utils \
		git \
		unzip \
		libzip-dev \
	; \
	rm -rf /var/lib/apt/lists/* \
    # install composer
    && { \
      curl -sS https://getcomposer.org/installer; \
    } | php \
    && mv composer.phar /usr/local/bin/composer

RUN set -ex \
    && mkdir -p /srv/app

COPY app/composer.json app/composer.lock /srv/app/
RUN set -ex \
    && composer install --working-dir=/srv/app --dev

COPY app /srv/app

WORKDIR /srv/app
CMD ["php", "/srv/app/queue.php"]
