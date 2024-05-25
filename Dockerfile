FROM debian:12.5-slim as base

RUN apt update -q \
    && apt install -y \
        git \
        curl \
        wget \
        libfontconfig1 \
        locales \
        fontconfig \
        default-jre \
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
        swath \
        liblog-log4perl-perl \
        libyaml-tiny-perl \
        libfile-homedir-perl \
        libunicode-linebreak-perl \
        graphviz \
        pandoc \
        inkscape \
        procps \
    && apt purge -y \
    && apt clean autoclean \
    && rm -rf /var/lib/apt/lists/*
    
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 100

FROM base as dist

# Define build arguments for TexLive year and scheme
ARG TEXLIVE_YEAR=2024
ARG TEXLIVE_SCHEME=scheme-full
ARG TEXLIVE_MIRROR=https://mirror.ctan.org/systems/texlive/tlnet
ARG TEXLIVE_REPOSITORY=${TEXLIVE_MIRROR}/${TEXLIVE_YEAR}

# Install TexLive
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
&&  echo "selected_scheme ${TEXLIVE_SCHEME}" >> /install-tl-unx/texlive.profile \
&&  /install-tl-unx/install-tl \
      -profile /install-tl-unx/texlive.profile \
      -repository ${TEXLIVE_REPOSITORY} \
&&  $(find /usr/local/texlive -name tlmgr) path add \
&&  rm -rf /install-tl-unx


# This must be before install texlive-full
#RUN set -x \
#    && tlmgr init-usertree \
#    && tlmgr option repository ${TEXLIVE_MIRROR} \
#    && tlmgr update --self \
#    && tlmgr install scheme-full

# installing texlive and utils
#RUN apt update \
#  && apt install -y \
    # biber \
    # latexmk \
    # texlive \
    # texlive-full \
 #   texlive-latex-extra \
 #   texlive-extra-utils \
 #   texlive-fonts-extra \
 #   texlive-bibtex-extra \
 #   texlive-lang-german \
#  && apt-get clean autoclean \
#  && apt-get autoremove --yes \
#  && rm -rf /var/lib/apt/lists/*

# generating locales
#RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
#    && sed -i -e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen \
#    && dpkg-reconfigure --frontend=noninteractive locales \
#	&& update-locale LANG=en_US.UTF-8
#ENV LANGUAGE=de_DE.UTF-8:en_US.UTF-8 LANG=de_DE.UTF-8 LC_ALL=de_DE.UTF-8

# installing cpanm & missing latexindent dependencies
#RUN curl -L http://cpanmin.us | perl - --self-upgrade \
#    && cpanm Log::Dispatch::File YAML::Tiny File::HomeDir