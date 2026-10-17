const tokenStorageKey = "isoko-admin-token";
const adminEmailStorageKey = "isoko-admin-email";
const auditStorageKey = "isoko-command-audit";
const lowBatteryThresholdPercent = 25;

function resolveApiBaseUrl() {
  if (typeof window !== "undefined" && window.__ISOKO_ADMIN_CONFIG__?.apiBaseUrl) {
    return window.__ISOKO_ADMIN_CONFIG__.apiBaseUrl;
  }
  return "https://api.smstechnologieset.com";
}

const DEFAULT_MAPBOX_TOKEN = atob(
  "cGsuZXlKMUlqb2ljMjF6ZEdWamFDSXNJbUVpT2lKamJYTTNiekJwTUdrd05IQnZNbnB4Y1RJellubzFjM3A1SW4wLmMwRFVfQmRzd25mRE5LZTlMNlh4dlE="
);

const KIGALI_PARKING_STATIONS = [
  { id: "station-001", name: "Kigali Convention Centre", latitude: -1.9536, longitude: 29.8894 },
  { id: "station-002", name: "Kigali Heights", latitude: -1.9496, longitude: 29.8767 },
  { id: "station-003", name: "Nyabugogo Bus Park", latitude: -1.9390, longitude: 29.8518 },
  { id: "station-004", name: "Kimironko Market", latitude: -1.9400, longitude: 29.8980 },
  { id: "station-005", name: "Kigali City Tower", latitude: -1.9437, longitude: 29.8759 },
  { id: "station-006", name: "Remera Stadium", latitude: -1.9478, longitude: 29.8990 },
  { id: "station-007", name: "University of Rwanda - Gikondo", latitude: -1.9652, longitude: 29.8730 },
  { id: "station-008", name: "Kicukiro Centre", latitude: -1.9740, longitude: 29.8640 }
];

let mapInstance = null;
const mapMarkers = new Map();
const parkingMarkers = new Map();

function loadAuditLogs() {
  try {
    const raw = localStorage.getItem(auditStorageKey);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

function saveAuditLogs(logs) {
  try {
    localStorage.setItem(auditStorageKey, JSON.stringify(logs.slice(0, 100)));
  } catch {}
}

const state = {
  apiBaseUrl: resolveApiBaseUrl(),
  token: localStorage.getItem(tokenStorageKey) ?? "",
  adminEmail: localStorage.getItem(adminEmailStorageKey) ?? "admin@isoko.rw",
  fleet: null,
  query: "",
  filter: "all",
  viewMode: localStorage.getItem("isoko-view-mode") ?? "split",
  selectedId: null,
  loading: false,
  actionBusy: null,
  error: null,
  notice: null,
  loginEmail: "",
  loginPassword: "",
  loginLoading: false,
  loginError: null,
  showPassword: false,
  showParkingZones: localStorage.getItem("isoko-parking-zones") !== "0",
  sideTab: "details",
  auditLogs: loadAuditLogs()
};

const root = document.getElementById("root");

render();

if (state.token) {
  void refreshFleet();
}

function render() {
  if (!state.token) {
    renderLogin();
  } else {
    renderDashboard();
  }
}

/* ==========================================================================
   1. Production Login View
   ========================================================================== */

function renderLogin() {
  root.innerHTML = `
    <div class="login-shell">
      <div class="login-card">
        <header class="login-header">
          <div class="login-brand-mark">
            <img src="/src/assets/logo.png" alt="ISOKO" />
          </div>
          <h1>ISOKO Admin</h1>
          <p>Fleet Operations & Security Console</p>
        </header>

        <form class="login-form" id="login-form">
          ${state.loginError ? `<div class="login-error-alert">&#9888; ${escapeHtml(state.loginError)}</div>` : ""}

          <div class="form-group">
            <label for="login-email">Email or Username</label>
            <input 
              id="login-email" 
              type="text" 
              autocomplete="username" 
              placeholder="admin@isoko.rw" 
              value="${escapeHtml(state.loginEmail)}" 
              required 
            />
          </div>

          <div class="form-group">
            <label for="login-password">Password</label>
            <div class="input-wrapper">
              <input 
                id="login-password" 
                type="${state.showPassword ? "text" : "password"}" 
                autocomplete="current-password" 
                placeholder="Enter password" 
                value="${escapeHtml(state.loginPassword)}" 
                required 
              />
              <button 
                type="button" 
                class="toggle-password-btn" 
                id="toggle-password-btn" 
                title="${state.showPassword ? "Hide password" : "Show password"}"
              >
                ${state.showPassword ? "✕" : "👁"}
              </button>
            </div>
          </div>

          <button type="submit" class="btn-primary-submit" id="login-submit-btn" ${state.loginLoading ? "disabled" : ""}>
            ${state.loginLoading ? `<span class="btn-spinner"></span> Signing in...` : `Sign In to Console`}
          </button>
        </form>
      </div>
    </div>
  `;

  const loginForm = document.getElementById("login-form");
  const emailInput = document.getElementById("login-email");
  const passwordInput = document.getElementById("login-password");
  const togglePasswordBtn = document.getElementById("toggle-password-btn");

  emailInput?.addEventListener("input", (e) => {
    state.loginEmail = e.target.value;
  });

  passwordInput?.addEventListener("input", (e) => {
    state.loginPassword = e.target.value;
  });

  togglePasswordBtn?.addEventListener("click", () => {
    state.showPassword = !state.showPassword;
    render();
  });

  loginForm?.addEventListener("submit", (e) => {
    e.preventDefault();
    void handleLogin(state.loginEmail, state.loginPassword);
  });
}

async function handleLogin(email, password) {
  state.loginLoading = true;
  state.loginError = null;
  render();

  try {
    const loginUrl = new URL("/admin/login", normalizeBaseUrl(state.apiBaseUrl)).href;
    const response = await fetch(loginUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json"
      },
      body: JSON.stringify({ email, password })
    });

    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      throw new Error(data?.message || data?.error || `Invalid credentials (HTTP ${response.status})`);
    }

    if (!data.token) {
      throw new Error("No authorization token received from server.");
    }

    state.token = data.token;
    state.adminEmail = data.admin?.email || email;
    state.loginLoading = false;
    state.loginPassword = "";

    localStorage.setItem(tokenStorageKey, state.token);
    localStorage.setItem(adminEmailStorageKey, state.adminEmail);

    render();
    await refreshFleet();
  } catch (error) {
    state.loginLoading = false;
    if (error.message.includes("Failed to fetch") || error.message.includes("Connection error")) {
      state.loginError = `Cannot connect to API server at ${state.apiBaseUrl}. Please verify the server is running.`;
    } else {
      state.loginError = error instanceof Error ? error.message : "Unable to authenticate.";
    }
    render();
  }
}

function handleLogout() {
  state.token = "";
  state.fleet = null;
  state.selectedId = null;
  state.error = null;
  state.notice = null;
  state.loginError = null;
  localStorage.removeItem(tokenStorageKey);
  localStorage.removeItem(adminEmailStorageKey);
  if (mapInstance) {
    try {
      mapInstance.remove();
    } catch {}
    mapInstance = null;
    mapMarkers.clear();
  }
  render();
}

/* ==========================================================================
   2. Production Dashboard View
   ========================================================================== */

function renderDashboard() {
  root.innerHTML = `
    <main class="shell">
      <header class="topbar">
        <div class="brand">
          <div class="brand-mark"><img src="/src/assets/logo.png" alt="ISOKO" /></div>
          <div>
            <h1>ISOKO Admin</h1>
            <p>Fleet operations console</p>
          </div>
        </div>
        <div class="topbar-actions">
          <div class="admin-session-badge">
            <span class="active-pulse"></span>
            <span>${escapeHtml(state.adminEmail)}</span>
          </div>
          <button class="icon-button" id="refresh-button" type="button" title="Refresh fleet">&#8635;</button>
          <button class="sign-out-btn" id="logout-button" type="button" title="Sign out">
            <span>&#8618;</span> Sign out
          </button>
        </div>
      </header>

      <div id="status-area"></div>

      <section class="metrics-grid" id="metrics-grid"></section>

      <section class="fleet-health-bar" id="fleet-health-bar"></section>

      <section class="controls">
        <div class="search">
          <span>&#8981;</span>
          <input id="query-input" placeholder="Search device ID or code" value="${escapeHtml(state.query)}" />
        </div>
        <div class="controls-right-group" style="display:flex; gap:10px; align-items:center; flex-wrap:wrap;">
          <div class="segments" aria-label="Fleet filter">
            <button data-filter="all" class="${state.filter === "all" ? "active" : ""}" type="button">All</button>
            <button data-filter="online" class="${state.filter === "online" ? "active" : ""}" type="button">Online</button>
            <button data-filter="alerts" class="${state.filter === "alerts" ? "active" : ""}" type="button">Alerts</button>
            <button data-filter="low_battery" class="${state.filter === "low_battery" ? "active" : ""}" type="button">Low Batt</button>
            <button data-filter="pending_gps" class="${state.filter === "pending_gps" ? "active" : ""}" type="button">No GPS</button>
          </div>
          <div class="view-segments" aria-label="View mode">
            <button data-view="split" class="${state.viewMode === "split" ? "active" : ""}" type="button" title="Split view">
              <span>&#x25EB;</span> Split
            </button>
            <button data-view="map" class="${state.viewMode === "map" ? "active" : ""}" type="button" title="Map only">
              <span>&#x1F5FA;</span> Map
            </button>
            <button data-view="table" class="${state.viewMode === "table" ? "active" : ""}" type="button" title="Table only">
              <span>&#x2637;</span> Table
            </button>
          </div>
        </div>
      </section>

      <section class="workspace view-${state.viewMode}">
        <div class="fleet-workspace-main">
          <div class="fleet-map-container ${state.viewMode === "map" ? "view-map-expanded" : ""}" id="fleet-map-container" style="${state.viewMode === "table" ? "display:none;" : ""}">
            <div id="fleet-map"></div>
            <div class="map-overlay-top">
              <div class="map-status-pill">
                <span class="map-status-dot"></span>
                <span id="map-status-text">Locating fleet...</span>
              </div>
              <div class="map-actions-group">
                <button type="button" class="map-control-btn" id="map-fit-bounds-btn" title="Fit all located scooters">
                  <span>&#x2922;</span> Fit Fleet
                </button>
                <button type="button" class="map-control-btn" id="map-kigali-btn" title="Focus Kigali stations">
                  <span>&#x1F4CD;</span> Kigali
                </button>
                <button type="button" class="map-control-btn ${state.showParkingZones ? "active" : ""}" id="map-parking-btn" title="Toggle Kigali designated parking zones">
                  <span>&#x1F17F;</span> Parking
                </button>
              </div>
            </div>
            <div class="map-pending-drawer" id="map-pending-drawer" style="display:none;"></div>
          </div>
          <div class="fleet-table" id="fleet-table" style="${state.viewMode === "map" ? "display:none;" : ""}"></div>
        </div>
        <aside class="side-panel">
          <div class="side-panel-tabs">
            <button type="button" class="side-panel-tab ${state.sideTab === "details" ? "active" : ""}" data-sidetab="details">
              <span>&#x1F527;</span> Diagnostics
            </button>
            <button type="button" class="side-panel-tab ${state.sideTab === "audit" ? "active" : ""}" data-sidetab="audit">
              <span>&#x1F4DC;</span> Audit Log
              <span class="side-tab-badge" id="audit-tab-count">${state.auditLogs.length}</span>
            </button>
            <button type="button" class="side-panel-tab ${state.sideTab === "events" ? "active" : ""}" data-sidetab="events">
              <span>&#x1F514;</span> Alerts
              <span class="side-tab-badge" id="events-tab-count">0</span>
            </button>
          </div>
          <div class="side-panel-body">
            <section class="panel details" id="details-panel" style="${state.sideTab === "details" ? "" : "display:none;"}"></section>
            <section class="panel audit" id="audit-panel" style="${state.sideTab === "audit" ? "" : "display:none;"}"></section>
            <section class="panel events" id="events-panel" style="${state.sideTab === "events" ? "" : "display:none;"}"></section>
          </div>
        </aside>
      </section>
    </main>
  `;

  document.getElementById("refresh-button")?.addEventListener("click", () => void refreshFleet());
  document.getElementById("logout-button")?.addEventListener("click", handleLogout);

  const queryInput = document.getElementById("query-input");
  queryInput?.addEventListener("input", () => {
    state.query = queryInput.value;
    updateDashboardContent();
  });

  document.querySelectorAll("[data-filter]").forEach((button) => {
    button.addEventListener("click", () => {
      state.filter = button.dataset.filter;
      document.querySelectorAll("[data-filter]").forEach((item) => item.classList.toggle("active", item === button));
      updateDashboardContent();
    });
  });

  document.querySelectorAll("[data-view]").forEach((button) => {
    button.addEventListener("click", () => {
      state.viewMode = button.dataset.view;
      localStorage.setItem("isoko-view-mode", state.viewMode);
      document.querySelectorAll("[data-view]").forEach((item) => item.classList.toggle("active", item === button));
      updateDashboardContent();
    });
  });

  document.querySelectorAll("[data-sidetab]").forEach((tabBtn) => {
    tabBtn.addEventListener("click", () => {
      state.sideTab = tabBtn.dataset.sidetab;
      document.querySelectorAll("[data-sidetab]").forEach((btn) => btn.classList.toggle("active", btn === tabBtn));
      const details = document.getElementById("details-panel");
      const audit = document.getElementById("audit-panel");
      const events = document.getElementById("events-panel");
      if (details) details.style.display = state.sideTab === "details" ? "" : "none";
      if (audit) audit.style.display = state.sideTab === "audit" ? "" : "none";
      if (events) events.style.display = state.sideTab === "events" ? "" : "none";
    });
  });

  document.getElementById("map-fit-bounds-btn")?.addEventListener("click", () => {
    const scooters = filterScooters(state.fleet?.scooters ?? [], state.query, state.filter);
    fitFleetBounds(scooters);
  });

  document.getElementById("map-kigali-btn")?.addEventListener("click", () => {
    mapInstance?.flyTo({ center: [29.8894, -1.9536], zoom: 13, duration: 1200 });
  });

  document.getElementById("map-parking-btn")?.addEventListener("click", (e) => {
    state.showParkingZones = !state.showParkingZones;
    localStorage.setItem("isoko-parking-zones", state.showParkingZones ? "1" : "0");
    e.currentTarget.classList.toggle("active", state.showParkingZones);
    syncParkingZonesWithMap();
  });

  updateDashboardContent();
}

function updateDashboardContent() {
  const statusArea = document.getElementById("status-area");
  const metricsGrid = document.getElementById("metrics-grid");
  const fleetHealthBar = document.getElementById("fleet-health-bar");
  const fleetTable = document.getElementById("fleet-table");
  const detailsPanel = document.getElementById("details-panel");
  const auditPanel = document.getElementById("audit-panel");
  const eventsPanel = document.getElementById("events-panel");
  const auditTabCount = document.getElementById("audit-tab-count");
  const eventsTabCount = document.getElementById("events-tab-count");
  const refreshButton = document.getElementById("refresh-button");

  if (!fleetTable) return;

  const scooters = filterScooters(state.fleet?.scooters ?? [], state.query, state.filter);
  const selected =
    scooters.find((scooter) => scooter.id === state.selectedId) ??
    (state.fleet?.scooters ?? []).find((scooter) => scooter.id === state.selectedId) ??
    scooters[0] ??
    (state.fleet?.scooters ?? [])[0] ??
    null;
  const events = buildEvents(state.fleet?.scooters ?? []);

  statusArea.innerHTML = [
    state.error ? `<div class="alert error">${escapeHtml(state.error)}</div>` : "",
    state.notice ? `<div class="alert success">${escapeHtml(state.notice)}</div>` : ""
  ].join("");

  metricsGrid.innerHTML = metricCards(state.fleet?.metrics ?? emptyMetrics());
  if (fleetHealthBar) {
    fleetHealthBar.innerHTML = fleetHealthBarHtml(state.fleet?.scooters ?? []);
  }

  fleetTable.innerHTML = tableHtml(scooters, selected);
  detailsPanel.innerHTML = detailsHtml(selected);
  if (auditPanel) {
    auditPanel.innerHTML = auditHtml(state.auditLogs);
  }
  eventsPanel.innerHTML = eventsHtml(events);

  if (auditTabCount) {
    auditTabCount.textContent = String(state.auditLogs.length);
  }
  if (eventsTabCount) {
    eventsTabCount.textContent = String(events.length);
  }

  // Bind audit actions
  document.getElementById("clear-audit-btn")?.addEventListener("click", () => {
    state.auditLogs = [];
    saveAuditLogs([]);
    updateDashboardContent();
  });
  document.getElementById("export-audit-btn")?.addEventListener("click", () => {
    exportAuditLogs();
  });

  // Bind detail focus map button
  document.getElementById("detail-focus-map-btn")?.addEventListener("click", (e) => {
    const scooterId = e.currentTarget.dataset.scooter;
    if (scooterId) {
      if (state.viewMode === "table") {
        state.viewMode = "split";
        localStorage.setItem("isoko-view-mode", "split");
        document.querySelectorAll("[data-view]").forEach((item) => item.classList.toggle("active", item.dataset.view === "split"));
        const mapContainer = document.getElementById("fleet-map-container");
        if (mapContainer) mapContainer.style.display = "block";
      }
      flyToScooter(scooterId);
    }
  });

  initOrUpdateMap(scooters);

  if (refreshButton) {
    refreshButton.classList.toggle("spin", state.loading);
    refreshButton.disabled = state.loading;
  }
}

async function refreshFleet() {
  if (!state.token) {
    render();
    return;
  }

  state.loading = true;
  state.error = null;
  updateDashboardContent();

  try {
    const response = await requestJson(`/admin/fleet?limit=500`, { method: "GET" });
    state.fleet = response;
    const count = response.scooters?.length ?? 0;
    state.notice = count > 0 ? `Fleet updated: ${count} scooter${count === 1 ? "" : "s"} loaded.` : null;
    if (!state.selectedId && count > 0) {
      state.selectedId = response.scooters[0]?.id ?? null;
    }
  } catch (error) {
    state.error = error instanceof Error ? error.message : "Unable to load fleet data.";
  } finally {
    state.loading = false;
    updateDashboardContent();
  }
}

async function runAction(scooter, action) {
  const startTime = performance.now();
  state.actionBusy = `${scooter.id}:${action}`;
  state.notice = null;
  state.error = null;
  updateDashboardContent();

  const auditEntry = {
    id: `cmd-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
    timestamp: new Date().toISOString(),
    scooterId: scooter.id,
    scooterCode: displayCode(scooter),
    deviceId: scooter.deviceId,
    action: action.toUpperCase(),
    status: "dispatched",
    latencyMs: null,
    error: null,
    commandRecord: null
  };

  try {
    const result = await requestJson(actionPath(scooter.id, action), { method: "POST" });
    const latencyMs = Math.round(performance.now() - startTime);
    auditEntry.status = "acknowledged";
    auditEntry.latencyMs = latencyMs;
    auditEntry.commandRecord = result?.command ?? null;
    state.notice = `${label(action)} command sent for ${displayCode(scooter)} (${latencyMs}ms).`;
    await refreshFleet();
  } catch (error) {
    const latencyMs = Math.round(performance.now() - startTime);
    auditEntry.status = "failed";
    auditEntry.latencyMs = latencyMs;
    auditEntry.error = error instanceof Error ? error.message : "Command failed.";
    state.error = auditEntry.error;
  } finally {
    state.actionBusy = null;
    state.auditLogs.unshift(auditEntry);
    if (state.auditLogs.length > 100) {
      state.auditLogs = state.auditLogs.slice(0, 100);
    }
    saveAuditLogs(state.auditLogs);
    updateDashboardContent();
  }
}

async function requestJson(path, options) {
  const headers = {
    Accept: "application/json",
    Authorization: `Bearer ${state.token}`
  };

  if (options.body !== undefined) {
    headers["Content-Type"] = "application/json";
  }

  const url = new URL(path, normalizeBaseUrl(state.apiBaseUrl));
  let response;

  try {
    response = await fetch(url, {
      method: options.method,
      headers,
      ...(options.body !== undefined ? { body: JSON.stringify(options.body) } : {})
    });
  } catch (err) {
    throw new Error(`Cannot reach ${state.apiBaseUrl}. Ensure the server is online and reachable.`);
  }

  if (response.status === 401 || response.status === 403) {
    state.token = "";
    localStorage.removeItem(tokenStorageKey);
    state.loginError = "Session expired or unauthorized. Please sign in again.";
    render();
    throw new Error("Session expired.");
  }

  const bodyText = await response.text();
  const body = parseResponseBody(bodyText);

  if (!response.ok) {
    const detail = typeof body === "string" ? body : body?.message || body?.error;
    throw new Error(`${response.status} ${response.statusText}${detail ? `: ${detail}` : ""}`);
  }

  return body;
}

function parseResponseBody(bodyText) {
  if (!bodyText) {
    return {};
  }

  try {
    return JSON.parse(bodyText);
  } catch {
    return bodyText.replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim().slice(0, 180);
  }
}

function metricCards(metrics) {
  return [
    metricCard("Fleet", metrics.total, "Scooters"),
    metricCard("Online", metrics.online, `${metrics.offline} offline`),
    metricCard("Locked", metrics.locked, `${metrics.unlocked} unlocked`),
    metricCard("Alerts", metrics.alerts, `${metrics.lowBattery} low battery`)
  ].join("");
}

function metricCard(label, value, caption) {
  return `
    <article class="metric">
      <div class="metric-icon">&#9679;</div>
      <div>
        <span>${escapeHtml(label)}</span>
        <strong>${value}</strong>
        <small>${escapeHtml(caption)}</small>
      </div>
    </article>
  `;
}

function tableHtml(scooters, selected) {
  if (!scooters || scooters.length === 0) {
    return `<div class="empty">No scooters currently registered in the fleet.</div>`;
  }

  return `
    <table>
      <thead>
        <tr>
          <th>Scooter</th>
          <th>Status</th>
          <th>Battery</th>
          <th>Lock</th>
          <th>Last seen</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        ${scooters
          .map(
            (scooter) => `
            <tr class="${selected?.id === scooter.id ? "selected" : ""}" data-select="${scooter.id}">
              <td>${identityHtml(scooter)}</td>
              <td>${statusHtml(scooter)}</td>
              <td>${batteryLabel(scooter)}</td>
              <td>${lockLabel(scooter.lockState)}</td>
              <td>${timeAgo(scooter.lastHeartbeatAt)}</td>
              <td>${actionButtonsHtml(scooter)}</td>
            </tr>
          `
          )
          .join("")}
      </tbody>
    </table>
  `;
}

function detailsHtml(scooter) {
  if (!scooter) {
    return `<div class="empty">Select a scooter to view hardware and location details.</div>`;
  }

  const hasGps = isGpsLocked(scooter);

  return `
    ${identityHtml(scooter)}
    ${statusHtml(scooter)}
    ${
      hasGps
        ? `<button type="button" class="btn-focus-map" id="detail-focus-map-btn" data-scooter="${scooter.id}">
            <span>&#x1F5FA;</span> Center & Focus on Map
          </button>`
        : ""
    }
    <dl>
      <dt>Lock</dt><dd>${lockLabel(scooter.lockState)}</dd>
      <dt>Ride</dt><dd>${rideLabel(scooter.rideState)}</dd>
      <dt>Battery</dt><dd>${batteryLabel(scooter)}</dd>
      <dt>Signal</dt><dd>${signalLabel(scooter)}</dd>
      <dt>CCID</dt><dd>${escapeHtml(scooter.simCcid ?? "--")}</dd>
      <dt>GPS</dt><dd>${gpsLabel(scooter)}</dd>
    </dl>
    ${expandedActionsHtml(scooter)}
  `;
}

function fleetHealthBarHtml(scooters) {
  const total = scooters.length;
  if (total === 0) return "";

  const online = scooters.filter((s) => s.status === "online").length;
  const onlinePercent = Math.round((online / total) * 100);

  const validBatteries = scooters.map((s) => s.batteryPercent).filter((b) => b != null);
  const avgBattery =
    validBatteries.length > 0
      ? Math.round(validBatteries.reduce((a, b) => a + b, 0) / validBatteries.length)
      : "--";
  const lowestBattery = validBatteries.length > 0 ? Math.min(...validBatteries) : "--";

  const located = scooters.filter(isGpsLocked).length;
  const locked = scooters.filter((s) => s.lockState === "locked").length;
  const unlocked = scooters.filter((s) => s.lockState === "unlocked").length;

  return `
    <div class="health-item">
      <span class="health-label">Online Fleet Connectivity</span>
      <div class="health-meter-wrap">
        <div class="health-meter-bar" style="width: ${onlinePercent}%;"></div>
      </div>
      <strong class="health-value ${online === 0 ? "text-danger" : "text-success"}">
        ${online} / ${total} Units (${onlinePercent}%)
      </strong>
    </div>
    <div class="health-item">
      <span class="health-label">Average Battery</span>
      <strong class="health-value ${typeof avgBattery === "number" && avgBattery < 30 ? "text-danger" : "text-success"}">
        ${avgBattery}% <small style="font-weight:400; color:var(--secondary); font-size:11px;">(Min: ${lowestBattery}%)</small>
      </strong>
    </div>
    <div class="health-item">
      <span class="health-label">GPS Satellites Fix</span>
      <strong class="health-value text-accent">
        ${located} / ${total} Located <small style="font-weight:400; color:var(--secondary); font-size:11px;">(${total - located} pending)</small>
      </strong>
    </div>
    <div class="health-item">
      <span class="health-label">Physical Lock States</span>
      <strong class="health-value">
        ${locked} Locked • ${unlocked} Unlocked
      </strong>
    </div>
  `;
}

function auditHtml(logs) {
  if (!logs || logs.length === 0) {
    return `
      <div class="audit-panel-header">
        <h2>Live Command Audit</h2>
      </div>
      <div class="empty">No commands dispatched in this session yet. Dispatched Lock, Unlock, or Record requests will appear here in real time.</div>
    `;
  }

  return `
    <div class="audit-panel-header">
      <h2>Live Command Audit</h2>
      <div class="audit-header-actions">
        <button type="button" class="audit-btn" id="export-audit-btn" title="Download audit log JSON">&#x21E9; Export</button>
        <button type="button" class="audit-btn" id="clear-audit-btn" title="Clear session logs">&#x2715; Clear</button>
      </div>
    </div>
    <div class="audit-list">
      ${logs
        .map(
          (log) => `
        <article class="audit-card">
          <div class="audit-card-top">
            <span class="audit-badge ${log.action.toLowerCase()}">${escapeHtml(log.action)}</span>
            <span class="audit-latency">${log.latencyMs != null ? `⚡ ${log.latencyMs}ms` : "in flight..."}</span>
          </div>
          <div class="audit-card-target">
            ${escapeHtml(log.scooterCode)}
            <small>${escapeHtml(log.deviceId)}</small>
          </div>
          <div class="audit-card-meta">
            <span class="audit-status ${log.status}">
              ${
                log.status === "acknowledged"
                  ? "✔ ACK 00 / OK"
                  : log.status === "failed"
                  ? "✖ FAILED"
                  : "⏳ DISPATCHED"
              }
            </span>
            <time>${timeAgo(log.timestamp)}</time>
          </div>
          ${
            log.error
              ? `<div class="alert error" style="margin-top:6px; padding:6px; font-size:11px;">${escapeHtml(
                  log.error
                )}</div>`
              : ""
          }
          ${
            log.commandRecord
              ? `
            <details class="audit-raw-details">
              <summary>Command Record Payload</summary>
              <pre>${escapeHtml(JSON.stringify(log.commandRecord, null, 2))}</pre>
            </details>
          `
              : ""
          }
        </article>
      `
        )
        .join("")}
    </div>
  `;
}

function exportAuditLogs() {
  const dataStr =
    "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(state.auditLogs, null, 2));
  const downloadAnchor = document.createElement("a");
  downloadAnchor.setAttribute("href", dataStr);
  downloadAnchor.setAttribute("download", `isoko-command-audit-${new Date().toISOString().slice(0, 10)}.json`);
  document.body.appendChild(downloadAnchor);
  downloadAnchor.click();
  downloadAnchor.remove();
}

function eventsHtml(events) {
  if (!events || events.length === 0) {
    return `<div class="empty">No recent fleet alerts or events recorded.</div>`;
  }

  return events
    .map(
      (event) => `
        <article class="event ${event.severity}">
          <div>&#9679;</div>
          <div>
            <strong>${escapeHtml(event.title)}</strong>
            <p>${escapeHtml(event.detail)}</p>
          </div>
          <time>${timeAgo(event.createdAt)}</time>
        </article>
      `
    )
    .join("");
}

function identityHtml(scooter) {
  return `
    <div class="identity">
      <div></div>
      <div>
        <strong>${escapeHtml(displayCode(scooter))}</strong>
        <span>${escapeHtml(scooter.deviceId)}</span>
      </div>
    </div>
  `;
}

function statusHtml(scooter) {
  const online = scooter.status === "online";
  return `
    <span class="status ${online ? "online" : "offline"}">
      ${online ? "Online" : "Offline"}
    </span>
  `;
}

function actionButtonsHtml(scooter) {
  return actionButtons(scooter, false);
}

function expandedActionsHtml(scooter) {
  return actionButtons(scooter, true);
}

function actionButtons(scooter, expanded) {
  const buttons = [
    ["lock", "Lock"],
    ["unlock", "Unlock"],
    ["records", "Records"],
    ["ccid", "CCID"],
    ["update", "Update"]
  ];

  return `
    <div class="actions ${expanded ? "expanded" : ""}">
      ${buttons
        .map(
          ([action, labelText]) => `
            <button type="button" data-action="${action}" data-scooter="${scooter.id}" title="${labelText}" ${
            state.actionBusy ? "disabled" : ""
          }>
              ${escapeHtml(labelText)}
            </button>
          `
        )
        .join("")}
    </div>
  `;
}

document.addEventListener("click", (event) => {
  const action = event.target.closest?.("[data-action]");
  if (action) {
    const scooter = (state.fleet?.scooters ?? []).find((item) => item.id === action.dataset.scooter);
    if (scooter) {
      void runAction(scooter, action.dataset.action);
    }
    return;
  }

  const select = event.target.closest?.("[data-select]");
  if (select) {
    state.selectedId = select.dataset.select;
    updateDashboardContent();
    flyToScooter(state.selectedId);
  }
});

function buildEvents(scooters) {
  const events = [];
  for (const scooter of scooters) {
    if (scooter.status === "offline") {
      events.push({
        id: `${scooter.id}:offline`,
        title: "Connection lost",
        detail: `${displayCode(scooter)} is offline`,
        severity: "critical",
        createdAt: scooter.lastHeartbeatAt
      });
    }
    if ((scooter.batteryPercent ?? 100) < lowBatteryThresholdPercent) {
      events.push({
        id: `${scooter.id}:battery`,
        title: "Low battery",
        detail: `${displayCode(scooter)} is at ${batteryLabel(scooter)}`,
        severity: "warning",
        createdAt: scooter.updatedAt
      });
    }
    if (scooter.rideState === "in_ride") {
      events.push({
        id: `${scooter.id}:ride`,
        title: "Ride in progress",
        detail: `${displayCode(scooter)} is currently rented`,
        severity: "info",
        createdAt: scooter.updatedAt
      });
    }
  }
  return events
    .sort((a, b) => Date.parse(b.createdAt ?? "") - Date.parse(a.createdAt ?? ""))
    .slice(0, 6);
}

function filterScooters(scooters, query, filter) {
  const normalizedQuery = query.trim().toLowerCase();

  return scooters.filter((scooter) => {
    const isAlert =
      scooter.status === "offline" || (scooter.batteryPercent ?? 100) < lowBatteryThresholdPercent;
    const isLowBatt = (scooter.batteryPercent ?? 100) < lowBatteryThresholdPercent;
    const isNoGps = !isGpsLocked(scooter);

    const matchesFilter =
      filter === "all" ||
      (filter === "online" && scooter.status === "online") ||
      (filter === "alerts" && isAlert) ||
      (filter === "low_battery" && isLowBatt) ||
      (filter === "pending_gps" && isNoGps);

    if (!matchesFilter) {
      return false;
    }

    if (!normalizedQuery) {
      return true;
    }

    return (
      scooter.deviceId.toLowerCase().includes(normalizedQuery) ||
      displayCode(scooter).toLowerCase().includes(normalizedQuery) ||
      (scooter.simCcid ?? "").toLowerCase().includes(normalizedQuery)
    );
  });
}

function emptyMetrics() {
  return {
    total: 0,
    online: 0,
    offline: 0,
    locked: 0,
    unlocked: 0,
    alerts: 0,
    lowBattery: 0
  };
}

function actionPath(scooterId, action) {
  switch (action) {
    case "lock":
      return `/admin/scooters/${scooterId}/lock`;
    case "unlock":
      return `/admin/scooters/${scooterId}/unlock`;
    case "records":
      return `/admin/scooters/${scooterId}/records/read`;
    case "ccid":
      return `/admin/scooters/${scooterId}/ccid/request`;
    case "update":
      return `/admin/scooters/${scooterId}/update`;
    default:
      throw new Error(`Unsupported action: ${action}`);
  }
}

function displayCode(scooter) {
  return `ISK-${scooter.deviceId.slice(-3)}`;
}

function batteryLabel(scooter) {
  return scooter.batteryPercent == null ? "--" : `${scooter.batteryPercent}%`;
}

function signalLabel(scooter) {
  return scooter.signalStrength == null ? "--" : String(scooter.signalStrength);
}

function lockLabel(value) {
  return capitalize(value);
}

function rideLabel(value) {
  return value === "in_ride" ? "In ride" : capitalize(value);
}

function gpsLabel(scooter) {
  if (scooter.latitude == null || scooter.longitude == null) {
    return "--";
  }
  return `${scooter.latitude.toFixed(5)}, ${scooter.longitude.toFixed(5)}`;
}

function label(action) {
  return action === "records" ? "Record read" : action === "ccid" ? "CCID request" : capitalize(action);
}

function capitalize(value) {
  return value.slice(0, 1).toUpperCase() + value.slice(1).replace(/_/g, " ");
}

function timeAgo(value) {
  if (!value) {
    return "--";
  }
  const diff = Date.now() - Date.parse(value);
  if (!Number.isFinite(diff) || diff < 60_000) {
    return "Now";
  }
  const minutes = Math.floor(diff / 60_000);
  if (minutes < 60) {
    return `${minutes}m`;
  }
  const hours = Math.floor(minutes / 60);
  if (hours < 24) {
    return `${hours}h`;
  }
  return `${Math.floor(hours / 24)}d`;
}

function normalizeBaseUrl(value) {
  return value.endsWith("/") ? value : `${value}/`;
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

/* ==========================================================================
   3. Fleet Map View Implementation (Mapbox GL JS)
   ========================================================================== */

function isGpsLocked(scooter) {
  return (
    scooter.latitude != null &&
    scooter.longitude != null &&
    !isNaN(scooter.latitude) &&
    !isNaN(scooter.longitude) &&
    (Math.abs(scooter.latitude) > 0.0001 || Math.abs(scooter.longitude) > 0.0001)
  );
}

function initOrUpdateMap(scooters) {
  const mapContainer = document.getElementById("fleet-map-container");
  const mapElement = document.getElementById("fleet-map");
  if (!mapContainer || !mapElement) return;

  if (state.viewMode === "table") {
    mapContainer.style.display = "none";
    return;
  }
  mapContainer.style.display = "block";
  mapContainer.classList.toggle("view-map-expanded", state.viewMode === "map");

  const tableElement = document.getElementById("fleet-table");
  if (tableElement) {
    tableElement.style.display = state.viewMode === "map" ? "none" : "block";
  }

  if (typeof window.mapboxgl === "undefined") {
    const statusText = document.getElementById("map-status-text");
    if (statusText) statusText.textContent = "Loading Mapbox GL...";
    setTimeout(() => initOrUpdateMap(scooters), 300);
    return;
  }

  if (!mapInstance) {
    window.mapboxgl.accessToken = DEFAULT_MAPBOX_TOKEN;
    try {
      mapInstance = new window.mapboxgl.Map({
        container: "fleet-map",
        style: "mapbox://styles/mapbox/dark-v11",
        center: [30.0619, -1.9441], // Default Kigali center
        zoom: 12,
        attributionControl: false
      });

      mapInstance.addControl(new window.mapboxgl.NavigationControl({ showCompass: true }), "bottom-right");

      mapInstance.on("load", () => {
        syncMarkersWithMap(scooters, true);
        syncParkingZonesWithMap();
      });
    } catch (err) {
      console.error("Failed to initialize Mapbox:", err);
      const statusText = document.getElementById("map-status-text");
      if (statusText) statusText.textContent = "Map initialization error";
      return;
    }
  } else {
    setTimeout(() => {
      mapInstance?.resize();
    }, 60);
    if (mapInstance.isStyleLoaded()) {
      syncMarkersWithMap(scooters, false);
      syncParkingZonesWithMap();
    }
  }
}

function syncMarkersWithMap(scooters, shouldFitBounds = false) {
  if (!mapInstance) return;

  const locatedScooters = scooters.filter(isGpsLocked);
  const pendingCount = scooters.length - locatedScooters.length;

  const statusText = document.getElementById("map-status-text");
  if (statusText) {
    statusText.textContent = `${locatedScooters.length} Located • ${pendingCount} Awaiting GPS`;
  }

  const pendingDrawer = document.getElementById("map-pending-drawer");
  if (pendingDrawer) {
    if (pendingCount > 0) {
      pendingDrawer.style.display = "flex";
      pendingDrawer.innerHTML = `
        <div>
          <strong>${pendingCount} scooter${pendingCount === 1 ? "" : "s"}</strong> awaiting satellite GPS fix (will appear automatically on transmission).
        </div>
        <button type="button" class="map-control-btn" id="pending-drawer-close" style="height:26px; font-size:11px;">Dismiss</button>
      `;
      document.getElementById("pending-drawer-close")?.addEventListener("click", () => {
        pendingDrawer.style.display = "none";
      });
    } else {
      pendingDrawer.style.display = "none";
    }
  }

  // Remove markers that are no longer present
  const currentIds = new Set(locatedScooters.map((s) => s.id));
  for (const [id, entry] of mapMarkers.entries()) {
    if (!currentIds.has(id)) {
      entry.marker.remove();
      mapMarkers.delete(id);
    }
  }

  // Add or update markers
  for (const scooter of locatedScooters) {
    const isSelected = scooter.id === state.selectedId;
    const isLowBattery = (scooter.batteryPercent ?? 100) < lowBatteryThresholdPercent;
    const isOnline = scooter.status === "online";

    if (mapMarkers.has(scooter.id)) {
      const entry = mapMarkers.get(scooter.id);
      entry.marker.setLngLat([scooter.longitude, scooter.latitude]);
      entry.popup.setHTML(markerPopupHtml(scooter));

      entry.el.className = `scooter-map-marker ${isOnline ? "online" : "offline"} ${
        isLowBattery ? "low-battery" : ""
      } ${isSelected ? "selected" : ""}`;
      const battEl = entry.el.querySelector(".marker-battery");
      if (battEl) battEl.textContent = `${scooter.batteryPercent ?? "--"}%`;
    } else {
      const el = document.createElement("div");
      el.className = `scooter-map-marker ${isOnline ? "online" : "offline"} ${
        isLowBattery ? "low-battery" : ""
      } ${isSelected ? "selected" : ""}`;
      el.dataset.markerId = scooter.id;
      el.innerHTML = `
        ${isOnline ? '<div class="marker-pulse-ring"></div>' : ""}
        <div class="marker-pin">
          <span class="marker-icon">&#x1F6F4;</span>
          <span class="marker-battery">${scooter.batteryPercent ?? "--"}%</span>
        </div>
        <div class="marker-arrow"></div>
        <div class="marker-label">${escapeHtml(displayCode(scooter))}</div>
      `;

      const popup = new window.mapboxgl.Popup({
        offset: [0, -32],
        closeButton: true,
        closeOnClick: false,
        className: "isoko-dark-popup"
      }).setHTML(markerPopupHtml(scooter));

      popup.on("open", () => {
        const popupContent = popup.getElement();
        popupContent?.querySelectorAll("[data-popup-action]").forEach((btn) => {
          btn.addEventListener("click", () => {
            const action = btn.dataset.popupAction;
            const sc = (state.fleet?.scooters ?? []).find((s) => s.id === scooter.id);
            if (sc) void runAction(sc, action);
          });
        });
      });

      el.addEventListener("click", (e) => {
        e.stopPropagation();
        state.selectedId = scooter.id;
        updateDashboardContent();
        popup.addTo(mapInstance);
      });

      const marker = new window.mapboxgl.Marker({ element: el })
        .setLngLat([scooter.longitude, scooter.latitude])
        .setPopup(popup)
        .addTo(mapInstance);

      mapMarkers.set(scooter.id, { marker, popup, el });
    }
  }

  if (shouldFitBounds && locatedScooters.length > 0) {
    fitFleetBounds(locatedScooters);
  }
}

function fitFleetBounds(scooters) {
  if (!mapInstance) return;
  const located = (scooters || (state.fleet?.scooters ?? [])).filter(isGpsLocked);
  if (located.length === 0) {
    mapInstance.flyTo({ center: [30.0619, -1.9441], zoom: 12, duration: 1000 });
    return;
  }
  const bounds = new window.mapboxgl.LngLatBounds();
  located.forEach((s) => bounds.extend([s.longitude, s.latitude]));
  mapInstance.fitBounds(bounds, { padding: 65, maxZoom: 15, duration: 1100 });
}

function flyToScooter(scooterId) {
  if (!mapInstance) return;
  const scooter = (state.fleet?.scooters ?? []).find((s) => s.id === scooterId);
  if (!scooter) return;
  if (isGpsLocked(scooter)) {
    mapInstance.flyTo({
      center: [scooter.longitude, scooter.latitude],
      zoom: 15.5,
      essential: true,
      duration: 1100
    });
    const entry = mapMarkers.get(scooter.id);
    if (entry?.popup) {
      entry.popup.addTo(mapInstance);
    }
  }
}

function markerPopupHtml(scooter) {
  return `
    <div class="map-popup-card">
      <div class="map-popup-header">
        <div>
          <strong>${escapeHtml(displayCode(scooter))}</strong>
          <small>${escapeHtml(scooter.deviceId)}</small>
        </div>
        <span class="status ${scooter.status === "online" ? "online" : "offline"}">${scooter.status}</span>
      </div>
      <div class="map-popup-body">
        <div class="map-popup-stat">
          <span>Battery</span>
          <strong>${batteryLabel(scooter)}</strong>
        </div>
        <div class="map-popup-stat">
          <span>Lock</span>
          <strong>${lockLabel(scooter.lockState)}</strong>
        </div>
        <div class="map-popup-stat">
          <span>Ride</span>
          <strong>${rideLabel(scooter.rideState)}</strong>
        </div>
        <div class="map-popup-stat">
          <span>Signal</span>
          <strong>${signalLabel(scooter)}</strong>
        </div>
      </div>
      <div class="map-popup-footer">
        <button type="button" class="map-popup-btn" data-popup-action="lock" data-scooter="${scooter.id}">Lock</button>
        <button type="button" class="map-popup-btn" data-popup-action="unlock" data-scooter="${scooter.id}">Unlock</button>
      </div>
    </div>
  `;
}

function syncParkingZonesWithMap() {
  if (!mapInstance) return;

  if (!state.showParkingZones) {
    for (const [id, marker] of parkingMarkers.entries()) {
      marker.remove();
    }
    parkingMarkers.clear();
    if (mapInstance.getLayer("kigali-geofence-fills")) {
      mapInstance.removeLayer("kigali-geofence-fills");
    }
    if (mapInstance.getLayer("kigali-geofence-lines")) {
      mapInstance.removeLayer("kigali-geofence-lines");
    }
    if (mapInstance.getSource("kigali-geofences")) {
      mapInstance.removeSource("kigali-geofences");
    }
    return;
  }

  // Add station DOM markers
  for (const station of KIGALI_PARKING_STATIONS) {
    if (!parkingMarkers.has(station.id)) {
      const el = document.createElement("div");
      el.className = "parking-station-marker";
      el.innerHTML = `
        <div class="station-pulse-ring"></div>
        <div class="station-pin">&#x1F17F;</div>
        <div class="station-label">${escapeHtml(station.name)}</div>
      `;

      const popup = new window.mapboxgl.Popup({
        offset: [0, -28],
        closeButton: true,
        closeOnClick: false,
        className: "isoko-dark-popup"
      }).setHTML(`
        <div class="map-popup-card">
          <div class="map-popup-header">
            <div>
              <strong style="color:#00d2ff;">${escapeHtml(station.name)}</strong>
              <small>Designated Parking Station</small>
            </div>
            <span class="status-badge-cyan">100m Hub</span>
          </div>
          <div class="map-popup-body">
            <div class="map-popup-stat">
              <span>Latitude</span>
              <strong>${station.latitude.toFixed(4)}</strong>
            </div>
            <div class="map-popup-stat">
              <span>Longitude</span>
              <strong>${station.longitude.toFixed(4)}</strong>
            </div>
            <div class="map-popup-stat" style="grid-column:1/-1;">
              <span>Drop-Off Validation</span>
              <strong style="color:var(--green);">&#x2714; Valid Parking Zone</strong>
            </div>
          </div>
        </div>
      `);

      el.addEventListener("click", (e) => {
        e.stopPropagation();
        popup.addTo(mapInstance);
      });

      const marker = new window.mapboxgl.Marker({ element: el })
        .setLngLat([station.longitude, station.latitude])
        .setPopup(popup)
        .addTo(mapInstance);

      parkingMarkers.set(station.id, marker);
    }
  }

  // Add 100m geofence circle GeoJSON source & layers if style loaded
  if (mapInstance.isStyleLoaded() && !mapInstance.getSource("kigali-geofences")) {
    const features = KIGALI_PARKING_STATIONS.map((station) =>
      createGeoJsonCircle([station.longitude, station.latitude], 0.1, 32)
    );
    mapInstance.addSource("kigali-geofences", {
      type: "geojson",
      data: {
        type: "FeatureCollection",
        features
      }
    });

    mapInstance.addLayer({
      id: "kigali-geofence-fills",
      type: "fill",
      source: "kigali-geofences",
      paint: {
        "fill-color": "#0090e7",
        "fill-opacity": 0.14
      }
    });

    mapInstance.addLayer({
      id: "kigali-geofence-lines",
      type: "line",
      source: "kigali-geofences",
      paint: {
        "line-color": "#00d2ff",
        "line-width": 2,
        "line-opacity": 0.7,
        "line-dasharray": [2, 2]
      }
    });
  }
}

function createGeoJsonCircle(center, radiusKm = 0.1, points = 32) {
  const coords = [];
  const distanceX = radiusKm / (111.32 * Math.cos((center[1] * Math.PI) / 180));
  const distanceY = radiusKm / 110.574;
  for (let i = 0; i < points; i++) {
    const theta = (i / points) * (2 * Math.PI);
    const x = distanceX * Math.cos(theta);
    const y = distanceY * Math.sin(theta);
    coords.push([center[0] + x, center[1] + y]);
  }
  coords.push(coords[0]);
  return {
    type: "Feature",
    geometry: {
      type: "Polygon",
      coordinates: [coords]
    }
  };
}


