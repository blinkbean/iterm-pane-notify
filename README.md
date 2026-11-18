# iterm-pane-notify

多开 Claude Code 分屏时，容易忘记哪个 pane 已经跑完、在等你给下一条指令。这个插件在 Claude **任务结束**（`Stop`）或**等待授权/输入**（`Notification`）时，把**当前这个 iTerm2 pane** 的背景和文字染成醒目的提醒色；你一提交下一条指令（`UserPromptSubmit`）就自动还原。

靠 `$ITERM_SESSION_ID` 精确锁定本 pane，所以多开分屏时每个 Claude 只改自己那一格，互不干扰。非 iTerm2 环境（或拿不到 session id）自动跳过，不报错。

## 环境要求

- macOS + iTerm2
- iTerm2 开启 `Python API` / AppleScript 控制（默认即可）

## 安装

在任意 Claude Code 会话的提示符下输入：

```
/plugin install iterm-pane-notify --marketplace blinkbean/iterm-pane-notify
```

按提示 `y` 添加 marketplace，再选安装范围即可。多设备同步：每台机器装一次，配色跟着仓库走。

## 在自己 pane 里实测对比各候选

`/plugin install` 装好后，脚本在插件缓存目录里（路径带版本号）。用下面这条命令定位并直接跑 `preview`，不用关心具体路径：

```
"$(find ~/.claude/plugins/cache -path '*iterm-pane-notify*/scripts/iterm-notify.sh' | head -1)" preview
```

会在当前 pane 里把 8 个候选轮播一遍（每个停 2.2 秒并打出名字），看完自动还原。请在你**自己的 iTerm2 pane** 里跑（轮播约 18 秒，要亲眼看）。

## 换提醒色

颜色写在 `scripts/iterm-notify.sh` 顶部：`CANDIDATES` 数组列了 8 个候选（含各自 0–65535 值），`ATTENTION_BG` 那行是当前启用的。默认**深青 `#00695C`**，文字固定纯白高对比。

> ⚠️ 不要改缓存目录（`~/.claude/plugins/cache/...`）里的脚本——`claude plugin update` 一更新就会覆盖。要持久改色，改**你自己的源码仓库**再重装：

```
git clone https://github.com/blinkbean/iterm-pane-notify.git
# 编辑 iterm-pane-notify/scripts/iterm-notify.sh 里的 ATTENTION_BG=
claude plugin marketplace add ./iterm-pane-notify      # 把本地文件夹当 marketplace
claude plugin install iterm-pane-notify --marketplace iterm-pane-notify
```

本地文件夹源的插件直接从该文件夹读取，之后改脚本 + `/reload-plugins` 即生效，无需重装。

> 提示：浏览器色卡和 iTerm2 实际渲染有色差，**以 iTerm2 里的观感为准**。多开分屏时若提醒色发灰，多半是 iTerm2 的 “Dim inactive split panes” 把非活动 pane 压暗了（Settings → Appearance → Dimming 可关）。

## 它改了什么 / 没改什么

- 只改触发那一刻的 pane 背景+前景色，还原时恢复成你**原来**的颜色（首次变色时存下）。
- 有一道防护：如果读到的背景已经是提醒色（上次没还原干净 / 崩溃），不会把提醒色误存成“原始色”。
- 不改任何 iTerm2 Profile、不写全局配置、不联网。
