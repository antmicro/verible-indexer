FROM debian:11

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Install dependencies

RUN apt-get update -qq \
   && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends wget ca-certificates \
   && apt-get autoclean && apt-get clean && apt-get -y autoremove \
   && update-ca-certificates \
   && rm -rf /var/lib/apt/lists/*

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Get Kythe binaries

ARG KYTHE_VERSION='v0.0.61'
ARG KYTHE_URL="https://github.com/kythe/kythe/releases/download/$KYTHE_VERSION/kythe-$KYTHE_VERSION.tar.gz"

RUN echo 'Get Kythe' \
   &&	wget --no-verbose -O kythe.tar.gz "$KYTHE_URL" \
   && rm -rf kythe-bin \
   && mkdir kythe-bin \
   && tar -xzf kythe.tar.gz --strip-components=1 -C kythe-bin

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Expose port 8080 for http
EXPOSE 8080
ENV KYTHE_HTTP_SERVER=/kythe-bin/tools/http_server

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Copy indexed database

COPY artifacts /home/indexer/indexer/

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Define the entrypoint

COPY entrypoint.sh /home/indexer/indexer/entrypoint.sh
ENTRYPOINT ["/home/indexer/indexer/entrypoint.sh", "0.0.0.0:8080"]
