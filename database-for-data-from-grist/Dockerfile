FROM postgres:14.2

ENV PGSQL_HTTP_VERSION v1.5.0
ENV DEBIAN_FRONTEND=noninteractive

COPY scripts/install-extensions.sql /docker-entrypoint-initdb.d/
COPY scripts/functions.sql /docker-entrypoint-initdb.d/

RUN set -ex \
    && apt-get update && apt-get install -y wget make g++ postgresql-server-dev-14 libcurl4-openssl-dev \
    && wget -O pgsqlhttp.tar.gz "https://github.com/pramsey/pgsql-http/archive/refs/tags/${PGSQL_HTTP_VERSION}.tar.gz" \
    && mkdir -p /usr/src/pgsqlhttp \
    && tar \
        --extract \
        --file pgsqlhttp.tar.gz \
        --directory /usr/src/pgsqlhttp \
        --strip-components 1 \
    && rm pgsqlhttp.tar.gz \
    && cd /usr/src/pgsqlhttp \
    && make \
    && make install \
    && rm -rf /var/lib/apt/lists/*


