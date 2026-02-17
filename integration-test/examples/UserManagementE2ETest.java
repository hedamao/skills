package com.example.e2e;

import com.microsoft.playwright.Browser;
import com.microsoft.playwright.BrowserContext;
import com.microsoft.playwright.BrowserType;
import com.microsoft.playwright.Page;
import com.microsoft.playwright.Playwright;
import com.microsoft.playwright.options.LoadState;
import com.example.entity.UserEntity;
import com.example.repository.UserRepository;
import com.example.integration.ui.pages.LoginPage;
import com.example.integration.ui.pages.RegisterPage;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.Optional;

import static com.microsoft.playwright.assertions.PlaywrightAssertions.assertThat;
import static org.assertj.core.api.Assertions.*;

/**
 * 用户管理 E2E 测试示例
 *
 * 演示如何使用 Testcontainers + Playwright 进行端到端测试
 * 验证从用户操作到数据库落库的完整业务流程
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@DisplayName("用户管理 E2E 测试")
class UserManagementE2ETest {

    @LocalServerPort
    private int port;

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

    static Page page;
    static BrowserContext context;

    @Autowired
    private UserRepository userRepository;

    private final String baseUrl = "http://localhost:" + port;

    @BeforeAll
    static void launchBrowser(Playwright playwright) {
        Browser browser = playwright.chromium().launch(
            new BrowserType.LaunchOptions()
                .setHeadless(true)
                .setSlowMo(0)
        );
        context = browser.newContext(
            new Browser.NewContextOptions()
                .setViewportSize(1280, 720)
        );
        page = context.newPage();
    }

    @BeforeEach
    void setUp() {
        context.clearCookies();
        page.evaluate("() => localStorage.clear()");
    }

    @Test
    @Order(1)
    @DisplayName("完整流程：注册 -> 登录 -> 查看个人资料 -> 登出")
    void completeFlow_RegisterLoginProfileLogout_Success() {
        // ====== Step 1: 用户注册 ======
        page.navigate(baseUrl + "/register");

        RegisterPage registerPage = new RegisterPage(page);
        registerPage
            .enterUsername("e2e_test_user")
            .enterEmail("e2e_test@example.com")
            .enterPassword("SecurePass123!")
            .enterConfirmPassword("SecurePass123!")
            .acceptTerms()
            .clickRegister();

        // 验证注册成功消息
        assertThat(page.locator(".alert-success")).isVisible();
        assertThat(page.locator(".alert-success").textContent())
            .contains("Registration successful");

        // 验证数据库
        Optional<UserEntity> user = userRepository.findByUsername("e2e_test_user");
        assertThat(user).isPresent();
        assertThat(user.get().getEmail()).isEqualTo("e2e_test@example.com");
        Long userId = user.get().getId();

        // ====== Step 2: 用户登录 ======
        page.navigate(baseUrl + "/login");

        LoginPage loginPage = new LoginPage(page);
        loginPage
            .enterUsername("e2e_test_user")
            .enterPassword("SecurePass123!")
            .clickLogin();

        // 验证跳转到首页
        assertThat(page.url()).contains("/home");
        assertThat(page.locator(".welcome-message").textContent())
            .contains("e2e_test_user");

        // ====== Step 3: 查看个人资料 ======
        page.click("#profile-link");
        page.waitForLoadState(LoadState.NETWORKIDLE);

        // 验证资料页显示正确信息
        assertThat(page.url()).contains("/profile");
        assertThat(page.locator("#profile-username").textContent())
            .contains("e2e_test_user");
        assertThat(page.locator("#profile-email").textContent())
            .contains("e2e_test@example.com");

        // ====== Step 4: 登出 ======
        page.click("#logout-button");
        page.waitForLoadState(LoadState.NETWORKIDLE);

        // 验证跳转到登录页
        assertThat(page.url()).contains("/login");
        assertThat(page.locator(LOGIN_FORM)).isVisible();
    }

    @Test
    @Order(2)
    @DisplayName("异常流程：使用已存在的用户名注册")
    void register_DuplicateUsername_ShowsError() {
        // Arrange - 先创建一个用户
        UserEntity existing = new UserEntity();
        existing.setUsername("existing_user");
        existing.setEmail("existing@example.com");
        existing.setPassword("hashed");
        userRepository.save(existing);

        // Act
        page.navigate(baseUrl + "/register");

        RegisterPage registerPage = new RegisterPage(page);
        registerPage
            .enterUsername("existing_user")
            .enterEmail("another@example.com")
            .enterPassword("Password123!")
            .enterConfirmPassword("Password123!")
            .acceptTerms()
            .clickRegister();

        // Assert - 验证错误消息
        assertThat(page.locator(".alert-error")).isVisible();
        assertThat(page.locator(".alert-error").textContent())
            .contains("Username already exists");

        // Assert - 验证数据库没有创建新记录
        long count = userRepository.count();
        assertThat(count).isEqualTo(1);
    }

    @Test
    @Order(3)
    @DisplayName("异常流程：使用错误的凭证登录")
    void login_InvalidCredentials_ShowsError() {
        // Arrange - 先创建一个用户
        UserEntity user = new UserEntity();
        user.setUsername("login_test_user");
        user.setEmail("login@example.com");
        user.setPassword("encoded_password");
        userRepository.save(user);

        // Act - 使用错误密码登录
        page.navigate(baseUrl + "/login");

        LoginPage loginPage = new LoginPage(page);
        loginPage
            .enterUsername("login_test_user")
            .enterPassword("WrongPassword123!")
            .clickLogin();

        // Assert - 验证错误消息
        assertThat(page.locator(".alert-error")).isVisible();
        assertThat(page.locator(".alert-error").textContent())
            .contains("Invalid credentials");

        // Assert - 验证仍在登录页
        assertThat(page.url()).contains("/login");
    }

    @Test
    @Order(4)
    @DisplayName("权限流程：未登录用户访问受保护页面被重定向")
    void protectedPage_UnauthenticatedUser_RedirectsToLogin() {
        // Act - 尝试直接访问受保护页面
        page.navigate(baseUrl + "/profile");

        // Assert - 验证被重定向到登录页
        assertThat(page.url()).contains("/login");
        assertThat(page.locator(".alert-info")).isVisible();
        assertThat(page.locator(".alert-info").textContent())
            .contains("Please login to continue");
    }

    @Test
    @Order(5)
    @DisplayName("表单验证：注册时密码不匹配显示错误")
    void register_PasswordMismatch_ShowsValidationError() {
        // Arrange
        page.navigate(baseUrl + "/register");

        // Act
        RegisterPage registerPage = new RegisterPage(page);
        registerPage
            .enterUsername("validation_user")
            .enterEmail("validation@example.com")
            .enterPassword("Password123!")
            .enterConfirmPassword("DifferentPassword123!")
            .acceptTerms()
            .clickRegister();

        // Assert - 验证客户端验证错误
        assertThat(page.locator("#password-mismatch-error")).isVisible();
        assertThat(page.locator("#password-mismatch-error").textContent())
            .contains("Passwords do not match");

        // 验证没有发送请求（数据库无变化）
        assertThat(userRepository.findByUsername("validation_user")).isEmpty();
    }

    @AfterAll
    static void closeBrowser() {
        if (context != null) {
            context.close();
        }
    }
}
