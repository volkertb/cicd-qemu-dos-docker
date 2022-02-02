FROM alpine:3.15.0
#RUN apk add qemu-system-x86_64 qemu-modules libvirt libvirt-qemu
RUN apk add build-base
RUN apk add wget
WORKDIR /tmp
RUN wget https://download.qemu.org/qemu-6.2.0.tar.xz
RUN tar xvJf qemu-6.2.0.tar.xz
WORKDIR /tmp/qemu-6.2.0
RUN apk add python3
RUN apk add ninja
RUN apk add pkgconfig
RUN apk add glib-dev
RUN apk add meson
RUN apk add pixman-dev
RUN apk add ncurses-dev
RUN apk add gnu-libiconv-dev
RUN ./configure --target-list=i386-softmmu --without-default-features --enable-curses --enable-iconv --enable-tcg --enable-tools
RUN apk add bash
RUN apk add perl
RUN make
RUN make install
RUN qemu-system-i386 --version
WORKDIR /tmp
RUN wget https://www.ibiblio.org/pub/micro/pc-stuff/freedos/files/distributions/1.3/previews/1.3-rc5/FD13-FloppyEdition.zip
RUN unzip FD13-FloppyEdition.zip

RUN cp 144m/x86BOOT.img /

RUN apk del perl
RUN apk del bash
RUN apk del gnu-libiconv-dev
RUN apk del ncurses-dev
RUN apk del pixman-dev
RUN apk del meson
RUN apk del glib-dev
RUN apk del pkgconfig
RUN apk del ninja
RUN apk del python3
RUN apk del wget
RUN apk del build-base

RUN apk add pixman
RUN apk add ncurses
RUN apk add glib
RUN apk add libgcc

RUN rm -rf /tmp

#RUN echo n | qemu-system-i386 -nographic -blockdev driver=file,node-name=f0,filename=144m/x86BOOT.img -device floppy,drive=f0
#RUN qemu-system-i386 -display curses -blockdev driver=file,node-name=f0,filename=/x86BOOT.img -device floppy,drive=f0
ENTRYPOINT ["qemu-system-i386", "-display", "curses", "-blockdev", "driver=file,node-name=f0,filename=/x86BOOT.img", "-device", "floppy,drive=f0"]
