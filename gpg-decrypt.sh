#!/bin/bash
#------------------
# File: gpg-encrypt.sh
# Author: Wolfger Schramm <wolfger@spearwolf.de>
# Created: 11.01.2011 10:43:30 CET

#gpg --quiet --no-use-agent --passphrase-file secret --decrypt $1
gpg --quiet --no-use-agent --passphrase-fd 0 --decrypt $1
