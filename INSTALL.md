# business-advisor 部署包 · 安装指南

**版本**：v1.0 · 2026-04-05
**适用**：OpenClaw 2026.3.x+ 实例
**交付物**：business-advisor skill + 经营管理知识库（24 本书蒸馏卡）+ 配置模板

---

## 📦 部署包包含的内容

```
business-advisor-v1.0/
├── skills/
│   └── business-advisor/             # skill 本体
│       ├── SKILL.md                  # 主文件
│       ├── books-index.md            # 24 本书映射表
│       └── golden-examples/          # 4 个 few-shot 示范
│           ├── 01-战略-新能源转型.md
│           ├── 02-团队-代际冲突.md
│           ├── 03-投资-大项目风险.md
│           └── 04-情绪-被客户骂.md
│
├── workspace/
│   └── 经营管理知识库/                # qmd 挂载内容
│       ├── _index.md                  # 总索引
│       ├── 01-现代企业管理/（5本）
│       ├── 02-经营战略/（7本）
│       ├── 03-营销/（4本）
│       ├── 04-领导力/（5本）
│       └── 05-商业思维/（3本）
│
├── config-patches/                    # 需要合并到 openclaw.json 的配置片段
│   ├── memory-qmd-paths.json          # qmd 挂载新路径
│   ├── messages-mentionpatterns.json  # 群消息智能过滤关键字
│   └── feishu-requireMention.txt      # 要改的 feishu 字段
│
├── install.sh                         # 自动安装脚本（推荐）
├── INSTALL.md                         # 本文件
└── CHANGELOG.md                       # 版本历史
```

---

## 🚀 方式一：自动安装（推荐）

### 前置要求

1. 目标机器已安装 OpenClaw 2026.3.x+（`openclaw --version` 应能返回版本号）
2. OpenClaw gateway 正在运行（`openclaw health` 返回 `{"ok":true}`）
3. 有权限修改 `~/.openclaw/` 目录

### 一条命令安装

```bash
# 解压部署包
tar -xzf business-advisor-v1.0.tar.gz
cd business-advisor-v1.0

# 运行安装脚本
./install.sh
```

脚本会自动：
1. ✅ 备份现有 `openclaw.json` 为 `openclaw.json.bak.business-advisor.<timestamp>`
2. ✅ 复制 skill 到 `~/.openclaw/skills/business-advisor/`
3. ✅ 复制知识库到 `~/.openclaw/workspace/经营管理知识库/`
4. ✅ 合并配置到 `openclaw.json`：
   - 新增 qmd 挂载点 `business-wisdom-kb`
   - 设 `memory.qmd.searchMode` 为 `query`（混合 FTS+向量检索）
   - 新增 `messages.groupChat.mentionPatterns`（22 个智能过滤关键字）
   - 设 `channels.feishu.requireMention` 为 `true`
5. ✅ 触发 config 热重载（**无需重启 gateway**）
6. ✅ 验证安装成功

### 安装后验证

```bash
# 检查 skill 已注册
openclaw skills info business-advisor
# 预期输出："📦 business-advisor ✓ Ready"

# 检查 qmd 已索引（数字会在 3-8 分钟内上涨到 ~700）
openclaw memory status

# 检查配置
openclaw config get memory.qmd.paths
openclaw config get messages.groupChat.mentionPatterns
openclaw config get channels.feishu.requireMention
```

首次安装后，qmd 会在 **3-8 分钟内完成向量索引**（取决于机器性能和 embedding 模型是否已下载）。完成前检索还没开启向量通道，只有 FTS；完成后自动切换到混合检索。

---

## 🛠️ 方式二：手动安装（适合想理解每一步的运维）

### 步骤 1：备份现有配置

```bash
TS=$(date +%Y%m%d_%H%M%S)
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak.business-advisor.$TS
```

### 步骤 2：复制 skill

```bash
cp -r skills/business-advisor ~/.openclaw/skills/
```

### 步骤 3：复制知识库

```bash
cp -r workspace/经营管理知识库 ~/.openclaw/workspace/
```

### 步骤 4：修改 `openclaw.json`

用你喜欢的编辑器打开 `~/.openclaw/openclaw.json`，加以下 4 处修改：

#### 修改 1：`memory.qmd.searchMode`

找到 `memory.qmd` 段，确认或添加：

```json
"memory": {
  "qmd": {
    "searchMode": "query",    ← 改成或新增这行
    ...
  }
}
```

#### 修改 2：`memory.qmd.paths` 新增挂载点

```json
"memory": {
  "qmd": {
    "paths": [
      ...（原有挂载点）,
      {
        "path": "~/.openclaw/workspace/经营管理知识库",
        "name": "business-wisdom-kb",
        "pattern": "**/*.md"
      }
    ]
  }
}
```

#### 修改 3：`messages.groupChat.mentionPatterns` 新增智能关键字

```json
"messages": {
  "groupChat": {
    "historyLimit": 15,
    "mentionPatterns": [
      "小婷", "婷婷", "小婷婷", "@小婷",
      "帮我", "帮忙", "给我分析", "给我参谋", "给点建议",
      "你觉得", "你说", "你看", "你分析",
      "怎么办", "怎么看", "怎么搞", "咋整", "如何", "什么意思",
      "咱们", "我问你", "有没有建议"
    ]
  }
}
```

#### 修改 4：`channels.feishu.requireMention`

```json
"channels": {
  "feishu": {
    "requireMention": true    ← 改成 true
  }
}
```

### 步骤 5：保存文件，config 自动热重载

OpenClaw 的 config monitor 会在 2 秒内检测到变化并热重载。日志里应该看到：

```
[reload] config change detected; evaluating reload (memory.qmd.paths)
[reload] config hot reload applied (memory.qmd.paths)
[reload] config change detected; evaluating reload (messages.groupChat.mentionPatterns)
[reload] config hot reload applied
[reload] config change detected; evaluating reload (channels.feishu.requireMention)
[reload] config hot reload applied
```

### 步骤 6：等 qmd 索引完成（3-8 分钟）

```bash
# 观察 content_vectors 数量上涨
watch -n 10 'openclaw memory status'
```

当 `Vectors: ready` 且数量稳定（大约 700+）时完成。

---

## ✅ 测试是否生效

### 方式 1：在飞书群发测试消息

直接发这 4 条到群里看小婷反应：

```
1. 小婷，你觉得现在新能源风口要不要追？
   ← 预期：调用《创新者的窘境》，300 字内回答，带反问

2. 我今天被客户骂了半小时，特别气
   ← 预期：先共情，不念书，反问让你选择发泄还是找办法

3. 老师傅倔，年轻人留不住，怎么办
   ← 预期：调用《首先打破一切常规》，"因才适用" 概念

4. 方哥最近那个检修项目有进展吗
   ← 预期：沉默（这是对方哥说的，不是问小婷的）
```

### 方式 2：用 CLI 直接测试

```bash
openclaw agent \
  --session-id <你的 feishu session id> \
  --message "龙哥，你觉得现在新能源风口要不要追？" \
  --thinking low \
  --timeout 180
```

预期回答特征：
- ✓ 长度 300-400 字
- ✓ 出现《创新者的窘境》或相关概念（破坏性创新、从边缘切入）
- ✓ 用 "反过来想" 或 "能力圈" 等思维习惯
- ✓ 落地到电力行业场景
- ✓ 反问结尾让客户做选择
- ✗ 不编造具体地名、员工数、客户名

---

## 🔙 回退

如果发现问题需要回退：

```bash
# 回退 config
cp ~/.openclaw/openclaw.json.bak.business-advisor.<timestamp> ~/.openclaw/openclaw.json

# 删除 skill
rm -rf ~/.openclaw/skills/business-advisor

# 删除知识库（可选，文件本身不会影响 OpenClaw 运行）
rm -rf ~/.openclaw/workspace/经营管理知识库

# config 自动热重载，回退完成
```

---

## 📚 Skill 调优后续

### 迭代 skill 的方式

SKILL.md 和 golden-examples 都是纯文本，可以直接编辑。**修改后立即生效**，不需要重启 gateway。

### 建议的迭代节奏

1. **首周**：每天在群里真实使用，记录 3-5 个不满意的回答
2. **周末**：对照 SKILL.md 和 golden-examples，找出是"哪条规则没执行"还是"哪个示例缺失"
3. **修改**：要么加新规则，要么加新 golden example
4. **测试**：用 eval harness（如果有）跑回归

### 目前已知的可继续优化点

- 长度规则可以更严格（从 300 字改到 240 字）
- 可以为不同行业（电力/金融/制造）分别创建子 skill
- 可以加入更多"边界情形"的 golden example

---

## 📞 技术支持

- Skill 源码仓库：（待定）
- 问题反馈：联系 Tang
- 版本更新：见 CHANGELOG.md

---

_business-advisor v1.0 · Built with Opus + Tang · for OpenClaw_
