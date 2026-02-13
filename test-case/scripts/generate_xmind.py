#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
XMind 测试用例思维导图生成脚本

功能：根据结构化的测试用例数据，生成 XMind 格式（.xmind）的思维导图文件。
.xmind 文件本质上是一个 ZIP 压缩包，内部包含 content.json 描述思维导图结构。

使用方式：
    方式 1 — 命令行（传入 JSON 数据文件）：
        python generate_xmind.py --input test-data.json --output test-cases-2026-02-13.xmind

    方式 2 — 命令行（传入模块名称 + JSON 数据文件）：
        python generate_xmind.py --module "用户管理模块" --input test-data.json

    方式 3 — 作为模块导入（由 Agent 在代码中调用）：
        from generate_xmind import build_xmind_content, save_xmind
        content = build_xmind_content("模块名", unit_tests, integration_tests, e2e_tests)
        save_xmind(content, "output.xmind")

    方式 4 — 直接运行（使用内置示例数据）：
        python generate_xmind.py --demo

依赖：仅使用 Python 内置库（json, zipfile, uuid, os, argparse），无需安装任何第三方包。

JSON 数据文件格式：
    {
        "module": "模块名称",
        "unit_tests": [...],
        "integration_tests": [...],
        "e2e_tests": [...]
    }
    详见本文件末尾的 get_demo_data() 函数或 SKILL.md 中的数据结构说明。
"""

import json
import zipfile
import uuid
import os
import sys
import argparse
from datetime import datetime


# ============================================================
# 核心函数 (Core Functions)
# ============================================================

def generate_id():
    """生成唯一 ID（24 位十六进制字符串）"""
    return str(uuid.uuid4()).replace("-", "")[:24]


def create_topic(title, labels=None, notes=None, markers=None, children=None):
    """
    创建一个 XMind topic 节点

    Args:
        title: 节点显示文本
        labels: 标签数组，如 ["正向"]、["异常"]、["边界"]
        notes: 备注内容（纯文本）
        markers: 图标标记 ID 数组，如 ["priority-1"]
        children: 子节点数组

    Returns:
        dict: XMind topic 节点数据
    """
    topic = {
        "id": generate_id(),
        "class": "topic",
        "title": title
    }
    if labels:
        topic["labels"] = labels
    if notes:
        topic["notes"] = {
            "plain": {"content": notes}
        }
    if markers:
        topic["markers"] = [{"markerId": m} for m in markers]
    if children:
        topic["children"] = {"attached": children}
    return topic


def create_test_case_topic(name, case_type=None, description=None, priority=None):
    """
    创建一个测试用例叶子节点

    Args:
        name: 用例方法名（如 findById_DataExists_ReturnsResult）
        case_type: 场景类型标签（如 "正向"、"异常"、"边界"、"查询"、"权限"）
        description: 用例的中文描述
        priority: 优先级（1=P0最高, 2=P1高, 3=P2中, 4=P3低）

    Returns:
        dict: XMind topic 节点数据
    """
    labels = [case_type] if case_type else None
    markers = [f"priority-{priority}"] if priority else None
    return create_topic(name, labels=labels, notes=description, markers=markers)


def build_xmind_content(module_name, unit_tests=None, integration_tests=None, e2e_tests=None):
    """
    构建 XMind content.json 数据

    Args:
        module_name: 被测模块名称（显示在思维导图根节点）
        unit_tests: 单元测试数据列表，格式：
            [
                {
                    "class": "XxxServiceTest",
                    "methods": [
                        {
                            "method": "findById",
                            "cases": [
                                {"name": "findById_DataExists_ReturnsResult", "type": "正向", "desc": "描述", "priority": 1}
                            ]
                        }
                    ]
                }
            ]
        integration_tests: 集成测试数据列表，格式：
            [
                {
                    "category": "Repository 层",
                    "classes": [
                        {
                            "name": "XxxRepositoryIntegrationTest",
                            "cases": [
                                {"name": "findByName_Exists_ReturnsList", "type": "查询", "desc": "描述"}
                            ]
                        }
                    ]
                }
            ]
        e2e_tests: E2E 测试数据列表，格式：
            [
                {
                    "category": "Happy Path",
                    "cases": [
                        {"name": "userCRUD_FullLifecycle_Success", "desc": "描述", "priority": 1}
                    ]
                }
            ]

    Returns:
        list: XMind content.json 数据（Sheet 数组）
    """
    unit_tests = unit_tests or []
    integration_tests = integration_tests or []
    e2e_tests = e2e_tests or []

    # 构建单元测试分支
    unit_children = []
    for test_class in unit_tests:
        method_children = []
        for method in test_class.get("methods", []):
            case_children = [
                create_test_case_topic(
                    c["name"], c.get("type"), c.get("desc"), c.get("priority")
                )
                for c in method.get("cases", [])
            ]
            method_children.append(create_topic(method["method"], children=case_children))
        unit_children.append(create_topic(test_class["class"], children=method_children))

    # 构建集成测试分支
    integration_children = []
    for category in integration_tests:
        class_children = []
        for test_class in category.get("classes", []):
            case_children = [
                create_test_case_topic(
                    c["name"], c.get("type"), c.get("desc"), c.get("priority")
                )
                for c in test_class.get("cases", [])
            ]
            class_children.append(create_topic(test_class["name"], children=case_children))
        integration_children.append(create_topic(category["category"], children=class_children))

    # 构建 E2E 测试分支
    e2e_children = []
    for category in e2e_tests:
        case_children = [
            create_test_case_topic(
                c["name"], c.get("type"), c.get("desc"), c.get("priority")
            )
            for c in category.get("cases", [])
        ]
        e2e_children.append(create_topic(category["category"], children=case_children))

    # 组装完整结构
    root_topic = {
        "id": generate_id(),
        "class": "topic",
        "title": module_name,
        "structureClass": "org.xmind.ui.map.unbalanced",
        "children": {
            "attached": [
                create_topic("🧪 单元测试", children=unit_children),
                create_topic("🔗 集成测试", children=integration_children),
                create_topic("🌐 E2E 测试", children=e2e_children)
            ]
        }
    }

    return [{
        "id": generate_id(),
        "class": "sheet",
        "title": f"{module_name} - 测试用例",
        "rootTopic": root_topic
    }]


def save_xmind(content, output_path):
    """
    将 content.json 打包为 .xmind 文件

    Args:
        content: XMind content.json 数据（由 build_xmind_content 生成）
        output_path: 输出文件路径（如 test-cases-2026-02-13.xmind）
    """
    # 确保输出目录存在
    output_dir = os.path.dirname(output_path)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir, exist_ok=True)

    content_json = json.dumps(content, ensure_ascii=False, indent=2)
    with zipfile.ZipFile(output_path, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("content.json", content_json)
    print(f"✅ XMind 文件已生成：{os.path.abspath(output_path)}")


def load_test_data(input_path):
    """
    从 JSON 文件加载测试用例数据

    Args:
        input_path: JSON 数据文件路径

    Returns:
        dict: 包含 module, unit_tests, integration_tests, e2e_tests 的字典
    """
    with open(input_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    return data


# ============================================================
# 示例数据 (Demo Data)
# ============================================================

def get_demo_data():
    """
    返回内置的示例测试数据，用于演示和测试脚本功能。
    Agent 在实际使用时应根据代码分析结果构造类似结构的数据。
    """
    return {
        "module": "用户管理模块",
        "unit_tests": [
            {
                "class": "UserServiceTest",
                "methods": [
                    {
                        "method": "findById",
                        "cases": [
                            {"name": "findById_UserExists_ReturnsUser", "type": "正向", "desc": "查询存在的用户 ID，返回用户 DTO", "priority": 2},
                            {"name": "findById_UserNotFound_ThrowsNotFoundException", "type": "异常", "desc": "查询不存在的 ID，抛出 NotFoundException", "priority": 2},
                            {"name": "findById_NullId_ThrowsIllegalArgumentException", "type": "边界", "desc": "ID 为 null 时抛出参数异常", "priority": 3}
                        ]
                    },
                    {
                        "method": "createUser",
                        "cases": [
                            {"name": "createUser_ValidRequest_ReturnsCreatedUser", "type": "正向", "desc": "正常创建用户", "priority": 1},
                            {"name": "createUser_DuplicateUsername_ThrowsBusinessException", "type": "异常", "desc": "用户名已存在", "priority": 1},
                            {"name": "createUser_BlankName_ThrowsIllegalArgumentException", "type": "边界", "desc": "用户名为空白", "priority": 2}
                        ]
                    }
                ]
            }
        ],
        "integration_tests": [
            {
                "category": "Repository 层",
                "classes": [{
                    "name": "UserRepositoryIntegrationTest",
                    "cases": [
                        {"name": "findByUsername_Exists_ReturnsUser", "type": "查询", "desc": "按用户名查询存在的用户"},
                        {"name": "save_DuplicateUsername_ThrowsException", "type": "约束", "desc": "唯一约束校验"}
                    ]
                }]
            },
            {
                "category": "Controller 层",
                "classes": [{
                    "name": "UserControllerIntegrationTest",
                    "cases": [
                        {"name": "getUser_ValidId_Returns200", "type": "API", "desc": "GET 请求正常返回"},
                        {"name": "createUser_InvalidBody_Returns400", "type": "校验", "desc": "参数校验失败"},
                        {"name": "deleteUser_AdminRole_Returns204", "type": "权限", "desc": "管理员删除"}
                    ]
                }]
            }
        ],
        "e2e_tests": [
            {
                "category": "Happy Path",
                "cases": [
                    {"name": "userCRUD_FullLifecycle_Success", "desc": "用户完整 CRUD 流程", "priority": 1}
                ]
            },
            {
                "category": "异常场景",
                "cases": [
                    {"name": "createUser_DuplicateUsername_Returns409", "desc": "重复用户名创建返回 409"}
                ]
            },
            {
                "category": "安全场景",
                "cases": [
                    {"name": "accessProtectedEndpoint_Unauthenticated_Returns401", "desc": "未认证用户访问受保护接口"}
                ]
            }
        ]
    }


# ============================================================
# 命令行入口 (CLI Entry Point)
# ============================================================

def main():
    parser = argparse.ArgumentParser(
        description="XMind 测试用例思维导图生成工具",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用示例:
  # 使用内置演示数据生成 XMind 文件
  python generate_xmind.py --demo

  # 从 JSON 文件读取测试数据并生成 XMind 文件
  python generate_xmind.py --input test-data.json --output test-cases.xmind

  # 指定模块名称（覆盖 JSON 文件中的 module 字段）
  python generate_xmind.py --input test-data.json --module "订单模块"

  # 导出 JSON 数据模板（用于了解数据格式）
  python generate_xmind.py --export-template template.json
        """
    )

    parser.add_argument(
        "--input", "-i",
        help="输入的 JSON 测试数据文件路径"
    )
    parser.add_argument(
        "--output", "-o",
        help="输出的 .xmind 文件路径（默认: test-cases-YYYY-MM-DD.xmind）"
    )
    parser.add_argument(
        "--module", "-m",
        help="被测模块名称（覆盖 JSON 数据中的 module 字段）"
    )
    parser.add_argument(
        "--demo",
        action="store_true",
        help="使用内置演示数据生成 XMind 文件"
    )
    parser.add_argument(
        "--export-template",
        metavar="FILE",
        help="导出 JSON 数据模板文件（用于了解输入数据格式）"
    )

    args = parser.parse_args()

    # 导出数据模板
    if args.export_template:
        demo_data = get_demo_data()
        with open(args.export_template, "w", encoding="utf-8") as f:
            json.dump(demo_data, f, ensure_ascii=False, indent=2)
        print(f"✅ JSON 数据模板已导出：{os.path.abspath(args.export_template)}")
        return

    # 确定数据来源
    if args.demo:
        data = get_demo_data()
        print("📋 使用内置演示数据...")
    elif args.input:
        if not os.path.exists(args.input):
            print(f"❌ 错误：文件不存在: {args.input}", file=sys.stderr)
            sys.exit(1)
        data = load_test_data(args.input)
        print(f"📋 从文件加载数据：{args.input}")
    else:
        parser.print_help()
        print("\n💡 提示：使用 --demo 快速体验，或使用 --input 指定 JSON 数据文件")
        sys.exit(0)

    # 确定模块名称
    module_name = args.module or data.get("module", "测试用例")

    # 确定输出路径
    if args.output:
        output_path = args.output
    else:
        today = datetime.now().strftime("%Y-%m-%d")
        output_path = f"test-cases-{today}.xmind"

    # 构建并生成 XMind 文件
    content = build_xmind_content(
        module_name,
        unit_tests=data.get("unit_tests", []),
        integration_tests=data.get("integration_tests", []),
        e2e_tests=data.get("e2e_tests", [])
    )
    save_xmind(content, output_path)

    # 输出统计信息
    unit_count = sum(
        len(c) for t in data.get("unit_tests", []) for m in t.get("methods", []) for c in [m.get("cases", [])]
    )
    integration_count = sum(
        len(c) for cat in data.get("integration_tests", []) for cls in cat.get("classes", []) for c in [cls.get("cases", [])]
    )
    e2e_count = sum(
        len(c) for cat in data.get("e2e_tests", []) for c in [cat.get("cases", [])]
    )
    total = unit_count + integration_count + e2e_count
    print(f"\n📊 统计信息：")
    print(f"   🧪 单元测试用例：{unit_count} 个")
    print(f"   🔗 集成测试用例：{integration_count} 个")
    print(f"   🌐 E2E 测试用例：{e2e_count} 个")
    print(f"   📋 总计：{total} 个用例")


if __name__ == "__main__":
    main()
