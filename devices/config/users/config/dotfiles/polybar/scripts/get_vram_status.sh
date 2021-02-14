#!/usr/bin/env bash


vram_total=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits);
vram_used=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits);
vram_used_perc=$(echo "$vram_used*100/$vram_total" | bc);

echo $vram_used_perc;
