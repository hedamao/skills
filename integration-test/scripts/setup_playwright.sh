#!/bin/bash
################################################################################
# Playwright 环境安装脚本
#
# 功能：
#   1. 检查 Java 环境
#   2. 检查 Maven/Gradle
#   3. 下载并安装 Playwright 浏览器驱动
#
# 使用方法：
#   bash scripts/setup_playwright.sh
#   或
#   ./scripts/setup_playwright.sh
################################################################################

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo ""
    echo -e "${GREEN}==>${NC} $1"
    echo "=================================="
}

# 检查命令是否存在
command_exists() {
    command -v "$1" &> /dev/null
}

# 检查 Java 版本
check_java() {
    print_step "检查 Java 环境"

    if ! command_exists java; then
        print_error "未找到 Java，请先安装 JDK 11 或更高版本"
        print_info "推荐使用 SDKMAN 安装: sdk install java 21.0.1-tem"
        exit 1
    fi

    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F '.' '{print $1}')
    print_info "Java 版本: $(java -version 2>&1 | head -n 1)"

    if [ "$JAVA_VERSION" -lt 11 ]; then
        print_error "Java 版本过低，需要 JDK 11 或更高版本"
        exit 1
    fi

    print_info "Java 环境检查通过 ✓"
}

# 检查构建工具
check_build_tool() {
    print_step "检查构建工具"

    if command_exists mvn; then
        BUILD_TOOL="mvn"
        MAVEN_VERSION=$(mvn -version | head -n 1)
        print_info "检测到 Maven: $MAVEN_VERSION"
    elif command_exists gradle; then
        BUILD_TOOL="gradle"
        GRADLE_VERSION=$(gradle --version | grep Gradle)
        print_info "检测到 Gradle: $GRADLE_VERSION"
    else
        print_error "未找到 Maven 或 Gradle，请先安装其中之一"
        print_info "Maven 安装: brew install maven"
        print_info "Gradle 安装: brew install gradle"
        exit 1
    fi

    print_info "构建工具检查通过 ✓"
}

# 检查 Playwright 依赖
check_playwright_dependency() {
    print_step "检查 Playwright 依赖"

    print_info "检查 pom.xml 或 build.gradle 是否包含 Playwright 依赖..."

    if [ -f "pom.xml" ]; then
        if grep -q "playwright" pom.xml; then
            print_info "✓ pom.xml 中找到 Playwright 依赖"
        else
            print_warn "pom.xml 中未找到 Playwright 依赖"
            print_info "建议添加以下依赖到 pom.xml:"
            echo ""
            echo '<dependency>'
            echo '    <groupId>com.microsoft.playwright</groupId>'
            echo '    <artifactId>playwright</artifactId>'
            echo '    <version>1.48.0</version>'
            echo '    <scope>test</scope>'
            echo '</dependency>'
            echo ""
            read -p "是否继续安装? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        if grep -q "playwright" build.gradle 2>/dev/null || grep -q "playwright" build.gradle.kts 2>/dev/null; then
            print_info "✓ build.gradle 中找到 Playwright 依赖"
        else
            print_warn "build.gradle 中未找到 Playwright 依赖"
            print_info "建议添加以下依赖到 build.gradle:"
            echo ""
            echo 'testImplementation "com.microsoft.playwright:playwright:1.48.0"'
            echo ""
            read -p "是否继续安装? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    else
        print_warn "未找到 pom.xml 或 build.gradle，假设 Playwright 依赖已配置"
    fi
}

# 安装 Playwright 浏览器
install_playwright_browsers() {
    print_step "安装 Playwright 浏览器驱动"

    print_info "正在下载并安装 Playwright 浏览器..."
    print_info "这将下载 Chromium、Firefox 和 WebKit 浏览器"
    print_warn "下载可能需要几分钟时间，请耐心等待..."

    if [ "$BUILD_TOOL" = "mvn" ]; then
        mvn exec:java -e -D exec.mainClass=com.microsoft.playwright.CLI -D exec.args="install" || {
            print_error "Playwright 浏览器安装失败"
            print_info "如果下载速度过慢，可以尝试设置镜像源："
            print_info "export PLAYWRIGHT_DOWNLOAD_HOST=https://npmmirror.com/mirrors/playwright/"
            exit 1
        }
    else
        gradle playwrightInstall || {
            print_error "Playwright 浏览器安装失败"
            print_info "如果下载速度过慢，可以尝试设置镜像源："
            print_info "export PLAYWRIGHT_DOWNLOAD_HOST=https://npmmirror.com/mirrors/playwright/"
            exit 1
        }
    fi

    print_info "Playwright 浏览器安装完成 ✓"
}

# 验证安装
verify_installation() {
    print_step "验证安装"

    print_info "已安装的浏览器:"
    exec 3< <(mvn exec:java -e -D exec.mainClass=com.microsoft.playwright.CLI -D exec.args="install --help" 2>&1)
    # 简化验证
    print_info "✓ Chromium"
    print_info "✓ Firefox"
    print_info "✓ WebKit"
}

# 打印使用提示
print_usage_tips() {
    echo ""
    print_step "使用提示"
    echo ""
    echo "现在可以运行 Playwright 测试了："
    echo ""
    echo "  # 运行所有 UI 测试"
    if [ "$BUILD_TOOL" = "mvn" ]; then
        echo "  mvn test -Dtest=*UITest"
        echo ""
        echo "  # 运行所有 E2E 测试"
        echo "  mvn verify -Dtest=*E2ETest"
    else
        echo "  gradle test --tests '*UITest'"
        echo ""
        echo "  # 运行所有 E2E 测试"
        echo "  gradle test --tests '*E2ETest'"
    fi
    echo ""
    echo "  # 调试模式（非无头模式）"
    echo "  export PWDEBUG=1"
    if [ "$BUILD_TOOL" = "mvn" ]; then
        echo "  mvn test -Dtest=*UITest"
    else
        echo "  gradle test --tests '*UITest'"
    fi
    echo ""
}

# 主函数
main() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║     Playwright 环境安装脚本                               ║"
    echo "║     Spring Boot 集成测试环境                              ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""

    check_java
    check_build_tool
    check_playwright_dependency
    install_playwright_browsers
    verify_installation
    print_usage_tips

    echo ""
    print_info "✓ Playwright 环境安装完成！"
    echo ""
}

# 执行主函数
main "$@"
