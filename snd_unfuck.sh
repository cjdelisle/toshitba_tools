#!/bin/bash
die() { echo $1; exit 100; }
id | grep 'uid=0' >/dev/null || die "run as root";
PULSE=`which pulseaudio`
chmod a-x $PULSE
killall pulseaudio;
modprobe -r snd_hda_intel
modprobe snd_hda_intel
chmod a+x $PULSE
