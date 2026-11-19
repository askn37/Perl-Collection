# Perl-Collection

Perl用の雑多なスクリプト。なんならOSだって書ける。

> いずれも Artistic License 2.0 と MIT License を選択可

## Binary category

- gencrc.pl

  [euboot](https://github.com/askn37/euboot)等に添付している CRC計算／逆計算生成ツール。
  原理と目的は Qiita掲載の記事 [任意の CRC値を導出する](https://qiita.com/askn37/items/6b0380d2d4657229172d)を参照のこと。

## Text category

- hexview.pl

  Intel HEX Format ファイルを食わせて、色付けと ASCIIダンプを行う。 

- SpaceRemover.pl

  指定の（ディレクトリ以下の全ての）テキストファイルを対象に、Tab の Space変換と、行末の Space除去を行う。
  変換対象ファイルの拡張子は、スクリプト冒頭のフィルタで選別している。
バックアップは取らないので注意。

  先祖は 1980年代に書いたモノなので、結構な年代物。

## USB category

- lsusb.pl

  usbutilsの lsusbと同種の表示を行う。Windwosでも macosでも使える。一方で Linuxには不適。原典の libusbや、macos の usbdiagnoseが読みにくい／妙に使いにくいので自作したもの。VIDデータベース等は持たないので、情報量は原典より簡素。

## Copyright and Contact

Twitter(X): [@askn37](https://twitter.com/askn37) \
BlueSky Social: [@multix.jp](https://bsky.app/profile/multix.jp) \
GitHub: [https://github.com/askn37/](https://github.com/askn37/) \
Product: [https://askn37.github.io/](https://askn37.github.io/)

Copyright (c) askn (K.Sato) multix.jp \
Released under the Artistic License 2.0 \
https://opensource.org/license/Artistic-2.0
