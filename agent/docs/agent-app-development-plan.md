# 独立 Agent 应用开发计划

## 1. 项目目标

开发一个可在 macOS 和 Windows 上独立运行的 Agent 桌面应用。应用需要支持聊天对话、多轮记忆、自定义大模型接入、文件生成、Shell 调用、工具调用、Skill 扩展和 MCP 能力接入，并具备清晰的权限控制、可观测性和可扩展架构。

本阶段目标是完成开发设计和实施计划，作为后续产品原型、技术选型、模块开发和测试验收的基础文档。

## 2. 产品定位

该应用面向开发者、技术团队和需要本地自动化能力的高级用户，核心价值是让用户在本地桌面环境中运行一个可控、可扩展、可接入多模型的 Agent。

重点能力：

- 对接 OpenAI API、Azure OpenAI、本地模型、OpenAI-compatible API 和用户自定义模型服务。
- 通过自然语言完成文件生成、代码修改、Shell 命令执行、资料整理和多步骤任务。
- 支持多轮对话记忆、项目级上下文、长期记忆和可清理的会话历史。
- 支持工具调用、Skill 工作流和 MCP Server 集成。
- 支持跨平台桌面运行，优先覆盖 macOS 和 Windows。
- 支持权限确认、命令审计、运行日志和安全隔离。

## 3. 核心使用场景

### 3.1 聊天与任务执行

用户可以在桌面应用中与 Agent 对话，Agent 根据上下文理解任务，调用模型、工具、Shell、文件系统或 MCP 能力完成工作。

示例：

- “帮我在这个目录生成一个 React 项目。”
- “读取这些日志，找出错误原因。”
- “根据这份需求文档生成开发计划。”
- “调用本地 Shell 跑测试并修复失败。”

### 3.2 自定义模型接入

用户可以配置多个模型 Provider：

- OpenAI API
- Azure OpenAI
- Anthropic-compatible 或 OpenAI-compatible 服务
- Ollama、本地 vLLM、LM Studio 等本地模型服务
- 企业私有模型网关

每个 Provider 支持独立配置：

- Base URL
- API Key
- Model 名称
- 请求头
- 上下文长度
- 是否支持 tool calling
- 是否支持 streaming
- 是否支持 structured output

### 3.3 文件生成与项目操作

Agent 可以在用户授权的工作区内读取、创建、修改和删除文件。

基础能力：

- 创建文档、代码、配置文件、报告、计划书。
- 读取项目结构和文件内容。
- 按 diff 或 patch 修改文件。
- 生成任务摘要和变更说明。
- 保护用户未确认的改动，避免覆盖未知变更。

### 3.4 Shell 调用

Agent 可以调用系统 Shell 执行命令，但必须具备权限边界。

设计原则：

- 默认只允许在用户选择的 workspace 内执行。
- 高风险命令需要用户确认。
- 支持命令白名单、黑名单和审批策略。
- 命令输出进入上下文，但需要截断和摘要。
- 所有命令执行记录写入审计日志。

### 3.5 Tool、Skill 和 MCP 能力

Agent Runtime 需要支持三类扩展：

- Tool：应用内置或外部注册的函数调用能力。
- Skill：一组本地说明、脚本、模板和工作流，用于指导 Agent 完成特定任务。
- MCP：通过 Model Context Protocol 接入外部能力，例如浏览器、数据库、Figma、文件系统、GitHub、文档工具等。

扩展系统需要支持：

- 能力发现
- 权限声明
- 参数 schema
- 调用日志
- 错误恢复
- 禁用和启用
- 用户级配置

## 4. 非目标范围

第一阶段不建议同时实现以下能力：

- 完整多人协作工作台。
- 云端 Agent 托管平台。
- 企业级权限管理和 SSO。
- 大规模插件市场。
- 全自动无审批高权限系统控制。
- 移动端 App。

这些能力可以作为后续版本规划。

## 5. 推荐技术路线

### 5.1 桌面框架

推荐优先选择 Tauri 2：

- 跨 macOS 和 Windows。
- 资源占用低于 Electron。
- 前端可使用 React、Vue 或 Svelte。
- Rust 后端适合做本地权限、Shell、文件系统和进程管理。
- 支持插件体系和系统托盘、窗口管理等桌面能力。

备选方案：

- Electron：生态成熟，开发速度快，但包体和资源占用更高。
- Wails：Go 技术栈友好，适合已有 Go 团队。
- Flutter Desktop：UI 一致性强，但 Web/Node/MCP 生态接入成本更高。

建议：

- 前端：React + TypeScript + Vite。
- 桌面后端：Tauri 2 + Rust。
- Agent Runtime：TypeScript 优先，必要时拆出 Rust 执行层。
- 数据库：SQLite。
- 向量检索：本地 sqlite-vss、LanceDB 或 Qdrant local。

### 5.2 为什么 Agent Runtime 建议 TypeScript 优先

MCP、工具 schema、前端状态、OpenAI-compatible SDK 和插件生态在 TypeScript 中更容易快速组合。Rust 更适合承担安全边界和系统能力，例如 Shell 执行、文件系统访问、进程隔离和权限管控。

推荐分层：

- TypeScript：Agent loop、模型调用、工具编排、上下文管理。
- Rust：本地系统能力、权限校验、Shell runner、文件读写、审计日志。
- SQLite：会话、记忆、配置、审计、任务状态。

## 6. 总体架构

```text
┌──────────────────────────────────────────────┐
│ Desktop UI                                   │
│ React / TypeScript / Vite                    │
│ Chat, Settings, Workspace, Tools, Logs       │
└───────────────────────┬──────────────────────┘
                        │
┌───────────────────────▼──────────────────────┐
│ Agent Runtime                                │
│ Planner, Memory, Context, Tool Router        │
│ Model Adapter, Skill Loader, MCP Client      │
└───────────────────────┬──────────────────────┘
                        │
┌───────────────────────▼──────────────────────┐
│ Local Capability Layer                       │
│ File System, Shell, Git, Process, Sandbox    │
│ Permission Gate, Audit Log                   │
└───────────────────────┬──────────────────────┘
                        │
┌───────────────────────▼──────────────────────┐
│ Persistence                                  │
│ SQLite, Vector Store, Config, Session Store  │
└──────────────────────────────────────────────┘

External:
- Model Providers
- MCP Servers
- Local Tools
- Skills
```

## 7. 模块设计

### 7.1 Desktop UI

主要页面：

- Chat：对话、工具调用状态、流式输出、中断任务、重新生成。
- Workspace：当前工作目录、文件树、变更预览、生成文件列表。
- Models：模型 Provider 配置、连接测试、默认模型选择。
- Tools：内置工具、MCP Server、Skill 管理。
- Memory：会话记忆、项目记忆、长期记忆查看和清理。
- Logs：命令记录、工具调用、模型请求摘要、错误诊断。
- Settings：权限策略、Shell 策略、数据目录、代理、主题。

关键交互：

- 流式聊天输出。
- Tool call 展开和折叠。
- Shell 命令执行前确认。
- 文件变更 diff 预览。
- 支持停止当前 Agent 任务。
- 支持恢复最近任务。

### 7.2 Agent Runtime

核心职责：

- 维护 Agent loop。
- 组合系统提示词、用户输入、项目上下文、历史摘要和记忆。
- 判断是否需要调用 tool。
- 处理 tool calling 响应。
- 管理多轮任务状态。
- 控制最大 token 和上下文压缩。
- 将任务事件写入日志。

推荐核心对象：

- `AgentSession`
- `ConversationTurn`
- `ModelAdapter`
- `ToolRegistry`
- `ToolRouter`
- `MemoryManager`
- `ContextBuilder`
- `SkillLoader`
- `McpClientManager`
- `PermissionManager`

### 7.3 Model Adapter

抽象统一模型接口：

```ts
interface ModelAdapter {
  id: string;
  provider: string;
  capabilities: ModelCapabilities;
  chat(request: ChatRequest): AsyncIterable<ChatEvent>;
  validateConfig(config: ModelConfig): Promise<ValidationResult>;
}
```

能力声明：

- `streaming`
- `toolCalling`
- `jsonMode`
- `structuredOutput`
- `vision`
- `reasoning`
- `maxContextTokens`

首批支持：

- OpenAI-compatible Chat Completions
- OpenAI-compatible Responses API 风格适配
- Ollama
- Azure OpenAI

### 7.4 Memory Manager

记忆分为四层：

- 当前轮上下文：用户当前请求、工具结果、临时状态。
- 会话历史：当前 chat thread 的历史消息。
- 项目记忆：与 workspace 相关的摘要、偏好、技术栈、重要文件。
- 长期记忆：用户偏好、常用配置、跨项目复用信息。

实现策略：

- 原始消息进入 SQLite。
- 长对话定期生成摘要。
- 项目记忆以结构化 JSON 保存。
- 可选向量索引用于语义召回。
- 用户可以查看、编辑、删除长期记忆。

### 7.5 File System Tool

能力：

- 列目录
- 读取文件
- 写入文件
- 应用 patch
- 创建目录
- 删除文件，需强确认
- 搜索文件

安全策略：

- 默认限制在 workspace 内。
- 读取敏感路径需要确认。
- 写入前检查文件是否被外部修改。
- 大文件读取需要分块和摘要。
- 二进制文件默认不读入模型上下文。

### 7.6 Shell Tool

能力：

- 执行命令
- 流式返回 stdout 和 stderr
- 超时控制
- 终止进程
- 设置工作目录
- 环境变量注入

安全策略：

- 高风险命令需要确认。
- 支持 allowlist 和 denylist。
- 默认禁止静默删除、格式化磁盘、系统级权限提升等操作。
- 支持 per-workspace 权限策略。
- 所有执行记录写入审计表。

### 7.7 Tool Registry

Tool 统一声明：

```ts
interface ToolDefinition {
  name: string;
  description: string;
  inputSchema: JsonSchema;
  permission: ToolPermission;
  handler: ToolHandler;
}
```

内置工具：

- `filesystem.read`
- `filesystem.write`
- `filesystem.patch`
- `filesystem.search`
- `shell.exec`
- `git.status`
- `git.diff`
- `git.applyPatch`
- `memory.search`
- `memory.write`
- `mcp.call`
- `skill.run`

### 7.8 Skill 系统

Skill 是本地能力包，建议目录结构：

```text
skills/
  code-review/
    SKILL.md
    scripts/
    templates/
    assets/
  document-writer/
    SKILL.md
    templates/
```

`SKILL.md` 定义：

- 适用场景
- 操作流程
- 约束和安全要求
- 可用脚本
- 输入输出格式

Agent 使用 Skill 的方式：

1. 根据用户任务匹配 Skill。
2. 读取 `SKILL.md`。
3. 将关键说明注入上下文。
4. 必要时调用 Skill 脚本或模板。
5. 记录 Skill 调用结果。

### 7.9 MCP 集成

MCP Client Manager 负责：

- MCP Server 配置。
- Server 启动和停止。
- 工具发现。
- 工具 schema 映射。
- 调用转发。
- 权限提示。
- 错误和超时处理。

MCP 配置示例：

```json
{
  "servers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/workspace"]
    }
  }
}
```

首批支持：

- stdio MCP server
- 本地命令启动
- 工具列表刷新
- 单次 tool 调用
- 调用日志

后续支持：

- SSE / Streamable HTTP MCP
- OAuth
- MCP resource
- MCP prompt

## 8. 数据设计

建议使用 SQLite。

核心表：

- `model_providers`
- `model_configs`
- `workspaces`
- `sessions`
- `messages`
- `message_parts`
- `tool_calls`
- `shell_runs`
- `file_changes`
- `memories`
- `skills`
- `mcp_servers`
- `audit_logs`
- `settings`

关键数据原则：

- API Key 使用系统 Keychain / Windows Credential Manager 保存。
- SQLite 保存非敏感配置和运行数据。
- 模型请求原文可配置是否保存。
- 日志默认脱敏。
- 用户可以导出和清理本地数据。

## 9. 安全与权限设计

权限分级：

- Level 0：只读对话，不访问本地资源。
- Level 1：读取 workspace 文件。
- Level 2：写入 workspace 文件。
- Level 3：执行普通 Shell 命令。
- Level 4：执行高风险命令或访问 workspace 外路径。

审批策略：

- 首次使用工具需要确认。
- 高风险操作每次确认。
- 用户可设置 workspace 级信任。
- 所有审批结果进入审计日志。

高风险操作示例：

- 删除大量文件。
- 修改系统目录。
- 执行 `sudo`。
- 下载并执行远程脚本。
- 修改 shell profile。
- 修改 credential 或 keychain。
- 启动长期后台进程。

## 10. 跨平台设计要点

macOS：

- Keychain 保存密钥。
- zsh 作为默认 Shell。
- 需要处理 Gatekeeper、签名和 notarization。
- 文件权限和 App Sandbox 策略需要提前规划。

Windows：

- Credential Manager 保存密钥。
- PowerShell 作为默认 Shell。
- 路径分隔符和编码需要统一处理。
- 需要支持 Windows Terminal / PowerShell 输出编码。
- 打包签名和 SmartScreen 需要规划。

共同要求：

- 路径统一用内部抽象。
- Shell 命令不跨平台假设。
- UI 文案提示当前系统能力差异。
- 测试覆盖 macOS arm64、macOS x64、Windows x64。

## 11. 开发里程碑

### Phase 0：设计与技术验证

目标：

- 完成架构设计。
- 确认技术栈。
- 验证 Tauri + React + SQLite + Shell + OpenAI-compatible 模型调用。

交付：

- 本计划文档。
- 技术选型说明。
- 最小可运行 demo。

### Phase 1：MVP

目标：

- 完成基础桌面应用。
- 支持聊天、模型配置、流式输出。
- 支持 workspace 文件读取和生成。
- 支持 Shell 调用和用户确认。

交付：

- macOS 和 Windows 可运行包。
- 单 workspace 支持。
- 基础审计日志。
- 基础设置页。

### Phase 2：Agent 工具编排

目标：

- 完整 tool calling。
- 文件 diff 和 patch。
- 多轮任务状态。
- 错误恢复。
- 会话摘要。

交付：

- Tool Registry。
- Agent loop。
- 文件变更预览。
- 任务中断和恢复。

### Phase 3：Memory、Skill 和 MCP

目标：

- 项目记忆和长期记忆。
- Skill 目录加载。
- stdio MCP server 接入。
- 工具权限配置。

交付：

- Memory 管理页。
- Skill 管理页。
- MCP Server 配置页。
- MCP tool 调用日志。

### Phase 4：安全、测试和发布

目标：

- 完善权限系统。
- 完善跨平台测试。
- 完成签名、打包和更新机制。

交付：

- macOS signed app。
- Windows signed installer。
- 崩溃日志和错误诊断。
- 自动更新方案。

## 12. MVP 功能清单

必须实现：

- 桌面窗口和基础导航。
- 聊天页面。
- 模型 Provider 配置。
- OpenAI-compatible 模型调用。
- 流式输出。
- 工作区选择。
- 文件读取。
- 文件创建和修改。
- Shell 命令执行。
- Shell 执行前确认。
- 工具调用日志。
- 会话历史保存。
- 基础设置页。

暂缓实现：

- 插件市场。
- 多用户协作。
- 云端同步。
- 复杂 RAG。
- OAuth MCP。
- 企业 SSO。

## 13. 推荐目录结构

```text
agent-app/
  apps/
    desktop/
      src/
      src-tauri/
  packages/
    agent-runtime/
    model-adapters/
    tool-registry/
    memory/
    mcp-client/
    skills/
    shared/
  docs/
    architecture.md
    security.md
    mcp.md
    skills.md
  tests/
    e2e/
    fixtures/
```

## 14. 测试计划

单元测试：

- Model Adapter。
- Context Builder。
- Memory Manager。
- Tool Registry。
- 权限判断。

集成测试：

- 模型流式输出。
- Shell 调用。
- 文件 patch。
- MCP tool 调用。
- Skill 加载。

端到端测试：

- 创建 workspace。
- 配置模型。
- 完成一次多步骤文件生成任务。
- 执行 Shell 测试命令。
- 用户拒绝高风险命令。

跨平台测试：

- macOS arm64。
- macOS x64。
- Windows x64。
- 路径、编码、换行符和 shell 差异。

## 15. 主要风险与对策

### 15.1 模型接口差异

风险：不同模型 Provider 对 tool calling、streaming 和 JSON 输出支持不一致。

对策：通过 Model Adapter 抽象能力声明，运行时按能力降级。

### 15.2 Shell 安全风险

风险：Agent 可能执行破坏性命令。

对策：权限分级、用户审批、命令审计、denylist、workspace 沙箱。

### 15.3 上下文过长

风险：多轮对话和文件内容导致上下文超限。

对策：上下文构建器、摘要、文件分块、语义召回、tool result 截断。

### 15.4 MCP 稳定性

风险：外部 MCP Server 行为不稳定，参数 schema 不一致。

对策：超时控制、错误隔离、工具禁用、调用日志、schema 校验。

### 15.5 跨平台差异

风险：Shell、路径、权限、编码和打包差异造成体验不一致。

对策：系统能力抽象层、平台测试矩阵、平台差异提示。

## 16. 后续决策点

需要尽快确认：

- 桌面框架最终选择：Tauri、Electron、Wails 或 Flutter。
- Agent Runtime 使用 TypeScript 还是 Rust 主导。
- 是否需要首版支持本地模型，例如 Ollama。
- 是否需要内置向量数据库。
- 是否需要自动更新。
- 是否需要离线运行模式。
- Skill 是否采用本地目录包格式。
- MCP 首版只支持 stdio，还是同时支持 HTTP。

## 17. 建议下一步

1. 确认技术栈：建议 Tauri 2 + React + TypeScript + Rust + SQLite。
2. 创建项目骨架。
3. 实现模型配置和基础聊天。
4. 实现 workspace 文件读写。
5. 实现 Shell 调用和审批。
6. 接入 Tool Registry。
7. 再接入 Skill 和 MCP。

