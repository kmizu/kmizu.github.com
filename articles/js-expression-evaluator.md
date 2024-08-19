---
title: "JavaScriptで100行で作る！数式言語のインタプリタ"
---

# はじめに

皆さんはプログラミング言語を作ったことがあるでしょうか？
おそらく大抵の方は「ない」というのが正直なところなのではないかと思います。背景には、おそらく「プログラミング言語を作るって難しそう」という先入観があるのではと筆者は踏んでいます。

プログラミング言語とは、コンピューターに指示を与えるための特別な言語です。私たちが日常で使う言語と同じように、プログラミング言語にも文法やルールがあります。そして、この言語を理解し実行するのが「処理系」と呼ばれるプログラムです。

しかし、実はプログラミング言語の処理系（インタプリタ）を作ることは非常に簡単なことです。小さなOSを作ることに比べても、ちゃんと動くWebサービスを作ることに比べても本当に簡単です。

というわけで、この記事では「プログラミング言語」を作るための導入として「数式言語」のインタプリタを作ってみます。数式言語とは、数学の式を扱う非常にシンプルな言語です。この言語の仕様は以下のようなものです：

* 扱えるデータは整数のみ
* 演算は四則演算（+、-、*、/）のみ
* 変数の代入 / 参照機能あり

たとえば、

```
a = 3 + 4 * 2
a + 3 // => 14
```

のような計算ができるものを想定しています。これは、変数aに3 + 4 * 2の結果（11）を代入し、その後aに3を足す計算です。

ただ、このくらいの「凄く小さい言語」でも、文字列を構文解析するという「本質的でない」作業をやると途端にややこしくなってしまいます。構文解析とは、プログラムの文字列を意味のある単位に分解し、それらの関係を木構造として構築する過程で、やや面倒くさいものです。

本記事では上記の数式に相当する「プログラム」をJavaScriptの抽象構文木として書き下すアプローチを取ることによってインタプリタの本質的な部分のみを説明できればと思います。抽象構文木とは、プログラムの構造を木のような形で表現したものです。これにより、プログラムの構造をより簡単に扱うことができます。

## 抽象構文木（AST）とは

プログラミング言語や数式を解析する際、最初に行うのは「構文解析」です。通常、この過程では入力されたテキストを「抽象構文木」（Abstract Syntax Tree, AST）と呼ばれる木構造のデータに変換します。
例えば、3 + 4 * 2という式のASTは以下のようになります：

```
   +
  / \
 3   *
    / \
   4   2
```

この木構造は、演算の優先順位を明確に表現しています。*（掛け算）が+（足し算）よりも下にあるため、先に実行されることがわかります。これは、数学で習う「掛け算は足し算より先に計算する」というルールを表現しています。

通常は、プログラムの文字列をこのような木構造に変換する「構文解析器」を作る必要がありますが、今回はこの過程を省略し、直接JavaScriptのオブジェクトとしてこの木構造を表現します。これにより、言語処理系の本質的な部分に集中することができます。

## ASTの設計

まず、数式言語のASTを表すクラスを定義します：

```js
//プログラム全体
class Program {
  constructor(...expressions){
    this.expressions = expressions
  }
}
// 式を表すクラス
class Expression {}
// 代入を表すクラス
class Assignment extends Expression {
  constructor(name, expr) {
    super();
    this.name = name;
    this.expr = expr;
  }
}
// 二項演算子（+、-、*、/）のためのクラス
class BinExpr extends Expression {
  constructor(operator, lhs, rhs) {
    super();
    this.operator = operator;
    this.lhs = lhs;
    this.rhs = rhs;
  }
}
// 整数値のためのクラス
class Num extends Expression {
  constructor(value) {
    super();
    this.value = value;
  }
}
// 変数参照のためのクラス
class VarRef extends Expression {
  constructor(name){
    super();
    this.name = name;
  }
}
```

これらのクラスを使えば

```
a = 3 + 4 * 2
a + 3
```

という「プログラム」は以下のように表現できます。

```js
const program = new Program(
  new Assignment("a",
    new BinExpr("+",
      new Num(3),
      new BinExpr("*", new Num(4), new Num(2))
    )
  ),
  new BinExpr("+", new VarRef("a"), new Num(3))
);
```

演算の優先順位はプログラムの抽象構文木の親子関係として表現されているため、別途考える必要がありません。

## インタプリタの実装

あとは、この「プログラム」を解釈実行するための関数`evalProgram()`（＝インタプリタ）を定義すればいいだけです。

`evalProgram()`関数は次のように定義することができます。

```js
function evalProgram(program) {
  const env = {};
  let result = null;
  program.expressions.forEach((e) => {
    result = eval(e, env);
  });
  return result;
}

function eval(expr, env) {
  if(expr instanceof BinExpr) {
    const resultL = eval(expr.lhs, env);
    const resultR = eval(expr.rhs, env);
    switch(expr.operator) {
      case "+":
        return resultL + resultR;
      case "-":
        return resultL - resultR;
      case "*":
        return resultL * resultR;
      case "/":
        return resultL / resultR;
    }
  } else if(expr instanceof Num) {
     return expr.value;
  } else if(expr instanceof VarRef) {
     return env[expr.name];
  } else if(expr instanceof Assignment) {
     const result = eval(expr.expr);
     env[expr.name] = result;
     return result;
  } else {
     console.assert(false, "should not reach here");
  }
}
```

この`evalProgram()`関数を使って先程の式をnode.js上で実行してみましょう。

```js
const program = new Program(
  new Assignment("a",
    new BinExpr("+",
      new Num(3),
      new BinExpr("*", new Num(4), new Num(2))
    )
  ),
  new BinExpr("+", new VarRef("a"), new Num(3))
); 
console.log("result = " + evalProgram(program)); // result = 14
```

`result = 14`と表示されたと思います。

ここまでのコードの総行数は90行未満。読者の方には「これだけのコードで作れてしまうんだ」と驚かれる方も多いのではないかと思います。しかし、プログラミング言語のインタプリタというのは基本的には抽象構文木を再帰的にたどる関数として実装できるのでこれくらいにシンプルなのは当然なのです。

もちろん、実際に「使える」言語を作るためには、構文解析が必要なのでもう少しコードは増えます。さらに、色々な機能や型検査を追加したり、あるいは高速化や親切なエラーメッセージを付け加えたりしていくと「簡単」とは言えなくなりますが、それは「製品」として使えるプログラミング言語は複雑になるというだけで、プログラミング言語そのものはそこまで複雑ではないと言えると考えています。

この記事を通じて、一人でも多くの方が「プログラミング言語をちょっと作ってみよう」という気になっていただければ幸いです。