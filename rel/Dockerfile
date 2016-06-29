# The one the elixir:1.2.5 image was built with
FROM debian:jessie

RUN apt-get update && apt-get install -y --no-install-recommends \
		libssl1.0.0 \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /root

# Set exposed ports
EXPOSE 4000
ENV PORT=4000 MIX_ENV=prod TERM=xterm LANG="C.UTF-8" RELX_REPLACE_OS_VARS=true

ADD . rel/site
RUN mkdir /root/work

WORKDIR /root/work

ENTRYPOINT ["/root/rel/site/bin/site"]
CMD ["foreground"]
