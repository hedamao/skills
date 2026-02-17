#!/bin/bash
################################################################################
# 集成测试执行脚本
#
# 功能：
#   1. 执行指定类型的集成测试
#   2. 生成测试报告
#   3. 支持并行执行
#
# 使用方法：
#   bash scripts/run_integration_tests.sh [type]
#   type: all | backend | api | ui | e2e
#   默认: all
#
# 示例：
#   ./scripts/run_integration_tests.sh backend   # 只执行后端集成测试
#   ./scripts/run_integration_tests.sh ui        # 只执行前端 UI 测试
#   ./scripts/run_integration_tests.sh all       # 执行全部测试
################################################################################

set -e  # 遇到错误立即退出

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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo ""
    echo -e "${BLUE}==>${NC} $1"
    echo "=================================="
}

# 显示使用说明
show_usage() {
    echo "集成测试执行脚本"
    echo ""
    echo "使用方法:"
    echo "  $0 [type] [options]"
    echo ""
    echo "测试类型:"
    echo "  all      执行全部集成测试 (默认)"
    echo "  backend  执行后端集成测试"
    echo "  api      执行 API 契约测试"
    echo "  ui       执行前端 UI 测试"
    echo "  e2e      执行 E2E 测试"
    echo ""
    echo "选项:"
    echo "  --parallel    并行执行测试"
    echo "  --coverage    生成代码覆盖率报告"
    echo "  --skip-build  跳过构建，直接运行测试"
    echo ""
    echo "示例:"
    echo "  $0 backend"
    echo "  $0 ui --parallel"
    echo "  $0 all --coverage"
    echo ""
}

# 解析参数
TEST_TYPE="all"
PARALLEL=""
COVERAGE=""
SKIP_BUILD=""

while [[ $# -gt 0 ]]; do
    case $1 in
        all|backend|api|ui|e2e)
            TEST_TYPE="$1"
            shift
            ;;
        --parallel)
            PARALLEL="-Dfork.count=2"
            shift
            ;;
        --coverage)
            COVERAGE="jacoco:prepare-agent test jacoco:report"
            shift
            ;;
        --skip-build)
            SKIP_BUILD="-DskipTests"
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            print_error "未知参数: $1"
            show_usage
            exit 1
            ;;
    esac
done

# 检查构建工具
detect_build_tool() {
    if [ -f "mvnw" ]; then
        BUILD_TOOL="./mvnw"
    elif command_exists mvn; then
        BUILD_TOOL="mvn"
    elif [ -f "gradlew" ]; then
        BUILD_TOOL="./gradlew"
    elif command_exists gradle; then
        BUILD_TOOL="gradle"
    else
        print_error "未找到 Maven 或 Gradle"
        exit 1
    fi

    print_info "使用构建工具: $BUILD_TOOL"
}

# 获取测试类名模式
get_test_pattern() {
    case $TEST_TYPE in
        backend)
            if [[ "$BUILD_TOOL" == *"mvn"* ]]; then
                echo "-Dtest=*BackendIntegrationTest"
            else
                echo "--tests '*BackendIntegrationTest'"
            fi
            ;;
        api)
            if [[ "$BUILD_TOOL" == *"mvn"* ]]; then
                echo "-Dtest=*ApiContractTest"
            else
                echo "--tests '*ApiContractTest'"
            fi
            ;;
        ui)
            if [[ "$BUILD_TOOL" == *"mvn"* ]]; then
                echo "-Dtest=*UITest"
            else
                echo "--tests '*UITest'"
            fi
            ;;
        e2e)
            if [[ "$BUILD_TOOL" == *"mvn"* ]]; then
                echo "-Dtest=*E2ETest"
            else
                echo "--tests '*E2ETest'"
            fi
            ;;
        all)
            if [[ "$BUILD_TOOL" == *"mvn"* ]]; then
                echo "-Dtest=*IntegrationTest,*ApiContractTest,*UITest,*E2ETest"
            else
                echo "--tests '*IntegrationTest' --tests '*ApiContractTest' --tests '*UITest' --tests '*E2ETest'"
            fi
            ;;
    esac
}

# 构建命令
build_maven_command() {
    local test_pattern=$(get_test_pattern)

    if [ -n "$COVERAGE" ]; then
        echo "$BUILD_TOOL clean $COVERAGE $test_pattern $PARALLEL"
    else
        echo "$BUILD_TOOL clean test $test_pattern $PARALLEL"
    fi
}

build_gradle_command() {
    local test_pattern=$(get_test_pattern)

    if [ -n "$PARALLEL" ]; then
        test_pattern="$test_pattern --parallel"
    fi

    if [ -n "$COVERAGE" ]; then
        echo "$BUILD_TOOL clean test $test_pattern jacocoTestReport"
    else
        echo "$BUILD_TOOL clean test $test_pattern"
    fi
}

# 执行测试
run_tests() {
    print_step "开始执行集成测试"
    echo "测试类型: $TEST_TYPE"
    [ -n "$PARALLEL" ] && echo "并行执行: 是"
    [ -n "$COVERAGE" ] && echo "代码覆盖率: 是"

    # 确保报告目录存在
    mkdir -p target/test-reports
    mkdir -p target/surefire-reports

    # 构建并执行命令
    if [[ "$BUILD_TOOL" == *"mvn"* ]]; then
        local cmd=$(build_maven_command)
    else
        local cmd=$(build_gradle_command)
    fi

    print_info "执行命令: $cmd"
    echo ""

    # 执行测试
    eval $cmd || {
        print_error "测试执行失败"
        echo ""
        print_info "查看详细日志: target/test-reports/"
        exit 1
    }

    echo ""
    print_info "✓ 测试执行完成"
}

# 生成测试摘要
generate_summary() {
    print_step "测试结果摘要"

    local reports_dir="target/surefire-reports"

    if [ -d "$reports_dir" ]; then
        local total_tests=$(grep -h "tests=" "$reports_dir"/*.xml 2>/dev/null | sed 's/.*tests="\([0-9]*\)".*/\1/' | awk '{s+=$1} END {print s}')
        local total_failures=$(grep -h "failures=" "$reports_dir"/*.xml 2>/dev/null | sed 's/.*failures="\([0-9]*\)".*/\1/' | awk '{s+=$1} END {print s}')
        local total_errors=$(grep -h "errors=" "$reports_dir"/*.xml 2>/dev/null | sed 's/.*errors="\([0-9]*\)".*/\1/' | awk '{s+=$1} END {print s}')

        echo ""
        echo "测试统计:"
        echo "  总测试数: ${total_tests:-0}"
        echo "  失败: ${total_failures:-0}"
        echo "  错误: ${total_errors:-0}"
        echo ""

        if [ "${total_failures:-0}" -gt 0 ] || [ "${total_errors:-0}" -gt 0 ]; then
            print_warn "存在失败的测试，请查看日志"
        else
            print_info "所有测试通过 ✓"
        fi
    fi

    echo ""
    echo "报告位置:"
    echo "  测试报告: target/test-reports/"
    echo "  XML 报告: target/surefire-reports/"
    if [ -n "$COVERAGE" ]; then
        echo "  覆盖率报告: target/site/jacoco/index.html"
    fi
}

# 打印下一步操作建议
print_next_steps() {
    echo ""
    print_step "下一步操作"
    echo ""
    echo "查看详细测试报告:"
    if [[ "$BUILD_TOOL" == *"mvn"* ]]; then
        echo "  $BUILD_TOOL surefire-report:report"
    fi
    echo ""
    echo "只运行失败的测试:"
    if [[ "$BUILD_TOOL" == *"mvn"* ]]; then
        echo "  $BUILD_TOOL test -DfailIfNoTests=false"
    fi
    echo ""
}

# 主函数
main() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║     集成测试执行脚本                                       ║"
    echo "║     Spring Boot Integration Tests                         ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""

    detect_build_tool
    run_tests
    generate_summary
    print_next_steps
}

# 执行主函数
main "$@"
