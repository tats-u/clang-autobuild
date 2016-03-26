#Clang自動ビルドシェルスクリプト
##概要
Clangの最新版を取ってきて自動でビルドし、インストールまで行います。

##ターゲットOS(他のOSでも動くかもしれません)
CentOS 6～ + GCC4.7～

##必要なもの
- **C++11に対応している**GCCなどのC/C++コンパイラ
- C++11に対応しているlibstdc++などのC++ランタイム(libc++のビルドは行いません)
- Python 2.7
- porgもしくはpaco(ソースビルドしたソフトウェアの管理ソフト)
- その他Clangのビルドに必要なライブラリなど

##インストールするモジュール
- LLVM
- Clang
- Compiler-RT
##インストールしないモジュール
- **extra Clang Tools**
- libc++

##注意
CentOS 6では予め最新版のGCCをソースビルドしておく必要があります。

##使用方法
- `build_llvm.sh`をダウンロードします。
```Bash
wget https://raw.githubusercontent.com/tats-u/clang-autobuild/master/build_llvm.sh
```
- ダウンロードした`build_llvm.sh`を開いて、設定項目をいじります。
- 最後に、端末から
```Bash
sh ./build_llvm.sh
```
を実行します。
