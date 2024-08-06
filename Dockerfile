FROM debian:12.5-slim as base

ARG PLANTUML_URL=http://github.com/plantuml/plantuml/releases/latest/download/plantuml.jar

RUN apt update -q \
    && apt install -y \
        git \
        curl \
        wget \
        default-jre \
        libfontconfig1 \
        locales \
        fontconfig \
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
        lilypond \
        procps \
    && apt purge -y \
    && apt clean autoclean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/plantuml \
    && curl -o /opt/plantuml/plantuml.jar -L "${PLANTUML_URL}" \
    && printf '#!/bin/sh\nexec java -Djava.awt.headless=true -XX:-UsePerfData -jar /opt/plantuml/plantuml.jar "$@"' > /usr/bin/plantuml \
    && chmod +x /usr/bin/plantuml


FROM base as dist

# Define build arguments for TexLive year and scheme
ARG BUILD_YEAR=$(date +%Y)
ARG BUILD_SCHEME=scheme-full

# Install TexLive
RUN if [ "$BUILD_YEAR" = "$(date +%Y)" ]; then \
    export BUILD_REPOSITORY=https://mirror.physik.tu-berlin.de/pub/CTAN/systems/texlive/tlnet; \
    else \
    export BUILD_REPOSITORY=https://ftp.tu-chemnitz.de/pub/tex/historic/systems/texlive/$BUILD_YEAR/tlnet-final; \
    fi \
	&& echo "BUILD_REPOSITORY is set to $BUILD_REPOSITORY"
    && mkdir /install-tl-unx \
	&& wget -qO- https://tug.org/texlive/files/texlive.asc | gpg --import - \
	&& (echo 5; echo y; echo save) | gpg --command-fd 0 --no-tty --no-greeting -q --edit-key 0D5E5D9106BAB6BC trust

RUN echo "BUILD_REPOSITORY is set to $BUILD_REPOSITORY"

RUN  wget -q "${BUILD_REPOSITORY}/install-tl-unx.tar.gz" \
    &&  wget -q "${BUILD_REPOSITORY}/install-tl-unx.tar.gz.sha512" \
    &&  wget -q "${BUILD_REPOSITORY}/install-tl-unx.tar.gz.sha512.asc"

RUN  gpg --verify install-tl-unx.tar.gz.sha512.asc \
    &&  sha512sum -c install-tl-unx.tar.gz.sha512 \
    &&  tar -xz -C /install-tl-unx --strip-components=1 -f install-tl-unx.tar.gz \
    &&  rm install-tl-unx.tar.gz* \
    &&  echo "tlpdbopt_autobackup 0" >> /install-tl-unx/texlive.profile \
    &&  echo "tlpdbopt_install_docfiles 0" >> /install-tl-unx/texlive.profile \
    &&  echo "tlpdbopt_install_srcfiles 0" >> /install-tl-unx/texlive.profile \
    &&  echo "selected_scheme ${BUILD_SCHEME}" >> /install-tl-unx/texlive.profile
RUN  /install-tl-unx/install-tl \
        -profile /install-tl-unx/texlive.profile \
        -repository $BUILD_REPOSITORY 
RUN  $(find /usr/local/texlive -name tlmgr) path add \
    &&  rm -rf /install-tl-unx \
    && echo % enable shell-escape by default >> /usr/local/texlive/$BUILD_YEAR/texmf.cnf \
    && echo shell_escape = t >> /usr/local/texlive/$BUILD_YEAR/texmf.cnf

ENV PATH="/usr/local/texlive/${BUILD_YEAR}/bin/x86_64-linux:${PATH}"

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