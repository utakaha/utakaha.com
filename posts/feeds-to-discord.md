---
title: 'DiscordにRSSフィードを流す'
date: '2020-12-30'
image: 'feeds-to-discord.png'
---

DiscordにRSSフィードを流したい時があったのでその時の作業まとめを書く。
ちなみにRSSリーダーは主にFeedlyを使っている。

今回はGoogleアラートのフィードを流したかったのでGoogleアラートのフィードURLを指定して実装しているけど、どのフィードURLでも基本の実装は変わらないはず。

## 実装
Googleアラートの配信先がデフォルトだとメールになっているので、メールからRSSフィードに変更する。
DiscordはSlackみたいに公式でRSSの機能があるわけではないので、RSSを取得するところは自分で実装した。

ソースコードはこちら。

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rss'
require 'dotenv/load'
require 'discordrb/webhooks'

client = Discordrb::Webhooks::Client.new(url: ENV['WEBHOOK_URL'])

urls = [
  ENV['A_ENDPOINT'],
  ENV['B_ENDPOINT'],
  ENV['C_ENDPOINT']
]

items = urls.map do |url|
  RSS::Parser.parse(url).items.map do |item|
    {
      title: item.title.content,
      description: item.content.content,
      url: item.link.href,
      timestamp: item.updated.content
    }
  end
rescue RSS::MissingTagError => e
  puts "#{e.class}: #{e.message}"
end.flatten.compact

if items.any?
  client.execute do |builder|
    items.each do |item|
      builder.add_embed do |embed|
        embed.title = item[:title]
        embed.description = item[:description]
        embed.url = item[:url]
        embed.timestamp = item[:timestamp]
      end
    end
  end
else
  puts '新着情報はありません'
end
```

流したいフィードURLをループして、新着情報があればその情報をWebhook URLで指定したチャンネルに流すというコードを書いた。
このスクリプトを毎朝10時に実行するようにスケジューラを設定している。
