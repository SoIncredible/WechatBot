# 微信聊天机器人 - Kimi AI

基于 Wechaty 和 Kimi 大模型的智能微信聊天机器人。

## 功能特性

- 🤖 **私聊自动回复**: 在私聊中，机器人会自动将消息转发给 Kimi 大模型，并回复 AI 生成的内容
- 👥 **群聊@回复**: 在群聊中，只有当机器人被 @ 时，才会处理消息并回复
- 🚀 **简单易用**: 只需配置 API Key 即可运行

## 安装依赖

```bash
npm install
```

## 配置

1. 复制 `.env.example` 文件为 `.env`:

```bash
cp .env.example .env
```

2. 编辑 `.env` 文件，填入你的 Kimi API Key:

```env
KIMI_API_KEY=你的API密钥
```

### 获取 Kimi API Key

1. 访问 [Moonshot AI 开放平台](https://platform.moonshot.cn/)
2. 注册并登录账号
3. 在控制台创建 API Key
4. 复制 API Key 到 `.env` 文件

## 运行

```bash
node bot.js
```

首次运行时，终端会显示一个二维码链接，使用微信扫码登录即可。

## 使用说明

### 私聊使用

直接给机器人发送消息，机器人会自动回复。

**示例**:
```
你: 你好，请介绍一下你自己
机器人: 你好！我是一个基于 Kimi 大模型的 AI 助手...
```

### 群聊使用

在群聊中 @ 机器人，然后输入你的问题。

**示例**:
```
你: @机器人 今天天气怎么样？
机器人: @你 根据当前的信息...
```

## 注意事项

1. **Node.js 版本**: 需要 Node.js 16 或更高版本
2. **网络环境**: 建议在国外服务器运行，以避免网络问题
3. **API 配额**: 注意 Kimi API 的使用配额和限制
4. **微信限制**: 频繁操作可能导致微信账号受限，建议合理使用

## 技术栈

- [Wechaty](https://wechaty.js.org/) - 微信机器人 SDK
- [Kimi API](https://platform.moonshot.cn/) - Moonshot AI 大模型
- [Axios](https://axios-http.com/) - HTTP 客户端
- [dotenv](https://github.com/motdotla/dotenv) - 环境变量管理

## 项目结构

```
wechatyTest/
├── bot.js              # 主程序文件
├── package.json        # 项目配置
├── .env               # 环境变量配置（需要自己创建）
├── .env.example       # 环境变量示例
└── README.md          # 项目说明
```

## 常见问题

### 1. 登录二维码过期

重新运行程序，扫描新的二维码即可。

### 2. API 调用失败

- 检查 KIMI_API_KEY 是否正确配置
- 检查网络连接是否正常
- 查看 API 配额是否用完

### 3. 群聊中无法回复

确保机器人账号已加入群聊，并且在消息中正确 @ 了机器人。

## 许可证

MIT
