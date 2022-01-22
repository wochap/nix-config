#!/usr/bin/env bash

swaylock --screenshots --clock --indicator-idle-visible \
	--indicator-radius 100 \
	--indicator-thickness 7 \
	--ignore-empty-password \
	--ring-color 282c34 \
        --ring-ver-color 61afef \
        --ring-wrong-color e06c75 \
        --ring-clear-color d19a66 \
	--key-hl-color 61afef \
	--text-color abb2bf \
        --text-ver-color abb2bf \
        --text-wrong-color abb2bf \
        --text-clear-color abb2bf \
        --text-caps-lock-color d19a66 \
	--line-uses-inside \
	--inside-color 12151d \
        --inside-ver-color 12151d\
        --inside-wrong-color 12151d \
        --inside-clear-color 12151d \
        --layout-bg 12151d \
        --layout-border-color 282c34 \
        --layout-text-color abb2bf \
	--separator-color 00000000 \
	--fade-in 0.5 \
	--effect-scale 0.5 --effect-blur 7x3 --effect-scale 2 \
        -F --grace 5
