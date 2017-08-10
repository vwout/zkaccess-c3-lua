FROM ubuntu

RUN apt-get update -y \
 && apt-get install -y \
    luajit \
    lua-bit32 \
    luarocks

RUN luarocks install luasocket \
 && luarocks install lunit

RUN mkdir /source
VOLUME ["/source"]

WORKDIR "/source"
