---
title: "JavaScriptで作る！ミニ言語のインタプリタ（３）〜動的スコープと静的スコープ〜"
---

# はじめに

[前回の記事](https://zenn.dev/nextbeat/articles/262f1d6b352e7b)では、関数定義と関数呼び出しの機能を実装し、再帰関数まで動作するインタプリタを作ることができました。しかし、その実装には大きな問題がありました。今回は、その問題点を明らかにし、解決策を提示します。

# 動的スコープの問題点

前回の実装では、関数呼び出し時に以下のようなコードを使用していました：

```javascript
const newEnv = Object.assign({}, env);
```

これは既存の環境をコピーして新しい環境を作成するものですが、この方法には大きな問題があります。

具体的にどのような問題が起こるか、以下のプログラムで確認してみましょう：

```javascript
/*
 * function refA() {
 *   return a;
 * }
 * function main() {
 *   let a = 3;
 *   return refA();
 * }
 * に相当
 */
const program = new Program(
  [
    new FunDef("refA", [],
      new VarRef("a"),
    ),
    new FunDef("main", [],
      new Assignment("a", new Num(3)),
      new FunCall("refA"),
    )
  ],
  new FunCall("main")
);
console.log("result = " + evalProgram(program)); // 3
```

このプログラムは、`main`関数内で変数`a`に3を代入し、その後`refA`関数を呼び出して`a`の値を返すものです。多くのプログラマーは`refA`関数内では`a`が定義されていないため、エラーになるか`undefined`が返されることを期待するでしょう。

しかし、実際の出力は`3`になります。これは`refA`関数が呼び出された時点での環境（つまり`main`関数の環境）を引き継いでしまうためです。

このような挙動は動的スコープと呼ばれます。動的スコープは古くはEmacs Lispなどに採用されていました。当時は決して珍しい方式ではありませんでした。しかし、多くのプログラマーにとって直感に反するものであり、バグの温床となる可能性があるため、現代のほとんどの言語は動的スコープを採用していません。

# 静的スコープの実装

この問題を解決するために、静的スコープを実装します。静的スコープでは、関数がどこで定義されたかによって参照できる変数が決まります。上の例でいうと、関数`refA`が定義された時点では変数`a`は定義されていないのでエラーになります。

まず、`evalProgram`関数を以下のように変更します：

```javascript
 function evalProgram(program) {
   const env = {};
+  const funEnv = {};
   let result = null;
   program.defs.forEach((d) => {
-    env[d.name] = d;
+    funEnv[d.name] = d;
   });
   program.expressions.forEach((e) => {
-    result = eval(e, env);
+    result = eval(e, env, funEnv);
   });
   return result;
 }

```

今回から変更点をdiff形式で表示してみることにしました。

ここで変数の環境`env`と関数の環境`funEnv`を分離しています。関数の環境を分離しているのは、関数定義はプログラムの実行を通して変わらないためです。`eval`の引数が１つ増えたため、これまでの`eval`呼び出しの引数に`funEnv`を追加します。

次に、`eval`関数の関数の中身を以下のように変更します：

```javascript
   } else if(expr instanceof FunCall) {
-     const def = env[expr.name];
+     const def = funEnv[expr.name];
      if(!def) throw `function ${expr.name} is not defined`;
 
-     const args = expr.args.map((a) => eval(a, env));
+     const args = expr.args.map((a) => eval(a, env, funEnv));
 
-     const newEnv = Object.assign({}, env);
+     const newEnv = {}
      for(let i = 0; i < def.args.length; i++) {
        newEnv[def.args[i]] = args[i];
      }
-     return eval(def.body, newEnv);
+     return eval(def.body, newEnv, funEnv);
```

重要な変更点は、新しい環境`newEnv`を作成する際に、既存の環境をコピーするのではなく、完全に新しい空の環境を作成していることです。これにより、関数内で参照できる変数は、その関数の引数と関数内で定義されたローカル変数のみになります。

変更を加えた後、先ほどのプログラムを実行すると：

```javascript
console.log("result = " + evalProgram(program)); // undefined
```

期待通り`undefined`が出力されます。これは`refA`関数内で`a`が定義されていないためです。もし`undefined`でなく例外が投げられるようにしたい場合、変数参照をあらわす`VarRef`の処理を以下のように修正します。

```js
   } else if(expr instanceof VarRef) {
+     if (!(expr.name in env)) {
+       throw new Error(`variable ${key} is not defined`);
+     }
      return env[expr.name];
+
+     return env[expr.name];
```

# まとめ

今回の記事では、以下の点について学びました。

1. 動的スコープの問題点
2. 静的スコープの実装方法

静的スコープを実装することで、より直感的で予測可能な挙動のインタプリタを作ることができました。

現在のインタプリタは組み込み関数がありませんから、次回は入出力を行う組み込み関数を定義していきたいと思います。

# イベントの宣伝

記事の趣旨とはややずれますが、9月20日（金）にプログラミング教育について考える技術イベント「[Nextbeat Tech Bar：第一回プログラミング教育について語る会](https://nextbeat.connpass.com/event/326635/)」を行います。

9月下旬なのでまだまだ残暑が厳しい時期かと思いますが、オフラインだけでなくオンライン参加も可能です。

昨今、盛んに議論されるようになってきたプログラミング教育について興味がある方、是非参加してみませんか？

https://nextbeat.connpass.com/event/326635/