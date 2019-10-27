ARG QUARTUS_MAJOR_VERSION=18.1
FROM ubuntu:18.04 AS build

ARG QUARTUS_MAJOR_VERSION
ARG MIRROR=http://download.altera.com/akdlm/software/acdsinst/
ARG QUARTUS_INSTALLER="18.1std/625/ib_tar/Quartus-lite-18.1.0.625-linux.tar"
ARG QUARTUS_UPDATER="18.1std.1/646/update/QuartusSetup-18.1.1.646-linux.run"

ARG INSTALL_DIR="/opt/quartus/${QUARTUS_MAJOR_VERSION}"
ARG INSTALL_ARGS="--mode unattended \
        --installdir ${INSTALL_DIR} \
        --accept_eula 1 \
        --unattendedmodeui minimal"

ARG WGET="curl -O -# "

RUN apt update && \
	apt install -y wget curl

RUN cd /tmp && \
	${WGET} ${MIRROR}${QUARTUS_INSTALLER} && \
	tar xvf Quartus*.tar && \
	rm *.tar && \
	cd components && \
	echo "Installing ${QUARTUS_INSTALLER} to ${INSTALL_DIR}" && \
	echo ./QuartusLiteSetup*.run ${INSTALL_ARGS} && \
	./QuartusLiteSetup*.run ${INSTALL_ARGS} && \
	cd /tmp && rm -Rf /tmp/components
	
RUN cd /tmp && \
	[ "${QUARTUS_UPDATER}" = "" ] || ( \
		${WGET} ${MIRROR}${QUARTUS_UPDATER} && \
		chmod +x *.run && \
		echo "Installing ${QUARTUS_UPDATER} to ${INSTALL_DIR}" && \
		echo ./QuartusSetup*.run ${INSTALL_ARGS} && \
		./QuartusSetup*.run ${INSTALL_ARGS} \
	)

RUN rm -Rf ${INSTALL_DIR}/uninstall
	
FROM daverichmond/fpga:latest
MAINTAINER David Richmond <dave@prstat.org>
ARG QUARTUS_MAJOR_VERSION
ARG DEBIAN_FRONTEND=noninteractive

COPY --from=build /opt /opt

# install libraries required
RUN apt update && \
	apt install -y libfreetype6 libsm6 libglib2.0-0 libxrender1 \
		libfontconfig1 libxext6 locales xterm wget curl && \
	echo "en_AU.UTF-8 UTF-8" >> /etc/locale.gen && \
	echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
	locale-gen && \
	apt-get clean

# quartus needs an old version of libpng that's not available in recent
# versions of ubuntu
WORKDIR /tmp
# ubuntu makes it a bit of a pain to grab old stuff (in a scripted way).
# grabbed a link from:
#  https://packages.ubuntu.com/xenial-updates/amd64/libpng12-0/download
RUN wget -q http://security.ubuntu.com/ubuntu/pool/main/libp/libpng/libpng12-0_1.2.54-1ubuntu1.1_amd64.deb && \
        dpkg -i libpng12*.deb && \
        rm *.deb

# environment to ensure quartus runs
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV QT_X11_NO_MITSHM=1

ENV PATH=${PATH}:/opt/quartus/${QUARTUS_MAJOR_VERSION}/quartus/bin
ENV PATH=${PATH}:/opt/quartus/${QUARTUS_MAJOR_VERSION}/nios2eds/bin
ENV QUARTUS_ROOTDIR=/opt/quartus/${QUARTUS_MAJOR_VERSION}/quartus

CMD ["/bin/bash"]
