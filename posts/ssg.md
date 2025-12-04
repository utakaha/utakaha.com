---
title: 'ブログを作り変えた'
date: '2025-12-06'
---

このブログを自作したSSGに移行した。

[utakaha/utakaha.com](https://github.com/utakaha/utakaha.com)

ブログを一新するにあたって色々な選択肢を考えたが、リッチなUIや機能は必要なかったし、できるだけ依存関係を減らしたかったので、最終的にはSSGを自作することにした。

元々はNext.jsを使っていたけど、あまりブログを更新しないこともあって、ブログを書くときに毎回ライブラリの更新作業が発生していてメンテナンスが面倒になっていた。
なので、今回はできるだけメンテナンスの手間が少ない構成を目指した。

Gemfile: 

```ruby
# frozen_string_literal: true

source "https://rubygems.org"

gem "webrick"
gem "redcarpet"
gem "rouge"
```

基本的には標準ライブラリのみを利用するようにしている。
Markdown parserとSyntax highlighterは自分で書くのが億劫だったので、そこだけOSSのRedcarpetとRougeを利用した。

Webrickは開発環境でHTTPサーバーとして利用している。
今後もできるだけ依存は増やさない予定だけど、RuboCopは入れるかもしれない。

Next.jsで作っていたときはVercelにデプロイしていて、その前のJekyllで作っていた頃はGitHub Pagesにデプロイしていた。
今回は新しいものを使いたかったこともあり、Cloudflare Pagesにデプロイしている。
GitHub Actionsを使ってさくっとデプロイできるし、Cloudflare Web Analyticsもボタン一個で追加できるので楽でいい。

Markdownで書いた文章をERBのテンプレートを使ってHTMLに変換して、それをpublicディレクトリに吐き出している。
そのpublicディレクトリにある静的ファイルをデプロイするだけのシンプルな実装になっている。
あとはFront Matterをパースするようにしているのと、ERBでパーシャルを使えるようにするくらいのことはした。

現在のディレクトリ構成は以下。

```
.
├── assets
├── bin
│   ├── build
│   └── server
├── Gemfile
├── Gemfile.lock
├── lib
│   ├── build.rb
│   ├── post.rb
│   └── template_renderer.rb
├── posts
├── README.md
└── templates
    ├── _footer.html.erb
    ├── _head.html.erb
    ├── _header.html.erb
    ├── 404.html.erb
    ├── index.html.erb
    └── post.html.erb
```

今後もいくつか追加した機能があるので、最小限の状態を保ちながら少しずつ育てていきたい。