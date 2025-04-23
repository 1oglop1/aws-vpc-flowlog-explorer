FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    lsb-release \
    ca-certificates \
    luajit \
    lua5.1-dev \
    build-essential \
    zlib1g-dev \
    git \
    unzip

# Install Fluent Bit from official repos
RUN curl https://raw.githubusercontent.com/fluent/fluent-bit/master/install.sh | sh

# Install Lua package manager
RUN wget https://luarocks.org/releases/luarocks-3.9.2.tar.gz && \
    tar zxpf luarocks-3.9.2.tar.gz && \
    cd luarocks-3.9.2 && \
    ./configure && \
    make && \
    make install && \
    cd .. && \
    rm -rf luarocks-3.9.2*

# Install Lua zlib module
RUN luarocks install lua-zlib

# Set up environment
ENV LUA_PATH="/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/usr/local/lib/lua/5.1/?.lua;/usr/local/lib/lua/5.1/?/init.lua;./?.lua;./?/init.lua"
ENV LUA_CPATH="/usr/local/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so;./?.so"

# Cleanup
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Volumes and entrypoint
VOLUME ["/fluent-bit/etc", "/logs"]
WORKDIR /fluent-bit/bin
ENTRYPOINT ["/opt/fluent-bit/bin/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf"]