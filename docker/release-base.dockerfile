FROM debian:trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends libssl3t64 libncurses6 libsctp1 locales \
 && rm -rf /var/lib/apt/lists/*

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LC_ALL="en_US.UTF-8" LANG="en_US.UTF-8" LANGUAGE="en_US:en"
