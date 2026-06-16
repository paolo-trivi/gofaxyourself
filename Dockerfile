# GoFaxYourself — minimal baresip SIP auto-answer image.
# No PBX. No Asterisk. No FreeSWITCH. Just baresip on Debian.
FROM debian:trixie-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends baresip-core ca-certificates \
  && rm -rf /var/lib/apt/lists/*

COPY docker/baresip-entrypoint.sh /usr/local/bin/baresip-entrypoint.sh
RUN chmod +x /usr/local/bin/baresip-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/baresip-entrypoint.sh"]
