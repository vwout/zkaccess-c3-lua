FROM ubuntu:16.04

RUN apt-get update -y \
 && apt-get install --no-install-recommends -y \
    luajit \
    lua-bit32 \
    luarocks \
 && rm -rf /var/lib/apt/lists/*

RUN luarocks install luasocket \
 && luarocks install lunit

RUN mkdir /source
VOLUME ["/source"]

WORKDIR "/source"
