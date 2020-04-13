FROM debian

RUN apt-get update && apt-get install -y \
        build-essential \
        xxd curl tar xz-utils \
        dh-autoreconf libcurl4-gnutls-dev libexpat1-dev \
        gettext libz-dev libssl-dev \
        asciidoc xmlto docbook2x \
        install-info

WORKDIR /opt
RUN curl -fsSL https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.26.0.tar.xz | tar xJ
WORKDIR /opt/git-2.26.0
RUN ./configure
RUN make -j32 all
RUN make install

WORKDIR /root
