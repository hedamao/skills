# Prompt Optimizer MCP Server

> 前后端开发提示词优化智能体 — MCP 封装版本  
> 将粗略的开发需求描述转化为高质量、可直接使用的 AI 编码提示词

## 工具列表

| 工具名 | 描述 |
|--------|------|
| `optimize_prompt` | 优化原始开发需求，输出结构化高质量提示词 |
| `get_template` | 获取特定场景的提示词填写模板 |
| `get_system_prompt` | 获取完整系统提示词（可配置到其他 AI 助手） |

### `optimize_prompt` 参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `raw_requirement` | string | ✅ | 原始开发需求描述 |
| `tech_stack` | string | ❌ | 指定技术栈，如 `React 18 + TypeScript` |
| `scene` | enum | ❌ | 场景：`frontend_component` / `backend_api` / `database_design` / `fullstack_feature` / `auto`（默认） |
| `output_language` | enum | ❌ | 输出语言：`zh`（默认）/ `en` |

### `get_template` 参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `scene` | enum | ✅ | `frontend_component` / `backend_api` / `database_design` / `fullstack_feature` |

## 安装与使用

### 1. 安装依赖

```bash
cd mcp/prompt-optimizer
npm install
```

### 2. 配置到 Claude Desktop

编辑 `~/Library/Application Support/Claude/claude_desktop_config.json`：

```json
{
  "mcpServers": {
    "prompt-optimizer": {
      "command": "node",
      "args": ["/Users/hedamao/Desktop/skills/mcp/prompt-optimizer/index.js"]
    }
  }
}
```

### 3. 配置到 Cursor

编辑 `~/.cursor/mcp.json`（或项目根目录下 `.cursor/mcp.json`）：

```json
{
  "mcpServers": {
    "prompt-optimizer": {
      "command": "node",
      "args": ["/Users/hedamao/Desktop/skills/mcp/prompt-optimizer/index.js"]
    }
  }
}
```

## 使用示例

**优化一个简单需求：**
```
工具：optimize_prompt
参数：{ "raw_requirement": "帮我做一个登录页面" }
```

**指定技术栈优化：**
```
工具：optimize_prompt
参数：{
  "raw_requirement": "做一个用户列表页，支持分页和搜索",
  "tech_stack": "Vue 3 + TypeScript + Element Plus",
  "scene": "frontend_component"
}
```

**获取后端 API 模板：**
```
工具：get_template
参数：{ "scene": "backend_api" }
```

## 原始来源

基于 `prompt-optimizer-agent.md` 系统提示词封装，版本 v1.0。
