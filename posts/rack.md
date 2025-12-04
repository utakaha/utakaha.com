---
title: 'Rackアプリケーションが起動するまでの処理を追う'
date: '2024-12-12'
---

[SmartHR Advent Calendar 2024 シリーズ1](https://qiita.com/advent-calendar/2024)の12日目です。昨日はyurikoさんの[入社して1年、「修復」への道](https://yuriko1211.hatenablog.com/entry/2024/12/11/085346)でした。


## Rackアプリケーションはどのように起動されるのか
Rackアプリケーションが `call` を実装して `[status, headers, body]` を返すことはなんとなく知っていましたが、Rackが実際何をしているのか気になったのでコードを読んでみました。

Rackのバージョンは3.1.8を使用しています。
今回はRackupを用いてRackアプリケーションが起動するまでの流れを追います。
`rackup` コマンドは [rack/rackup](https://github.com/rack/rackup) で提供されています。
ちなみにWEBrickがRubyに含まれていた頃はRackupもRackの一部として提供されていましたが、v3.0.0で分離されました。
分離するかどうかのディスカッションでRackはインターフェースに集中すべき（意訳）という意見があり、Rackの真髄が見えた気がしました。

- [https://github.com/rack/rack/discussions/1928](https://github.com/rack/rack/discussions/1928)
- [https://github.com/rack/rack/pull/1937](https://github.com/rack/rack/pull/1937)

`rackup` コマンドを使うことで簡単にRackアプリケーションを起動できます。

```sh
$ rackup
```

なお、プロダクションで `rackup` コマンドを使ってサーバーを起動することは推奨されておらず、Webサーバーが提供しているコマンドから起動することが推奨されています。

まず、シンプルなRackアプリケーションを作成します。
今回はRackアプリケーションが起動するまでの処理を追うだけなので、config.ru に直接アプリを定義し、`run` にアプリのインスタンスを渡します。

```ruby
# config.ru
class App
  def call(env)
    [200, {}, ["Hello World."]]
  end
end

run App.new
```

config.ru を作成したあとに `rackup` コマンドを実行すると、bin/rackup で `Rackup::Server.start` が動きます。`Rackup::Server` のインスタンスを作成し、 `Rackup::Server#start` を呼び出します。`Rackup::Server#start` では、`options` の有無を確認し、存在する場合はオプションごとの処理を行ったあと、`server.run` を実行します。

```ruby
# rackup/lib/rackup/server.rb
def start(&block)  
  # オプションが存在する場合の処理

  trap(:INT) do
    if server.respond_to?(:shutdown)
      server.shutdown
    else
      exit
    end
  end

  server.run(wrapped_app, **options, &block)
end
```

[https://github.com/rack/rackup/blob/v2.2.1/lib/rackup/server.rb#L300](https://github.com/rack/rackup/blob/v2.2.1/lib/rackup/server.rb#L300)

`server.run` に引数として渡している `wrapped_app` の中で `Rack::Builder.parse_file` が実行されていて、この中でconfig.ruを解析し、Rackアプリケーションを返します。

```ruby
# rack/lib/rack/builder.rb
def self.parse_file(path, **options)
  if path.end_with?('.ru')
    # 設定ファイル（config.ru）を読み込んで app を返している
    return self.load_file(path, **options)
  else
    require path
    return Object.const_get(::File.basename(path, '.rb').split('_').map(&:capitalize).join(''))
  end
end
```

[https://github.com/rack/rack/blob/v3.1.8/lib/rack/builder.rb#L65](https://github.com/rack/rack/blob/v3.1.8/lib/rack/builder.rb#L65)

Rackビルダーは、スタックにミドルウェアを追加する `use` やRackアプリケーションをディスパッチする `run` など、Rackアプリケーションを構築するためのDSLを提供しています。

`server.run` のレシーバーである `server` は何らかのRackハンドラーです。今回は何も指定してないので、デフォルトのWEBrickのハンドラーである `Rackup::Handler::WEBrick` が代入されます。

```ruby
# rackup/lib/rackup/server.rb
def server
  @_server ||= Handler.get(options[:server]) || Handler.default
end
```

[https://github.com/rack/rackup/blob/v2.2.1/lib/rackup/server.rb#L344](https://github.com/rack/rackup/blob/v2.2.1/lib/rackup/server.rb#L344)

RackハンドラーはWebサーバーとRackを繋ぐためのもので、基本的に各Webサーバー側で実装されています。WEBrickとCGIのハンドラーのみRackupに内包されています。Pumaのハンドラーは [puma/lib/rack/handler/puma.rb](https://github.com/puma/puma/blob/master/lib/rack/handler/puma.rb) で提供されています。
Rackハンドラーは `Handler.run(app)` を呼び出して起動します。

`Rackup::Handler::WEBrick.run` の中で `WEBrick::HTTPServer` オブジェクトを作成し、RackアプリケーションをマウントしてWebサーバーを起動しています。

```ruby
# rackup/lib/rackup/handler/webrick.rb
def self.run(app, **options)
  environment  = ENV['RACK_ENV'] || 'development'
  default_host = environment == 'development' ? 'localhost' : nil

  if !options[:BindAddress] || options[:Host]
    options[:BindAddress] = options.delete(:Host) || default_host
  end
  options[:Port] ||= 8080
  if options[:SSLEnable]
    require 'webrick/https'
  end

  @server = ::WEBrick::HTTPServer.new(options)
  @server.mount "/", Rackup::Handler::WEBrick, app
  yield @server if block_given?
  @server.start
end
```

[https://github.com/rack/rackup/blob/v2.2.1/lib/rackup/handler/webrick.rb#L19](https://github.com/rack/rackup/blob/v2.2.1/lib/rackup/handler/webrick.rb#L19)

## Rackが提供している機能
ここまではビルダーくらいしかRack本体の機能は登場してませんが、Rackは他にも様々な機能を提供しています。
Rackは[仕様](https://github.com/rack/rack/blob/main/SPEC.rdoc)が厳密に決まっています。
仕様に則って楽にRackアプリケーションやミドルウェアが開発できるように、便利なヘルパーが用意されています。

[https://github.com/rack/rack?tab=readme-ov-file#convenience-interfaces](https://github.com/rack/rack?tab=readme-ov-file#convenience-interfaces)

例えば、`Rack::Response` はRackのインターフェースに沿ったレスポンスを作成してくれます。
以下のように使うことができます。

```ruby
# config.ru
require "rack"

class App
  def call(env)
    response = Rack::Response.new("Hello World.", 200, {})
    response.finish # `[status, headers, body]` の形式で返してくる
  end
end
```
`Rack::Response#location=` などのセッターもRack::Response::Helpersモジュールとして提供されています。
```ruby
response.location = "https://example.com"
```

また、Rack本体にもミドルウェアが内包されています。
Rack::ContentLength は、bodyのサイズを計算してレスポンスヘッダーに `Content-Length` を追加します。
ちなみにこのミドルウェアはRackupでも使われています。

```ruby
# ruby/lib/rack/content_length.rb
def call(env)
  status, headers, body = response = @app.call(env)

  if !STATUS_WITH_NO_ENTITY_BODY.key?(status.to_i) &&
     !headers[CONTENT_LENGTH] &&
     !headers[TRANSFER_ENCODING] &&
     body.respond_to?(:to_ary)

    response[2] = body = body.to_ary
    headers[CONTENT_LENGTH] = body.sum(&:bytesize).to_s
  end

  response
end
```

[https://github.com/rack/rack/blob/v3.1.8/lib/rack/content_length.rb](https://github.com/rack/rack/blob/v3.1.8/lib/rack/content_length.rb)

## 終わり
Rackを読むつもりがほぼほぼRackupを読んでました。

あとRackという命名がとても好きです。

## References
- [https://leahneukirchen.org/blog/archive/2007/02/introducing-rack.html](https://leahneukirchen.org/blog/archive/2007/02/introducing-rack.html)
- [https://github.com/rack/rack](https://github.com/rack/rack)
- [https://github.com/rack/rackup](https://github.com/rack/rackup)
- [https://github.com/ruby/webrick](https://github.com/ruby/webrick)