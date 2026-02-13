---
name: test-case
description: 根据代码变更或业务需求，自动分析被测目标，生成结构化的测试用例（含单元测试、集成测试、端到端测试），并输出可直接运行的测试代码和 XMind 思维导图文件，确保代码变更的质量和可靠性。
---

# Test Case Generator (测试用例生成助手)

## 技能描述 (Description)

此技能帮助 Agent 根据代码变更（`git diff`）、源代码文件或业务需求文档，自动分析被测目标的逻辑结构、依赖关系和业务场景，生成覆盖 **单元测试 (Unit Test)**、**集成测试 (Integration Test)** 和 **端到端测试 (E2E Test)** 三个层次的结构化测试用例，并输出可直接运行的测试代码。同时支持将测试用例导出为 **XMind 思维导图**（`.xmind` 文件），方便团队可视化评审和管理测试用例。

**适用技术栈**：Spring Boot（含 Spring MVC、Spring Data JPA / MyBatis、Spring Security 等生态组件），测试框架：JUnit 5 + Mockito + Spring Boot Test + MockMvc / RestAssured / TestRestTemplate。

---

## 执行指令 (Instructions)

当用户要求你生成测试用例时，请严格按照以下步骤执行：

### 步骤 1：确定测试目标 (Identify Test Target)

根据用户的输入确定要为哪些代码生成测试：

```bash
# 场景 A：基于当前代码变更生成测试
git diff --cached --stat
git diff --cached
git diff --stat
git diff

# 场景 B：基于某次提交生成测试
git show <commit-hash> --stat
git show <commit-hash>

# 场景 C：基于指定文件生成测试
# 直接读取用户指定的源文件

# 场景 D：基于某个分支的变更生成测试
git diff <target-branch>...<feature-branch> --stat
git diff <target-branch>...<feature-branch>
```

> **注意**：如果用户已明确指定了目标文件或代码片段，可跳过此步骤。

### 步骤 2：分析被测代码 (Analyze Code Under Test)

对目标代码进行深入分析，建立以下理解：

#### 2.1 结构分析

| 分析项 | 说明 |
|--------|------|
| 类职责 | 被测类的核心职责是什么？属于 Controller / Service / Repository / Component 中的哪一层？ |
| 公共方法 | 列出所有需要测试的 `public` 方法及其签名 |
| 依赖关系 | 该类依赖了哪些 Bean（通过构造器注入或 `@Autowired`）？哪些需要 Mock？ |
| 输入/输出 | 每个方法的输入参数和返回值类型是什么？ |
| 异常路径 | 方法可能抛出哪些异常？有哪些防御性校验逻辑？ |

#### 2.2 业务逻辑分析

| 分析项 | 说明 |
|--------|------|
| 核心业务流程 | 主要的业务逻辑路径是什么？ |
| 分支条件 | 有哪些 `if/else`、`switch` 等分支逻辑？ |
| 边界条件 | 存在哪些边界值？（null、空集合、最大/最小值、零值等） |
| 状态变化 | 方法执行后会产生哪些状态变化？（数据库变更、缓存更新、消息发送等） |
| 事务边界 | 是否涉及 `@Transactional`？事务的边界和回滚条件是什么？ |

### 步骤 3：设计测试用例 (Design Test Cases)

按照 **测试金字塔** 原则，从三个层次设计测试用例：

```
        ╱╲
       ╱E2E╲          ← 少量关键端到端场景
      ╱──────╲
     ╱集成测试 ╲        ← 适量模块间交互验证
    ╱──────────╲
   ╱  单元测试   ╲      ← 大量核心逻辑覆盖
  ╱──────────────╲
```

---

#### 🧪 3.1 单元测试 (Unit Test)

**目标**：验证单个类/方法的内部逻辑正确性，完全隔离外部依赖。

**技术选型**：
- 框架：JUnit 5 (`@Test`, `@DisplayName`, `@ParameterizedTest`)
- Mock：Mockito (`@Mock`, `@InjectMocks`, `@ExtendWith(MockitoExtension.class)`)
- 断言：AssertJ 或 JUnit 5 Assertions

**用例设计原则**：

| 原则 | 说明 |
|------|------|
| 方法级覆盖 | 每个 public 方法至少一个正向用例 |
| 分支覆盖 | 每个 `if/else` 分支至少一个用例 |
| 边界值 | null、空字符串、空集合、边界数值等 |
| 异常路径 | 预期异常的触发和捕获 |
| 等价类划分 | 对输入空间进行等价类划分，每类至少一个用例 |

**测试命名规范**：
```
方法名_测试场景_预期结果
例：findById_UserExists_ReturnsUser
例：findById_UserNotFound_ThrowsNotFoundException
例：createOrder_InsufficientStock_ThrowsBusinessException
```

**代码模板**：
```java
@ExtendWith(MockitoExtension.class)
@DisplayName("XxxService 单元测试")
class XxxServiceTest {

    @Mock
    private XxxRepository xxxRepository;

    @Mock
    private YyyService yyyService;

    @InjectMocks
    private XxxService xxxService;

    @Test
    @DisplayName("正向场景：根据 ID 查询，数据存在时返回结果")
    void findById_DataExists_ReturnsResult() {
        // Arrange (准备)
        Long id = 1L;
        XxxEntity entity = new XxxEntity();
        entity.setId(id);
        entity.setName("test");
        when(xxxRepository.findById(id)).thenReturn(Optional.of(entity));

        // Act (执行)
        XxxDTO result = xxxService.findById(id);

        // Assert (断言)
        assertThat(result).isNotNull();
        assertThat(result.getId()).isEqualTo(id);
        assertThat(result.getName()).isEqualTo("test");
        verify(xxxRepository, times(1)).findById(id);
    }

    @Test
    @DisplayName("异常场景：根据 ID 查询，数据不存在时抛出异常")
    void findById_DataNotFound_ThrowsNotFoundException() {
        // Arrange
        Long id = 999L;
        when(xxxRepository.findById(id)).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(NotFoundException.class, () -> xxxService.findById(id));
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"  ", "\t", "\n"})
    @DisplayName("边界场景：参数为空白值时抛出参数异常")
    void create_BlankName_ThrowsIllegalArgumentException(String name) {
        // Arrange
        XxxCreateRequest request = new XxxCreateRequest();
        request.setName(name);

        // Act & Assert
        assertThrows(IllegalArgumentException.class, () -> xxxService.create(request));
    }
}
```

---

#### 🔗 3.2 集成测试 (Integration Test)

**目标**：验证多个组件/模块之间的协作是否正确，包括 Spring 容器、数据库、缓存等基础设施的真实交互。

**技术选型**：
- 框架：Spring Boot Test (`@SpringBootTest`, `@DataJpaTest`, `@WebMvcTest`)
- 数据库：H2 内存数据库 / Testcontainers（推荐用于需要真实数据库的场景）
- 工具：`@Sql` 数据初始化、`@Transactional` 自动回滚、`TestEntityManager`

**测试分类与适用注解**：

| 测试类型 | 注解 | 使用场景 |
|----------|------|----------|
| Repository 层 | `@DataJpaTest` | 验证 JPA Repository 的 CRUD、自定义查询、分页等 |
| Controller 层 | `@WebMvcTest` | 验证 Controller 的请求映射、参数校验、序列化/反序列化 |
| Service + DB | `@SpringBootTest` + `@Transactional` | 验证 Service 与真实数据库的交互 |
| 缓存集成 | `@SpringBootTest` | 验证 `@Cacheable` 等缓存注解的行为 |
| 安全集成 | `@WebMvcTest` + `@WithMockUser` | 验证接口权限控制 |

**用例设计原则**：

| 原则 | 说明 |
|------|------|
| 端口与适配器 | 验证适配器（Controller/Repository）与外部系统的真实交互 |
| 数据完整性 | 验证数据库约束（唯一键、外键、非空等）是否生效 |
| 事务行为 | 验证 `@Transactional` 的传播与回滚行为 |
| 配置正确性 | 验证 Spring 配置（Bean 注入、属性绑定）是否正确 |
| API 契约 | 验证 REST API 的请求/响应格式是否符合接口约定 |

**代码模板 — Repository 集成测试**：
```java
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE) // 使用真实数据库（配合 Testcontainers）
@DisplayName("XxxRepository 集成测试")
class XxxRepositoryIntegrationTest {

    @Autowired
    private XxxRepository xxxRepository;

    @Autowired
    private TestEntityManager entityManager;

    @Test
    @DisplayName("自定义查询：按名称模糊搜索返回匹配结果")
    void findByNameContaining_MatchExists_ReturnsMatchedEntities() {
        // Arrange
        XxxEntity entity1 = new XxxEntity();
        entity1.setName("Test Alpha");
        entity1.setStatus("ACTIVE");
        entityManager.persistAndFlush(entity1);

        XxxEntity entity2 = new XxxEntity();
        entity2.setName("Test Beta");
        entity2.setStatus("ACTIVE");
        entityManager.persistAndFlush(entity2);

        XxxEntity entity3 = new XxxEntity();
        entity3.setName("Other");
        entity3.setStatus("ACTIVE");
        entityManager.persistAndFlush(entity3);

        // Act
        List<XxxEntity> result = xxxRepository.findByNameContaining("Test");

        // Assert
        assertThat(result).hasSize(2);
        assertThat(result).extracting(XxxEntity::getName)
                .containsExactlyInAnyOrder("Test Alpha", "Test Beta");
    }

    @Test
    @DisplayName("唯一约束：插入重复 code 时抛出异常")
    void save_DuplicateCode_ThrowsDataIntegrityViolationException() {
        // Arrange
        XxxEntity entity1 = new XxxEntity();
        entity1.setCode("UNIQUE_001");
        entityManager.persistAndFlush(entity1);

        XxxEntity entity2 = new XxxEntity();
        entity2.setCode("UNIQUE_001");

        // Act & Assert
        assertThrows(DataIntegrityViolationException.class,
                () -> entityManager.persistAndFlush(entity2));
    }
}
```

**代码模板 — Controller 集成测试 (MockMvc)**：
```java
@WebMvcTest(XxxController.class)
@DisplayName("XxxController 集成测试")
class XxxControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private XxxService xxxService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @DisplayName("GET /api/xxx/{id} — 正常返回数据")
    void getById_ValidId_Returns200WithData() throws Exception {
        // Arrange
        Long id = 1L;
        XxxDTO dto = new XxxDTO(id, "test", "ACTIVE");
        when(xxxService.findById(id)).thenReturn(dto);

        // Act & Assert
        mockMvc.perform(get("/api/xxx/{id}", id)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(id))
                .andExpect(jsonPath("$.name").value("test"))
                .andExpect(jsonPath("$.status").value("ACTIVE"));

        verify(xxxService).findById(id);
    }

    @Test
    @DisplayName("POST /api/xxx — 参数校验失败返回 400")
    void create_InvalidRequest_Returns400() throws Exception {
        // Arrange
        XxxCreateRequest request = new XxxCreateRequest(); // 缺少必填字段

        // Act & Assert
        mockMvc.perform(post("/api/xxx")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    @DisplayName("DELETE /api/xxx/{id} — 管理员可以删除")
    void delete_AdminRole_Returns204() throws Exception {
        // Arrange
        Long id = 1L;
        doNothing().when(xxxService).deleteById(id);

        // Act & Assert
        mockMvc.perform(delete("/api/xxx/{id}", id))
                .andExpect(status().isNoContent());
    }

    @Test
    @WithMockUser(roles = "USER")
    @DisplayName("DELETE /api/xxx/{id} — 普通用户无权删除返回 403")
    void delete_UserRole_Returns403() throws Exception {
        // Act & Assert
        mockMvc.perform(delete("/api/xxx/{id}", 1L))
                .andExpect(status().isForbidden());
    }
}
```

**代码模板 — Service 事务集成测试**：
```java
@SpringBootTest
@Transactional // 测试结束后自动回滚
@DisplayName("XxxService 事务集成测试")
class XxxServiceTransactionIntegrationTest {

    @Autowired
    private XxxService xxxService;

    @Autowired
    private XxxRepository xxxRepository;

    @Test
    @DisplayName("创建操作：成功创建后可以查询到数据")
    void create_ValidRequest_PersistsAndReturns() {
        // Arrange
        XxxCreateRequest request = new XxxCreateRequest();
        request.setName("Integration Test");
        request.setCode("INT_TEST_001");

        // Act
        XxxDTO result = xxxService.create(request);

        // Assert
        assertThat(result.getId()).isNotNull();
        Optional<XxxEntity> persisted = xxxRepository.findById(result.getId());
        assertThat(persisted).isPresent();
        assertThat(persisted.get().getName()).isEqualTo("Integration Test");
    }

    @Test
    @DisplayName("事务回滚：业务异常时数据不会被持久化")
    void create_BusinessException_RollbacksTransaction() {
        // Arrange — 构造一个会触发业务异常的请求
        XxxCreateRequest request = new XxxCreateRequest();
        request.setName("Duplicate");
        request.setCode("EXISTING_CODE"); // 假设此 code 已存在

        // 先插入一条已有数据
        xxxService.create(request);
        long countBefore = xxxRepository.count();

        // Act & Assert
        assertThrows(BusinessException.class, () -> xxxService.create(request));

        // 事务回滚，数据量应不变
        long countAfter = xxxRepository.count();
        assertThat(countAfter).isEqualTo(countBefore);
    }
}
```

---

#### 🌐 3.3 端到端测试 (End-to-End Test / E2E Test)

**目标**：模拟真实客户端请求，验证从 HTTP 入口到数据库落库的完整业务流程，确保系统各层协作正确。

**技术选型**：
- 框架：`@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)`
- HTTP 客户端：`TestRestTemplate` 或 `WebTestClient`（WebFlux 场景）
- 数据库：Testcontainers（推荐，提供真实数据库环境）
- 数据准备：`@Sql` 脚本 / `DataInitializer` 组件
- 环境：Docker（通过 Testcontainers 管理依赖容器）

**用例设计原则**：

| 原则 | 说明 |
|------|------|
| 业务场景驱动 | 每个 E2E 用例对应一个完整的业务场景（如：用户注册 → 登录 → 下单 → 支付） |
| 真实基础设施 | 使用真实的数据库、缓存、消息队列（通过 Testcontainers） |
| 完整请求链路 | 从 HTTP 请求入口验证到数据库最终状态 |
| 数据隔离 | 每个测试用例独立准备和清理数据，互不影响 |
| 核心路径优先 | 优先覆盖核心业务的 Happy Path，再补充异常路径 |

**E2E 测试场景分类**：

| 场景类型 | 说明 | 示例 |
|----------|------|------|
| Happy Path | 业务主流程的正常执行 | 用户注册成功、订单创建成功 |
| 异常/降级 | 业务异常和系统降级 | 库存不足、支付超时、服务降级 |
| 权限与安全 | 认证和授权流程 | 未登录拒绝访问、角色权限验证 |
| 并发场景 | 多线程/多用户并发操作 | 秒杀抢购、并发扣减库存 |
| 数据流转 | 跨模块的数据一致性 | 下单后库存扣减 + 订单记录 + 消息通知 |

**代码模板 — 完整业务流程 E2E 测试**：
```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@DisplayName("用户管理模块 E2E 测试")
class UserManagementE2ETest {

    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0")
            .withDatabaseName("test_db")
            .withUsername("test")
            .withPassword("test");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", mysql::getJdbcUrl);
        registry.add("spring.datasource.username", mysql::getUsername);
        registry.add("spring.datasource.password", mysql::getPassword);
    }

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private UserRepository userRepository;

    @Test
    @Order(1)
    @DisplayName("完整流程：创建用户 → 查询用户 → 更新用户 → 删除用户")
    void userCRUD_FullLifecycle_Success() {
        // ====== Step 1: 创建用户 ======
        UserCreateRequest createReq = new UserCreateRequest();
        createReq.setUsername("e2e_test_user");
        createReq.setEmail("e2e@test.com");
        createReq.setPassword("SecurePass123!");

        ResponseEntity<ApiResponse<UserDTO>> createResp = restTemplate.postForEntity(
                "/api/users",
                createReq,
                new ParameterizedTypeReference<>() {}
        );

        assertThat(createResp.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(createResp.getBody()).isNotNull();
        Long userId = createResp.getBody().getData().getId();
        assertThat(userId).isNotNull();

        // 验证数据库落库
        Optional<UserEntity> persisted = userRepository.findById(userId);
        assertThat(persisted).isPresent();
        assertThat(persisted.get().getUsername()).isEqualTo("e2e_test_user");

        // ====== Step 2: 查询用户 ======
        ResponseEntity<ApiResponse<UserDTO>> getResp = restTemplate.getForEntity(
                "/api/users/{id}",
                new ParameterizedTypeReference<>() {},
                userId
        );

        assertThat(getResp.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(getResp.getBody().getData().getUsername()).isEqualTo("e2e_test_user");

        // ====== Step 3: 更新用户 ======
        UserUpdateRequest updateReq = new UserUpdateRequest();
        updateReq.setEmail("updated_e2e@test.com");

        restTemplate.put("/api/users/{id}", updateReq, userId);

        // 验证更新生效
        UserEntity updated = userRepository.findById(userId).orElseThrow();
        assertThat(updated.getEmail()).isEqualTo("updated_e2e@test.com");

        // ====== Step 4: 删除用户 ======
        restTemplate.delete("/api/users/{id}", userId);

        // 验证删除生效
        Optional<UserEntity> deleted = userRepository.findById(userId);
        assertThat(deleted).isEmpty();
    }

    @Test
    @Order(2)
    @DisplayName("异常场景：创建用户时用户名已存在返回 409")
    void createUser_DuplicateUsername_Returns409() {
        // Arrange — 先创建一个用户
        UserCreateRequest request = new UserCreateRequest();
        request.setUsername("duplicate_user");
        request.setEmail("first@test.com");
        request.setPassword("Pass123!");
        restTemplate.postForEntity("/api/users", request, ApiResponse.class);

        // Act — 尝试用相同用户名再次创建
        UserCreateRequest duplicate = new UserCreateRequest();
        duplicate.setUsername("duplicate_user");
        duplicate.setEmail("second@test.com");
        duplicate.setPassword("Pass456!");

        ResponseEntity<ApiResponse<?>> response = restTemplate.postForEntity(
                "/api/users", duplicate, new ParameterizedTypeReference<>() {}
        );

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
    }

    @Test
    @Order(3)
    @DisplayName("安全场景：未认证用户访问受保护接口返回 401")
    void accessProtectedEndpoint_Unauthenticated_Returns401() {
        // 不携带 Token 访问受保护资源
        ResponseEntity<String> response = restTemplate.getForEntity(
                "/api/admin/dashboard", String.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }
}
```

**代码模板 — 使用 @Sql 准备数据的 E2E 测试**：
```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Sql(scripts = "/sql/init-test-data.sql", executionPhase = Sql.ExecutionPhase.BEFORE_TEST_METHOD)
@Sql(scripts = "/sql/cleanup-test-data.sql", executionPhase = Sql.ExecutionPhase.AFTER_TEST_METHOD)
@DisplayName("订单模块 E2E 测试")
class OrderE2ETest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private ProductRepository productRepository;

    @Test
    @DisplayName("下单流程：创建订单后库存扣减且订单状态正确")
    void createOrder_SufficientStock_DeductsStockAndCreatesOrder() {
        // Arrange
        Long productId = 1L; // 通过 @Sql 脚本预置，库存为 100
        OrderCreateRequest request = new OrderCreateRequest();
        request.setProductId(productId);
        request.setQuantity(5);

        // Act
        ResponseEntity<ApiResponse<OrderDTO>> response = restTemplate.postForEntity(
                "/api/orders", request, new ParameterizedTypeReference<>() {}
        );

        // Assert — 订单创建成功
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        OrderDTO order = response.getBody().getData();
        assertThat(order.getStatus()).isEqualTo("PENDING");
        assertThat(order.getQuantity()).isEqualTo(5);

        // Assert — 库存已扣减
        ProductEntity product = productRepository.findById(productId).orElseThrow();
        assertThat(product.getStock()).isEqualTo(95); // 100 - 5

        // Assert — 订单已落库
        OrderEntity persisted = orderRepository.findById(order.getId()).orElseThrow();
        assertThat(persisted.getProductId()).isEqualTo(productId);
    }
}
```

---

### 步骤 4：生成测试用例清单 (Generate Test Case Checklist)

在生成测试代码之前，先输出结构化的测试用例清单供用户确认：

---

#### 📋 测试用例清单

**被测目标**：`XxxService` / `XxxController` / 订单模块

**用例统计**：

| 测试层次 | 用例数 | 覆盖目标 |
|----------|--------|----------|
| 🧪 单元测试 | X 个 | 核心方法逻辑、边界条件、异常路径 |
| 🔗 集成测试 | X 个 | DB 交互、API 契约、权限控制、事务行为 |
| 🌐 E2E 测试 | X 个 | 核心业务流程、跨模块数据流转 |

---

**🧪 单元测试用例：**

| # | 被测方法 | 用例名称 | 场景描述 | 预期结果 |
|---|---------|---------|----------|----------|
| 1 | `findById` | findById_DataExists_ReturnsResult | 查询存在的 ID | 返回对应的 DTO 对象 |
| 2 | `findById` | findById_DataNotFound_ThrowsNotFoundException | 查询不存在的 ID | 抛出 NotFoundException |
| 3 | `create` | create_ValidRequest_ReturnsCreatedDTO | 正常创建请求 | 返回创建后的 DTO |
| 4 | `create` | create_BlankName_ThrowsIllegalArgumentException | 名称为空白 | 抛出参数校验异常 |
| 5 | `create` | create_DuplicateCode_ThrowsBusinessException | code 已存在 | 抛出业务异常 |

---

**🔗 集成测试用例：**

| # | 测试类型 | 用例名称 | 场景描述 | 预期结果 |
|---|---------|---------|----------|----------|
| 1 | Repository | findByNameContaining_MatchExists | 模糊查询有匹配 | 返回匹配的实体列表 |
| 2 | Controller | getById_ValidId_Returns200 | GET 请求正常 ID | 返回 200 + JSON 数据 |
| 3 | Controller | create_InvalidRequest_Returns400 | POST 缺少必填字段 | 返回 400 错误 |
| 4 | Security | delete_AdminRole_Returns204 | 管理员角色删除 | 返回 204 |
| 5 | Transaction | create_BusinessException_Rollbacks | 异常时事务回滚 | 数据无变化 |

---

**🌐 E2E 测试用例：**

| # | 场景类型 | 用例名称 | 场景描述 | 验证点 |
|---|---------|---------|----------|--------|
| 1 | Happy Path | userCRUD_FullLifecycle_Success | 用户完整 CRUD 流程 | HTTP 状态码 + DB 数据 |
| 2 | 异常场景 | createUser_DuplicateUsername_Returns409 | 重复用户名创建 | 返回 409 |
| 3 | 安全场景 | accessProtectedEndpoint_Unauthenticated | 未认证访问受保护接口 | 返回 401 |
| 4 | 数据流转 | createOrder_DeductsStockAndCreatesOrder | 下单 → 扣库存 → 建订单 | 多表数据一致性 |

---

### 步骤 5：生成测试代码 (Generate Test Code)

根据确认的测试用例清单，生成完整可运行的测试代码：

1. **文件组织**：
```
src/test/java/com/xxx/
├── unit/                           # 单元测试
│   ├── service/
│   │   └── XxxServiceTest.java
│   └── util/
│       └── XxxUtilTest.java
├── integration/                    # 集成测试
│   ├── repository/
│   │   └── XxxRepositoryIntegrationTest.java
│   ├── controller/
│   │   └── XxxControllerIntegrationTest.java
│   └── service/
│       └── XxxServiceTransactionIntegrationTest.java
└── e2e/                            # 端到端测试
    ├── UserManagementE2ETest.java
    └── OrderE2ETest.java
```

2. **必须检查项**：

| 检查项 | 说明 |
|--------|------|
| 编译通过 | 确保所有 import 正确，代码可编译 |
| 命名规范 | 遵循 `方法名_场景_预期结果` 命名规范 |
| 注解完整 | `@DisplayName`、`@Test`、`@Order` 等注解齐全 |
| Mock 正确 | Mock 对象的行为设置（when/then）正确完整 |
| 断言充分 | 每个用例至少有一个有意义的断言 |
| 数据清理 | E2E 测试确保数据隔离和清理 |

### 步骤 6：生成测试报告模板 (Generate Test Report Template)

测试用例生成完成后，输出测试报告的 Markdown 文件：

```
文件命名：test-cases-YYYY-MM-DD.md
存放路径：项目根目录下（与 src/ 同级）
```

报告模板：

---

#### 📊 测试用例报告

**生成日期**：YYYY-MM-DD

**被测模块**：（本次变更涉及的模块名称）

**变更摘要**：（一句话描述代码变更内容）

---

**测试覆盖统计：**

| 维度 | 数据 |
|------|------|
| 被测类数量 | X |
| 被测方法数量 | X |
| 🧪 单元测试用例数 | X |
| 🔗 集成测试用例数 | X |
| 🌐 E2E 测试用例数 | X |
| 总用例数 | X |
| 预估代码行覆盖率 | >X% |

---

**测试用例明细：**

（此处插入步骤 4 生成的完整测试用例清单表格）

---

**依赖与环境要求：**

| 依赖 | 版本 | 用途 |
|------|------|------|
| JUnit 5 | 5.x | 测试框架 |
| Mockito | 5.x | Mock 框架 |
| Spring Boot Test | X.x | Spring 集成测试 |
| H2 Database | X.x | 内存数据库（集成测试） |
| Testcontainers | 1.x | 容器化真实数据库（E2E 测试） |
| AssertJ | 3.x | 流式断言 |

---

### 步骤 7：生成 XMind 思维导图 (Generate XMind Mind Map)

将测试用例以 **XMind 思维导图** 的形式导出，便于团队评审和可视化管理。

#### 7.1 XMind 文件格式说明

`.xmind` 文件本质上是一个 **ZIP 压缩包**，其中包含一个 `content.json` 文件，用于描述思维导图的层级结构。

```
test-cases-YYYY-MM-DD.xmind  (ZIP 压缩包)
└── content.json              (思维导图数据，JSON 格式)
```

#### 7.2 content.json 数据结构

`content.json` 是一个 **JSON 数组**，每个元素代表一个 Sheet（画布），核心结构如下：

```json
[
  {
    "id": "sheet-unique-id",
    "class": "sheet",
    "title": "测试用例思维导图",
    "rootTopic": {
      "id": "root-topic-id",
      "class": "topic",
      "title": "被测模块名称",
      "structureClass": "org.xmind.ui.map.unbalanced",
      "children": {
        "attached": [
          {
            "id": "unit-test-branch-id",
            "class": "topic",
            "title": "🧪 单元测试",
            "children": {
              "attached": [
                {
                  "id": "class1-id",
                  "class": "topic",
                  "title": "XxxServiceTest",
                  "children": {
                    "attached": [
                      {
                        "id": "case1-id",
                        "class": "topic",
                        "title": "findById_DataExists_ReturnsResult",
                        "labels": ["正向"],
                        "notes": {
                          "plain": {
                            "content": "根据 ID 查询，数据存在时返回结果"
                          }
                        }
                      },
                      {
                        "id": "case2-id",
                        "class": "topic",
                        "title": "findById_DataNotFound_ThrowsNotFoundException",
                        "labels": ["异常"],
                        "notes": {
                          "plain": {
                            "content": "根据 ID 查询，数据不存在时抛出异常"
                          }
                        }
                      }
                    ]
                  }
                }
              ]
            }
          },
          {
            "id": "integration-test-branch-id",
            "class": "topic",
            "title": "🔗 集成测试",
            "children": { "attached": [] }
          },
          {
            "id": "e2e-test-branch-id",
            "class": "topic",
            "title": "🌐 E2E 测试",
            "children": { "attached": [] }
          }
        ]
      }
    }
  }
]
```

**节点属性说明**：

| 属性 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | ✅ | 节点唯一 ID，使用 UUID 或自定义唯一标识 |
| `class` | string | ✅ | 固定值 `"topic"`（根节点所在 Sheet 为 `"sheet"`） |
| `title` | string | ✅ | 节点显示文本 |
| `structureClass` | string | ❌ | 布局样式，仅 rootTopic 需要。推荐 `"org.xmind.ui.map.unbalanced"` 或 `"org.xmind.ui.logic.right"` |
| `children.attached` | array | ❌ | 子节点数组 |
| `labels` | array | ❌ | 标签数组，用于标注用例类型（如 `["正向"]`、`["异常"]`、`["边界"]`） |
| `notes.plain.content` | string | ❌ | 备注内容，用于存放用例的详细描述 |
| `markers` | array | ❌ | 图标标记，如优先级标识 `[{"markerId": "priority-1"}]` |

**常用 markers（图标标记）**：

| markerId | 说明 |
|----------|------|
| `priority-1` | 🔴 最高优先级（P0） |
| `priority-2` | 🟠 高优先级（P1） |
| `priority-3` | 🟡 中优先级（P2） |
| `priority-4` | 🟢 低优先级（P3） |
| `symbol-exclam` | ❗ 重要 |
| `symbol-question` | ❓ 待确认 |
| `task-done` | ✅ 已完成 |
| `task-start` | 🔄 进行中 |

#### 7.3 思维导图层级结构设计

按以下层级组织测试用例：

```
被测模块名称 (rootTopic)
├── 🧪 单元测试
│   ├── XxxServiceTest (被测类)
│   │   ├── findById (被测方法)
│   │   │   ├── [正向] findById_DataExists_ReturnsResult
│   │   │   ├── [异常] findById_DataNotFound_ThrowsNotFoundException
│   │   │   └── [边界] findById_NullId_ThrowsIllegalArgumentException
│   │   └── create (被测方法)
│   │       ├── [正向] create_ValidRequest_ReturnsCreatedDTO
│   │       ├── [异常] create_DuplicateCode_ThrowsBusinessException
│   │       └── [边界] create_BlankName_ThrowsIllegalArgumentException
│   └── YyyServiceTest (被测类)
│       └── ...
├── 🔗 集成测试
│   ├── Repository 层
│   │   └── XxxRepositoryIntegrationTest
│   │       ├── [查询] findByNameContaining_MatchExists
│   │       └── [约束] save_DuplicateCode_ThrowsException
│   ├── Controller 层
│   │   └── XxxControllerIntegrationTest
│   │       ├── [API] getById_ValidId_Returns200
│   │       ├── [校验] create_InvalidRequest_Returns400
│   │       └── [权限] delete_AdminRole_Returns204
│   └── Service 事务
│       └── XxxServiceTransactionIntegrationTest
│           ├── [事务] create_ValidRequest_PersistsData
│           └── [回滚] create_BusinessException_RollbacksTransaction
└── 🌐 E2E 测试
    ├── Happy Path
    │   └── userCRUD_FullLifecycle_Success
    ├── 异常场景
    │   └── createUser_DuplicateUsername_Returns409
    ├── 安全场景
    │   └── accessProtectedEndpoint_Unauthenticated_Returns401
    └── 数据流转
        └── createOrder_DeductsStockAndCreatesOrder
```

#### 7.4 XMind 文件生成脚本

生成脚本位于本技能的 `scripts/` 目录下：

```
test-case/
├── SKILL.md
└── scripts/
    └── generate_xmind.py    ← XMind 生成脚本
```

> **脚本特点**：仅使用 Python 内置库（`json`、`zipfile`、`uuid`、`argparse`），无需安装任何第三方依赖。

##### 使用方式一：命令行 — 使用内置演示数据

快速验证脚本是否正常工作：

```bash
python scripts/generate_xmind.py --demo
```

输出：
```
📋 使用内置演示数据...
✅ XMind 文件已生成：/path/to/project/test-cases-2026-02-13.xmind

📊 统计信息：
   🧪 单元测试用例：6 个
   🔗 集成测试用例：5 个
   🌐 E2E 测试用例：3 个
   📋 总计：14 个用例
```

##### 使用方式二：命令行 — 从 JSON 文件读取数据

Agent 将分析出的测试用例数据保存为 JSON 文件，然后调用脚本生成 XMind：

```bash
# 从 JSON 文件生成 XMind（输出文件名自动以当天日期命名）
python scripts/generate_xmind.py --input test-data.json

# 指定输出文件名
python scripts/generate_xmind.py --input test-data.json --output test-cases-订单模块.xmind

# 覆盖模块名称
python scripts/generate_xmind.py --input test-data.json --module "订单管理模块"
```

**JSON 数据文件格式**（`test-data.json`）：

```json
{
  "module": "用户管理模块",
  "unit_tests": [
    {
      "class": "UserServiceTest",
      "methods": [
        {
          "method": "findById",
          "cases": [
            {"name": "findById_UserExists_ReturnsUser", "type": "正向", "desc": "查询存在的用户 ID，返回用户 DTO", "priority": 2},
            {"name": "findById_UserNotFound_ThrowsNotFoundException", "type": "异常", "desc": "查询不存在的 ID，抛出 NotFoundException", "priority": 2}
          ]
        }
      ]
    }
  ],
  "integration_tests": [
    {
      "category": "Repository 层",
      "classes": [
        {
          "name": "UserRepositoryIntegrationTest",
          "cases": [
            {"name": "findByUsername_Exists_ReturnsUser", "type": "查询", "desc": "按用户名查询存在的用户"}
          ]
        }
      ]
    }
  ],
  "e2e_tests": [
    {
      "category": "Happy Path",
      "cases": [
        {"name": "userCRUD_FullLifecycle_Success", "desc": "用户完整 CRUD 流程", "priority": 1}
      ]
    }
  ]
}
```

##### 使用方式三：导出 JSON 数据模板

如果不确定 JSON 数据格式，可以先导出模板参考：

```bash
python scripts/generate_xmind.py --export-template template.json
```

##### 使用方式四：Agent 在代码中导入调用

Agent 也可以直接在 Python 代码中导入脚本的核心函数使用：

```python
import sys
sys.path.append("/path/to/test-case/scripts")

from generate_xmind import build_xmind_content, save_xmind

# 构造测试数据（Agent 根据实际代码分析结果动态填充）
unit_tests = [
    {
        "class": "OrderServiceTest",
        "methods": [
            {
                "method": "createOrder",
                "cases": [
                    {"name": "createOrder_ValidRequest_Success", "type": "正向", "desc": "正常创建订单", "priority": 1},
                    {"name": "createOrder_InsufficientStock_ThrowsException", "type": "异常", "desc": "库存不足", "priority": 1}
                ]
            }
        ]
    }
]

content = build_xmind_content("订单模块", unit_tests=unit_tests)
save_xmind(content, "test-cases-2026-02-13.xmind")
```

##### Agent 执行流程

当需要生成 XMind 文件时，Agent 应按以下流程操作：

1. **分析代码** → 执行步骤 1-4，得到结构化的测试用例清单
2. **构造 JSON 数据** → 根据用例清单构造符合格式的 JSON 数据
3. **写入 JSON 文件** → 将数据保存到项目根目录下的临时 JSON 文件（如 `test-data.json`）
4. **调用脚本** → 执行 `python <skill-path>/scripts/generate_xmind.py --input test-data.json`
5. **清理临时文件** → 可选，删除临时 JSON 文件

```bash
# Agent 完整执行命令示例
python /path/to/test-case/scripts/generate_xmind.py \
  --input test-data.json \
  --module "用户管理模块" \
  --output test-cases-2026-02-13.xmind
```

#### 7.5 生成规则

```
文件命名：test-cases-YYYY-MM-DD.xmind
存放路径：项目根目录下（与 src/ 同级，与 Markdown 报告同目录）
```

| 规则 | 说明 |
|------|------|
| 同步生成 | 每次生成测试报告（步骤 6）时，同时生成对应的 XMind 文件 |
| 命名一致 | XMind 文件名与 Markdown 报告使用相同的日期后缀 |
| 层级清晰 | 严格按照 `模块 → 测试层次 → 被测类/分类 → 被测方法 → 用例` 的层级组织 |
| 标签标注 | 每个用例节点必须使用 `labels` 标注场景类型（正向/异常/边界/查询/权限等） |
| 备注说明 | 每个用例节点的 `notes` 中放入中文的用例描述 |
| 优先级标记 | 核心用例使用 `markers` 标记优先级（P0-P3） |
| 仅用内置库 | 生成脚本仅使用 Python 内置库（`json`, `zipfile`, `uuid`, `os`），无需额外安装依赖 |

> **Agent 执行方式**：Agent 根据步骤 4 生成的测试用例清单，自动构造测试数据参数，调用上述 Python 脚本生成 `.xmind` 文件。用户也可以单独要求 "只生成 XMind 文件" 或 "把测试用例导出为思维导图"。

---

## 附加规则 (Additional Rules)

1.  **语言**：测试代码中的 `@DisplayName` 使用中文，方法命名使用英文（遵循 `方法名_场景_预期结果` 格式），报告使用中文。
2.  **AAA 模式**：所有测试方法必须遵循 **Arrange → Act → Assert** 模式，使用注释标注每个阶段。
3.  **独立性**：每个测试用例必须完全独立，不依赖执行顺序（E2E 的流程测试除外）。
4.  **测试金字塔**：单元测试数量 > 集成测试数量 > E2E 测试数量。
5.  **Mock 原则**：单元测试中只 Mock 直接依赖（一层），不要 Mock 被测类内部的私有方法。
6.  **真实数据优先**：集成测试和 E2E 测试尽量使用真实基础设施（如 Testcontainers），避免过度 Mock 导致测试失去意义。
7.  **快速反馈**：单元测试应在毫秒级完成，集成测试在秒级完成，E2E 测试应控制在分钟级以内。
8.  **边界值覆盖**：每个参数至少覆盖以下边界值：null、空字符串/空集合、正常值、边界最大值/最小值。
9.  **幂等验证**：对于写操作，需验证重复执行是否保持幂等。
10. **项目适配**：生成测试代码前，先确认项目使用的 Spring Boot 版本、测试框架版本和项目包结构，确保生成的代码与项目兼容。
11. **XMind 同步**：每次生成测试用例报告时，必须同步生成对应的 `.xmind` 思维导图文件，文件名使用相同的日期后缀。
12. **XMind 层级**：XMind 文件必须严格遵循 `模块 → 测试层次 → 被测类/分类 → 被测方法 → 用例` 的五层结构，不得跳级或合并层级。
13. **XMind 内置库**：生成 XMind 文件的脚本仅使用 Python 内置库（`json`、`zipfile`、`uuid`），不依赖任何第三方包。

## 与 Git Commit / Code Review 联动 (Integration)

当与其他技能联动使用时，推荐的工作流为：

1.  **编写代码** → 完成功能开发
2.  **生成测试** → 使用 Test Case 技能生成测试用例
3.  **运行测试** → 执行测试并确保通过
4.  **代码审查** → 使用 Code Review 技能审查变更（含测试代码）
5.  **提交代码** → 使用 Git Commit 技能生成提交信息

> 用户可以通过 "帮我为这次改动生成测试用例，然后 review，没问题就提交" 来触发联动流程。

## 示例应用 (Example Usage)

*   **User**: "帮我为这次改动生成测试用例"
    *   **Agent**: 执行步骤 1-7，分析变更代码并生成三个层次的测试用例、测试代码、Markdown 报告和 XMind 思维导图。

*   **User**: "给 UserService 的 createUser 方法写单元测试"
    *   **Agent**: 聚焦步骤 3.1，为指定方法生成全面的单元测试。

*   **User**: "我需要这个接口的集成测试，包括权限验证"
    *   **Agent**: 聚焦步骤 3.2，生成 `@WebMvcTest` + `@WithMockUser` 的集成测试。

*   **User**: "帮我写一个完整的订单流程 E2E 测试"
    *   **Agent**: 聚焦步骤 3.3，生成包含 Testcontainers 的完整业务流程 E2E 测试。

*   **User**: "给这个模块生成完整的测试用例清单，我先看看再决定生成哪些"
    *   **Agent**: 执行步骤 1-4，只输出测试用例清单，等用户确认后再生成代码。

*   **User**: "帮我为这次改动生成测试，然后 review，没问题就提交"
    *   **Agent**: 依次执行 Test Case → Code Review → Git Commit 联动流程。

*   **User**: "把测试用例导出为 XMind 思维导图"
    *   **Agent**: 执行步骤 1-4 分析并生成用例清单，然后聚焦步骤 7 生成 `.xmind` 文件。

*   **User**: "生成测试用例的 XMind 文件，不需要代码"
    *   **Agent**: 执行步骤 1-4 + 步骤 7，只输出用例清单和 XMind 文件，跳过步骤 5 的代码生成。

*   **User**: "帮我生成这个模块的测试用例思维导图，要包含优先级"
    *   **Agent**: 执行步骤 1-4 + 步骤 7，在 XMind 节点上使用 `markers` 标记用例优先级（P0-P3）。
