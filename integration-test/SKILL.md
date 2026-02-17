---
name: integration-test
description: 为 Spring Boot + Web 应用生成全栈集成测试，涵盖后端集成测试（@SpringBootTest + Testcontainers）、API 契约测试（RestAssured）、前端 UI 测试（Playwright Java）和 E2E 全链路测试。输出可执行的 Java 测试代码、测试报告、XMind 思维导图和自动化脚本。
---

# Integration Test Generator (全栈集成测试生成助手)

## 技能描述 (Description)

此技能帮助 Agent 为 Spring Boot + 前端应用生成完整的集成测试方案，覆盖四个测试层次：

| 测试层次 | 技术栈 | 验证目标 |
|---------|-------|---------|
| **后端集成测试** | @SpringBootTest + Testcontainers | 数据库交互、事务行为、Service 层集成 |
| **API 契约测试** | RestAssured + MockMvc | REST API 契约、请求/响应格式、状态码 |
| **前端 UI 测试** | Playwright Java + Page Object | 页面交互、表单提交、用户导航流程 |
| **E2E 全链路测试** | Testcontainers + Playwright | 完整业务流程、前后端联调、数据一致性 |

**适用技术栈**：Spring Boot 3.x、JUnit 5、Testcontainers、Playwright Java、RestAssured、MySQL/PostgreSQL。

---

## 执行指令 (Instructions)

当用户要求你生成集成测试时，请严格按照以下步骤执行：

### 步骤 1：确定测试目标 (Identify Test Target)

根据用户的输入确定要为哪些代码生成集成测试：

```bash
# 场景 A：基于当前代码变更生成测试
git diff --cached --stat
git diff --stat

# 场景 B：基于某次提交生成测试
git show <commit-hash> --stat

# 场景 C：基于指定文件/模块生成测试
# 用户直接指定模块名称或文件路径

# 场景 D：为整个项目生成集成测试
# 扫描项目结构，识别需要测试的核心模块
```

> **注意**：优先分析 Controller、Service、Repository 层的关键类，以及前端的关键页面组件。

### 步骤 2：分析被测代码 (Analyze Code Under Test)

对目标代码进行深入分析，建立以下理解：

#### 2.1 后端分析

| 分析项 | 说明 |
|--------|------|
| API 端点 | 列出所有 Controller 的 REST 端点（路径、方法、参数） |
| 数据模型 | 识别 Entity/DTO 的字段和校验规则 |
| 依赖关系 | Service 层的依赖、Repository 的查询方法 |
| 业务逻辑 | 核心业务流程、分支条件、边界条件 |

#### 2.2 前端分析

| 分析项 | 说明 |
|--------|------|
| 页面结构 | 主要页面（登录、注册、列表、详情等） |
| 表单字段 | 每个表单的字段、校验规则、提交行为 |
| 交互流程 | 用户操作流程（页面跳转、按钮点击、异步请求） |
| 选择器 | 元素定位方式（ID、CSS Selector、XPath） |

#### 2.3 数据流转分析

| 分析项 | 说明 |
|--------|------|
| 请求链路 | 前端请求 → Controller → Service → Repository → 数据库 |
| 响应链路 | 数据库 → Entity → DTO → JSON → 前端渲染 |
| 状态变化 | 操作导致的数据状态变化（创建、更新、删除） |

### 步骤 3：设计测试分层 (Design Test Layers)

按照 **四层集成测试金字塔** 原则设计测试用例：

```
                ╱╲
               ╱E2E╲         ← 少量核心业务场景全链路测试
              ╱──────╲
             ╱Frontend╲       ← Playwright UI 测试覆盖关键用户路径
            ╱──────────╲
           ╱ API ╲           ← RestAssured 契约测试验证接口规范
          ╱────────╲
         ╱Backend  ╲         ← @SpringBootTest + Testcontainers 集成测试
        ╱──────────╲
```

---

#### 📦 3.1 后端集成测试 (Backend Integration Test)

**目标**：验证后端各层与基础设施（数据库、缓存等）的真实交互。

**技术选型**：
- 框架：`@SpringBootTest`、`@DataJpaTest`、`@WebMvcTest`
- 数据库：Testcontainers（MySQL/PostgreSQL）
- 工具：`TestEntityManager`、`@Sql`、`@Transactional`

**测试分类与适用注解**：

| 测试类型 | 注解 | 使用场景 |
|----------|------|----------|
| Repository 层 | `@DataJpaTest` | 验证 JPA Repository 的 CRUD、自定义查询 |
| Service 层 | `@SpringBootTest` + `@Transactional` | 验证 Service 与真实数据库的交互 |
| 完整应用 | `@SpringBootTest(webEnvironment = RANDOM_PORT)` | 验证多层协作 |

**代码模板 — Testcontainers 集成测试**：
```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
@DisplayName("用户模块后端集成测试")
class UserBackendIntegrationTest {

    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0")
            .withDatabaseName("test_db")
            .withUsername("test_user")
            .withPassword("test_pass");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", mysql::getJdbcUrl);
        registry.add("spring.datasource.username", mysql::getUsername);
        registry.add("spring.datasource.password", mysql::getPassword);
    }

    @Autowired
    private UserService userService;

    @Autowired
    private UserRepository userRepository;

    @Test
    @DisplayName("创建用户：数据正确落库")
    void createUser_ValidData_PersistsToDatabase() {
        // Arrange
        UserCreateRequest request = new UserCreateRequest();
        request.setUsername("testuser");
        request.setEmail("test@example.com");

        // Act
        UserDTO result = userService.createUser(request);

        // Assert - 验证 Service 返回
        assertThat(result.getId()).isNotNull();

        // Assert - 验证数据库
        Optional<UserEntity> persisted = userRepository.findById(result.getId());
        assertThat(persisted).isPresent();
        assertThat(persisted.get().getUsername()).isEqualTo("testuser");
    }

    @Test
    @DisplayName("事务回滚：业务异常时数据不会被持久化")
    void createUser_BusinessException_RollbacksTransaction() {
        // Arrange - 构造触发业务异常的请求
        UserCreateRequest request = new UserCreateRequest();
        request.setUsername("duplicate"); // 假设用户名已存在

        long countBefore = userRepository.count();

        // Act & Assert
        assertThrows(BusinessException.class, () -> userService.createUser(request));

        // 事务回滚，数据量应不变
        long countAfter = userRepository.count();
        assertThat(countAfter).isEqualTo(countBefore);
    }
}
```

---

#### 📡 3.2 API 契约测试 (API Contract Test)

**目标**：验证 REST API 的请求/响应格式是否符合接口约定。

**技术选型**：
- 框架：`@SpringBootTest(webEnvironment = RANDOM_PORT)`
- 工具：RestAssured
- 验证：JSON Schema、状态码、响应头

**测试重点**：

| 验证项 | 说明 |
|--------|------|
| 状态码 | 200、201、400、401、403、404、500 等 |
| Content-Type | application/json、application/xml 等 |
| 响应结构 | JSON 字段存在性、类型、格式 |
| 业务错误码 | 自定义错误码和错误消息 |

**代码模板 — RestAssured API 测试**：
```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@DisplayName("API 契约测试")
class UserApiContractTest {

    @LocalServerPort
    private int port;

    @BeforeEach
    void setUp() {
        RestAssured.port = port;
        RestAssured.basePath = "/api";
        RestAssured.enableLoggingOfRequestAndResponseIfValidationFails();
    }

    @Test
    @DisplayName("GET /api/users/{id} - 正常返回符合契约")
    void getUserById_ExistingUser_ReturnsValidContract() {
        given()
            .pathParam("id", 1)
            .accept(ContentType.JSON)
        .when()
            .get("/users/{id}")
        .then()
            .statusCode(200)
            .contentType(ContentType.JSON)
            .body("id", equalTo(1))
            .body("username", notNullValue())
            .body("email", matchesPattern("[^@]+@[^@]+\\.[^@]+"))
            .body("createdAt", notNullValue());
    }

    @Test
    @DisplayName("GET /api/users/{id} - 不存在返回 404")
    void getUserById_NonExisting_Returns404() {
        given()
            .pathParam("id", 99999)
        .when()
            .get("/users/{id}")
        .then()
            .statusCode(404)
            .body("errorCode", equalTo("USER_NOT_FOUND"))
            .body("message", containsString("not found"));
    }

    @Test
    @DisplayName("POST /api/users - 请求参数校验失败返回 400")
    void createUser_InvalidRequest_Returns400() {
        String requestBody = """
            {
                "username": "",
                "email": "invalid-email"
            }
            """;

        given()
            .body(requestBody)
            .contentType(ContentType.JSON)
        .when()
            .post("/users")
        .then()
            .statusCode(400)
            .body("validationErrors", hasSize(greaterThan(0)));
    }

    @Test
    @DisplayName("POST /api/users - 成功创建返回 201")
    void createUser_ValidRequest_Returns201() {
        String requestBody = """
            {
                "username": "newuser",
                "email": "newuser@example.com",
                "password": "SecurePass123!"
            }
            """;

        given()
            .body(requestBody)
            .contentType(ContentType.JSON)
        .when()
            .post("/users")
        .then()
            .statusCode(201)
            .body("id", notNullValue())
            .body("username", equalTo("newuser"))
            .header("Location", containsString("/api/users/"));
    }
}
```

---

#### 🎨 3.3 前端 UI 测试 (Frontend UI Test)

**目标**：验证前端页面的用户交互和表单操作。

**技术选型**：
- 框架：Playwright Java
- 模式：Page Object Model（POM）
- 浏览器：Chromium（无头模式）

**Page Object Model 设计原则**：

| 原则 | 说明 |
|------|------|
| 分离关注点 | 页面元素定位与测试逻辑分离 |
| 可复用性 | 页面操作方法可在多个测试中复用 |
| 可维护性 | 元素定位变更只需修改 Page Object |
| 流式接口 | 方法返回 this，支持链式调用 |

**代码模板 — Playwright UI 测试**：
```java
@ExtendWith(PlaywrightExtension.class)
@DisplayName("前端 UI 测试")
class LoginUITest {

    static Page page;
    static BrowserContext context;

    @BeforeAll
    static void launchBrowser(Playwright playwright) {
        Browser browser = playwright.chromium().launch(
            new BrowserType.LaunchOptions().setHeadless(true)
        );
        context = browser.newContext();
        page = context.newPage();
    }

    @Test
    @DisplayName("登录流程：输入正确凭证后跳转到首页")
    void loginWithValidCredentials_ShouldRedirectToHomePage() {
        // Arrange & Act
        page.navigate("http://localhost:8080/login");

        // 使用 Page Object
        LoginPage loginPage = new LoginPage(page);
        loginPage
            .enterUsername("testuser")
            .enterPassword("password123")
            .clickLogin();

        // Assert - 验证跳转
        assertThat(page.url()).contains("/home");
        assertThat(page.locator(".welcome-message").textContent())
            .contains("Welcome, testuser");
    }

    @Test
    @DisplayName("登录流程：输入错误凭证显示错误消息")
    void loginWithInvalidCredentials_ShouldShowErrorMessage() {
        page.navigate("http://localhost:8080/login");

        LoginPage loginPage = new LoginPage(page);
        loginPage
            .enterUsername("wronguser")
            .enterPassword("wrongpass")
            .clickLogin();

        // Assert - 验证错误消息
        assertThat(page.locator(".alert-error").isVisible())
            .isTrue();
        assertThat(page.locator(".alert-error").textContent())
            .contains("Invalid credentials");
    }

    @Test
    @DisplayName("表单验证：空用户名显示验证错误")
    void loginWithEmptyUsername_ShouldShowValidationError() {
        page.navigate("http://localhost:8080/login");

        LoginPage loginPage = new LoginPage(page);
        loginPage
            .enterUsername("")
            .enterPassword("password123")
            .clickLogin();

        // Assert - 验证错误消息
        assertThat(page.locator("#username-error").isVisible())
            .isTrue();
        assertThat(page.locator("#username-error").textContent())
            .contains("Username is required");
    }

    @AfterAll
    static void closeBrowser() {
        if (context != null) {
            context.close();
        }
    }
}
```

**Page Object Model 模板**：
```java
package {{packageName}}.ui.pages;

import com.microsoft.playwright.Page;
import com.microsoft.playwright.Locator;

/**
 * Page Object for: {{pageName}}
 * Description: {{description}}
 */
public class {{pageClassName}} {

    private final Page page;

    // 页面元素定位器
    private static final String USERNAME_INPUT = "#username";
    private static final String PASSWORD_INPUT = "#password";
    private static final String LOGIN_BUTTON = "#login-button";
    private static final String ERROR_MESSAGE = ".alert-error";
    private static final String FORM_CONTAINER = ".login-form";

    public {{pageClassName}}(Page page) {
        this.page = page;
        // 等待页面关键元素出现
        page.waitForSelector(FORM_CONTAINER);
    }

    // 页面操作方法 - 流式接口
    public {{pageClassName}} enterUsername(String username) {
        page.fill(USERNAME_INPUT, username);
        return this;
    }

    public {{pageClassName}} enterPassword(String password) {
        page.fill(PASSWORD_INPUT, password);
        return this;
    }

    public {{pageClassName}} clickLogin() {
        page.click(LOGIN_BUTTON);
        return this;
    }

    // 断言辅助方法
    public Locator errorMessage() {
        return page.locator(ERROR_MESSAGE);
    }

    public {{pageClassName}} assertErrorMessageContains(String expectedMessage) {
        assertThat(errorMessage().textContent())
            .contains(expectedMessage);
        return this;
    }

    public {{pageClassName}} assertOnPage() {
        assertThat(page.locator(FORM_CONTAINER).isVisible())
            .isTrue();
        return this;
    }
}
```

---

#### 🔄 3.4 E2E 全链路测试 (End-to-End Test)

**目标**：验证从用户操作到数据库落库的完整业务流程。

**技术选型**：
- 后端：`@SpringBootTest` + Testcontainers
- 前端：Playwright Java
- 验证：HTTP 状态 + UI 渲染 + 数据库状态

**E2E 测试场景分类**：

| 场景类型 | 说明 | 示例 |
|----------|------|------|
| Happy Path | 业务主流程正常执行 | 用户注册 → 登录 → 创建订单 |
| 异常流程 | 异常和降级场景 | 库存不足拒绝下单 |
| 权限流程 | 认证和授权 | 未登录跳转登录页、无权限显示 403 |
| 数据流转 | 跨模块数据一致性 | 下单后库存扣减、订单记录、消息发送 |

**代码模板 — E2E 测试**：
```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
@ExtendWith(PlaywrightExtension.class)
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@DisplayName("E2E 全链路测试")
class UserManagementE2ETest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16")
            .withDatabaseName("e2e_test")
            .withUsername("e2e_user")
            .withPassword("e2e_pass");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @LocalServerPort
    private int port;

    static Page page;
    static BrowserContext context;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private OrderRepository orderRepository;

    @BeforeAll
    static void launchBrowser(Playwright playwright) {
        Browser browser = playwright.chromium().launch(
            new BrowserType.LaunchOptions().setHeadless(true)
        );
        context = browser.newContext();
        page = context.newPage();
    }

    @Test
    @Order(1)
    @DisplayName("完整用户流程：注册 -> 登录 -> 创建订单 -> 登出")
    void completeUserFlow_RegisterLoginCreateOrderLogout_Success() {
        String baseUrl = "http://localhost:" + port;

        // ====== Step 1: 用户注册 ======
        page.navigate(baseUrl + "/register");

        RegisterPage registerPage = new RegisterPage(page);
        registerPage
            .enterUsername("e2euser")
            .enterEmail("e2e@test.com")
            .enterPassword("Pass123!")
            .enterConfirmPassword("Pass123!")
            .acceptTerms()
            .clickRegister();

        // 验证注册成功消息
        assertThat(page.locator(".alert-success").textContent())
            .contains("Registration successful");

        // 验证数据库
        Optional<UserEntity> user = userRepository.findByUsername("e2euser");
        assertThat(user).isPresent();
        Long userId = user.get().getId();

        // ====== Step 2: 用户登录 ======
        page.navigate(baseUrl + "/login");

        LoginPage loginPage = new LoginPage(page);
        loginPage
            .enterUsername("e2euser")
            .enterPassword("Pass123!")
            .clickLogin();

        // 验证跳转到首页
        assertThat(page.url()).contains("/home");
        assertThat(page.locator(".welcome-message").textContent())
            .contains("e2euser");

        // ====== Step 3: 创建订单 ======
        page.navigate(baseUrl + "/orders/new");

        OrderCreatePage orderPage = new OrderCreatePage(page);
        orderPage
            .selectProduct(1)
            .setQuantity(2)
            .clickSubmit();

        // 验证订单创建成功
        assertThat(page.locator(".order-success").textContent())
            .contains("Order created successfully");

        // 验证数据库
        List<OrderEntity> orders = orderRepository.findByUserId(userId);
        assertThat(orders).hasSize(1);
        assertThat(orders.get(0).getQuantity()).isEqualTo(2);

        // ====== Step 4: 登出 ======
        page.click("#logout-button");

        // 验证跳转到登录页
        assertThat(page.url()).contains("/login");
    }

    @Test
    @Order(2)
    @DisplayName("异常流程：库存不足时下单失败")
    void createOrder_InsufficientStock_ShowsError() {
        String baseUrl = "http://localhost:" + port;

        // 先登录
        page.navigate(baseUrl + "/login");
        new LoginPage(page)
            .enterUsername("e2euser")
            .enterPassword("Pass123!")
            .clickLogin();

        // 尝试下单（库存为 0 的商品）
        page.navigate(baseUrl + "/orders/new");

        OrderCreatePage orderPage = new OrderCreatePage(page);
        orderPage
            .selectProduct(999) // 库存不足的商品
            .setQuantity(100)
            .clickSubmit();

        // 验证错误消息
        assertThat(page.locator(".alert-error").textContent())
            .contains("Insufficient stock");

        // 验证数据库没有创建订单
        UserEntity user = userRepository.findByUsername("e2euser").orElseThrow();
        List<OrderEntity> orders = orderRepository.findByUserId(user.getId());
        assertThat(orders).hasSize(1); // 仍然是之前创建的一个订单
    }

    @AfterAll
    static void closeBrowser() {
        if (context != null) {
            context.close();
        }
    }
}
```

---

### 步骤 4：生成测试代码 (Generate Test Code)

根据确认的测试用例清单，生成完整可运行的测试代码。

#### 4.1 文件组织

```
src/test/java/com/xxx/
├── integration/
│   ├── backend/                   # 后端集成测试
│   │   ├── UserBackendIntegrationTest.java
│   │   └── OrderBackendIntegrationTest.java
│   ├── api/                       # API 契约测试
│   │   ├── UserApiContractTest.java
│   │   └── OrderApiContractTest.java
│   ├── ui/                        # 前端 UI 测试
│   │   ├── LoginUITest.java
│   │   ├── RegisterUITest.java
│   │   └── pages/                 # Page Objects
│   │       ├── LoginPage.java
│   │       ├── RegisterPage.java
│   │       └── OrderCreatePage.java
│   └── e2e/                       # E2E 测试
│       ├── UserManagementE2ETest.java
│       └── OrderFlowE2ETest.java
```

#### 4.2 必须检查项

| 检查项 | 说明 |
|--------|------|
| 编译通过 | 确保所有 import 正确，代码可编译 |
| 命名规范 | 遵循 `方法名_场景_预期结果` 命名规范 |
| 注解完整 | `@DisplayName`、`@Test`、`@Order` 等注解齐全 |
| 断言充分 | 每个用例至少有一个有意义的断言 |
| 数据隔离 | E2E 测试确保数据隔离和清理 |

---

### 步骤 5：生成测试报告 (Generate Test Report)

测试用例生成完成后，输出测试报告的 Markdown 文件：

```
文件命名：integration-test-report-YYYY-MM-DD.md
存放路径：项目根目录下（与 src/ 同级）
```

报告模板：

```markdown
## 集成测试用例报告

**生成日期**：YYYY-MM-DD
**被测模块**：（本次变更涉及的模块名称）

### 测试覆盖统计

| 维度 | 数据 |
|------|------|
| 被测 API 数量 | X |
| 被测页面数量 | X |
| 后端集成测试用例数 | X |
| API 契约测试用例数 | X |
| 前端 UI 测试用例数 | X |
| E2E 测试用例数 | X |
| 总用例数 | X |

### 依赖与环境要求

| 依赖 | 版本 | 用途 |
|------|------|------|
| Spring Boot | 3.x | 应用框架 |
| JUnit 5 | 5.x | 测试框架 |
| Testcontainers | 1.x | 容器化测试 |
| Playwright Java | 1.x | UI 自动化 |
| RestAssured | 5.x | API 测试 |
```

---

### 步骤 6：生成 XMind 思维导图 (Generate XMind Mind Map)

将测试用例以 **XMind 思维导图** 的形式导出。

**复用现有脚本**：使用 `test-case/scripts/generate_xmind.py` 脚本生成 XMind 文件。

**XMind 层级结构**：

```
被测模块名称 (rootTopic)
├── 后端集成测试
│   ├── Repository 层
│   ├── Service 层
│   └── 事务测试
├── API 契约测试
│   ├── GET 端点
│   ├── POST 端点
│   └── 错误处理
├── 前端 UI 测试
│   ├── 登录页面
│   ├── 注册页面
│   └── 订单页面
└── E2E 测试
    ├── Happy Path
    ├── 异常流程
    └── 权限流程
```

---

### 步骤 7：生成辅助脚本 (Generate Support Scripts)

生成以下辅助脚本帮助用户执行和管理测试：

| 脚本名称 | 功能 |
|---------|------|
| `setup_playwright.sh` | 安装 Playwright 浏览器驱动 |
| `run_integration_tests.sh` | 执行集成测试并生成报告 |
| `init_test_project.sh` | 初始化测试项目结构 |

#### setup_playwright.sh

```bash
#!/bin/bash
# Playwright 环境安装脚本

set -e

echo "正在安装 Playwright Java 浏览器驱动..."

# 检查 Java
if ! command -v java &> /dev/null; then
    echo "错误: 未找到 Java，请先安装 JDK 11+"
    exit 1
fi

# 检查 Maven
if ! command -v mvn &> /dev/null; then
    echo "错误: 未找到 Maven"
    exit 1
fi

# 安装 Playwright 浏览器
echo "正在下载并安装 Playwright 浏览器..."
mvn exec:java -e -D exec.mainClass=com.microsoft.playwright.CLI -D exec.args="install"

echo "Playwright 环境安装完成!"
echo "已安装的浏览器: Chromium, Firefox, WebKit"
```

#### run_integration_tests.sh

```bash
#!/bin/bash
# 集成测试执行脚本

set -e

TEST_TYPE=${1:-"all"}  # all, backend, api, ui, e2e
REPORT_DIR="target/test-reports"

echo "开始执行集成测试..."
echo "测试类型: $TEST_TYPE"

# 清理旧报告
rm -rf $REPORT_DIR
mkdir -p $REPORT_DIR

case $TEST_TYPE in
    backend)
        echo "执行后端集成测试..."
        mvn test -Dtest=*BackendIntegrationTest -DfailIfNoTests=false
        ;;
    api)
        echo "执行 API 契约测试..."
        mvn test -Dtest=*ApiContractTest -DfailIfNoTests=false
        ;;
    ui)
        echo "执行前端 UI 测试..."
        mvn test -Dtest=*UITest -DfailIfNoTests=false
        ;;
    e2e)
        echo "执行 E2E 测试..."
        mvn verify -Dtest=*E2ETest -DfailIfNoTests=false
        ;;
    all)
        echo "执行全部集成测试..."
        mvn verify
        ;;
esac

echo "测试执行完成，报告位于: $REPORT_DIR"
```

#### init_test_project.sh

```bash
#!/bin/bash
# 测试项目初始化脚本

set -e

echo "初始化集成测试项目结构..."

# 创建目录
mkdir -p src/test/java/com/xxx/integration/{backend,api,ui/pages,e2e}
mkdir -p src/test/resources/sql
mkdir -p src/test/resources/schemas

echo "✅ 目录结构创建完成"
echo "📁 已创建以下目录："
echo "   - src/test/java/.../integration/backend/"
echo "   - src/test/java/.../integration/api/"
echo "   - src/test/java/.../integration/ui/pages/"
echo "   - src/test/java/.../integration/e2e/"
echo "   - src/test/resources/sql/"
echo "   - src/test/resources/schemas/"
```

---

## 附加规则 (Additional Rules)

1.  **语言**：测试代码中的 `@DisplayName` 使用中文，方法命名使用英文（遵循 `方法名_场景_预期结果` 格式），报告使用中文。
2.  **AAA 模式**：所有测试方法必须遵循 **Arrange → Act → Assert** 模式，使用注释标注每个阶段。
3.  **独立性**：每个测试用例必须完全独立，E2E 流程测试除外（需要按顺序执行）。
4.  **Page Object**：前端 UI 测试必须使用 Page Object Model，选择器集中在 Page Object 类中。
5.  **真实基础设施**：集成测试和 E2E 测试使用 Testcontainers 提供真实数据库，避免内存数据库的差异性。
6.  **快速反馈**：UI 测试使用无头浏览器模式，提升执行速度。
7.  **数据隔离**：每个 E2E 测试用例使用独立的测试数据，避免相互干扰。
8.  **项目适配**：生成测试代码前，先确认项目使用的 Spring Boot 版本、数据库类型和前端框架。
9.  **XMind 复用**：复用 `test-case/scripts/generate_xmind.py` 脚本生成思维导图。
10. **脚本可执行**：生成的 shell 脚本需要添加执行权限（`chmod +x`）。

---

## 与其他技能联动 (Integration)

当与其他技能联动使用时，推荐的工作流为：

1.  **开发功能** → 完成功能开发
2.  **生成集成测试** → 使用 Integration Test 技能生成集成测试
3.  **运行测试** → 执行测试并确保通过
4.  **代码审查** → 使用 Code Review 技能审查变更
5.  **提交代码** → 使用 Git Commit 技能生成提交信息

> 用户可以通过 "帮我为这个功能写集成测试" 来触发此技能。

---

## 示例应用 (Example Usage)

*   **User**: "帮我为用户模块生成集成测试"
    *   **Agent**: 执行步骤 1-7，分析用户模块并生成四层集成测试。

*   **User**: "给登录功能写前端 UI 测试"
    *   **Agent**: 聚焦步骤 3.3，生成 Playwright UI 测试和 Page Object。

*   **User**: "我需要完整的订单流程 E2E 测试"
    *   **Agent**: 聚焦步骤 3.4，生成包含 Testcontainers + Playwright 的 E2E 测试。

*   **User**: "为所有 API 生成契约测试"
    *   **Agent**: 聚焦步骤 3.2，生成 RestAssured API 契约测试。

*   **User**: "生成测试报告和 XMind 文件"
    *   **Agent**: 执行步骤 5-6，生成 Markdown 报告和 XMind 思维导图。

*   **User**: "帮我设置 Playwright 测试环境"
    *   **Agent**: 执行步骤 7，生成 `setup_playwright.sh` 脚本并指导安装。
