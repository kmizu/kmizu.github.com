---
title: "JavaScriptで作る！ミニ言語のインタプリタ（２）〜関数定義〜"
---

# はじめに

[前回の記事](https://zenn.dev/nextbeat/articles/1afee22d61c021)では抽象構文木を手で組み立てることによって、**200行未満で**以下の機能を持ったミニ言語のインタプリタを作ることができました。

- データ型として整数のみをサポート
- 四則演算、比較演算をサポート
- 条件分岐、繰り返し、連接が使える
- 変数の定義（代入）と参照ができる

既に、以下のような形で「プログラム」を組むことができます：

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

だいぶプログラミング言語らしくなってきましたが、せっかくプログラミング言語を作るのだから関数の定義や関数呼び出しの機能も欲しいところです。

今回の記事では、いよいよ関数定義や関数呼び出しの機能を作り込んでいきます。

# 関数定義

まず、関数定義のためのクラスを考えます。

たとえば以下のような関数定義について考えてみます。

```js
function add(x, y) { return x + y; }
```

このとき、関数定義に必要な要素を考えてみると、

- 関数名:`add`
- 引数列:`[x, y]`
- 本体: `return x + y;`

この３つがあることに気づきます。というわけで、この３つを持ったクラス`FunDef`を作ってみます：

```js
//関数定義を表すクラス
class FunDef {
  constructor(name, args, body) {
    this.name = name;
    this.args = args;
    this.body = body;
  }
}
```

この`FunDef`クラスは次のようにインスタンス化できます。

```js
// function add(x, y){ return x + y; }
const add = new FunDef(
  "add", ["x", "y"], new BinExpr("+", new VarRef("x"), new VarRef("y"))
)
```

# 関数の登録

さて、関数定義を表す`FunDef`クラスを定義しましたが、それに伴って`Program`クラスも変更する必要があります。具体的には、プログラム本体の前に関数定義の列`defs`を追加する必要があります。

```js
//プログラム全体 
class Program {
  constructor(defs, ...expressions){
    this.defs = defs;
    this.expressions = expressions;
  }
}
```

プログラムの最初に関数定義の並びがあって、その後にプログラム本体が出てくるイメージです。さらに、このプログラムを処理するときに、関数名と関数定義本体を結びつける必要があります。既に変数と値を結びつけるための`env`があるのでそれを流用してしまいましょう。

プログラム全体を評価する`evalProgram`を改変すると次のようになります。

```js
function evalProgram(program) {
  const env = {};
  let result = null;
  program.defs.forEach((d) => {
    env[d.name] = d;
  }); // 関数定義を登録
  program.expressions.forEach((e) => {
    result = eval(e, env);
  });
  return result;
}
```

`programs.defs.forEach...`という処理で関数名と関数定義本体を紐づけています。これによって、プログラム本体を評価するときに`env[name]`のようにすることで、関数`name`を参照できるわけです。

あとは定義した関数をプログラム本体で呼び出せるようにします。

# 関数呼び出し

前回の記事では「関数呼び出し」という機能がありませんでした。これまでと同様に新しいクラスを作ってしまいます。名前は`Function Call`を省略した`FunCall`とします。

```js
// 関数呼び出しのためのクラス
class FunCall extends Expression {
  constructor(name, ...args) {
    super();
    this.name = name;
    this.args = args;
  }
}
```

`name`は呼び出す関数名で、`args`は実引数の並びです。利便性のために可変長引数にしてあります。

関数呼び出しを処理する部分は以下のようになります。

```js
  } else if(expr instanceof FunCall) {
     //関数名から関数定義本体を引っ張ってくる
     const def = env[expr.name];
     //関数定義が存在しなければ例外を投げる
     if(!def) throw `function ${expr.name} is not defined`;

     //実引数の処理。mapを使うと簡潔に書ける
     const args = expr.args.map((a) => eval(a, env));

     //関数を呼び出すときは、今までの環境を「コピー」して新しい環境を作る
     //これだと動的スコープになるので注意が必要
     const newEnv = Object.assign({}, env);
     //新しい環境で仮引数名 -> 実引数の対応付けを作る
     for(let i = 0; i < def.args.length; i++) {
       newEnv[def.args[i]] = args[i];
     }
     //新しい環境で関数本体を評価して結果を返す
     return eval(def.body, newEnv);
  }
```

関数本体の処理は各行のコメントに書かれている通りですが、一つ一つ見ていきましょう。

```js
const def = env[expr.name];
```

関数名をキーに`env`を参照することで、対応する関数定義を取得します。

```js
if(!def) throw `function ${expr.name} is not defined`;
```

プログラマーが誤って存在しない関数を呼んでしまう可能性がありますので、ここでは例外を投げてそのことを知らせています。

```js
const args = expr.args.map((a) => eval(a, env));
```

`expr.args`には関数呼び出しの実引数の並びが格納されているはずです。それぞれの実引数は`eval()`で評価できるはずですから、`map`を使うことで全ての実引数を評価した結果の並びを取得することができます。

```js
const newEnv = Object.assign({}, env);
```

関数を呼び出すときの「環境」、つまり変数から値への対応付けは関数を呼び出し終わったら消える必要があります。そのための方法は色々あるのですが、ここでは関数呼び出しのたびに新しい「環境」を作る方式を採用しています。`Object.assign({}, env)`によって「環境」のコピーを取得することができます。

```js
for(let i = 0; i < def.args.length; i++) {
  newEnv[def.args[i]] = args[i];
}
```

新しい環境の元で、仮引数名`def.args[i]`から実引数`args[i]`への対応付けを登録します。これによって、関数の本体を評価するときに仮引数を変数として使えるわけです。

気付いた方がいるかもしれませんが、仮引数と通常の（ローカル）変数は内部的には区別されていません。両方とも同じ「環境」に登録された変数です。

実際、多くのプログラミング言語でも、仮引数は単に関数呼び出しの最初に作られるちょっと特別なローカル変数という扱いを受けているわけですが、今回の処理を見るとその理由にも納得できるのではないかと思います。

```js
return eval(def.body, newEnv);
```

関数本体である`def.body`を新しい「環境」である`newEnv`の下で評価しています。`newEnv`は関数呼び出しが終わったら「ゴミ」になりどこかのタイミングでGC(ガベージコレクション）によって自動的に回収されます。

# プログラム本体

ここまでで関数定義および呼び出しの機能を作ることができたので、関数を使ったプログラムを組み上げてみましょう。以下は階乗を表す関数`fact`の定義と呼び出しをするプログラムです。

```js
const program = new Program(
  // function fact(n) {
  //   return n < 2 ? 1 : n * fact(n - 1)
  // }
  [new FunDef("fact", ["n"], 
     // n < 2 ? 1 : n * fact(n - 1)
     new If(
       // n < 2
       new BinExpr("<", new VarRef("n"), new Num(2)),
       // 1
       new Num(1),
       // n * fact(n - 1)
       new BinExpr("*", 
          new VarRef("n"),
          new FunCall("fact", new BinExpr("-", new VarRef("n"), new Num(1)))
       )
     )
   )],
  // fact(5)
  new FunCall("fact", new Num(5))
);
console.log("fact(5) = " + evalProgram(program)); // fact(5) = 120
```

だいぶ冗長になってきていますが、階乗の再帰も含めて適切に処理されています。

次回は今回の「関数定義」のアプローチの問題点とそれに対する解決法、組み込み関数の定義を取り扱います。

# イベントの宣伝

記事の趣旨とはややずれますが、7月26日（金）に関係データベース/SQLについての技術勉強会「Nextbeat Tech Bar：第一回関係データベース/SQL勉強会」を行います。

かなり暑くなってきた今日この頃ですが、オンライン参加も可能です。

関係データベースやSQLについて一言いいたい方の登壇や、発表を肴に盛り上がりたい方の参加をお待ちしております。

https://nextbeat.connpass.com/event/320119/