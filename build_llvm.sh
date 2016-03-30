#!/bin/sh

########## 設定項目 ##########
#porg OR paco
PORG=porg
#インストール先
PREFIX=/usr/local
GCC_PREFIX=/usr/local
#コンパイラ
CC=gcc5
CXX=g++5
#コンパイルオプション(ダブルクォーテーションで囲みます)
CFLAGS="-march=native -O3"
#sudo(不要なら空文字)
SUDO="sudo"
# FLAGS→後につける(-j8など)
# BEFORE→前につける(nice -n 19・env 〇〇〇〇など)
MAKE_BEFORE=""
MAKE_FLAGS="-j8"
#ビルド時のみ
BUILD_FLAGS=""
BUILD_BEFORE=""
#インストール時のみ
INSTALL_FLAGS=""
INSTALL_BEFORE=""
########## ここまで ##########


DUMP=/dev/null
set -e
set -u
if ! which ${PORG} > $DUMP 2>&1; then
    if ! which porg > $DUMP 2>&1 ; then
	if which paco > $DUMP 2>&1 ; then
	    PORG=paco
	else
	    echo "porgかpacoをインストールしてください" >&2
	    exit 1
	fi
    fi
fi

if ! which python2.7 > /dev/null 2>&1; then
    echo "Python2.7をインストールしてください" >&2
    exit 1
fi


PYTHONPATH=`which python2.7 | sed -e "s_/python2.7\\\$__"`
PROCESSOR=`uname -p`
SYSTEM=`uname -s`
TARGET_TRIPLE=`$CC -v 2>&1 | grep ": ${PROCESSOR}-" | head -n 1 | sed "s/^..*: //"`
REPO="http://llvm.org/svn/llvm-project"

echo "最新版の確認中・・・" >&2

for dir in `svn ls ${REPO}/llvm/tags | grep RELEASE_ | sort -r`; do
    if svn ls ${REPO}/llvm/tags/${dir} | fgrep final > /dev/null; then
	VERSION2=`echo $dir | sed 's@^RELEASE_\([^/]*\)/$@\1@'`
	VERSION=`echo $VERSION2 | sed 's/\([0-9]\)/\1./g' | sed 's/\.$//'`
	break
    fi
done

if which clang > /dev/null 2>&1; then
    if clang --version | head -n 1 | fgrep "version ${VERSION}" > /dev/null; then
	echo "お使いのClang ${VERSION} は最新版です。" >&2
	exit 2
    fi
fi

echo "最新版、バージョン ${VERSION} をインストールします。" >&2

echo "ソースコードをダウンロード中・・・" >&2

if cd llvm > /dev/null 2>&1 ; then
    svn sw ${REPO}/llvm/tags/RELEASE_${VERSION2}/final .
    cd tools/clang
    svn sw ${REPO}/cfe/tags/RELEASE_${VERSION2}/final .
    cd ../../projects/compiler-rt
    svn sw ${REPO}/compiler-rt/tags/RELEASE_${VERSION2}/final .
    cd ../../../
else
    svn co ${REPO}/llvm/tags/RELEASE_${VERSION2}/final/ llvm
    cd llvm/tools
    svn co ${REPO}/cfe/tags/RELEASE_${VERSION2}/final clang
    cd ../projects
    svn co ${REPO}/compiler-rt/tags/RELEASE_${VERSION2}/final compiler-rt
    cd ../../
fi

echo "configure中・・・" >&2

mkdir clang-${VERSION} > /dev/null 2>&1 || test 0
cd clang-${VERSION}
# cp ../myarch.cmake ./
cat > myarch.cmake <<EOF
#set(CMAKE_SYSTEM_NAME ${SYSTEM})
#set(CMAKE_HOST_SYSTEM_PROCESSOR ${PROCESSOR})
set(triple ${TARGET_TRIPLE})

set(CMAKE_C_COMPILER ${CC})
set(CMAKE_C_COMPILER_TARGET \${triple})
set(CMAKE_C_FLAGS_RELEASE "${CFLAGS}")
set(CMAKE_CXX_COMPILER ${CXX})
set(CMAKE_CXX_COMPILER_TARGET \${triple})
EOF

export PATH=$PYTHONPATH:$PATH
cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD="X86" -DCMAKE_INSTALL_PREFIX=$PREFIX -DGCC_INSTALL_PREFIX=$GCC_PREFIX -DCMAKE_TOOLCHAIN_FILE="./myarch.cmake" -DLLVM_HOST_TRIPLE=${TARGET_TRIPLE} -DLLVM_DEFAULT_TARGET_TRIPLE=${TARGET_TRIPLE} ../llvm

echo "ビルド中・・・" >&2

$MAKE_BEFORE $BUILD_BEFORE make $MAKE_FLAGS $BUILD_FLAGS

set +e
echo "旧バージョンの削除中・・・(ある場合)" >&2
$SUDO $PORG -br clang || $SUDO $PORG -br llvm

echo "インストール中・・・" >&2
set -e
$SUDO $PORG -lD "${MAKE_BEFORE} ${INSTALL_BEFORE} make install ${MAKE_FLAGS} ${INSTALL_FLAGS}"

echo "Clang ${VERSION} のインストールが完了しました！" >&2
