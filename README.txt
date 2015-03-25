How to build
============

cd {emsdk_root}
source ./emsdk_env.sh

cd {somewhere}
git clone git@github.com:tomboinc/objc4.git
cd objc4
git checkout feature/emscripten
make
make install

cd em-test/simple
make
node minimum.js
