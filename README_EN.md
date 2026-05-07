# Claude Desktop Tomcat

[![English](https://img.shields.io/badge/lang-English-blue.svg)](README_EN.md) [![中文](https://img.shields.io/badge/lang-中文-red.svg)](README.md)

A cute desktop pet companion for your Claude Code programming sessions.

## Features

- 🐱 Desktop pet display, always on top
- 🔄 State synchronization: idle, working, task completed
- 🎯 Double-click pet to quickly return to terminal
- 🖱️ Drag to move pet position
- 🔗 Integration with Claude Code Hooks

## Preview

| Idle | Working | Done |
|:----:|:------:|:----:|
| Static waiting | Active working | Task completed notification |

## Installation

### Prerequisites

- Node.js 18+
- npm

### Run

```bash
# Clone the repository
git clone https://github.com/beastq7777/claude-desktop-tomcat.git
cd claude-desktop-tomcat

# Install dependencies
npm install

# Start
npm start
```

## Configure Claude Code Hooks

Add the following to `~/.claude/settings.json`:

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

## Usage

| Action | Effect |
|--------|--------|
| Drag pet | Move position |
| Double-click pet | Return to terminal window |
| Hover over pet | Show close button |

## Customization

Replace the images in the `assets/` directory to customize your pet:

- `idle.png` - Idle state
- `working.png` - Working state
- `happy.png` - Completed state

## Tech Stack

- Electron - Cross-platform desktop application framework
- Node.js HTTP Server - State communication

## Cross-Platform Support

| Platform | Status |
|----------|--------|
| Windows | ✅ Supported |
| Linux | ✅ Supported (requires wmctrl or xdotool) |
| macOS | ✅ Supported |

## License

[MIT](LICENSE)

## Author

Mr.A
