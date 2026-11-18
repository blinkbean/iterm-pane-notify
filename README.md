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

## 换提醒色

脚本 `scripts/iterm-notify.sh` 顶部的 `CANDIDATES` 数组里列了 8 个候选（含各自的 0–65535 值）。想换色，把某个候选的值填进 `ATTENTION_BG` 那行即可。当前默认是**深青 `#00695C`**，文字固定纯白高对比。

想在自己 pane 里实测对比各候选：

```
./scripts/iterm-notify.sh preview
```

会在当前 pane 里把 8 个候选轮播一遍（每个停 2.2 秒并打出名字），看完自动还原。

> 提示：浏览器色卡和 iTerm2 实际渲染有色差，**以 iTerm2 里的观感为准**。多开分屏时若提醒色发灰，多半是 iTerm2 的 “Dim inactive split panes” 把非活动 pane 压暗了（Settings → Appearance → Dimming 可关）。

## 它改了什么 / 没改什么

- 只改触发那一刻的 pane 背景+前景色，还原时恢复成你**原来**的颜色（首次变色时存下）。
- 有一道防护：如果读到的背景已经是提醒色（上次没还原干净 / 崩溃），不会把提醒色误存成“原始色”。
- 不改任何 iTerm2 Profile、不写全局配置、不联网。
