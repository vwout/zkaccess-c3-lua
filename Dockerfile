FROM ubuntu:16.04

RUN apt-get update -y \
 && apt-get install -y \
    luajit \
    lua-bit32 \
    luarocks \
 && rm -rf /var/lib/apt/lists/*

RUN luarocks install luasocket \
 && luarocks install lunit \
 && luarocks install luacheck

RUN mkdir /source
VOLUME ["/source"]

WORKDIR "/source"
