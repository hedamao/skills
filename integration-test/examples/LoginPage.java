package com.example.integration.ui.pages;

import com.microsoft.playwright.Page;
import com.microsoft.playwright.Locator;
import com.microsoft.playwright.options.LoadState;

import static com.microsoft.playwright.assertions.PlaywrightAssertions.assertThat;

/**
 * Page Object for: 登录页面
 *
 * 封装登录页面的所有元素定位和操作方法
 * 使用流式接口支持链式调用
 *
 * 使用示例：
 * <pre>
 * LoginPage loginPage = new LoginPage(page);
 * loginPage.enterUsername("testuser")
 *          .enterPassword("password123")
 *          .clickLogin();
 * </pre>
 */
public class LoginPage {

    private final Page page;

    // ==================== 页面元素定位器 ====================

    /** 登录表单容器 */
    private static final String LOGIN_FORM = ".login-form";

    /** 用户名输入框 */
    private static final String USERNAME_INPUT = "#username";

    /** 密码输入框 */
    private static final String PASSWORD_INPUT = "#password";

    /** 登录按钮 */
    private static final String LOGIN_BUTTON = "#login-button";

    /** 错误消息 */
    private static final String ERROR_MESSAGE = ".alert-error";

    /** 成功消息 */
    private static final String SUCCESS_MESSAGE = ".alert-success";

    /** 忘记密码链接 */
    private static final String FORGOT_PASSWORD_LINK = "a[href*='forgot-password']";

    /** 注册链接 */
    private static final String REGISTER_LINK = "a[href*='register']";

    // ==================== 页面 URL ====================

    private static final String PAGE_URL = "/login";

    // ==================== 构造函数 ====================

    /**
     * 创建 LoginPage 实例
     *
     * @param page Playwright Page 对象
     */
    public LoginPage(Page page) {
        this.page = page;
        // 等待页面关键元素出现，确保页面已加载
        page.waitForSelector(LOGIN_FORM);
    }

    /**
     * 导航到登录页面
     *
     * @param baseUrl 基础 URL (如: http://localhost:8080)
     * @return 当前 LoginPage 实例（流式接口）
     */
    public LoginPage navigate(String baseUrl) {
        page.navigate(baseUrl + PAGE_URL);
        page.waitForLoadState(LoadState.DOMCONTENTLOADED);
        return this;
    }

    /**
     * 导航到登录页面并等待网络空闲
     *
     * @param baseUrl 基础 URL
     * @return 当前 LoginPage 实例（流式接口）
     */
    public LoginPage navigateAndWait(String baseUrl) {
        page.navigate(baseUrl + PAGE_URL);
        page.waitForLoadState(LoadState.NETWORKIDLE);
        return this;
    }

    // ==================== 表单输入方法 ====================

    /**
     * 输入用户名
     *
     * @param username 用户名
     * @return 当前 LoginPage 实例（流式接口）
     */
    public LoginPage enterUsername(String username) {
        page.fill(USERNAME_INPUT, username);
        return this;
    }

    /**
     * 输入密码
     *
     * @param password 密码
     * @return 当前 LoginPage 实例（流式接口）
     */
    public LoginPage enterPassword(String password) {
        page.fill(PASSWORD_INPUT, password);
        return this;
    }

    /**
     * 清空用户名
     *
     * @return 当前 LoginPage 实例（流式接口）
     */
    public LoginPage clearUsername() {
        page.fill(USERNAME_INPUT, "");
        return this;
    }

    /**
     * 清空密码
     *
     * @return 当前 LoginPage 实例（流式接口）
     */
    public LoginPage clearPassword() {
        page.fill(PASSWORD_INPUT, "");
        return this;
    }

    /**
     * 获取用户名输入框的值
     *
     * @return 当前输入的用户名
     */
    public String getUsername() {
        return page.inputValue(USERNAME_INPUT);
    }

    /**
     * 获取密码输入框的值
     *
     * @return 当前输入的密码
     */
    public String getPassword() {
        return page.inputValue(PASSWORD_INPUT);
    }

    // ==================== 按钮点击方法 ====================

    /**
     * 点击登录按钮
     *
     * @return 当前 LoginPage 实例（流式接口）
     */
    public LoginPage clickLogin() {
        page.click(LOGIN_BUTTON);
        return this;
    }

    /**
     * 按下回车键提交登录（通常在密码框）
     *
     * @return 当前 LoginPage 实例（流式接口）
     */
    public LoginPage pressEnterToLogin() {
        page.press(PASSWORD_INPUT, "Enter");
        return this;
    }

    /**
     * 点击忘记密码链接
     *
     * @return 当前 LoginPage 实例（流式接口）
     */
    public LoginPage clickForgotPassword() {
        page.click(FORGOT_PASSWORD_LINK);
        return this;
    }

    /**
     * 点击注册链接
     *
     * @return 当前 LoginPage 实例（流式接口）
     */
    public LoginPage clickRegister() {
        page.click(REGISTER_LINK);
        return this;
    }

    // ==================== 断言辅助方法 ====================

    /**
     * 断言当前在登录页面上
     *
     * @return 当前 LoginPage 实例（流式接口）
     */
    public LoginPage assertOnPage() {
        assertThat(page.locator(LOGIN_FORM)).isVisible();
        return this;
    }

    /**
     * 断言登录按钮可点击
     *
     * @return 当前 LoginPage 实例（流式接口）
     */
    public LoginPage assertLoginButtonEnabled() {
        assertThat(page.locator(LOGIN_BUTTON)).isEnabled();
        return this;
    }

    /**
     * 断言错误消息显示
     *
     * @param expectedErrorMessage 期望的错误消息
     * @return 当前 LoginPage 实例（流式接口）
     */
    public LoginPage assertErrorMessageShown(String expectedErrorMessage) {
        assertThat(page.locator(ERROR_MESSAGE)).isVisible();
        assertThat(page.locator(ERROR_MESSAGE).textContent())
            .contains(expectedErrorMessage);
        return this;
    }

    /**
     * 断言成功消息显示
     *
     * @param expectedSuccessMessage 期望的成功消息
     * @return 当前 LoginPage 实例（流式接口）
     */
    public LoginPage assertSuccessMessageShown(String expectedSuccessMessage) {
        assertThat(page.locator(SUCCESS_MESSAGE)).isVisible();
        assertThat(page.locator(SUCCESS_MESSAGE).textContent())
            .contains(expectedSuccessMessage);
        return this;
    }

    /**
     * 断言任何错误消息存在
     *
     * @return 当前 LoginPage 实例（流式接口）
     */
    public LoginPage assertHasError() {
        assertThat(page.locator(ERROR_MESSAGE)).isVisible();
        return this;
    }

    /**
     * 断言没有错误消息
     *
     * @return 当前 LoginPage 实例（流式接口）
     */
    public LoginPage assertNoError() {
        assertThat(page.locator(ERROR_MESSAGE)).not().isVisible();
        return this;
    }

    // ==================== 元素访问器 ====================

    /**
     * 获取错误消息的 Locator
     *
     * @return Playwright Locator 对象
     */
    public Locator errorMessage() {
        return page.locator(ERROR_MESSAGE);
    }

    /**
     * 获取错误消息的文本内容
     *
     * @return 错误消息文本
     */
    public String getErrorMessageText() {
        Locator errorLocator = page.locator(ERROR_MESSAGE);
        return errorLocator.isVisible() ? errorLocator.textContent() : "";
    }

    /**
     * 判断错误消息是否可见
     *
     * @return true 如果错误消息可见
     */
    public boolean isErrorVisible() {
        return page.locator(ERROR_MESSAGE).isVisible();
    }

    /**
     * 获取登录按钮的 Locator
     *
     * @return Playwright Locator 对象
     */
    public Locator loginButton() {
        return page.locator(LOGIN_BUTTON);
    }

    /**
     * 判断登录按钮是否启用
     *
     * @return true 如果登录按钮可用
     */
    public boolean isLoginButtonEnabled() {
        return page.locator(LOGIN_BUTTON).isEnabled();
    }

    // ==================== 等待方法 ====================

    /**
     * 等待页面导航完成
     *
     * @return 当前 LoginPage 实例（流式接口）
     */
    public LoginPage waitForNavigation() {
        page.waitForLoadState(LoadState.LOAD);
        return this;
    }

    /**
     * 等待网络空闲（所有请求完成）
     *
     * @return 当前 LoginPage 实例（流式接口）
     */
    public LoginPage waitForNetworkIdle() {
        page.waitForLoadState(LoadState.NETWORKIDLE);
        return this;
    }

    /**
     * 等待错误消息出现
     *
     * @return 当前 LoginPage 实例（流式接口）
     */
    public LoginPage waitForError() {
        page.waitForSelector(ERROR_MESSAGE);
        return this;
    }

    // ==================== 自定义操作方法 ====================

    /**
     * 执行完整的登录流程
     *
     * @param username 用户名
     * @param password 密码
     * @return 当前 LoginPage 实例（流式接口）
     */
    public LoginPage login(String username, String password) {
        return enterUsername(username)
                .enterPassword(password)
                .clickLogin();
    }

    /**
     * 检查当前 URL 是否包含指定路径
     *
     * @param expectedPath 期望的路径
     * @return true 如果当前 URL 包含期望路径
     */
    public boolean isAtPath(String expectedPath) {
        return page.url().contains(expectedPath);
    }
}
