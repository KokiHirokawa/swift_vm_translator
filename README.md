# swift vm translator
『コンピュータシステムの理論と実装』7~8章
VMコードをHackのアセンブリコードへと変換する。

## VMプログラムに含まれる4種類のコマンド
- 算術
  - スタック上で算術演算と論理演算を行う。 
- メモリアクセス
  - スタックとバーチャルメモリ領域の間でデータの転送を行う。
- プログラムフロー
  - 条件付き分岐処理または無条件の分岐処理を行う。
- サブルーチン呼び出し
  - 関数呼び出しとそれらからのリターンを行う。

## VMプログラム(スタック操作)
`d = (2-x)*(y+5)`
```
push 2
push x
sub
push y
push 5
add
mult
pop d
```

`if (x<7) or (y=8)`
```
push x
push 7
lt
push y
push 8
eq
or
```

## フォーマット
```
- command (ex: add)
- command arg (ex: goto LOOP)
- command arg1 arg2 (ex: push local 3)
```
引数はcommandパートから分離され、その間には空白文字がひとつ以上入る。
「//」以降はコメントとして解釈され、その内容は無視される。
空行を含むことができるが、無視される。

## 算術と論理コマンド
- 二変数関数（binary function）
  - スタックから2つのデータを取り出し二変数関数を実行したのちスタックに結果を戻す。
- 一変数関数（unary function）
  - スタックから1つのデータを取り出し一変数関数を実行したのちスタックに結果を戻す。

## メモリアクセスコマンド
```
- push segment index
  - segment[index]をスタックの上にプッシュする。
- pop segment index
  - スタックの一番上のデータをポップし、それをsegment[index]に格納する。
```
- argument
- local
- static
- constant
- this
- that
- pointer
- temp

## RAMの使用方法
- 0-15
  - 16個の仮想レジスタ
- 16-255
  - (VMプログラムの全てのVM関数における)スタティック変数
- 256-2047
  - スタック
- 2048-16383
  - ヒープ（オブジェクトと配列を格納する）
- 16384-24575
  - メモリマップドI/O
- 24576-32767
  - 使用しないメモリ空間

## レジスタ
- RAM[0]=SP
  - スタックポインタ：スタックの最上位の次を指す
- RAM[1]=LCL
  - localセグメントのベースアドレスを指す
- RAM[2]=ARG
  - argumentセグメントのベースアドレスを指す
- RAM[3]=THIS
  - thisセグメントのベースアドレスを指す
- RAM[4]=THAT
  - thatセグメントのベースアドレスを指す
- RAM[5-12]
  - tempセグメントの値を保持する
- RAM[13-15]
  - 汎用的なレジスタとして使用可能

## Memo
- true
  - -1
  - 0xFFFF
  - 1111111111111111
- false
  - 0
  - 0x0000
  - 0000000000000000
