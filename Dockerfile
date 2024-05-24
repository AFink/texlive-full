FROM debian:12.5-slim

RUN apt update \
    && apt install -y wget \
    && wget http://mirrors.rit.edu/CTAN/systems/texlive/tlnet/install-tl-unx.tar.gz \
    && mkdir install-tl \
    && tar xf install-tl-unx.tar.gz -C install-tl --strip-components=1 \
    && ./install-tl/install-tl -profile ./texlive.profile --location http://mirrors.rit.edu/CTAN/systems/texlive/tlnet \
    && rm -rf install-tl && rm -f install-tl-unx.tar.gz

ENV PATH /usr/local/texlive/distribution/bin/armhf-linux:$PATH

# This must be before install texlive-full
RUN set -x \
    && tlmgr init-usertree \
    && tlmgr option repository http://mirror.ctan.org/systems/texlive/tlnet/ \
    && tlmgr update --self \
    && tlmgr install scheme-full

# installing texlive and utils
RUN apt update \
  && apt install -y \
  curl \
  wget \
  locales \
  git \
  make \
  fontconfig \
  default-jre \
  python3 \
  python3-pygments \
  python3-pip \
  python3-venv \
  swath \
  liblog-log4perl-perl \
  libyaml-tiny-perl \
  libfile-homedir-perl \
  libunicode-linebreak-perl \
  graphviz \
  pandoc \
  texlive \
  texlive-full \
  texlive-latex-extra \
  texlive-extra-utils \
  texlive-fonts-extra \
  texlive-bibtex-extra \
  texlive-lang-german \
  biber \
  latexmk \
  procps \
  inkscape \
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