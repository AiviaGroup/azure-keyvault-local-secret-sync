#!/usr/bin/env bash

# Installs workspace dependencies
echo 'Setting up workspace for ci'

corepack enable

# Install Git LFS
sudo apt-get install git-lfs
