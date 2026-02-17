#!/bin/bash
################################################################################
# 集成测试项目初始化脚本
#
# 功能：
#   1. 创建标准化的测试目录结构
#   2. 生成基础的测试配置文件
#   3. 提供快速开始模板
#
# 使用方法：
#   bash scripts/init_test_project.sh [package_name]
#
# 示例：
#   bash scripts/init_test_project.sh com.example.demo
################################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_step() {
    echo ""
    echo -e "${BLUE}==>${NC} $1"
    echo "=================================="
}

# 默认包名
DEFAULT_PACKAGE="com.example"

# 解析参数
PACKAGE_NAME=${1:-$DEFAULT_PACKAGE}

# 将包名转换为路径
PACKAGE_PATH=$(echo $PACKAGE_NAME | tr '.' '/')

print_step "初始化集成测试项目"
echo "包名: $PACKAGE_NAME"
echo "路径: $PACKAGE_PATH"
echo ""

# 检查是否在正确的项目根目录
if [ ! -f "pom.xml" ] && [ ! -f "build.gradle" ] && [ ! -f "build.gradle.kts" ]; then
    print_warn "未检测到 pom.xml 或 build.gradle"
    print_warn "请确保在项目根目录下运行此脚本"
    read -p "是否继续? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 创建目录结构
print_step "创建测试目录结构"

directories=(
    "src/test/java/$PACKAGE_PATH/integration/backend"
    "src/test/java/$PACKAGE_PATH/integration/api"
    "src/test/java/$PACKAGE_PATH/integration/ui/pages"
    "src/test/java/$PACKAGE_PATH/e2e"
    "src/test/resources/sql"
    "src/test/resources/schemas"
    "src/test/resources/data"
)

for dir in "${directories[@]}"; do
    mkdir -p "$dir"
    print_info "创建: $dir"
done

# 创建 README 文件
print_step "创建测试说明文档"

cat > src/test/java/$PACKAGE_PATH/integration/README.md << 'EOF'
# 集成测试目录说明

本目录包含 Spring Boot 应用的集成测试。

## 目录结构

```
integration/
├── backend/          # 后端集成测试
│   └── *BackendIntegrationTest.java
├── api/              # API 契约测试
│   └── *ApiContractTest.java
├── ui/               # 前端 UI 测试
│   ├── *UITest.java
│   └── pages/        # Page Object Model
│       └── *Page.java
└── ../e2e/           # E2E 测试
    └── *E2ETest.java
```

## 测试分层

| 层次 | 说明 | 技术栈 |
|------|------|--------|
| Backend | 后端集成测试 | @SpringBootTest + Testcontainers |
| API | REST API 契约测试 | RestAssured |
| UI | 前端 UI 测试 | Playwright Java |
| E2E | 端到端测试 | Testcontainers + Playwright |

## 运行测试

```bash
# 运行所有集成测试
./scripts/run_integration_tests.sh all

# 只运行后端集成测试
./scripts/run_integration_tests.sh backend

# 只运行 UI 测试
./scripts/run_integration_tests.sh ui

# 只运行 E2E 测试
./scripts/run_integration_tests.sh e2e
```
EOF

print_info "创建: src/test/java/$PACKAGE_PATH/integration/README.md"

# 创建示例测试基类
print_step "创建测试基类"

# 创建基础测试配置类
cat > src/test/java/$PACKAGE_PATH/integration/AbstractIntegrationTest.java << EOF
package $PACKAGE_NAME.integration;

import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * 集成测试基类
 *
 * 提供通用的测试配置和工具方法
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@Testcontainers
@ActiveProfiles("test")
public abstract class AbstractIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16")
            .withDatabaseName("test_db")
            .withUsername("test_user")
            .withPassword("test_pass");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired(required = false)
    protected MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        // 子类可以覆盖此方法进行额外的设置
    }
}
EOF

print_info "创建: src/test/java/$PACKAGE_PATH/integration/AbstractIntegrationTest.java"

# 创建抽象 UI 测试基类
cat > src/test/java/$PACKAGE_PATH/integration/AbstractUITest.java << EOF
package $PACKAGE_NAME.integration;

import com.microsoft.playwright.Browser;
import com.microsoft.playwright.BrowserContext;
import com.microsoft.playwright.BrowserType;
import com.microsoft.playwright.Page;
import com.microsoft.playwright.Playwright;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.web.server.LocalServerPort;

/**
 * UI 测试基类
 *
 * 提供浏览器初始化和通用 UI 测试方法
 */
public abstract class AbstractUITest {

    static Playwright playwright;
    static Browser browser;
    static BrowserContext context;

    @Autowired
    protected Page page;

    @LocalServerPort
    protected int port;

    protected String baseUrl;

    @BeforeAll
    static void launchBrowser() {
        playwright = Playwright.create();
        browser = playwright.chromium().launch(
            new BrowserType.LaunchOptions()
                .setHeadless(true)
                .setSlowMo(0)
        );
    }

    @AfterAll
    static void closeBrowser() {
        if (context != null) {
            context.close();
        }
        if (browser != null) {
            browser.close();
        }
        if (playwright != null) {
            playwright.close();
        }
    }

    @BeforeEach
    void setUpPage() {
        if (context != null) {
            context.clearCookies();
        }
        context = browser.newContext(
            new Browser.NewContextOptions()
                .setViewportSize(1280, 720)
        );
        page = context.newPage();
        baseUrl = "http://localhost:" + port;
    }
}
EOF

print_info "创建: src/test/java/$PACKAGE_PATH/integration/AbstractUITest.java"

# 创建测试配置文件
print_step "创建测试配置文件"

# 创建 application-test.yml
if [ ! -f "src/test/resources/application-test.yml" ]; then
    cat > src/test/resources/application-test.yml << 'EOF'
spring:
  datasource:
    url: ${TEST_DB_URL}
    username: ${TEST_DB_USER}
    password: ${TEST_DB_PASSWORD}

  jpa:
    hibernate:
      ddl-auto: create-drop
    show-sql: false
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
        format_sql: true

  # 禁用 Spring Boot 重启功能
  devtools:
    restart:
      enabled: false

logging:
  level:
    root: INFO
    ${PACKAGE_NAME}: DEBUG
    org.testcontainers: INFO
EOF
    print_info "创建: src/test/resources/application-test.yml"
fi

# 创建 logback-test.xml
if [ ! -f "src/test/resources/logback-test.xml" ]; then
    cat > src/test/resources/logback-test.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>

    <logger name="${PACKAGE_NAME}" level="DEBUG"/>
    <logger name="org.testcontainers" level="INFO"/>

    <root level="INFO">
        <appender-ref ref="STDOUT"/>
    </root>
</configuration>
EOF
    print_info "创建: src/test/resources/logback-test.xml"
fi

# 创建示例 SQL 脚本
cat > src/test/resources/sql/example-data.sql << 'EOF'
-- 示例测试数据脚本
-- 使用 @Sql("/sql/example-data.sql") 注解加载

-- 清空现有数据
DELETE FROM users WHERE username LIKE 'test_%';

-- 插入测试用户
INSERT INTO users (username, email, password, created_at) VALUES
    ('test_user_1', 'test1@example.com', '$2a$10$encrypted', NOW()),
    ('test_user_2', 'test2@example.com', '$2a$10$encrypted', NOW());
EOF
print_info "创建: src/test/resources/sql/example-data.sql"

# 创建示例 JSON Schema
cat > src/test/resources/schemas/user-response-schema.json << 'EOF'
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["id", "username", "email"],
  "properties": {
    "id": {
      "type": "integer",
      "minimum": 1
    },
    "username": {
      "type": "string",
      "minLength": 3,
      "maxLength": 50
    },
    "email": {
      "type": "string",
      "format": "email"
    },
    "createdAt": {
      "type": "string",
      "format": "date-time"
    }
  }
}
EOF
print_info "创建: src/test/resources/schemas/user-response-schema.json"

# 打印完成信息
print_step "初始化完成"

echo ""
echo "✓ 集成测试项目结构已创建"
echo ""
echo "下一步操作:"
echo ""
echo "1. 添加必要的测试依赖到 pom.xml 或 build.gradle:"
echo ""
if [ -f "pom.xml" ]; then
    echo "   <!-- Testcontainers -->"
    echo "   <dependency>"
    echo "       <groupId>org.testcontainers</groupId>"
    echo "       <artifactId>postgresql</artifactId>"
    echo "       <version>1.20.0</version>"
    echo "       <scope>test</scope>"
    echo "   </dependency>"
    echo ""
    echo "   <!-- RestAssured -->"
    echo "   <dependency>"
    echo "       <groupId>io.rest-assured</groupId>"
    echo "       <artifactId>rest-assured</artifactId>"
    echo "       <version>5.4.0</version>"
    echo "       <scope>test</scope>"
    echo "   </dependency>"
    echo ""
    echo "   <!-- Playwright -->"
    echo "   <dependency>"
    echo "       <groupId>com.microsoft.playwright</groupId>"
    echo "       <artifactId>playwright</artifactId>"
    echo "       <version>1.48.0</version>"
    echo "       <scope>test</scope>"
    echo "   </dependency>"
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    echo "   testImplementation 'org.testcontainers:postgresql:1.20.0'"
    echo "   testImplementation 'io.rest-assured:rest-assured:5.4.0'"
    echo "   testImplementation 'com.microsoft.playwright:playwright:1.48.0'"
fi
echo ""
echo "2. 安装 Playwright 浏览器:"
echo "   bash scripts/setup_playwright.sh"
echo ""
echo "3. 运行集成测试:"
echo "   bash scripts/run_integration_tests.sh"
echo ""
echo "4. 查看测试基类:"
echo "   src/test/java/$PACKAGE_PATH/integration/AbstractIntegrationTest.java"
echo "   src/test/java/$PACKAGE_PATH/integration/AbstractUITest.java"
echo ""
