---
title: 'Obsidianで雑なメモを取れるようにする'
date: '2026-05-24'
---

最近メモアプリとしてObsidianを使っている。
ただ、気軽にメモを取るというよりは、ある程度の情報量になった知識をまとめるノートみたいに利用している。
気軽にメモを取りたいときはApple純正のメモを使うことが多いけど、せっかくObsidianを使っているし、[デイリーノート](https://obsidian.md/ja/help/plugins/daily-notes)の機能（コアプラグイン）もあるのでObisidianに統一したい気持ちがあった。

何度か試してみた感想として、Obsidianは雑にメモを取るには気軽さがなくて続かなかった。
一行くらいの雑なメモを取りたいだけなのに、Obsidianのアプリに切り替えてデイリーノートを開いてメモを追加する行にフォーカスしないといけないので、作業量が多くてめんどくさい気持ちになった。
ちなみにメモごとに新規でページを作るのは管理が不可能になるので自分的には選択肢としてなかった。
Obsidianで常にデイリーノートのページを開いておけばいいが、体系的な知識をまとめたいときにも使うので、常にデイリーノートを開いておく運用にもできなかったし、Obsidianのタブで開いていてもタブの切り替えをしないといけないので作業量は変わらなかった。
スマホでも同じように別のページを開いたりするので、結局Apple純正のメモに戻ってた。

ツイッターで流れてきた[Obsidianでプライベートな分報を運用する](https://ishkawa.org/1737032430)を読んで[QuickAdd](https://quickadd.obsidian.guide/)が良さそうだったので試してみたら、これが自分の用途ではぴったりだった。

まず、Obisidanを開いてからすぐに書き込めるようにホットキーを設定し、すぐにダイアログから書き込めるようにした。これだけでだいぶ楽になった。

![ObsidianのQuickAddでメモを入力するダイアログ](/assets/images/obsidian-quickadd.png)

リスト形式で追加されるようにして、最低限書いた時間は表示されるように設定した。
時間の表示はいらない気もしたが、振り返るときに何時に何を考えていたのかがわかるとありがたそうなので今のところ表示するようにしている。
ここらへんの表示形式は柔軟にカスタマイズできる。

![デイリーノートに時刻付きの箇条書きで追加されたJournalメモ](/assets/images/obsidian-journal.png)

これだけでも十分マシになったが、もっと気軽に書けるようにしたくてRaycastのプラグインを作り、Raycastでホットキーを設定していつでもすぐに書けるようにした。
プラグインのコードは以下の通り。

```tsx
// journal.tsx
import { execFile as execFileWithCallback } from "child_process";
import { promisify } from "util";
import { Action, ActionPanel, Form, closeMainWindow, showToast, Toast } from "@raycast/api";
import { useState } from "react";

const execFile = promisify(execFileWithCallback);

type Values = {
  text: string;
};

export default function Command() {
  const [text, setText] = useState("");

  async function handleSubmit(values: Values) {
    const submittedText = values.text?.trim();

    if (!submittedText) {
      await showToast({
        style: Toast.Style.Failure,
        title: "Text is empty",
      });
      return;
    }

    const encoded = encodeURIComponent(submittedText);
    const uri = `obsidian://quickadd?choice=Journal&value-input=${encoded}`;

    await execFile("open", ["-g", uri]);
    setText("");
    await closeMainWindow();
  }

  return (
    <Form
      actions={
        <ActionPanel>
          <Action.SubmitForm title="Add to Journal" onSubmit={handleSubmit} />
        </ActionPanel>
      }
    >
      <Form.TextArea id="text" title="Journal" value={text} onChange={setText} autoFocus />
    </Form>
  );
}
```

QuickAddはURIから起動できるので、その機能を用いて入力できるようにしている。
ただし、そのたびにObisidianに切り替わるのは避けたかったので `-g` （バックグラウンドで起動するオプション）を渡している。

ref: [Open QuickAdd from a URI | QuickAdd](https://quickadd.obsidian.guide/docs/Advanced/ObsidianUri/)

この設定でObsidianに切り替えなくてもいつでもどこでもホットキー（`command + ;`）を押すだけで気軽にメモを取ることが可能になり、めちゃくちゃ楽になった。
![RaycastからJournalメモを入力するフォーム](/assets/images/obsidian-raycast.png)

スマホでもQuickAddが使えるので、同じようにリスト形式かつ時間が入るように設定し、モバイルクイックアクション（画面をプルダウンして起動できるアクション）ですぐにメモに入力できるようにした。

![スマホ版ObsidianのモバイルクイックアクションでQuickAddを開く](/assets/images/obsidian-quickadd-sp.gif)

これでかなり気軽にメモが取れるようになった。
