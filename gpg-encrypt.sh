#!/bin/bash
#------------------
# File: gpg-encrypt.sh
# Author: Wolfger Schramm <wolfger@spearwolf.de>
# Created: 11.01.2011 10:43:30 CET

CIPHER_ALGORITHM='AES256'
#cat - | gpg --armor --no-use-agent --symmetric --cipher-algo $CIPHER_ALGORITHM --passphrase-file secret
#cat - | gpg --armor --no-use-agent --symmetric --cipher-algo $CIPHER_ALGORITHM
cat - | gpg --armor --no-use-agent --symmetric --cipher-algo $CIPHER_ALGORITHM --passphrase-fd 0
