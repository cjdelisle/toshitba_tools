#!/bin/bash
setval() { echo $2 > /sys/class/thermal/cooling_device$1/cur_state; }
getval() { cat /sys/class/thermal/cooling_device$1/cur_state; }
unfuck() {
    local orig0=`getval 0`;
    local orig3=`getval 3`;
    local orig4=`getval 4`;

    setval 0 1;
    setval 3 10;
    setval 4 10;

    setval 4 $orig4;
    setval 3 $orig3;
    setval 0 $orig0;
}
while :; do
    [ 75000 -lt `cat /sys/class/hwmon/hwmon1/device/temp1_input` ] && unfuck;
    sleep 1;
done
