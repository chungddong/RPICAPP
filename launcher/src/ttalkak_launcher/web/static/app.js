// TTalkak Launcher 프론트엔드

let currentDeviceInfo = null;
let statusPollInterval = null;

// 초기화
document.addEventListener('DOMContentLoaded', () => {
  startStatusPolling();
  loadDeviceList();
});

// 상태 폴링 (3초마다)
function startStatusPolling() {
  checkStatus();
  statusPollInterval = setInterval(checkStatus, 3000);
}

async function checkStatus() {
  try {
    const resp = await fetch('/api/status');
    const data = await resp.json();
    updateConnectionUI(data.pi_connected);
    if (data.pi_connected && !currentDeviceInfo) {
      await refreshDeviceInfo();
    }
  } catch {
    updateConnectionUI(false);
  }
}

function updateConnectionUI(connected) {
  const dot = document.getElementById('status-dot');
  const text = document.getElementById('status-text');
  const deviceSection = document.getElementById('device-section');
  const noDeviceSection = document.getElementById('no-device-section');

  if (connected) {
    dot.className = 'status-dot connected';
    text.textContent = 'Pi 연결됨 (192.168.7.2)';
    deviceSection.classList.remove('hidden');
    noDeviceSection.classList.add('hidden');
  } else {
    dot.className = 'status-dot disconnected';
    text.textContent = 'Pi 미연결';
    deviceSection.classList.add('hidden');
    noDeviceSection.classList.remove('hidden');
    currentDeviceInfo = null;
  }
}

// 기기 정보 조회
async function refreshDeviceInfo() {
  try {
    const resp = await fetch('/api/device-info');
    if (!resp.ok) throw new Error('fetch failed');
    const data = await resp.json();
    currentDeviceInfo = data;
    displayDeviceInfo(data);
  } catch {
    showToast('기기 정보를 가져올 수 없습니다', 'error');
  }
}

function displayDeviceInfo(info) {
  document.getElementById('info-serial').textContent = info.serial || '-';
  document.getElementById('info-ble-mac').textContent = info.ble_mac || '-';
  document.getElementById('info-ble-name').textContent = info.ble_name || '-';
  document.getElementById('info-hostname').textContent = info.hostname || '-';
  document.getElementById('info-ip').textContent = info.ip_address || '-';
  document.getElementById('info-qr-data').textContent = info.qr_data || '-';

  const qrImg = document.getElementById('qr-image');
  if (info.qr_image) {
    qrImg.src = info.qr_image;
    qrImg.style.display = 'block';
  }
}

// 기기 등록
async function registerDevice() {
  if (!currentDeviceInfo) {
    showToast('기기 정보가 없습니다', 'error');
    return;
  }

  const btn = document.getElementById('btn-register');
  btn.disabled = true;
  btn.textContent = '등록 중...';

  try {
    const resp = await fetch('/api/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        serial: currentDeviceInfo.serial,
        ble_mac: currentDeviceInfo.ble_mac,
        ble_name: currentDeviceInfo.ble_name,
        hostname: currentDeviceInfo.hostname,
      }),
    });

    if (!resp.ok) throw new Error('register failed');

    showToast('기기 등록 완료!', 'success');
    await loadDeviceList();
  } catch {
    showToast('등록에 실패했습니다', 'error');
  } finally {
    btn.disabled = false;
    btn.textContent = '기기 등록';
  }
}

// 등록된 기기 목록
async function loadDeviceList() {
  try {
    const resp = await fetch('/api/devices');
    const devices = await resp.json();
    renderDeviceList(devices);
  } catch {
    // 무시
  }
}

function renderDeviceList(devices) {
  const tbody = document.getElementById('devices-tbody');
  const countEl = document.getElementById('device-count');
  countEl.textContent = `${devices.length}대`;

  if (devices.length === 0) {
    tbody.innerHTML = '<tr><td colspan="4" class="empty">등록된 기기가 없습니다</td></tr>';
    return;
  }

  tbody.innerHTML = devices
    .slice()
    .reverse()
    .map(d => {
      const date = d.registered_at
        ? new Date(d.registered_at).toLocaleString('ko-KR')
        : d.timestamp
          ? new Date(d.timestamp).toLocaleString('ko-KR')
          : '-';
      return `<tr>
        <td><code>${d.serial || '-'}</code></td>
        <td><code>${d.ble_mac || '-'}</code></td>
        <td>${d.ble_name || '-'}</td>
        <td>${date}</td>
      </tr>`;
    })
    .join('');
}

// RNDIS 네트워크 설정
async function setupNetwork() {
  const btn = document.getElementById('btn-setup-network');
  btn.disabled = true;
  btn.textContent = '설정 중...';

  try {
    const resp = await fetch('/api/setup-network', { method: 'POST' });
    if (!resp.ok) throw new Error('setup failed');
    showToast('네트워크 설정 완료 (192.168.7.1)', 'success');
  } catch {
    showToast('네트워크 설정 실패. 관리자 권한이 필요합니다.', 'error');
  } finally {
    btn.disabled = false;
    btn.textContent = '네트워크 설정';
  }
}

// 토스트 알림
function showToast(message, type = 'success') {
  const toast = document.getElementById('toast');
  toast.textContent = message;
  toast.className = `toast ${type}`;
  setTimeout(() => toast.classList.add('hidden'), 3000);
}
