const { app, BrowserWindow, ipcMain } = require('electron');
const http = require('http');
const path = require('path');
const { exec } = require('child_process');

// HTTP 服务端口
const PORT = 3721;

let mainWindow = null;
let httpServer = null;

// 当前状态
let currentState = 'idle';

// 激活 Claude 终端窗口
function activateClaudeTerminal() {
  console.log('[Pet] Activating terminal...');

  const scriptPath = path.join(__dirname, 'activate-terminal.ps1');
  exec(`powershell -NoProfile -ExecutionPolicy Bypass -File "${scriptPath}"`, (error, stdout, stderr) => {
    if (error) {
      console.log('[Pet] Activation error:', error.message);
    } else {
      console.log('[Pet] Result:', stdout.trim());
    }
  });
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 130,
    height: 170,
    frame: false,           // 无边框
    transparent: true,      // 透明背景
    alwaysOnTop: true,      // 始终置顶
    resizable: false,
    skipTaskbar: true,      // 不显示在任务栏
    hasShadow: false,       // 无阴影
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false
    }
  });

  mainWindow.loadFile('index.html');
  mainWindow.setMovable(true);
}

// 创建 HTTP 服务器
function createHttpServer() {
  httpServer = http.createServer((req, res) => {
    const url = req.url;

    res.writeHead(200, { 'Content-Type': 'application/json' });

    if (url === '/start') {
      currentState = 'idle';
      if (mainWindow) {
        mainWindow.webContents.send('state-change', 'idle');
      }
      res.end(JSON.stringify({ status: 'ok', state: 'idle' }));
      console.log('[Pet] Session started');
    }
    else if (url === '/working') {
      currentState = 'working';
      if (mainWindow) {
        mainWindow.webContents.send('state-change', 'working');
      }
      res.end(JSON.stringify({ status: 'ok', state: 'working' }));
      console.log('[Pet] Working...');
    }
    else if (url === '/done') {
      currentState = 'done';
      if (mainWindow) {
        mainWindow.webContents.send('state-change', 'done');
      }
      res.end(JSON.stringify({ status: 'ok', state: 'done' }));
      console.log('[Pet] Task done!');
    }
    else if (url === '/status') {
      res.end(JSON.stringify({ status: 'ok', state: currentState }));
    }
    else {
      res.end(JSON.stringify({ status: 'error', message: 'Unknown endpoint' }));
    }
  });

  httpServer.listen(PORT, () => {
    console.log(`[Pet] HTTP server listening on port ${PORT}`);
  });
}

// 应用就绪
app.whenReady().then(() => {
  createWindow();
  createHttpServer();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

// 关闭所有窗口时退出 (Windows & Linux)
app.on('window-all-closed', () => {
  if (httpServer) {
    httpServer.close();
  }
  app.quit();
});

// 退出时关闭 HTTP 服务器
app.on('before-quit', () => {
  if (httpServer) {
    httpServer.close();
  }
});

// IPC: 获取当前状态
ipcMain.handle('get-state', () => {
  return currentState;
});

// IPC: 关闭窗口
ipcMain.on('close-app', () => {
  app.quit();
});

// IPC: 移动窗口
ipcMain.on('move-window', (event, deltaX, deltaY) => {
  if (mainWindow) {
    const [x, y] = mainWindow.getPosition();
    mainWindow.setPosition(x + deltaX, y + deltaY);
  }
});

// 拖动状态
let dragStartWindowX = 0;
let dragStartWindowY = 0;
let dragStartMouseX = 0;
let dragStartMouseY = 0;

// IPC: 开始拖动
ipcMain.on('start-drag', (event, mouseX, mouseY) => {
  if (mainWindow) {
    const [winX, winY] = mainWindow.getPosition();
    dragStartWindowX = winX;
    dragStartWindowY = winY;
    dragStartMouseX = mouseX;
    dragStartMouseY = mouseY;
  }
});

// IPC: 更新拖动位置
ipcMain.on('update-drag', (event, mouseX, mouseY) => {
  if (mainWindow) {
    const deltaX = mouseX - dragStartMouseX;
    const deltaY = mouseY - dragStartMouseY;
    mainWindow.setPosition(dragStartWindowX + deltaX, dragStartWindowY + deltaY);
  }
});

// IPC: 回到终端（激活 Claude 窗口）
ipcMain.on('go-to-terminal', () => {
  console.log('[Pet] Going to terminal...');
  // 不再最小化窗口，直接激活终端
  activateClaudeTerminal();
});
