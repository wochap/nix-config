#!/usr/bin/env bash

sudo docker ps -qf status="running" | wc -l
