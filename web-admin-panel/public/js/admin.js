// API Base URL
const API_URL = window.location.origin + '/api';

// Estado global
let authToken = localStorage.getItem('authToken');
let currentApp = 'FreeFire';
let ipaVersions = [];
let keys = [];
let notifications = [];

// Init
document.addEventListener('DOMContentLoaded', () => {
  if (authToken) {
    showDashboard();
  } else {
    showLogin();
  }

  setupEventListeners();
});

// Event Listeners
function setupEventListeners() {
  // Login
  document.getElementById('loginForm').addEventListener('submit', handleLogin);
  document.getElementById('logoutBtn').addEventListener('click', handleLogout);

  // Navigation
  document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      const section = e.target.dataset.section;
      showSection(section);
    });
  });

  // App Tabs
  document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      currentApp = e.target.dataset.app;
      document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
      e.target.classList.add('active');
      loadIPAVersions();
    });
  });

  // Forms
  document.getElementById('uploadForm').addEventListener('submit', handleUploadIPA);
  document.getElementById('keyForm').addEventListener('submit', handleGenerateKey);
  document.getElementById('notificationForm').addEventListener('submit', handleCreateNotification);
}

// Auth
async function handleLogin(e) {
  e.preventDefault();

  const username = document.getElementById('username').value;
  const password = document.getElementById('password').value;

  try {
    const response = await fetch(`${API_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password })
    });

    const data = await response.json();

    if (data.success) {
      authToken = data.token;
      localStorage.setItem('authToken', authToken);
      showDashboard();
    } else {
      document.getElementById('loginError').textContent = data.message || 'Credenciales inválidas';
    }
  } catch (err) {
    document.getElementById('loginError').textContent = 'Error de conexión';
    console.error(err);
  }
}

function handleLogout() {
  authToken = null;
  localStorage.removeItem('authToken');
  showLogin();
}

function showLogin() {
  document.getElementById('loginScreen').classList.add('active');
  document.getElementById('dashboardScreen').classList.remove('active');
}

function showDashboard() {
  document.getElementById('loginScreen').classList.remove('active');
  document.getElementById('dashboardScreen').classList.add('active');
  showSection('ipa');
}

// Navigation
function showSection(sectionName) {
  document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
  document.getElementById(`${sectionName}Section`).classList.add('active');

  document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.section === sectionName);
  });

  // Cargar datos
  if (sectionName === 'ipa') {
    loadIPAVersions();
  } else if (sectionName === 'keys') {
    loadKeys();
  } else if (sectionName === 'notifications') {
    loadNotifications();
  }
}

// IPA Management
async function loadIPAVersions() {
  try {
    const response = await fetch(`${API_URL}/ipa/versions/${currentApp}`, {
      headers: { 'Authorization': `Bearer ${authToken}` }
    });

    const data = await response.json();

    if (data.success) {
      ipaVersions = data.versions;
      renderIPAList();
    }
  } catch (err) {
    console.error('Error cargando IPAs:', err);
  }
}

function renderIPAList() {
  const container = document.getElementById('ipaList');

  if (ipaVersions.length === 0) {
    container.innerHTML = `
      <div class="empty-state">
        <h3>📦 No hay versiones subidas</h3>
        <p>Sube la primera versión de ${currentApp}</p>
      </div>
    `;
    return;
  }

  container.innerHTML = ipaVersions.map(ipa => `
    <div class="ipa-card">
      <div class="ipa-card-header">
        <div class="ipa-card-title">v${ipa.version}</div>
        <div class="ipa-status ${ipa.is_active ? 'active' : 'inactive'}">
          ${ipa.is_active ? '✓ Activa' : '✗ Desactivada'}
        </div>
      </div>
      <div class="ipa-card-body">
        <div>📅 Subida: ${new Date(ipa.upload_date).toLocaleString('es')}</div>
        <div>📦 Tamaño: ${(ipa.file_size / 1024 / 1024).toFixed(2)} MB</div>
        <div>⬇️ Descargas: ${ipa.download_count}</div>
        ${ipa.notes ? `<div>📝 ${ipa.notes}</div>` : ''}
      </div>
      <div class="ipa-card-actions">
        <button class="btn-sm btn-toggle" onclick="toggleIPAStatus(${ipa.id})">
          ${ipa.is_active ? 'Desactivar' : 'Activar'}
        </button>
        <button class="btn-sm btn-download" onclick="downloadIPA(${ipa.id})">
          Descargar
        </button>
        <button class="btn-sm btn-delete" onclick="deleteIPA(${ipa.id})">
          Eliminar
        </button>
      </div>
    </div>
  `).join('');
}

async function handleUploadIPA(e) {
  e.preventDefault();

  const appName = document.getElementById('uploadAppName').value;
  const version = document.getElementById('uploadVersion').value;
  const notes = document.getElementById('uploadNotes').value;
  const file = document.getElementById('uploadFile').files[0];

  if (!file) {
    alert('Selecciona un archivo .ipa');
    return;
  }

  const formData = new FormData();
  formData.append('app_name', appName);
  formData.append('version', version);
  formData.append('notes', notes);
  formData.append('ipa', file);

  const progressDiv = document.getElementById('uploadProgress');
  progressDiv.textContent = 'Subiendo...';

  try {
    const response = await fetch(`${API_URL}/ipa/upload`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${authToken}` },
      body: formData
    });

    const data = await response.json();

    if (data.success) {
      progressDiv.textContent = '✅ Subido correctamente';
      setTimeout(() => {
        closeModal('uploadModal');
        document.getElementById('uploadForm').reset();
        progressDiv.textContent = '';
        if (currentApp === appName) {
          loadIPAVersions();
        }
      }, 1500);
    } else {
      progressDiv.textContent = `❌ Error: ${data.message}`;
    }
  } catch (err) {
    progressDiv.textContent = '❌ Error de conexión';
    console.error(err);
  }
}

async function toggleIPAStatus(id) {
  try {
    const response = await fetch(`${API_URL}/ipa/versions/${id}/toggle`, {
      method: 'PATCH',
      headers: { 'Authorization': `Bearer ${authToken}` }
    });

    const data = await response.json();

    if (data.success) {
      loadIPAVersions();
    }
  } catch (err) {
    console.error('Error toggling IPA:', err);
  }
}

async function deleteIPA(id) {
  if (!confirm('¿Eliminar esta versión permanentemente?')) return;

  try {
    const response = await fetch(`${API_URL}/ipa/versions/${id}`, {
      method: 'DELETE',
      headers: { 'Authorization': `Bearer ${authToken}` }
    });

    const data = await response.json();

    if (data.success) {
      loadIPAVersions();
    }
  } catch (err) {
    console.error('Error eliminando IPA:', err);
  }
}

function downloadIPA(id) {
  window.open(`${API_URL}/ipa/download/${id}`, '_blank');
}

// Keys Management
async function loadKeys() {
  try {
    const response = await fetch(`${API_URL}/keys/list`, {
      headers: { 'Authorization': `Bearer ${authToken}` }
    });

    const data = await response.json();

    if (data.success) {
      keys = data.keys;
      renderKeysList();
    }
  } catch (err) {
    console.error('Error cargando keys:', err);
  }
}

function renderKeysList() {
  const container = document.getElementById('keysList');

  if (keys.length === 0) {
    container.innerHTML = `
      <div class="empty-state">
        <h3>🔑 No hay keys generadas</h3>
        <p>Genera la primera key para tus usuarios</p>
      </div>
    `;
    return;
  }

  container.innerHTML = keys.map(key => {
    const isExpired = key.expires_at && Date.now() > key.expires_at;
    const remainingDays = key.expires_at ? Math.ceil((key.expires_at - Date.now()) / (1000 * 60 * 60 * 24)) : null;

    return `
      <div class="key-card">
        <div class="key-card-header">
          <div class="key-card-title">${key.key_string}</div>
          <div class="key-status ${key.is_active && !isExpired ? 'active' : 'inactive'}">
            ${isExpired ? '⏰ Expirada' : key.is_active ? '✓ Activa' : '✗ Desactivada'}
          </div>
        </div>
        <div class="key-card-body">
          <div>👤 Usuario: ${key.user_name}</div>
          <div>⏱️ Duración: ${key.duration}</div>
          <div>📅 Creada: ${new Date(key.created_at).toLocaleString('es')}</div>
          ${key.activated_at ? `<div>✅ Activada: ${new Date(key.activated_at).toLocaleString('es')}</div>` : '<div>⏳ Sin activar</div>'}
          ${remainingDays !== null ? `<div>📆 ${remainingDays > 0 ? `${remainingDays} días restantes` : 'Expirada'}</div>` : '<div>♾️ Permanente</div>'}
          ${key.notes ? `<div>📝 ${key.notes}</div>` : ''}
        </div>
        <div class="key-card-actions">
          <button class="btn-sm btn-toggle" onclick="toggleKeyStatus(${key.id})">
            ${key.is_active ? 'Desactivar' : 'Activar'}
          </button>
          <button class="btn-sm btn-delete" onclick="deleteKey(${key.id})">
            Eliminar
          </button>
        </div>
      </div>
    `;
  }).join('');
}

async function handleGenerateKey(e) {
  e.preventDefault();

  const userName = document.getElementById('keyUserName').value;
  const duration = document.getElementById('keyDuration').value;
  const notes = document.getElementById('keyNotes').value;

  try {
    const response = await fetch(`${API_URL}/keys/generate`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ user_name: userName, duration, notes })
    });

    const data = await response.json();

    if (data.success) {
      document.getElementById('generatedKeyDisplay').innerHTML = `
        <h3>✅ Key generada correctamente</h3>
        <div class="generated-key-code">${data.key.key_string}</div>
        <p>Copia esta key y envíala al usuario</p>
      `;

      setTimeout(() => {
        closeModal('keyModal');
        document.getElementById('keyForm').reset();
        document.getElementById('generatedKeyDisplay').innerHTML = '';
        loadKeys();
      }, 3000);
    }
  } catch (err) {
    console.error('Error generando key:', err);
  }
}

async function toggleKeyStatus(id) {
  try {
    const response = await fetch(`${API_URL}/keys/${id}/toggle`, {
      method: 'PATCH',
      headers: { 'Authorization': `Bearer ${authToken}` }
    });

    const data = await response.json();

    if (data.success) {
      loadKeys();
    }
  } catch (err) {
    console.error('Error toggling key:', err);
  }
}

async function deleteKey(id) {
  if (!confirm('¿Eliminar esta key permanentemente?')) return;

  try {
    const response = await fetch(`${API_URL}/keys/${id}`, {
      method: 'DELETE',
      headers: { 'Authorization': `Bearer ${authToken}` }
    });

    const data = await response.json();

    if (data.success) {
      loadKeys();
    }
  } catch (err) {
    console.error('Error eliminando key:', err);
  }
}

// Notifications Management
async function loadNotifications() {
  try {
    const response = await fetch(`${API_URL}/notifications/list`, {
      headers: { 'Authorization': `Bearer ${authToken}` }
    });

    const data = await response.json();

    if (data.success) {
      notifications = data.notifications;
      renderNotificationsList();
    }
  } catch (err) {
    console.error('Error cargando notificaciones:', err);
  }
}

function renderNotificationsList() {
  const container = document.getElementById('notificationsList');

  if (notifications.length === 0) {
    container.innerHTML = `
      <div class="empty-state">
        <h3>🔔 No hay notificaciones</h3>
        <p>Crea la primera notificación para tus usuarios</p>
      </div>
    `;
    return;
  }

  const typeIcons = {
    info: 'ℹ️',
    success: '✅',
    warning: '⚠️',
    error: '❌'
  };

  container.innerHTML = notifications.map(notif => `
    <div class="notification-card">
      <div class="notification-card-header">
        <div class="notification-card-title">
          ${typeIcons[notif.type] || 'ℹ️'} ${notif.title}
        </div>
      </div>
      <div class="notification-card-body">
        <div>${notif.message}</div>
        <div>📅 ${new Date(notif.created_at).toLocaleString('es')}</div>
        <div>👥 Destinatarios: ${notif.target_users}</div>
      </div>
      <div class="notification-card-actions">
        <button class="btn-sm btn-delete" onclick="deleteNotification(${notif.id})">
          Eliminar
        </button>
      </div>
    </div>
  `).join('');
}

async function handleCreateNotification(e) {
  e.preventDefault();

  const title = document.getElementById('notifTitle').value;
  const message = document.getElementById('notifMessage').value;
  const type = document.getElementById('notifType').value;
  const targetUsers = document.getElementById('notifTarget').value;

  try {
    const response = await fetch(`${API_URL}/notifications/create`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ title, message, type, target_users: targetUsers })
    });

    const data = await response.json();

    if (data.success) {
      alert('✅ Notificación enviada');
      closeModal('notificationModal');
      document.getElementById('notificationForm').reset();
      loadNotifications();
    }
  } catch (err) {
    console.error('Error creando notificación:', err);
  }
}

async function deleteNotification(id) {
  if (!confirm('¿Eliminar esta notificación?')) return;

  try {
    const response = await fetch(`${API_URL}/notifications/${id}`, {
      method: 'DELETE',
      headers: { 'Authorization': `Bearer ${authToken}` }
    });

    const data = await response.json();

    if (data.success) {
      loadNotifications();
    }
  } catch (err) {
    console.error('Error eliminando notificación:', err);
  }
}

// Modals
function showUploadModal() {
  document.getElementById('uploadModal').classList.add('active');
}

function showKeyModal() {
  document.getElementById('keyModal').classList.add('active');
}

function showNotificationModal() {
  document.getElementById('notificationModal').classList.add('active');
}

function closeModal(modalId) {
  document.getElementById(modalId).classList.remove('active');
}

// Close modals on outside click
window.addEventListener('click', (e) => {
  if (e.target.classList.contains('modal')) {
    e.target.classList.remove('active');
  }
});
