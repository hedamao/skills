# Integration Test Generator 技能模块

为 Spring Boot + Web 应用生成全栈集成测试的 AI 技能模块。

## 技能概述

这个技能模块帮助 Agent 为 Java + Web 应用生成完整的集成测试方案，涵盖四个测试层次：

| 测试层次 | 技术栈 | 验证目标 |
|---------|-------|---------|
| **后端集成测试** | @SpringBootTest + Testcontainers | 数据库交互、事务行为 |
| **API 契约测试** | RestAssured + MockMvc | REST API 契约、请求/响应格式 |
| **前端 UI 测试** | Playwright Java + Page Object | 页面交互、表单操作 |
| **E2E 全链路测试** | Testcontainers + Playwright | 完整业务流程验证 |

## 目录结构

```
integration-test/
├── SKILL.md                         # 主技能定义文件
├── README.md                        # 本文件
├── templates/                       # 代码模板目录
│   ├── backend/                     # 后端测试模板
│   │   ├── testcontainers_test.java.template
│   │   └── restassured_test.java.template
│   └── frontend/                    # 前端测试模板
│       ├── playwright_test.java.template
│       ├── page_object.java.template
│       └── e2e_test.java.template
├── scripts/                         # 辅助脚本目录
│   ├── setup_playwright.sh          # Playwright 环境安装脚本
│   ├── run_integration_tests.sh     # 测试执行脚本
│   └── init_test_project.sh         # 测试项目初始化脚本
└── examples/                        # 示例代码
    ├── UserBackendIntegrationTest.java
    ├── UserApiContractTest.java
    ├── LoginPage.java
    └── UserManagementE2ETest.java
```

## 快速开始

### 1. 初始化测试项目

```bash
bash scripts/init_test_project.sh com.example.yourapp
```

这将创建标准化的测试目录结构和基类。

### 2. 安装 Playwright 浏览器

```bash
bash scripts/setup_playwright.sh
```

### 3. 运行集成测试

```bash
# 运行所有集成测试
bash scripts/run_integration_tests.sh all

# 只运行后端集成测试
bash scripts/run_integration_tests.sh backend

# 只运行 API 契约测试
bash scripts/run_integration_tests.sh api

# 只运行前端 UI 测试
bash scripts/run_integration_tests.sh ui

# 只运行 E2E 测试
bash scripts/run_integration_tests.sh e2e

# 并行执行测试
bash scripts/run_integration_tests.sh all --parallel

# 生成代码覆盖率报告
bash scripts/run_integration_tests.sh all --coverage
```

## 使用技能

在 Claude Code 或 Claude Agent SDK 中调用此技能：

```
"帮我为用户模块生成集成测试"
"给登录功能写前端 UI 测试"
"我需要完整的订单流程 E2E 测试"
"为所有 API 生成契约测试"
```

## 技术要求

| 依赖 | 版本 | 用途 |
|------|------|------|
| Spring Boot | 3.x | 应用框架 |
| JUnit 5 | 5.x | 测试框架 |
| Testcontainers | 1.20+ | 容器化测试 |
| Playwright Java | 1.48+ | UI 自动化 |
| RestAssured | 5.4+ | API 测试 |
| PostgreSQL/MySQL | 14+/8.0+ | 测试数据库 |

## 示例代码

查看 `examples/` 目录下的示例代码：

- `UserBackendIntegrationTest.java` - 后端集成测试示例
- `UserApiContractTest.java` - API 契约测试示例
- `LoginPage.java` - Page Object Model 示例
- `UserManagementE2ETest.java` - E2E 测试示例

## 与其他技能协作

这个技能可以与项目中的其他技能配合使用：

1. **test-case** - 生成通用测试用例
2. **integration-test** - 生成全栈集成测试（本技能）
3. **code-review** - 审查测试代码
4. **git-commit** - 提交测试代码

## License

MIT License
