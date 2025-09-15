#!/usr/bin/env bash

sudo pacman -s --needed --noconfirm postgresql

sudo -u postgres initdb --locale=en_US.UTF-8 -E UTF8 -D /var/lib/postgres/data

sudo systemctl enable postgresql.service
sudo systemctl start postgresql.service