#!/bin/bash

# GO
wget "https://go.dev/dl/$(curl https://go.dev/VERSION\?m=text | head -n 1).linux-$(dpkg --print-architecture).tar.gz" -O golang.tar.gz
tar -C /usr/local -xzf golang.tar.gz
rm golang.tar.gz