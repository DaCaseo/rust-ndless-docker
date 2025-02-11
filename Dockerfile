FROM ubuntu:18.04

LABEL \
    maintainer="dacaseo" \
    version="1.0" \
    description="Ndless SDK + Rust"

WORKDIR /opt/ndless-dev
SHELL ["/bin/bash", "-c"]

## Settings to avoid tzdata configuring
## ref: https://sleepless-se.net/2018/07/31/docker-build-tzdata-ubuntu/ or https://github.com/phusion/baseimage-docker/issues/319
ENV TZ=UTC \
    DEBIAN_FRONTEND=noninteractive

## Install dependencies
## Dependencies of Ndless SDK for Linux are:
## "git, GCC (with c++ support), binutils, GMP (libgmp-dev), MPFR (libmpfr-dev), MPC (libmpc-dev), zlib, boost-program-options, wget"
## But your computer fails to build the SDK if these packages are not installed in: python3, python3-dev, texinfo, and php
RUN apt-get update -y \
 && apt-get install -y \
    git \
    build-essential \
    binutils \
    libgmp-dev \
    libmpfr-dev \
    libmpc-dev \
    zlib1g zlib1g-dev zlib1g-dbg \
    libboost-dev libboost-program-options-dev \
    wget \
    python3 python3-dev texinfo php \
    curl pkg-config libssl-dev

# Install rustup and set path
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain nightly
ENV PATH=/root/.cargo/bin:$PATH

## Install cargo packages we need
RUN cargo install cargo-make cargo-generate && cargo install cargo-ndless

## Configure Ndless and the SDK
RUN git clone --recursive https://github.com/ndless-nspire/Ndless.git \
 && cd Ndless/ndless-sdk/toolchain && chmod +x build_toolchain.sh && ./build_toolchain.sh

## Set PATH before building the toolchain
ENV PATH /opt/ndless-dev/Ndless/ndless-sdk/toolchain/install/bin:/opt/ndless-dev/Ndless/ndless-sdk/bin:$PATH

## Build Ndless and the SDK
## In line 43 your computer checks whether everything has been set up correctly
RUN cd /opt/ndless-dev/Ndless \
 && make \
 && test "$(nspire-gcc 2>&1)" = "$(echo -e "arm-none-eabi-gcc: fatal error: no input files\ncompilation terminated.")"

