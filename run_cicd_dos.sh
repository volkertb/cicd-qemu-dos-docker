#!/bin/sh
(qemu-system-i386 \
-machine pc,accel=kvm:tcg,hpet=off \
-smp cpus=1,cores=1 \
-m 256M \
-rtc base=localtime \
-nographic \
-blockdev driver=file,node-name=fd0,filename=/media/x86BOOT.img -device floppy,drive=fd0 \
-drive if=virtio,format=raw,file=fat:rw:"$(pwd)" \
-boot order=a \
-audiodev wav,id=snd0,path="$(pwd)"/ac97_out.wav -device AC97,audiodev=snd0 \
-audiodev wav,id=snd1,path="$(pwd)"/adlib_out.wav -device adlib,audiodev=snd1 \
-audiodev wav,id=snd2,path="$(pwd)"/sb16_out.wav -device sb16,audiodev=snd2 \
-audiodev wav,id=snd3,path="$(pwd)"/pcspk_out.wav -machine pcspk-audiodev=snd3 \
| tee "$(pwd)"/qemu_stdout.log) 3>&1 1>&2 2>&3 | tee "$(pwd)"/qemu_stderr.log
