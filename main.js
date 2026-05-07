const { app, BrowserWindow, ipcMain } = require('electron');
const http = require('http');
const path = require('path');
const { exec } = require('child_process');

// 解析命令行参数
const args = process.argv.slice(2);
const portArg = args.find(a => a.startsWith('--port='));
const hwndArg = args.find(a => a.startsWith('--hwnd='));

const PORT = portArg ? parseInt(portArg.split('=')[1]) : 3721;
const HWND = hwndArg ? hwndArg.split('=')[1] : null;
const CAT_NUMBER = PORT - 3721 + 1;

let mainWindow = null;
let httpServer = null;
let currentState = 'idle';

console.log(`[Pet] Starting cat #${CAT_NUMBER} on port ${PORT}, hwnd: ${HWND}`);

// 激活指定窗口
function activateWindowByHwnd(hwnd) {
  console.log('[Pet] Activating window:', hwnd);
  console.log('[Pet] HWND type:', typeof hwnd, 'value:', hwnd);

  if (!hwnd) {
    console.log('[Pet] No hwnd, skipping activation');
    return;
  }

  const scriptPath = path.join(__dirname, 'activate-terminal.ps1');
  const cmd = `powershell -NoProfile -ExecutionPolicy Bypass -File "${scriptPath}" -hwnd ${hwnd}`;
  console.log('[Pet] Executing:', cmd);

  exec(cmd, (error, stdout, stderr) => {
    if (error) {
      console.log('[Pet] Activation error:', error.message);
    } else {
      console.log('[Pet] Result:', stdout.trim());
    }
  });
}

// 检查窗口是否存在
function checkWindowExists(hwnd) {
  return new Promise((resolve) => {
    const cmd = `powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type 'using System; using System.Runtime.InteropServices; public class Win32 { [DllImport(\\\"user32.dll\\\")] public static extern bool IsWindow(IntPtr hWnd); }'; [Win32]::IsWindow([IntPtr]::new(${hwnd}))"`;

    exec(cmd, (error, stdout) => {
      if (error) {
        console.log('[Pet] Window check error:', error.message);
        resolve(true); // 如果检查失败，假设窗口存在，避免误关闭
      } else {
        const result = stdout.trim().toLowerCase() === 'true';
        console.log(`[Pet] Window ${hwnd} exists: ${result}`);
        resolve(result);
      }
    });
  });
}

// 定期检查窗口是否存在
let checkInterval = null;
function startWindowCheck() {
  if (!HWND) return;

  // 延迟10秒后开始检查，给窗口时间稳定
  setTimeout(() => {
    checkInterval = setInterval(async () => {
      const exists = await checkWindowExists(HWND);
      if (!exists) {
        console.log('[Pet] Target window closed, exiting...');
        if (httpServer) {
          httpServer.close();
        }
        app.quit();
      }
    }, 5000); // 每5秒检查一次
  }, 10000); // 10秒后开始
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 130,
    height: 170,
    frame: false,
    transparent: true,
    alwaysOnTop: true,
    resizable: false,
    skipTaskbar: true,
    hasShadow: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false
    }
  });

  mainWindow.loadFile('index.html');
  mainWindow.setMovable(true);
}

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

app.whenReady().then(() => {
  createWindow();
  createHttpServer();
  startWindowCheck();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (httpServer) {
    httpServer.close();
  }
  if (checkInterval) {
    clearInterval(checkInterval);
  }
  app.quit();
});

app.on('before-quit', () => {
  if (httpServer) {
    httpServer.close();
  }
  if (checkInterval) {
    clearInterval(checkInterval);
  }
});

// IPC: 获取当前状态
ipcMain.handle('get-state', () => {
  return currentState;
});

// IPC: 获取小猫编号
ipcMain.handle('get-cat-number', () => {
  return CAT_NUMBER;
});

// IPC: 获取窗口句柄
ipcMain.handle('get-hwnd', () => {
  return HWND;
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

// IPC: 回到终端（激活指定窗口）
ipcMain.on('go-to-terminal', () => {
  console.log('[Pet] Going to terminal...');
  if (HWND) {
    activateWindowByHwnd(HWND);
  }
});
