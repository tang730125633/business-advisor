#!/usr/bin/env bash
# business-advisor 一键安装脚本
# v1.0 · 2026-04-05

set -euo pipefail

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║  business-advisor v1.0 · Installer            ║"
echo "║  OpenClaw Skill + 经营管理知识库               ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""

# ---- 前置检查 ----
echo -e "${YELLOW}[1/7]${NC} 前置检查..."

OPENCLAW_HOME="${HOME}/.openclaw"
if [ ! -d "$OPENCLAW_HOME" ]; then
  echo -e "${RED}✗ 没找到 $OPENCLAW_HOME。请确认 OpenClaw 已安装。${NC}"
  exit 1
fi

OPENCLAW_JSON="$OPENCLAW_HOME/openclaw.json"
if [ ! -f "$OPENCLAW_JSON" ]; then
  echo -e "${RED}✗ 没找到 $OPENCLAW_JSON。${NC}"
  exit 1
fi

# 检查 python3 用于 JSON 合并
if ! command -v python3 &>/dev/null; then
  echo -e "${RED}✗ 需要 python3 来合并 JSON 配置。${NC}"
  exit 1
fi

echo -e "${GREEN}  ✓${NC} OpenClaw 已安装"
echo -e "${GREEN}  ✓${NC} python3 可用"

# ---- 备份 ----
echo ""
echo -e "${YELLOW}[2/7]${NC} 备份 openclaw.json..."

TS=$(date +%Y%m%d_%H%M%S)
BACKUP="$OPENCLAW_HOME/openclaw.json.bak.business-advisor.$TS"
cp "$OPENCLAW_JSON" "$BACKUP"
echo -e "${GREEN}  ✓${NC} 备份到: $BACKUP"

# ---- 安装 skill ----
echo ""
echo -e "${YELLOW}[3/7]${NC} 复制 skill 到 $OPENCLAW_HOME/skills/..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="$SCRIPT_DIR/../skills/business-advisor"

if [ ! -d "$SKILL_SRC" ]; then
  # 如果脚本和 skill 在同一层（部署包解压后的标准布局）
  SKILL_SRC="$SCRIPT_DIR/skills/business-advisor"
fi

if [ ! -d "$SKILL_SRC" ]; then
  echo -e "${RED}✗ 没找到 skill 源：$SKILL_SRC${NC}"
  exit 1
fi

mkdir -p "$OPENCLAW_HOME/skills"
cp -r "$SKILL_SRC" "$OPENCLAW_HOME/skills/"
echo -e "${GREEN}  ✓${NC} Skill 已复制"

# ---- 安装知识库 ----
echo ""
echo -e "${YELLOW}[4/7]${NC} 复制经营管理知识库到 workspace..."

KB_SRC="$SCRIPT_DIR/../workspace/经营管理知识库"
if [ ! -d "$KB_SRC" ]; then
  KB_SRC="$SCRIPT_DIR/workspace/经营管理知识库"
fi

if [ ! -d "$KB_SRC" ]; then
  echo -e "${RED}✗ 没找到知识库源：$KB_SRC${NC}"
  exit 1
fi

mkdir -p "$OPENCLAW_HOME/workspace"
cp -r "$KB_SRC" "$OPENCLAW_HOME/workspace/"
KB_FILE_COUNT=$(find "$OPENCLAW_HOME/workspace/经营管理知识库" -name "*.md" | wc -l | tr -d ' ')
echo -e "${GREEN}  ✓${NC} 知识库已复制（$KB_FILE_COUNT 个 .md 文件）"

# ---- 合并 config ----
echo ""
echo -e "${YELLOW}[5/7]${NC} 合并 openclaw.json 配置..."

python3 << PYEOF
import json
import os

cfg_path = "$OPENCLAW_JSON"
home = os.path.expanduser("~")

with open(cfg_path) as f:
    cfg = json.load(f)

# 1. memory.qmd.searchMode
cfg.setdefault("memory", {}).setdefault("qmd", {})["searchMode"] = "query"

# 2. memory.qmd.paths 新增挂载点
paths = cfg["memory"]["qmd"].setdefault("paths", [])
new_mount = {
    "path": "~/.openclaw/workspace/经营管理知识库",
    "name": "business-wisdom-kb",
    "pattern": "**/*.md"
}
# 去重
if not any(p.get("name") == "business-wisdom-kb" for p in paths):
    paths.append(new_mount)
    print("  ✓ 新增 qmd 挂载点: business-wisdom-kb")
else:
    print("  ○ qmd 挂载点已存在，跳过")

# 3. messages.groupChat.mentionPatterns
msgs = cfg.setdefault("messages", {}).setdefault("groupChat", {})
patterns = msgs.get("mentionPatterns", [])
new_patterns = [
    "小婷", "婷婷", "小婷婷", "@小婷",
    "帮我", "帮忙", "给我分析", "给我参谋", "给点建议",
    "你觉得", "你说", "你看", "你分析",
    "怎么办", "怎么看", "怎么搞", "咋整", "如何", "什么意思",
    "咱们", "我问你", "有没有建议"
]
# 合并，去重
merged = list(dict.fromkeys(patterns + new_patterns))
msgs["mentionPatterns"] = merged
print(f"  ✓ mentionPatterns 合计 {len(merged)} 个关键字")

# 4. channels.feishu.requireMention
feishu = cfg.setdefault("channels", {}).setdefault("feishu", {})
feishu["requireMention"] = True
print("  ✓ feishu.requireMention = true")

# 保存
with open(cfg_path, 'w') as f:
    json.dump(cfg, f, ensure_ascii=False, indent=2)

print("  ✓ openclaw.json 已更新")
PYEOF

# ---- 等待 config 热重载 ----
echo ""
echo -e "${YELLOW}[6/7]${NC} 等待 config 热重载（3 秒）..."
sleep 3

# ---- 验证 ----
echo ""
echo -e "${YELLOW}[7/7]${NC} 验证安装..."

# 找 openclaw CLI
OPENCLAW_BIN=""
for path in "$HOME/.nvm/versions/node/v24.11.1/bin/openclaw" "$(which openclaw 2>/dev/null)" "/usr/local/bin/openclaw"; do
  if [ -x "$path" ]; then
    OPENCLAW_BIN="$path"
    break
  fi
done

if [ -z "$OPENCLAW_BIN" ]; then
  echo -e "${YELLOW}  ⚠${NC} 找不到 openclaw CLI，跳过自动验证"
  echo -e "${YELLOW}  ⚠${NC} 请手动运行: openclaw skills info business-advisor"
else
  # 检查 skill 是否识别
  if "$OPENCLAW_BIN" skills info business-advisor 2>&1 | grep -q "Ready"; then
    echo -e "${GREEN}  ✓${NC} business-advisor skill 已识别为 Ready"
  else
    echo -e "${YELLOW}  ⚠${NC} skill 未识别为 Ready，请手动检查: openclaw skills info business-advisor"
  fi
fi

# ---- 完成 ----
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ✓ 安装完成                          ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo "下一步："
echo "  1. 等 3-8 分钟让 qmd 完成向量索引（首次）"
echo "     observe: openclaw memory status"
echo ""
echo "  2. 在飞书群测试，发以下任一消息验证："
echo "     • \"小婷，你觉得现在新能源风口要不要追？\"（应调用《创新者的窘境》）"
echo "     • \"我今天被客户骂了半小时，特别气\"（应先共情）"
echo ""
echo "  3. 回退命令（如需）："
echo "     cp $BACKUP $OPENCLAW_JSON"
echo "     rm -rf $OPENCLAW_HOME/skills/business-advisor"
echo ""
echo "备份: $BACKUP"
echo "文档: $(dirname "$0")/INSTALL.md"
echo ""
