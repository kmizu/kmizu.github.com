---
title: "JavaScriptで作る！ミニ言語のインタプリタ（１）"
---

# はじめに

[前回の記事](https://zenn.dev/nextbeat/articles/4006498a7f36bc)では抽象構文木を手で組み立てることによって、**たった100行で**変数機能を持った数式言語のインタプリタを作ることができました。

しかし、これではプログラミング言語と呼ぶことはできません。今回からは「最低限の機能を揃えたプログラミング言語」を作ることを目標にしていきます。

この記事では前回の数式言語を拡張して

- 条件分岐
- 繰り返し
- 連接
- 比較演算

を実装する過程を示します。これらを実装しても200行に満たないのですから、プログラミング言語を作るというのは、少なくとも「規模の大きいプロジェクトでない」のはわかるかと思います。RubyやPython、Javaといった「製品として使えるクオリティの言語を作る」となると、もちろん話は別になりますが。

## 条件分岐

まずは条件分岐について考えます。大抵の言語の条件分岐は

```js
if(条件) then節 else else節
```

のように表せるわけですが、前回と同様にこれをJavaScriptのクラスとして表現してみましょう。

```js
// 条件分岐のためのクラス
class If extends Expression {
  constructor(cond, thenExpr, elseExpr) {
    super();
    this.cond = cond;
    this.thenExpr = thenExpr;
    this.elseExpr = elseExpr;
  }
}
```

`cond`が条件式を、`thenExpr`が条件式が真のときに評価される式を、`elseExpr`が条件式が偽のときに評価される式を表します。

`cond`にいれる条件式についてはまだ未実装ですがこれについては後ほど触れます。

これを評価するためには`eval`関数に次の部分を加える必要があります。

```js
function eval(expr, env) {
  ...
  } else if(expr instanceof If) {
     if(eval(expr.cond, env) !== 0) {
       return eval(expr.thenExpr, env);
     }else {
       return eval(expr.elseExpr, env);
     }
  } ...
}
```

`expr`が`If`のインスタンスの場合に特別な処理を実行しています。ここでポイントは条件式を評価した結果が**0でないとき**は`thenExpr`を評価して、**0のとき**は`elseExpr`を評価していることです。

C言語などでは0を偽、それ以外を1として取り扱いますが発想としてはそれと同じです。データ型として真偽値を別に用意できた方が望ましいですが、この記事はできるだけ簡潔にプログラミング言語のインタプリタを作ることが目標なので、整数で真偽値を代用してしまうことにします。

## 繰り返し

次に繰り返しについて考えてみます。ほとんどの言語の繰り返しは

```js
while(条件) body
```

のように表せるので、これを素直にJavaScriptのクラスとして表せばよさそうです。

```js
// 繰り返しのためのクラス
class While extends Expression {
  constructor(cond, body) {
    super();
    this.cond = cond;
    this.body = body;
  }
}
```

`cond`が継続条件を、`body`が繰り返し評価される式を表します。

これを評価するためには`eval`関数に次の部分を加える必要があります。

```js
function eval(expr, env) {
  ...
  } else if(expr instanceof While) {
     while(eval(expr.cond, env) !== 0) {
       eval(expr.body, env);
     }
     return 0;
  } ...
}
```

`expr`が`While`のインスタンスの場合に特別な処理を実行しています。条件分岐のときと同様に整数によって真偽値をあらわしていることに注意してください。

## 連接

既に条件分岐や繰り返しのためのクラスを作りましたが、定義を見るとわかるように本体に「たった一つの式」しか書くことができません。一般的にはこれでは困りますから「複数の式を受け取って、順番に実行して最後の式の値を返す」ための構文を用意します。いわゆる「連接」と呼ばれるものですね。

```js
// 連接のためのクラス
class Seq extends Expression {
  constructor(...bodies) {
    super();
    this.bodies = bodies;
  }
}
```

これを評価するためには`eval`関数に次の部分を加える必要があります。

```js
function eval(expr, env) {
  ...
  } else if(expr instanceof Seq) {
     let result = null;
     expr.bodies.forEach((e) => {
        result = eval(e, env);
     });
     return result;
  } ...
}
```

`bodies`に順番に実行すべき式が入っているので、それを`forEach`で一つずつ取り出し、評価しています。`Seq`は最後に評価した結果が全体の結果になる必要があるため、結果を毎回`result`に代入しているのがポイントです。

## 比較演算

ここまででだいたいの部品は揃ったのですが、比較がまだないのでした。たとえば、

```js
let sum = 0;
let i = 0;
while(i <= 10) {
  sum += i;
  i += 1;
}
```

に相当するプログラムを書きたくても、`i <= 10`を表現する方法がありません。というわけで追加してみましょう。今回追加するのは`<`, `>`, `<=`, `>=`, `==`, `!=`の6つです。

```js
function eval(expr, env) {
  // 前回と同じ
  if(expr instanceof BinExpr) {
    const resultL = eval(expr.lhs, env);
    const resultR = eval(expr.rhs, env);
    switch(expr.operator) {
      ...
      case "<":
        return resultL < resultR ? 1 : 0;
      case ">":
        return resultL > resultR ? 1 : 0;
      case "<=":
        return resultL <= resultR ? 1 : 0;
      case ">=":
        return resultL >= resultR ? 1 : 0;
      case "==":
        return resultL === resultR ? 1 : 0;
      case "!=":
        return resultL !== resultR ? 1 : 0;
    }
}
```

前回作った四則演算を評価する部分に継ぎ足す形で処理を実装します。左辺と右辺を再帰的に評価して、結果を`resultL`と`resultR`に代入するところは同じですね。

あとはJavaScriptに元々備わっている比較演算子を使って、結果が真なら`1`を、偽なら`0`を返すだけです。

## プログラムを実行する

条件分岐、繰り返し、連接を実装できたので前回より意味のあるプログラムを作ってみましょう。

```js
/*
 * let sum = 0;
 * let i = 0;
 * while(i <= 0) {
 *   sum += i;
 *   i += 1;
 * }
 * sum
 */
const program = new Program(
  // sum = 0
  new Assignment("sum", new Num(0)),
  // i = 0
  new Assignment("i", new Num(0)),
  new While(
    // i <= 10
    new BinExpr("<=", new VarRef("i"), new Num(10)),
    new Seq(
      // sum = sum + i
      new Assignment("sum", new BinExpr("+", new VarRef("sum"), new VarRef("i"))),
      // i = i + 1
      new Assignment("i", new BinExpr("+", new VarRef("i"), new Num(1)))
    )
  ),
  new VarRef("sum")
);
console.log("result = " + evalProgram(program)); // result = 55
```

だいぶ冗長にはなってきましたが、やろうとしてること自体は直感的にわかるのではないでしょうか。この「プログラム」を実行すると、

```console
result = 55
```

と表示されます。ここまで拡張しても行数は150行。次回はいよいよ関数定義と関数呼び出しの機能を作り込んでいきます。

[次の記事はこちら](https://zenn.dev/nextbeat/articles/262f1d6b352e7b)