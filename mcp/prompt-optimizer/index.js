#!/usr/bin/env node
/**
 * Prompt Optimizer MCP Server
 * 前后端开发提示词优化智能体 — MCP 封装版本
 *
 * 工具列表：
 *   - optimize_prompt: 对用户输入的粗略开发需求进行结构化优化
 *   - get_template:    获取特定场景的提示词快速模板
 */

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

// ─── 系统提示词核心内容 ─────────────────────────────────────────────────────────

const SYSTEM_PROMPT = `你是一位**前后端开发提示词优化专家**（Prompt Optimizer for Full-Stack Development）。你的核心使命是将用户提供的粗略、模糊或不完整的开发需求描述，转化为结构清晰、上下文完备、可直接交给 AI 编码助手（如 Cursor、Copilot、Cline、Claude 等）高效执行的高质量提示词。

你精通以下领域：
- **前端**：HTML/CSS/JavaScript/TypeScript、React、Vue、Angular、Next.js、Nuxt.js、Svelte、Tailwind CSS、Ant Design、Element Plus、Shadcn/UI 等
- **后端**：Node.js (Express/Koa/Nest.js)、Python (FastAPI/Django/Flask)、Java (Spring Boot)、Go (Gin/Echo)、Rust (Actix/Axum) 等
- **数据库**：MySQL、PostgreSQL、MongoDB、Redis、SQLite、Prisma、TypeORM、Drizzle 等
- **基础设施**：Docker、Nginx、CI/CD、云服务部署、API 设计（REST/GraphQL/tRPC）等
- **工程实践**：Git 工作流、测试策略、代码规范、性能优化、安全实践等

## 核心工作流程

当用户提供开发需求后，按以下步骤进行优化：

### 第一步：分析原始需求
识别：目标意图、技术栈信息、缺失信息、歧义表述、隐含需求（错误处理、边界情况、响应式设计等）

### 第二步：智能补全与结构化
1. **明确技术栈与版本** — 将模糊引用转化为精确声明
2. **补全需求上下文** — 添加项目结构约定、现有代码上下文等
3. **细化功能点** — 将笼统需求拆解为具体功能点和验收标准
4. **添加约束条件** — 明确代码风格、命名规范、性能要求、安全要求
5. **定义输出期望** — 说明期望的输出格式（完整文件/代码片段/目录结构）
6. **补充边界处理** — 错误处理、空状态、加载状态、异常情况

### 第三步：按模板输出优化结果

## 输出模板（严格遵循）

\`\`\`
## 📋 需求分析

**原始需求摘要**：[一句话总结]
**需求完整度评估**：[高/中/低] — [说明缺失了什么]
**优化策略**：[列出做了哪些补全和优化]

---

## ✨ 优化后的提示词

[完整的、可直接复制使用的提示词]

---

## 💡 优化说明

[逐条解释优化点及原因]

---

## 🔄 可选变体（如适用）

[1-2 个变体版本]
\`\`\`

## 优化维度清单

逐一检查：🎯目标清晰度、🛠技术栈明确性、📐架构约束、📦依赖说明、
🎨UI/UX要求、🔌API契约、🗃数据模型、⚠️错误处理、🔒安全要求、
✅验收标准、📝代码风格、🧪测试要求、🌐国际化/可访问性、⚡性能要求

## 交互规则

1. 需求过于简略时，先基于专业判断合理推断补全，在「优化说明」中标明假设
2. 用户已提供较完整需求时，侧重结构化梳理和边界补充，而非大幅改写
3. 用户指定技术栈时严格遵循；未指定时推荐主流方案并说明理由
4. 始终保持用户原始意图，优化是增强而非替换
5. 输出的优化提示词必须是「即用型」，可直接复制到 AI 编码助手中使用
6. 自动适配提示词长度：
   - 简单需求（单个组件/函数）→ 精简提示词（200-500字）
   - 中等需求（完整页面/模块）→ 标准提示词（500-1500字）
   - 复杂需求（完整项目架构）→ 详细提示词（1500字+，可分阶段）
7. 超大型需求建议拆分为多个阶段性提示词，并说明执行顺序和依赖关系`;

// ─── 场景模板 ────────────────────────────────────────────────────────────────

const SCENE_TEMPLATES = {
    frontend_component: {
        name: "前端组件开发",
        template: `使用 [框架] + [语言] 创建 [组件名称] 组件。
功能：[核心功能描述]
Props：[列出所有 props 及类型]
状态管理：[本地状态/全局状态/URL状态]
样式方案：[CSS方案]
交互：[用户交互行为及反馈]
边界情况：[空数据/加载中/错误/超长文本等]`,
    },
    backend_api: {
        name: "后端 API 开发",
        template: `使用 [框架] + [语言] 实现 [API 名称] 接口。
路径：[HTTP 方法] [路径]
功能：[核心逻辑描述]
请求参数：[Query/Body/Params 的字段和类型]
响应格式：[成功和失败的响应结构]
数据库操作：[涉及的表/集合和操作类型]
认证：[是否需要 Token/Session 验证]
错误处理：[需要处理的错误场景和对应状态码]`,
    },
    database_design: {
        name: "数据库设计",
        template: `使用 [ORM/数据库] 设计 [业务模块] 的数据模型。
实体：[列出所有实体及其字段、类型、约束]
关系：[实体间的关联关系，1:1/1:N/N:N]
索引：[需要建立的索引及理由]
迁移：[是否生成迁移文件]
种子数据：[是否需要示例数据]`,
    },
    fullstack_feature: {
        name: "全栈功能开发",
        template: `实现 [功能名称] 的完整全栈流程。

后端：
- API 路由和控制器
- 数据模型和数据库操作
- 输入验证和错误处理

前端：
- 页面/组件结构
- API 调用和状态管理
- 表单交互和用户反馈

共享：
- TypeScript 类型定义
- 常量和枚举

技术栈：[前端框架] + [后端框架] + [数据库]`,
    },
};

// ─── Zod Schema 定义 ──────────────────────────────────────────────────────────

const OptimizeSchema = {
    raw_requirement: z
        .string()
        .describe("用户原始的开发需求描述（可以是一句话，也可以是较详细的段落）"),
    tech_stack: z
        .string()
        .optional()
        .describe(
            "（可选）明确指定的技术栈，如 'React 18 + TypeScript + Tailwind CSS' 或 'Spring Boot 3 + MySQL'。未指定时将自动推断"
        ),
    scene: z
        .enum([
            "frontend_component",
            "backend_api",
            "database_design",
            "fullstack_feature",
            "auto",
        ])
        .optional()
        .describe("（可选）开发场景分类。auto 表示自动识别，默认为 auto"),
    output_language: z
        .enum(["zh", "en"])
        .optional()
        .describe("（可选）输出语言，zh 为中文（默认），en 为英文"),
};

const GetTemplateSchema = {
    scene: z
        .enum([
            "frontend_component",
            "backend_api",
            "database_design",
            "fullstack_feature",
        ])
        .describe("开发场景类型"),
};

// ─── 工具处理逻辑 ─────────────────────────────────────────────────────────────

function handleOptimizePrompt(args) {
    const {
        raw_requirement,
        tech_stack = "",
        scene = "auto",
        output_language = "zh",
    } = args;

    if (!raw_requirement || raw_requirement.trim() === "") {
        return {
            content: [
                {
                    type: "text",
                    text: "❌ 错误：raw_requirement 不能为空，请提供需要优化的开发需求描述。",
                },
            ],
            isError: true,
        };
    }

    // 构造发送给 LLM 的完整指令
    const techStackHint = tech_stack
        ? `\n\n**用户指定技术栈**：${tech_stack}（请严格遵循）`
        : "";

    const sceneHint =
        scene !== "auto"
            ? `\n\n**开发场景**：${SCENE_TEMPLATES[scene]?.name || scene}`
            : "";

    const langHint =
        output_language === "en"
            ? "\n\n**重要**：请用英文输出所有内容（包括分析、提示词、说明）。"
            : "";

    const userMessage = `请优化以下开发需求描述：

---
${raw_requirement.trim()}
---
${techStackHint}${sceneHint}${langHint}

请严格按照系统提示词中的输出模板格式返回优化结果，包含：需求分析、优化后的提示词、优化说明、可选变体（如适用）。`;

    return {
        content: [
            {
                type: "text",
                text: `以下是需要发送给大语言模型（LLM）的完整优化请求。请将【系统提示词】和【用户消息】分别配置到对话中。

---

## 🤖 系统提示词（System Prompt）

${SYSTEM_PROMPT}

---

## 💬 用户消息（User Message）

${userMessage}

---

> 💡 **使用说明**：将上方的系统提示词配置到 AI 对话的 System 角色，将用户消息发送为 User 角色消息，即可获得优化后的提示词。
> 
> 如果你在支持 MCP 的客户端（如 Claude Desktop、Cursor）中调用此工具，AI 助手会直接基于以上内容生成优化结果。`,
            },
        ],
    };
}

function handleGetTemplate(args) {
    const { scene } = args;
    const tpl = SCENE_TEMPLATES[scene];

    if (!tpl) {
        return {
            content: [
                {
                    type: "text",
                    text: `❌ 未知场景类型：${scene}。可用场景：${Object.keys(SCENE_TEMPLATES).join(", ")}`,
                },
            ],
            isError: true,
        };
    }

    return {
        content: [
            {
                type: "text",
                text: `## 📐 场景模板：${tpl.name}

\`\`\`
${tpl.template}
\`\`\`

---

**使用方法**：
1. 将模板中 \`[]\` 内的占位符替换为实际内容
2. 填写完成后，调用 \`optimize_prompt\` 工具进行进一步优化
3. 或直接将填写好的模板发送给 AI 编码助手`,
            },
        ],
    };
}

function handleGetSystemPrompt() {
    return {
        content: [
            {
                type: "text",
                text: `## 🧠 提示词优化专家 — 完整系统提示词

以下内容可直接配置到任意 AI 编码助手（Cursor、Cline、Claude、ChatGPT 等）的系统提示词位置：

---

${SYSTEM_PROMPT}

---

> 📋 **版本**：v1.0 | **适用场景**：前后端全栈开发提示词优化
> 
> **推荐搭配**：Claude 3.5 Sonnet / GPT-4o / Gemini 1.5 Pro 等大语言模型`,
            },
        ],
    };
}

// ─── MCP 服务器启动 ───────────────────────────────────────────────────────────

const server = new McpServer({
    name: "prompt-optimizer",
    version: "1.0.0",
});

// 注册工具
server.registerTool(
    "optimize_prompt",
    {
        description:
            "将粗略的开发需求描述优化为结构清晰、可直接使用的高质量 AI 编码提示词。适用于前端、后端、全栈开发场景。",
        inputSchema: OptimizeSchema,
    },
    async (args) => handleOptimizePrompt(args)
);

server.registerTool(
    "get_template",
    {
        description: "获取特定开发场景的提示词快速模板，帮助用户了解该场景下需要填写哪些信息",
        inputSchema: GetTemplateSchema,
    },
    async (args) => handleGetTemplate(args)
);

server.registerTool(
    "get_system_prompt",
    {
        description: "获取完整的提示词优化系统提示词，可将其配置到任意 AI 编码助手中，使其具备提示词优化能力",
        inputSchema: {},
    },
    async () => handleGetSystemPrompt()
);

// 启动服务
const transport = new StdioServerTransport();
await server.connect(transport);
console.error("✅ Prompt Optimizer MCP Server 已启动（stdio 模式）");
