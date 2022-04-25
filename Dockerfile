#########################################################################################
# Grab the offical timescale image to copy some stuff out of
#########################################################################################

FROM timescale/timescaledb:latest-pg14 AS timescaledb
# Reference from timescale source image:
#  https://github.com/timescale/timescaledb-docker/blob/main/Dockerfile

#########################################################################################
# "Build" image to basically download the appropriate packages
#########################################################################################

# Source for official postgres image: https://github.com/docker-library/postgres/blob/master/14/bullseye/Dockerfile

FROM postgres:14 AS build

RUN set -ex && \
    apt-get update && apt-get install --no-install-suggests --no-install-recommends --yes \
      wget \
      lsb-release \
      ca-certificates

RUN set -ex && \
    curl https://techsupport.enterprisedb.com/api/repository/dl/default/release/deb | bash && \
    # TODO: figure out how to add the correcct release \
    sh -c "echo 'deb https://packagecloud.io/timescale/timescaledb/debian/ $(lsb_release -c -s) main' > /etc/apt/sources.list.d/timescaledb.list" && \
    wget -O timescale-gpgkey https://packagecloud.io/timescale/timescaledb/gpgkey && \
    apt-key add timescale-gpgkey && \
    apt-get update

RUN apt-get download \
    postgresql-14-pglogical \
    timescaledb-2-postgresql-14 \
    timescaledb-2-loader-postgresql-14

#########################################################################################
# Final "real" image
#########################################################################################

FROM postgres:14

COPY --from=build *.deb .

# This copy is mainly to get timescaledb-tune command
# TODO: figure out how to get the version from the timescaledb-tools package is not getting picked up when installed
COPY --from=timescaledb /usr/local/bin/timescaledb-* /usr/local/bin/

# Some docker setu up stuff:
COPY --from=timescaledb /docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/

RUN set -ex && \
    dpkg -i *.deb && \
    sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'timescaledb,pglogical,\2'/;s/,'/'/" /usr/share/postgresql/14/postgresql.conf.sample && \
    echo "CREATE EXTENSION IF NOT EXISTS pglogical;" > /docker-entrypoint-initdb.d/002_pglogical.sql
