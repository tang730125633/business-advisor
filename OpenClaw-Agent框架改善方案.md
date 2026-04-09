# OpenClaw Agent 框架改善方案

> 基于 claw-code (Rust 重写版 Claude Code) 源码分析
> 分析日期：2026-04-09
> 来源仓库：https://github.com/ultraworkers/claw-code

---

## 一、权限系统改善（最紧急）

### 现状问题
升级到 2026.4.9 后 `exec-approvals.json` 丢失，工具调用在 cron 后台执行时无人确认会超时。

### Claw Code 的权限模型（5层）

```
ReadOnly        ← 只读操作（cat/grep/git status）
WorkspaceWrite  ← 工作区内写入（edit/write 限定在项目目录）
DangerFullAccess ← 完全放行（bash/curl/WebFetch）
Prompt          ← 弹窗确认（默认模式）
Allow           ← 全部放行（遗留模式）
```

### 建议配置

在 `.openclaw/settings.json` 中添加：

```json
{
  "permissions": {
    "mode": "workspace-write",
    "rules": {
      "allow": [
        "bash(lark-cli:*)",
        "bash(curl:*)",
        "bash(git:*)",
        "bash(node:*)",
        "bash(python3:*)",
        "bash(echo:*)",
        "bash(cat:*)",
        "bash(ls:*)",
        "bash(wc:*)",
        "bash(date:*)",
        "bash(test:*)",
        "bash(mkdir:*)",
        "bash(cp:*)",
        "read_file(*)",
        "write_file(*)",
        "edit_file(*)",
        "glob_search(*)",
        "grep_search(*)",
        "WebFetch(*)"
      ],
      "deny": [
        "bash(rm -rf:*)",
        "bash(dd:*)",
        "bash(mkfs:*)",
        "bash(shutdown:*)",
        "bash(reboot:*)"
      ],
      "ask": [
        "bash(git push --force:*)",
        "bash(git reset --hard:*)"
      ]
    }
  }
}
```

---

## 二、Bash 安全检查（参考 Claw Code 的 18 个子模块）

### Claw Code 的 Bash 安全机制

1. **只读命令白名单**：cat, grep, git, jq, ls, wc, head, tail, find, which, env, echo, date, test
2. **重定向拦截**：阻止 `>`, `>>`, 管道写入
3. **就地编辑拦截**：阻止 `-i`, `--in-place` 参数
4. **路径边界校验**：防止 `../` 越狱
5. **输出截断**：最大 16KB，防止内存溢出
6. **超时保护**：默认 120 秒，可配置

### 建议：在 watchdog cron 中加入超时保护

```
每个工具调用最大执行时间：120秒
超时后自动标记任务为"失败"并写回表格
```

---

## 三、MCP 插件稳定性（飞书 CLI 超时问题）

### Claw Code 的 MCP 架构

```
每次 MCP 工具调用 → 独立线程 → 独立 Tokio runtime → 超时保护
连接状态：Disconnected → Connecting → Connected → AuthRequired → Error
```

### 建议
- 飞书 CLI 调用加 30 秒超时
- 连续 3 次 MCP 失败后自动跳过该工具
- 在轮询日志中记录 MCP 调用耗时

---

## 四、多 Agent 协作改善（小婷+小琳）

### Claw Code 的多 Agent 系统

```
TaskRegistry:
  - task_id 格式: task_{timestamp}_{counter}
  - 状态机: Created → Running → Completed/Failed/Stopped
  - 终态不可逆（Completed/Failed/Stopped 后不可再变）

TeamRegistry:
  - 多个 Task 组成 Team
  - 软删除（标记 Deleted 但保留查询）
  - 支持跨 Task 依赖追踪

WorkerRegistry:
  - 信任门控（Trust Gate）：新环境自动检测并等待确认
  - 指令投递追踪：检测误投递并自动重试
  - 失败恢复：stash prompt → replay
```

### 对我们飞书 Base 任务队列的改善建议

| 现有 | 改善 |
|------|------|
| 状态只有4种 | 加入"已超时"状态，超时自动标记 |
| 无依赖追踪 | 加"依赖任务ID"字段，A完成后才触发B |
| 无重试机制 | 失败任务自动重试1次 |
| 无执行耗时 | 记录认领→完成的耗时 |

---

## 五、Hook 系统（前/后置钩子）

### Claw Code 的 Hook 机制

```
pre_tool_use  → 工具执行前运行（可拦截/修改输入）
post_tool_use → 工具执行后运行（通知/日志）
post_tool_use_failure → 失败后运行（告警/重试）
```

Hook 可以返回：
- `permission_override`: 覆盖权限决策
- `updated_input`: 修改工具输入
- `denied/cancelled`: 阻止执行

### 建议：给 OpenClaw 加前置检查

在 config.json 中添加：
```json
{
  "hooks": {
    "pre_tool_use": ["~/.openclaw/scripts/pre_check.sh"],
    "post_tool_use_failure": ["~/.openclaw/scripts/failure_alert.sh"]
  }
}
```

---

## 六、会话压缩（Session Compaction）

### Claw Code 的压缩策略

```
触发条件：input tokens 超过阈值
保留：system prompt + 最近 N 轮对话
压缩：旧对话 → 摘要
效果：长对话不丢失上下文
```

### OpenClaw 4.9 已支持
确保 config.json 中启用：
```json
{
  "agents": {
    "defaults": {
      "autoCompactionInputTokensThreshold": 100000
    }
  }
}
```

---

## 七、配置文件优先级（三层覆盖）

### Claw Code 的配置发现顺序

```
User (最低)   → ~/.claw/settings.json
Project (中)  → ./.claw/settings.json  
Local (最高)  → ./.claw/settings.local.json
```

### OpenClaw 对应

```
全局  → ~/.openclaw/config.json
项目  → ~/.openclaw/.openclaw/openclaw.json
Agent → ~/.openclaw/.openclaw/agents/main/agent/models.json
```

---

## 八、落地优先级

| P0（本周） | P1（下周） | P2（后续） |
|-----------|-----------|-----------|
| 重建权限白名单 | Bash 安全检查 | Hook 系统 |
| MCP 超时保护 | 任务依赖追踪 | 会话压缩调优 |
| 轮询日志加耗时 | 失败自动重试 | 多 Agent 信任门控 |
