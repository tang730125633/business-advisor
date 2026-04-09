# Claw Code 架构分析 — OpenClaw 优化参考

> 来源：https://github.com/ultraworkers/claw-code
> 分析日期：2026-04-09

## 一、项目定位

Claw Code 是 Claude Code 的 **Rust 开源重写版**，179k stars。它把原版的 Agent 循环、工具权限、记忆系统等核心机制都复现了，代码结构比原版清晰。

**核心哲学**（PHILOSOPHY.md）：
> "Humans set direction; claws perform the labor."
> 人类定方向，AI 执行劳动。

## 二、架构（9大模块）

| Crate | 职责 | 对应 OpenClaw 的什么 |
|-------|------|---------------------|
| `api` | Anthropic API 通信 | 网关 → AI Provider |
| `commands` | CLI 命令解析 | TUI 命令入口 |
| `runtime` | Agent 运行时（核心） | 网关 Agent 执行引擎 |
| `tools` | 工具注册+执行 | 工具系统（Bash/Read/Write等） |
| `plugins` | MCP 插件桥接 | extensions/ 飞书插件等 |
| `telemetry` | 遥测日志 | logs/ |
| `rusty-claude-cli` | CLI 二进制 | openclaw CLI |
| `mock-anthropic-service` | 测试用 mock | — |
| `compat-harness` | 兼容性测试 | — |

## 三、权限系统（重点参考）

Claw Code 的权限分三层：

```
PermissionMode:
├── Allow    — 全部放行（类似 OpenClaw 的全权限模式）
├── Prompt   — 弹窗确认（默认模式）
└── Deny     — 全部拒绝
```

**PermissionEnforcer** 在每次工具调用前检查：
- 工具名 + 输入参数 → 匹配权限策略 → Allow / Deny / Prompt
- Bash 命令有额外验证：只读检查、破坏性命令警告、sed 验证、路径校验

**对 OpenClaw 的启发**：
→ 你的 `exec-approvals.json` 升级后丢失了，这正是权限白名单文件
→ 建议重建，参考 Claw Code 的分层模式

## 四、工具系统

Claw Code 复现了完整的工具列表：
- **Bash** — 命令执行（18个子模块验证）
- **Read/Write/Edit** — 文件操作
- **Glob/Grep** — 文件搜索
- **Agent** — 子Agent派发
- **AskUserQuestion** — 用户交互
- **RemoteTrigger** — 远程触发
- **TodoWrite** — 任务管理
- **MCP Bridge** — 外部工具桥接（飞书CLI、Chrome等）

**对 OpenClaw 的启发**：
→ 工具调用失败通常发生在 MCP Bridge 层（插件通信超时）
→ 或 PermissionEnforcer 拒绝了未授权的操作

## 五、三层协作系统

```
OmX (oh-my-codex)     — 工作流层：把一句话指令变成结构化执行
clawhip                — 事件路由：git/tmux/GitHub/agent 事件监听+通知
OmO (oh-my-openagent)  — 多Agent协调：规划/交接/分歧解决/验证循环
```

**对 OpenClaw 的启发**：
→ 你的"小婷+小琳飞书Base任务队列"就是简化版的 OmX + clawhip
→ 可以参考 OmO 的分歧解决机制，让两个 AI 在意见不同时有处理流程

## 六、工具调用失败的常见原因

根据 Claw Code 的实现和 PARITY.md，工具调用失败通常是：

1. **权限不足** — PermissionEnforcer 拒绝（OpenClaw 对应 exec-approvals）
2. **MCP 插件超时** — 外部工具（飞书CLI等）响应太慢
3. **Bash 安全检查** — 破坏性命令被拦截（rm -rf、git push --force 等）
4. **文件边界保护** — 读写超出工作区范围
5. **二进制文件检测** — 尝试读取非文本文件被拒
6. **沙箱限制** — 容器/沙箱环境下 unshare 能力不足

## 七、给 OpenClaw 的优化建议

1. **重建 exec-approvals.json** — 升级后丢失了，需要重新配置工具授权白名单
2. **参考 Bash 验证模块** — 加入破坏性命令警告（OpenClaw 目前没有）
3. **MCP 超时处理** — 飞书 CLI 调用加超时保护，避免 cron 任务卡死
4. **权限分级** — 参考 Allow/Prompt/Deny 三层，给不同的 cron job 设不同权限
5. **工具调用日志** — 记录每次工具调用的成功/失败/耗时，便于排查问题
