// DOM 元素
const petImage = document.getElementById('petImage');
const bubble = document.getElementById('bubble');
const closeBtn = document.getElementById('closeBtn');
const petContainer = document.getElementById('petContainer');
const catNumber = document.getElementById('catNumber');

// 状态配置
const stateConfig = {
  idle: {
    image: 'assets/idle.png',
    showBubble: false
  },
  working: {
    image: 'assets/working.png',
    showBubble: false
  },
  waiting: {
    image: 'assets/question.png',
    showBubble: true,
    bubbleText: '等待选择...'
  },
  done: {
    image: 'assets/happy.png',
    showBubble: true,
    bubbleText: '任务完成!',
    next: 'idle',
    delay: 2000
  }
};

// 当前状态
let currentState = 'idle';
let doneTimeout = null;

// 拖动状态
let isDragging = false;

// 切换状态
function setState(state) {
  if (doneTimeout) {
    clearTimeout(doneTimeout);
    doneTimeout = null;
  }

  const config = stateConfig[state];
  if (!config) return;

  currentState = state;
  console.log('[Renderer] State changed to:', state);

  // 更新图片
  petImage.src = config.image;

  // 添加/移除动画类
  petImage.classList.remove('happy', 'working');
  if (state === 'done') {
    petImage.classList.add('happy');
  } else if (state === 'working') {
    petImage.classList.add('working');
  }

  // 控制气泡显示
  if (config.showBubble) {
    bubble.querySelector('.bubble-text').textContent = config.bubbleText || '任务完成!';
    bubble.classList.add('show');

    if (config.next) {
      doneTimeout = setTimeout(() => {
        setState(config.next);
      }, config.delay);
    }
  } else {
    bubble.classList.remove('show');
  }
}

// 显示临时提示
let tipTimeout = null;
function showTip(text) {
  if (tipTimeout) {
    clearTimeout(tipTimeout);
  }
  bubble.querySelector('.bubble-text').textContent = text;
  bubble.classList.add('show');
  tipTimeout = setTimeout(() => {
    bubble.classList.remove('show');
    if (currentState === 'done') {
      bubble.querySelector('.bubble-text').textContent = '任务完成!';
    }
  }, 2000);
}

// 监听主进程发来的状态变化
window.petAPI.onStateChange((state) => {
  setState(state);
});

// 关闭按钮
closeBtn.addEventListener('click', (e) => {
  e.stopPropagation();
  window.petAPI.closeApp();
});

// === 拖动功能 ===
petContainer.addEventListener('mousedown', (e) => {
  if (e.target === closeBtn) return;
  isDragging = true;
  petContainer.style.cursor = 'grabbing';
  // 通知主进程开始拖动，传递初始鼠标位置
  window.petAPI.startDrag(e.screenX, e.screenY);
});

document.addEventListener('mousemove', (e) => {
  if (!isDragging) return;
  // 传递当前鼠标位置
  window.petAPI.updateDrag(e.screenX, e.screenY);
});

document.addEventListener('mouseup', () => {
  if (isDragging) {
    isDragging = false;
    petContainer.style.cursor = 'grab';
  }
});

// === 双击回到终端 ===
let clickCount = 0;
let clickTimer = null;

petImage.addEventListener('click', (e) => {
  e.stopPropagation();
  clickCount++;

  if (clickCount === 1) {
    clickTimer = setTimeout(() => {
      clickCount = 0;
    }, 300);
  } else if (clickCount === 2) {
    clearTimeout(clickTimer);
    clickCount = 0;
    // 双击触发
    console.log('[Renderer] Double click detected!');
    showTip('回到终端');
    setTimeout(() => {
      window.petAPI.goToTerminal();
    }, 300);
  }
});

// 初始化：获取当前状态
window.petAPI.getState().then((state) => {
  if (state) {
    setState(state);
  }
});

// 初始化：获取并显示编号
window.petAPI.getCatNumber().then((number) => {
  if (number) {
    catNumber.textContent = number;
  }
});

// === 点击穿透控制 ===
// 鼠标进入猫咪时，禁用穿透，允许交互
petContainer.addEventListener('mouseenter', () => {
  window.petAPI.setIgnoreMouseEvents(false);
});

// 鼠标离开猫咪时，启用穿透，让透明区域可点击
petContainer.addEventListener('mouseleave', () => {
  window.petAPI.setIgnoreMouseEvents(true);
});

// 页面卸载时清理
window.addEventListener('beforeunload', () => {
  window.petAPI.removeAllListeners();
});
