FROM ubuntu:18.04

ENV REFRESHED_AT=2018-08-16 \
  LANG=en_US.UTF-8 \
  HOME=/opt/build \
  TERM=xterm

RUN \
  apt-get update -y && \
  apt-get install -y openssh-server git wget vim locales ssh gnupg build-essential && \
  locale-gen en_US.UTF-8

RUN \
  wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && \
  dpkg -i erlang-solutions_1.0_all.deb && \
  rm erlang-solutions_1.0_all.deb && \
  apt-get update -y && \
  apt-get install -y esl-erlang=1:22.2.6-1 elixir=1.10.0-1

CMD ["/bin/bash"]
