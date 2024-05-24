FROM debian:12.5-slim


RUN apt-get update -q \
    && apt-get install -y \
        git \
        curl \
        wget \
        libfontconfig1 \
        python3 \
        make \
        ghostscript \
        perl \
        tar \
        lmodern \
        gnupg2 \
        python3 \
        python3-pygments \
        python3-pip \
        python3-venv \
        libfontconfig1 \
    && apt-get purge -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
    
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 100

# Install TexLive
# ---------------
# CTAN mirrors occasionally fail, in that case install TexLive using a
# different server, for example https://ctan.crest.fr
#
# # docker build \
#     --build-arg TEXLIVE_MIRROR=https://ctan.crest.fr/tex-archive/systems/texlive/tlnet \
#     -f Dockerfile-base -t sharelatex/sharelatex-base .
ARG TEXLIVE_MIRROR=https://mirror.ox.ac.uk/sites/ctan.org/systems/texlive/tlnet

RUN mkdir /install-tl-unx \
&&  wget --quiet https://tug.org/texlive/files/texlive.asc \
&&  gpg --import texlive.asc \
&&  rm texlive.asc \
&&  wget --quiet ${TEXLIVE_MIRROR}/install-tl-unx.tar.gz \
&&  wget --quiet ${TEXLIVE_MIRROR}/install-tl-unx.tar.gz.sha512 \
&&  wget --quiet ${TEXLIVE_MIRROR}/install-tl-unx.tar.gz.sha512.asc \
&&  gpg --verify install-tl-unx.tar.gz.sha512.asc \
&&  sha512sum -c install-tl-unx.tar.gz.sha512 \
&&  tar -xz -C /install-tl-unx --strip-components=1 -f install-tl-unx.tar.gz \
&&  rm install-tl-unx.tar.gz* \
&&  echo "tlpdbopt_autobackup 0" >> /install-tl-unx/texlive.profile \
&&  echo "tlpdbopt_install_docfiles 0" >> /install-tl-unx/texlive.profile \
&&  echo "tlpdbopt_install_srcfiles 0" >> /install-tl-unx/texlive.profile \
&&  echo "selected_scheme scheme-basic" >> /install-tl-unx/texlive.profile \
    \
&&  /install-tl-unx/install-tl \
      -profile /install-tl-unx/texlive.profile \
      -repository ${TEXLIVE_MIRROR} \
    \
&&  $(find /usr/local/texlive -name tlmgr) path add \
&&  rm -rf /install-tl-unx


# This must be before install texlive-full
RUN set -x \
    && tlmgr init-usertree \
    && tlmgr option repository http://mirror.ctan.org/systems/texlive/tlnet/ \
    && tlmgr update --self \
    && tlmgr install scheme-full

# installing texlive and utils
RUN apt update \
  && apt install -y \
    locales \
    fontconfig \
    default-jre \
    swath \
    liblog-log4perl-perl \
    libyaml-tiny-perl \
    libfile-homedir-perl \
    libunicode-linebreak-perl \
    graphviz \
    pandoc \
    texlive-latex-extra \
    texlive-extra-utils \
    texlive-fonts-extra \
    texlive-bibtex-extra \
    texlive-lang-german \
    biber \
    latexmk \
    procps \
    inkscape \
    # texlive \
    # texlive-full \
  && apt-get clean autoclean \
  && apt-get autoremove --yes \
  && rm -rf /var/lib/apt/lists/*

# generating locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
	sed -i -e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen && \
	dpkg-reconfigure --frontend=noninteractive locales && \
	update-locale LANG=en_US.UTF-8
ENV LANGUAGE=de_DE.UTF-8:en_US.UTF-8 LANG=de_DE.UTF-8 LC_ALL=de_DE.UTF-8

# installing cpanm & missing latexindent dependencies
RUN curl -L http://cpanmin.us | perl - --self-upgrade && \
	cpanm Log::Dispatch::File YAML::Tiny File::HomeDir