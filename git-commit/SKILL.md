---
name: git-commit
description: 分析当前工作区的代码变动，按条目列出改动内容与影响范围，并生成结构化的 Git 提交信息（Commit Message），确保每次提交都清晰、可追溯。同时具备 Code Review 能力，对代码变更进行多维度审查，输出结构化审查报告。
---

# Git Commit Assistant (Git 提交助手)

## 技能描述 (Description)
此技能帮助 Agent 在代码变更完成后，自动分析 `git diff` 的输出，识别每一处变动的类型（新增、修改、删除、重构），评估其影响范围（功能、性能、安全、兼容性），并按条目化的格式输出一份完整的提交摘要。最终生成符合 **Conventional Commits** 规范的 Commit Message。

## 执行指令 (Instructions)

当用户要求你分析代码变动并生成提交信息时，请严格按照以下步骤执行：

### 步骤 1：获取变动 (Collect Changes)

依次执行以下命令以收集完整的变动信息：

```bash
# 查看暂存区的变动（已 git add 的文件）
git diff --cached --stat
git diff --cached

# 查看工作区的变动（未 git add 的文件）
git diff --stat
git diff

# 查看未跟踪的新文件
git status --short
```

> **注意**：如果用户已经明确告知了改动内容，可以跳过此步骤。

### 步骤 2：分类变动 (Classify Changes)

将所有变动按以下类别进行分类：

| 类别标识 | 含义 | 示例 |
|---------|------|------|
| `feat` | 新功能 | 新增接口、新增页面 |
| `fix` | Bug 修复 | 修复空指针、修复计算错误 |
| `refactor` | 重构 | 方法提取、类拆分、命名优化 |
| `style` | 样式/格式 | 代码格式化、注释修改 |
| `perf` | 性能优化 | 缓存、SQL 优化、算法改进 |
| `docs` | 文档 | README、注释、API 文档 |
| `test` | 测试 | 新增/修改单元测试 |
| `chore` | 工程/构建 | 依赖更新、CI 配置、脚本修改 |
| `security` | 安全 | 权限修复、漏洞修补 |

### 步骤 3：逐条分析影响 (Impact Analysis)

对每一处变动，分析其可能的影响范围，使用以下维度：

*   **功能影响**：此改动是否改变了现有功能的行为？是否引入了新功能？
*   **兼容性影响**：此改动是否会导致 API、数据库 Schema 或配置的不兼容变更（Breaking Change）？
*   **性能影响**：此改动是否涉及循环、数据库查询、缓存等对性能敏感的区域？
*   **安全影响**：此改动是否涉及权限校验、数据脱敏、输入校验等安全相关逻辑？
*   **依赖影响**：此改动是否修改了 `pom.xml`、`package.json` 等依赖文件？是否引入或移除了第三方库？

### 步骤 4：生成输出 (Generate Output)

按照以下模板生成最终输出：

---

#### 📋 本次提交变动摘要

**提交类型**：`feat` / `fix` / `refactor` （根据主要变动选择）

**一句话概述**：（用一句话描述本次提交的核心目的）

---

**📝 变动明细：**

| # | 文件 | 变动类型 | 改动说明 |
|---|------|---------|---------|
| 1 | `src/main/java/com/.../XxxController.java` | 新增 | 新增用户查询接口 `GET /api/users/{id}` |
| 2 | `src/main/java/com/.../XxxService.java` | 修改 | 增加参数校验逻辑，防止空指针 |
| 3 | `src/main/resources/application.yml` | 修改 | 新增 Redis 缓存配置项 |
| 4 | `pom.xml` | 修改 | 引入 `spring-boot-starter-data-redis` 依赖 |

---

**⚡ 影响评估：**

| 影响维度 | 等级 | 说明 |
|---------|------|------|
| 功能影响 | 🟡 中 | 新增了用户查询功能，不影响现有接口 |
| 兼容性 | 🟢 低 | 无 Breaking Change |
| 性能 | 🟢 低 | 引入 Redis 缓存，预计提升查询性能 |
| 安全 | 🟡 中 | 新接口需确保已配置权限拦截 |
| 依赖 | 🟡 中 | 新增 Redis Starter，需确保 Redis 服务可用 |

---

**💬 建议的 Commit Message：**

```
feat(user): 新增用户详情查询接口

- 新增 GET /api/users/{id} 接口，支持按 ID 查询用户详情
- Service 层增加参数非空校验
- 引入 spring-boot-starter-data-redis 用于缓存用户数据
- application.yml 中新增 Redis 连接配置

影响范围：用户模块
Breaking Change: 无
```

---

### 步骤 5：提供可执行命令 (Executable Commands)

在输出末尾，提供用户可以直接复制执行的 git 命令：

```bash
# 添加所有变动的文件
git add -A

# 提交（将下方 message 替换为实际生成的内容）
git commit -m "feat(user): 新增用户详情查询接口" -m "- 新增 GET /api/users/{id} 接口
- Service 层增加参数非空校验
- 引入 spring-boot-starter-data-redis
- 新增 Redis 连接配置"
```

## 附加规则 (Additional Rules)

1.  **语言**：Commit Message 的语言应与使用中文。
2.  **粒度**：如果本次变动涉及多个不相关的逻辑，建议用户拆分为多次提交，并为每次提交分别生成 Message。
3.  **Breaking Change**：如果存在不兼容的变更，必须在 Commit Message 的 footer 中以 `BREAKING CHANGE:` 开头进行标注。
4.  **关联 Issue**：如果用户提到了相关的 Issue 或 JIRA 编号，在 footer 中追加 `Closes #123` 或 `Refs: JIRA-456`。

## 示例应用 (Example Usage)

*   **User**: "帮我看看这次改了什么，生成一个提交信息"
    *   **Agent**: 执行步骤 1-5，输出完整的变动摘要和 Commit Message。

*   **User**: "我这次改动会有破坏性变更吗？"
    *   **Agent**: 重点执行步骤 3 的兼容性分析，给出结论。

*   **User**: "把这些改动拆成两个提交"
    *   **Agent**: 分析变动的逻辑归属，建议拆分方案，并为每个提交生成独立的 Message。

---

# Code Review Assistant (代码审查助手)

## 技能描述 (Description)
此技能帮助 Agent 对 **Spring Boot** 项目的代码变更进行系统化、多维度的审查（Code Review），识别代码中的潜在问题、安全风险、性能瓶颈和可维护性隐患，并输出结构化的审查报告与改进建议。审查过程将结合 Spring Boot 框架的最佳实践和常见陷阱进行针对性检查。可与上方的 Git Commit 技能联动使用——先 Review 再 Commit，确保每次提交的代码质量。

**适用技术栈**：Spring Boot（含 Spring MVC、Spring Data JPA / MyBatis、Spring Security、Spring Cache 等生态组件）

## 执行指令 (Instructions)

当用户要求你对代码变更进行审查时，请严格按照以下步骤执行：

### 步骤 1：获取审查目标 (Collect Review Target)

根据审查场景选择合适的命令获取变更内容：

```bash
# 场景 A：审查当前工作区尚未提交的变更
git diff --cached --stat
git diff --cached
git diff --stat
git diff

# 场景 B：审查某次特定提交
git show <commit-hash> --stat
git show <commit-hash>

# 场景 C：审查某个分支相对于目标分支的所有变更
git log --oneline <target-branch>..<feature-branch>
git diff <target-branch>...<feature-branch> --stat
git diff <target-branch>...<feature-branch>

# 场景 D：审查最近 N 次提交
git log --oneline -n <N>
git diff HEAD~<N>..HEAD --stat
git diff HEAD~<N>..HEAD
```

> **注意**：如果用户已经提供了具体的代码片段或文件，可以跳过此步骤，直接对提供的内容进行审查。

### 步骤 2：理解变更上下文 (Understand Context)

在深入审查之前，先建立对变更的整体理解：

1.  **变更目的**：这次改动想解决什么问题？实现什么功能？
2.  **涉及模块**：改动涉及哪些模块/包/组件？
3.  **上下文代码**：阅读变更文件的相关上下文代码，理解改动在整个代码结构中的位置和作用。
4.  **关联配置**：是否涉及配置文件、数据库变更、API 接口变更？

### 步骤 3：多维度审查 (Multi-Dimensional Review)

对每处变更，从以下 **5 个维度** 进行系统化审查：

#### 维度 1：代码质量 (Code Quality)

| 检查项 | 说明 |
|--------|------|
| 命名规范 | 变量、方法、类的命名是否清晰、准确、符合项目约定？ |
| 代码重复 | 是否存在可以提取的重复逻辑？是否违反 DRY 原则？ |
| 方法复杂度 | 方法是否过长？圈复杂度是否过高？是否需要拆分？ |
| 错误处理 | 异常是否被正确捕获和处理？是否有未处理的边界情况？是否使用了 `@ControllerAdvice` / `@ExceptionHandler` 进行统一异常处理？ |
| 代码风格 | 是否符合项目的代码风格规范（格式、缩进、注释）？ |
| SOLID 原则 | 是否遵循单一职责、开闭原则等设计原则？Controller 是否只做参数接收和转发？Service 是否只处理业务逻辑？ |
| 魔法值 | 是否存在未定义的硬编码常量？是否应提取到 `application.yml` 或常量类中？ |
| 分层规范 | 是否遵循 Controller → Service → Repository 的分层调用？是否存在跨层调用？ |

#### 维度 2：安全性 (Security)

| 检查项 | 说明 |
|--------|------|
| 输入校验 | 用户输入是否经过充分校验？是否使用了 `@Valid` / `@Validated` + JSR-303 注解？是否存在注入风险（SQL / XSS / SSRF）？ |
| 权限控制 | 新增或修改的接口是否有正确的 `@PreAuthorize` / `@Secured` 权限注解？是否存在越权风险？ |
| 敏感数据 | 日志中是否打印了密码、Token、身份证号等敏感信息？返回的 DTO 中是否通过 `@JsonIgnore` 或独立 VO 隐藏了敏感字段？ |
| 依赖安全 | `pom.xml` / `build.gradle` 中新引入的第三方库是否存在已知漏洞？Spring Boot Starter 版本是否与 BOM 一致？ |
| 认证鉴权 | Spring Security 过滤链配置是否正确？Token/Session 处理是否安全？CORS 配置是否合理？ |
| Actuator 暴露 | 若使用 Spring Boot Actuator，是否限制了外部可访问的端点？`/actuator/env`、`/actuator/heapdump` 等敏感端点是否受保护？ |

#### 维度 3：性能 (Performance)

| 检查项 | 说明 |
|--------|------|
| 数据库查询 | 是否存在 N+1 查询（JPA 的 `LAZY` 加载陷阱）？是否使用了 `@EntityGraph` 或 `JOIN FETCH` 优化？批量操作是否使用 `saveAll()` / `batchUpdate()`？ |
| 循环与算法 | 是否在循环中执行了耗时操作（如 IO、网络调用、数据库查询）？算法复杂度是否合理？ |
| 内存使用 | 是否存在大对象未释放？`@Autowired` 的 Bean 是否持有了不必要的大量状态？集合操作是否高效？ |
| 缓存策略 | 是否合理使用了 `@Cacheable` / `@CacheEvict` / `@CachePut`？缓存 Key 是否合理？缓存失效策略是否正确？ |
| 并发安全 | 多线程场景下是否有竞态条件？`@Async` 方法的线程池是否合理配置？锁的粒度是否合理？ |
| 连接池 | 数据库连接池（HikariCP）和 HTTP 连接池配置是否合理？是否存在连接泄漏风险？ |

#### 维度 4：可维护性 (Maintainability)

| 检查项 | 说明 |
|--------|------|
| 可读性 | 代码意图是否清晰？复杂逻辑是否有注释说明？ |
| 可测试性 | 新增逻辑是否易于编写单元测试？是否可用 `@MockBean` / `@SpyBean` 进行 Mock？`@SpringBootTest` 的使用范围是否合理（避免全量加载）？ |
| 扩展性 | 设计是否考虑了未来的扩展需求？是否有过度设计？是否利用了 Spring 的扩展点（`BeanPostProcessor`、`ApplicationEvent` 等）？ |
| 文档更新 | 公共 API 变更是否更新了 Swagger / SpringDoc 注解（`@Operation`、`@Schema` 等）？接口文档是否同步？ |
| 配置外部化 | 环境相关的值是否提取到了 `application.yml` / `application-{profile}.yml` 中？是否使用了 `@Value` 或 `@ConfigurationProperties` 注入？ |

#### 维度 5：业务逻辑 (Business Logic)

| 检查项 | 说明 |
|--------|------|
| 逻辑正确性 | 业务逻辑是否正确实现了需求？边界条件是否覆盖？ |
| 数据一致性 | 涉及多表/多服务操作时，`@Transactional` 事务边界是否正确？传播行为和隔离级别是否合理？是否考虑了分布式事务场景？ |
| 幂等性 | 接口是否具有幂等性？重复调用是否会产生副作用？ |
| 向后兼容 | 是否兼容旧版本的数据/接口？是否需要 Flyway / Liquibase 数据迁移脚本？ |

#### 维度 6：Spring Boot 专项审查 (Spring Boot Specific)

| 检查项 | 说明 |
|--------|------|
| 注解使用 | `@RestController` vs `@Controller`、`@Service` vs `@Component` 等注解使用是否正确和语义化？`@RequestBody` / `@RequestParam` / `@PathVariable` 使用是否恰当？ |
| 依赖注入 | 是否优先使用构造器注入（而非 `@Autowired` 字段注入）？是否存在循环依赖？ |
| Bean 管理 | 新增的 Bean 作用域（`@Scope`）是否正确？`@Configuration` 类中的 `@Bean` 方法是否合理？是否存在不必要的 Bean 注册？ |
| 配置管理 | `@ConfigurationProperties` 是否搭配 `@Validated` 使用？配置类是否有 `@ConstructorBinding`？多环境配置（`application-{profile}.yml`）是否正确？ |
| 事务管理 | `@Transactional` 注解是否放在了 `public` 方法上？是否存在自调用导致事务失效的问题？`rollbackFor` 属性是否指定了正确的异常类型？只读查询是否使用了 `@Transactional(readOnly = true)`？ |
| AOP 使用 | 自定义切面（`@Aspect`）的切点表达式是否精确？执行顺序（`@Order`）是否合理？是否避免了过于宽泛的切面范围？ |
| 异步处理 | `@Async` 方法是否返回了 `Future` / `CompletableFuture`？自定义线程池是否配置了合理的核心线程数、队列容量和拒绝策略？ |
| 定时任务 | `@Scheduled` 任务在集群部署下是否有防重复执行机制（如 ShedLock）？Cron 表达式是否正确？ |
| REST 规范 | HTTP 方法语义是否正确（GET 查询、POST 创建、PUT 更新、DELETE 删除）？响应状态码是否合理？是否使用了统一的响应体封装？ |
| 日志规范 | 是否使用了 SLF4J + Logback（而非 `System.out.println`）？日志级别是否合理？参数化日志（`log.info("user: {}", name)`）是否替代了字符串拼接？ |

### 步骤 4：对问题进行分级 (Issue Severity Classification)

将发现的每个问题按严重程度分级：

| 等级 | 标识 | 含义 | 处理方式 |
|------|------|------|----------|
| 致命 | 🔴 `BLOCKER` | 存在严重 Bug、安全漏洞或数据丢失风险 | **必须修复**，阻断提交 |
| 严重 | 🟠 `MAJOR` | 存在明显的逻辑错误、性能问题或设计缺陷 | **强烈建议修复** |
| 一般 | 🟡 `MINOR` | 代码质量或可维护性可改进，但不影响功能 | **建议修复**，可协商 |
| 建议 | 🟢 `SUGGESTION` | 优化建议、最佳实践推荐、风格改进 | **可选**，供参考 |
| 赞赏 | 💙 `PRAISE` | 写得好的代码，值得肯定和学习的实践 | 给予正面反馈 |

### 步骤 5：生成审查报告 (Generate Review Report)

审查完成后，需要生成 **Markdown 格式的审查报告文件**，并按以下规则保存：

```
文件命名：code-review-YYYY-MM-DD.md
存放路径：项目根目录下（与 src/ 同级）
示例：code-review-2026-02-13.md
```

> **说明**：
> - 日期取审查执行当天的日期（格式：`YYYY-MM-DD`）。
> - 若同一天执行多次审查，使用序号后缀区分：`code-review-2026-02-13-2.md`。
> - Agent 在输出报告内容的同时，必须将报告内容写入上述路径的 Markdown 文件中。

按照以下模板生成报告文件内容：

---

#### 🔍 Code Review 审查报告

**审查范围**：（说明审查的分支/提交/文件范围）

**变更概述**：（一段话概括本次变更的目的和主要内容）

**总体评价**：✅ 通过 / ⚠️ 需修改后通过 / ❌ 需重新设计

---

**📋 审查发现：**

| # | 文件 | 行号 | 等级 | 维度 | 问题描述 |
|---|------|------|------|------|----------|
| 1 | `src/.../UserService.java` | L45-L52 | 🔴 BLOCKER | 安全性 | 用户输入未做 SQL 注入防护，直接拼接到查询语句中 |
| 2 | `src/.../OrderController.java` | L120 | 🟠 MAJOR | 性能 | 在循环内执行了数据库查询，存在 N+1 问题 |
| 3 | `src/.../Utils.java` | L30-L45 | 🟡 MINOR | 代码质量 | 方法过长（60 行），建议拆分为多个私有方法 |
| 4 | `src/.../Config.java` | L10 | 🟢 SUGGESTION | 可维护性 | 数据库连接超时值建议提取为配置项 |
| 5 | `src/.../CacheManager.java` | L88-L95 | 💙 PRAISE | 性能 | 缓存预热策略设计得很好，有效避免了冷启动问题 |

---

**🔧 改进建议详情：**

**问题 1 — 🔴 SQL 注入风险**
- **文件**：`src/.../UserService.java` L45-L52
- **现状**：
```java
// 原代码（有风险）
String sql = "SELECT * FROM users WHERE name = '" + userName + "'";
```
- **建议**：
```java
// 改用参数化查询
@Query("SELECT u FROM User u WHERE u.name = :name")
User findByName(@Param("name") String name);
```
- **理由**：直接拼接用户输入存在 SQL 注入风险，应使用参数化查询或 ORM 框架的安全查询方式。

---

（对每个 🔴 和 🟠 级别的问题都提供类似的详细改进建议，包含 **现状代码** → **建议代码** → **理由**）

---

**📊 审查统计：**

| 统计项 | 数量 |
|--------|------|
| 审查文件数 | X |
| 🔴 致命问题 | X |
| 🟠 严重问题 | X |
| 🟡 一般问题 | X |
| 🟢 优化建议 | X |
| 💙 代码亮点 | X |

---

### 步骤 6：给出最终结论 (Final Conclusion)

根据审查结果给出明确的结论和后续行动建议：

-   **✅ 通过 (Approved)**：代码质量良好，无阻断问题，可以进行合并/提交。
-   **⚠️ 需修改后通过 (Request Changes)**：存在需要修复的问题，修改后无需再次审查即可合并。
-   **❌ 需重新设计 (Redesign Required)**：存在根本性的设计问题，需要讨论方案后重新实现。

## 附加规则 (Additional Rules for Code Review)

1.  **客观公正**：审查意见应基于事实和最佳实践，避免主观偏好。对于代码风格争议，遵从项目已有约定。
2.  **建设性反馈**：每个问题都应附带具体的改进建议或修复方案，不要只指出问题而不给出方向。
3.  **肯定优点**：好的代码实践也值得指出（💙 PRAISE），保持积极的审查氛围。
4.  **聚焦重要问题**：优先关注 🔴 和 🟠 级别的问题，避免在琐碎问题上花费过多时间。
5.  **上下文感知**：审查时应结合 Spring Boot 框架的特性和最佳实践，考虑项目的整体架构和团队约定。
6.  **语言**：审查报告使用中文。
7.  **报告输出**：每次审查必须生成 Markdown 报告文件，文件名以当前日期命名（`code-review-YYYY-MM-DD.md`），存放于项目根目录。
8.  **Spring Boot 版本感知**：审查时应关注项目使用的 Spring Boot 版本，不同版本的 API 和最佳实践可能存在差异（如 Spring Boot 2.x vs 3.x）。

## 与 Git Commit 联动 (Integration with Git Commit)

当同时使用 Code Review 和 Git Commit 两个技能时，推荐的工作流为：

1.  **先审查**：使用 Code Review 技能对变更进行审查
2.  **再修复**：根据审查报告修复 🔴 和 🟠 级别的问题
3.  **最后提交**：使用 Git Commit 技能生成提交信息并提交

> 用户可以通过 "先帮我 review 一下，没问题就帮我提交" 来触发这个联动流程。

## 示例应用 (Example Usage)

*   **User**: "帮我 review 一下这次的代码改动"
    *   **Agent**: 执行步骤 1-6，输出完整的审查报告。

*   **User**: "看看这段代码有没有安全问题"
    *   **Agent**: 聚焦步骤 3 的安全性维度进行审查，输出安全相关的发现。

*   **User**: "review 一下 feature/xxx 分支的改动，对比 main 分支"
    *   **Agent**: 使用场景 C 的命令获取分支差异，执行完整审查流程。

*   **User**: "先帮我 review 一下，没问题就帮我提交"
    *   **Agent**: 先执行 Code Review 流程，如果无 🔴 BLOCKER 问题，则继续执行 Git Commit 流程生成提交信息。

*   **User**: "这段代码性能上有什么可以优化的吗？"
    *   **Agent**: 聚焦步骤 3 的性能维度进行分析，输出性能相关的建议。
