#!/usr/bin/env bash

xkbcomp -xkb "$DISPLAY" - | sed 's#key <CAPS>.*#key <CAPS> {\
    repeat=no,\
    type[group1]="ALPHABETIC",\
    symbols[group1]=[ Caps_Lock, Caps_Lock],\
    actions[group1]=[ LockMods(modifiers=Lock),\
    Private(type=3,data[0]=1,data[1]=3,data[2]=3)]\
};\
#' | xkbcomp -w 0 - "$DISPLAY"
