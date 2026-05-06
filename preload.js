const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('petAPI', {
  // 监听状态变化
  onStateChange: (callback) => {
    ipcRenderer.on('state-change', (event, state) => {
      callback(state);
    });
  },

  // 获取当前状态
  getState: () => {
    return ipcRenderer.invoke('get-state');
  },

  // 关闭应用
  closeApp: () => {
    ipcRenderer.send('close-app');
  },

  // 回到终端
  goToTerminal: () => {
    ipcRenderer.send('go-to-terminal');
  },

  // 开始拖动
  startDrag: (initialX, initialY) => {
    ipcRenderer.send('start-drag', initialX, initialY);
  },

  // 更新拖动位置
  updateDrag: (mouseX, mouseY) => {
    ipcRenderer.send('update-drag', mouseX, mouseY);
  },

  // 移除监听器
  removeAllListeners: () => {
    ipcRenderer.removeAllListeners('state-change');
  }
});
