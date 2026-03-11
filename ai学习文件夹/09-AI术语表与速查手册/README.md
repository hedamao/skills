# 第 9 课：AI 术语表与速查手册

> 🎯 **学习目标**：掌握 AI 领域常见术语，建立完整的概念体系，遇到不懂的词可以随时查阅

---

## 一、基础概念

| 术语 | 英文 | 简明解释 |
|------|------|---------|
| 人工智能 | Artificial Intelligence (AI) | 让机器像人一样思考和行动的技术 |
| 机器学习 | Machine Learning (ML) | AI 的子集，让机器从数据中学习规律 |
| 深度学习 | Deep Learning (DL) | ML 的子集，用神经网络来学习 |
| 神经网络 | Neural Network | 模仿人脑神经元连接的数学模型 |
| 算法 | Algorithm | 解决问题的一套步骤和规则 |
| 模型 | Model | 机器学习训练后得到的"知识体" |
| 训练 | Training | 用数据教会模型学习的过程 |
| 推理 | Inference | 用训练好的模型来做预测的过程 |
| 数据集 | Dataset | 用于训练或测试模型的数据集合 |

---

## 二、大模型（LLM）相关

| 术语 | 英文 | 简明解释 |
|------|------|---------|
| 大语言模型 | Large Language Model (LLM) | 参数量巨大的语言理解和生成模型 |
| Transformer | Transformer | 大模型的核心架构，2017 年发明 |
| 注意力机制 | Attention Mechanism | 让模型能关注输入中重要部分的技术 |
| 参数 | Parameters | 模型内部学习到的数值，决定模型的能力 |
| Token | Token | 模型处理文本的最小单位（字/词/子词） |
| 上下文窗口 | Context Window | 模型一次能"记住"的最大文本长度 |
| 预训练 | Pre-training | 在海量数据上进行基础训练 |
| 微调 | Fine-tuning | 在特定数据上进一步训练，让模型更专业 |
| 对齐 | Alignment | 让模型输出符合人类价值观和预期 |
| RLHF | Reinforcement Learning from Human Feedback | 人类反馈强化学习，改善模型输出质量 |
| 提示词 | Prompt | 给模型的输入指令或问题 |
| 幻觉 | Hallucination | 模型生成不真实或虚构的内容 |
| 温度 | Temperature | 控制模型输出随机性的参数（越高越创意） |
| Top-P | Top-P (Nucleus Sampling) | 控制输出多样性的另一个参数 |
| 嵌入 | Embedding | 将文本转化为数值向量的技术 |
| 向量 | Vector | 表示数据特征的数字数组 |
| RAG | Retrieval-Augmented Generation | 检索增强生成，让模型能查询外部知识 |
| CoT | Chain of Thought | 链式思考，让模型一步步推理 |

---

## 三、生成式 AI 相关

| 术语 | 英文 | 简明解释 |
|------|------|---------|
| 生成式 AI | Generative AI | 能创造新内容（文字/图片/音频/视频）的 AI |
| 扩散模型 | Diffusion Model | 图像生成的核心技术，从噪声中恢复图像 |
| GAN | Generative Adversarial Network | 生成对抗网络，通过两个网络对抗来生成内容 |
| 文生图 | Text-to-Image | 根据文字描述生成图片 |
| 文生视频 | Text-to-Video | 根据文字描述生成视频 |
| 多模态 | Multimodal | 能处理多种数据类型（文字+图片+音频等） |
| LoRA | Low-Rank Adaptation | 低成本微调大模型的技术 |

---

## 四、智能体（Agent）相关

| 术语 | 英文 | 简明解释 |
|------|------|---------|
| 智能体 | AI Agent | 能自主规划和执行任务的 AI 系统 |
| 工具调用 | Tool Use / Function Calling | AI 调用外部工具完成任务的能力 |
| 规划 | Planning | Agent 将任务分解为步骤的能力 |
| 反思 | Reflection | Agent 检查自己的输出并改进的能力 |
| 记忆 | Memory | Agent 存储和检索历史信息的能力 |
| 多智能体 | Multi-Agent | 多个 Agent 协同工作的系统 |
| Agentic AI | Agentic AI | 具有自主代理能力的 AI 系统 |
| Workflow | Workflow | 预定义的任务执行流程 |
| Orchestration | Orchestration | 管理和协调多个 Agent 的过程 |

---

## 五、MCP 与 Skill 相关

| 术语 | 英文 | 简明解释 |
|------|------|---------|
| MCP | Model Context Protocol | 模型上下文协议，AI 连接外部工具的标准 |
| MCP Host | MCP Host | 运行 AI 的宿主应用（如 Claude Desktop） |
| MCP Client | MCP Client | 负责连接 Host 和 Server 的中间件 |
| MCP Server | MCP Server | 提供具体工具和数据的服务程序 |
| Skill | Skill | 教给 AI 的专业操作指南和工作流程 |
| Plugin | Plugin | 给 AI 添加额外功能的扩展组件 |
| API | Application Programming Interface | 应用程序之间通信的接口 |
| SDK | Software Development Kit | 软件开发工具包 |

---

## 六、大数据相关

| 术语 | 英文 | 简明解释 |
|------|------|---------|
| 大数据 | Big Data | 超出传统工具处理能力的海量数据 |
| 5V 特征 | 5V Characteristics | 大量、高速、多样、真实性、价值 |
| 数据湖 | Data Lake | 存储各类原始数据的中央仓库 |
| 数据仓库 | Data Warehouse | 经过整理的结构化数据存储 |
| ETL | Extract, Transform, Load | 数据抽取、转换、加载的过程 |
| 分布式计算 | Distributed Computing | 多台计算机协同处理任务 |
| 数据标注 | Data Labeling/Annotation | 给数据打标签，用于训练 AI |

---

## 七、模型部署和使用相关

| 术语 | 英文 | 简明解释 |
|------|------|---------|
| 开源 | Open Source | 代码/模型权重公开，可自由使用 |
| 闭源 | Closed Source | 代码不公开，只提供使用接口 |
| API 调用 | API Call | 通过编程接口使用 AI 服务 |
| 本地部署 | Local Deployment | 在自己的电脑/服务器上运行模型 |
| 云端部署 | Cloud Deployment | 在云服务器上运行模型 |
| 量化 | Quantization | 压缩模型大小，降低运行门槛 |
| 蒸馏 | Knowledge Distillation | 用大模型教小模型，保持能力 |
| 边缘计算 | Edge Computing | 在设备端（手机/电脑）运行 AI |
| SaaS | Software as a Service | 通过网络使用的软件服务 |
| GPU | Graphics Processing Unit | 图形处理器，AI 训练的核心硬件 |
| TPU | Tensor Processing Unit | Google 开发的 AI 专用芯片 |
| NPU | Neural Processing Unit | 神经网络处理单元，手机/电脑中的 AI 芯片 |

---

## 八、安全与伦理相关

| 术语 | 英文 | 简明解释 |
|------|------|---------|
| AI 安全 | AI Safety | 确保 AI 系统不会造成危害 |
| AI 对齐 | AI Alignment | 让 AI 的行为符合人类的意图和价值观 |
| 偏见 | Bias | AI 模型中存在的不公平倾向 |
| 越狱 | Jailbreak | 绕过 AI 安全限制的技术 |
| 隐私保护 | Privacy Protection | 保护用户数据不被滥用 |
| 可解释性 | Explainability | AI 决策过程能被人类理解 |
| AGI | Artificial General Intelligence | 通用人工智能，接近人类智能水平的 AI |
| ASI | Artificial Super Intelligence | 超级人工智能，超越人类智能的 AI |

---

## 九、提示工程（Prompt Engineering）相关

| 术语 | 英文 | 简明解释 |
|------|------|---------|
| 提示工程 | Prompt Engineering | 设计有效提示词来引导 AI 输出的技术 |
| 系统提示词 | System Prompt | 定义 AI 角色和行为规则的指令 |
| 零样本 | Zero-Shot | 不给任何示例，直接让 AI 完成任务 |
| 少样本 | Few-Shot | 给几个示例，引导 AI 完成类似任务 |
| 角色设定 | Role Playing | 让 AI 扮演特定角色来回答问题 |
| 思维链 | Chain of Thought (CoT) | 让 AI 展示推理过程，步骤式回答 |
| 自一致性 | Self-Consistency | 多次生成答案取最一致的结果 |

---

## 十、快速记忆口诀

```
🧠 基础三层：AI > ML > DL
📝 LLM 三步：预训练 → 微调 → 对齐
🤖 Agent 四能：感知、规划、执行、反思
🔌 MCP 三角：Host → Client → Server
📖 Skill 本质：给 AI 的专业操作手册
💾 大数据 5V：Volume Velocity Variety Veracity Value
```

---

> ⬅️ [第 8 课：热门 AI 应用与工具盘点](../08-热门AI应用与工具盘点/README.md) | ➡️ [第 10 课：学习路线图与进阶指南](../10-学习路线图与进阶指南/README.md)
