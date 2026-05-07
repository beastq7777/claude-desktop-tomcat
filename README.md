# Claude Desktop Tomcat

[![English](https://img.shields.io/badge/lang-English-blue.svg)](README_EN.md) [![中文](https://img.shields.io/badge/lang-中文-red.svg)](README.md)

一个可爱的桌面电子宠物，陪伴你的 Claude Code 编程时光。对于我们这种非专业编程人员，在不影响办公的时候也可以跑一下claude，用这个tom猫可以观察程序跑的怎么样了。

## 功能特性

- 🐱 桌面宠物显示，始终置顶
- 🔄 状态同步：空闲、工作中、任务完成
- 🎯 双击宠物快速回到终端
- 🖱️ 拖动移动宠物位置
- 🔗 与 Claude Code Hooks 联动

## 预览

| 空闲 | 工作中 | 完成 |
|:----:|:------:|:----:|
| 静态等待 | 动态工作 | 任务完成提示 |

## 安装

### 前置要求

- Node.js 18+
- npm

### 运行

```bash
# 克隆仓库
git clone https://github.com/beastq7777/claude-desktop-tomcat.git
cd claude-desktop-tomcat

# 安装依赖
npm install

# 启动
npm start
```

## 配置 Claude Code Hooks

在 `~/.claude/settings.json` 中添加：

```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "curl -s http://localhost:3721/start"
      }]
    }],
    "PreToolUse": [{
      "hooks": [{
        "type": "command",
        "command": "curl -s http://localhost:3721/working"
      }]
    }],
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "curl -s http://localhost:3721/done"
      }]
    }]
  }
}
```

## 操作说明

| 操作 | 效果 |
|------|------|
| 拖动宠物 | 移动位置 |
| 双击宠物 | 回到终端窗口 |
| 悬停宠物 | 显示关闭按钮 |

## 自定义

替换 `assets/` 目录下的图片即可自定义宠物外观：

- `idle.png` - 空闲状态
- `working.png` - 工作状态
- `happy.png` - 完成状态

## 技术栈

- Electron - 跨平台桌面应用框架
- Node.js HTTP Server - 状态通信

## 跨平台支持

| 平台 | 状态 |
|------|------|
| Windows | ✅ 支持 |
| Linux | ⚠️ 可能需要修改和调试 |
| macOS | ⚠️ 可能需要修改和调试 |

## License

[MIT](LICENSE)

## Author

Mr.A
