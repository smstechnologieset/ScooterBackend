const tokenStorageKey = "isoko-admin-token";
const adminEmailStorageKey = "isoko-admin-email";
const lowBatteryThresholdPercent = 25;

function resolveApiBaseUrl() {
  if (typeof window === "undefined") return "http://localhost:3000";
  if (window.__ISOKO_ADMIN_CONFIG__?.apiBaseUrl) {
    return window.__ISOKO_ADMIN_CONFIG__.apiBaseUrl;
  }
  const hostname = window.location.hostname;
  if (hostname === "localhost" || hostname === "127.0.0.1" || hostname.endsWith(".local")) {
    return "http://localhost:3000";
  }
  return "https://api.smstechnologieset.com";
}

const state = {
  apiBaseUrl: resolveApiBaseUrl(),
  token: localStorage.getItem(tokenStorageKey) ?? "",
  adminEmail: localStorage.getItem(adminEmailStorageKey) ?? "admin@isoko.rw",
  fleet: null,
  query: "",
  filter: "all",
  selectedId: null,
  loading: false,
  actionBusy: null,
  error: null,
  notice: null,
  loginEmail: "",
  loginPassword: "",
  loginLoading: false,
  loginError: null,
  showPassword: false
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

      <section class="controls">
        <div class="search">
          <span>&#8981;</span>
          <input id="query-input" placeholder="Search device ID or code" value="${escapeHtml(state.query)}" />
        </div>
        <div class="segments" aria-label="Fleet filter">
          <button data-filter="all" class="${state.filter === "all" ? "active" : ""}" type="button">All</button>
          <button data-filter="online" class="${state.filter === "online" ? "active" : ""}" type="button">Online</button>
          <button data-filter="alerts" class="${state.filter === "alerts" ? "active" : ""}" type="button">Alerts</button>
        </div>
      </section>

      <section class="workspace">
        <div class="fleet-table" id="fleet-table"></div>
        <aside class="side-panel">
          <section class="panel details" id="details-panel"></section>
          <section class="panel events">
            <h2>Recent events</h2>
            <div id="events-panel"></div>
          </section>
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

  updateDashboardContent();
}

function updateDashboardContent() {
  const statusArea = document.getElementById("status-area");
  const metricsGrid = document.getElementById("metrics-grid");
  const fleetTable = document.getElementById("fleet-table");
  const detailsPanel = document.getElementById("details-panel");
  const eventsPanel = document.getElementById("events-panel");
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
  fleetTable.innerHTML = tableHtml(scooters, selected);
  detailsPanel.innerHTML = detailsHtml(selected);
  eventsPanel.innerHTML = eventsHtml(events);

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
    state.notice = count > 0 ? `Fleet updated: ${count} scooter${count === 1 ? "" : "s"} online.` : null;
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
  state.actionBusy = `${scooter.id}:${action}`;
  state.notice = null;
  state.error = null;
  updateDashboardContent();

  try {
    await requestJson(actionPath(scooter.id, action), { method: "POST" });
    state.notice = `${label(action)} command sent for ${displayCode(scooter)}.`;
    await refreshFleet();
  } catch (error) {
    state.error = error instanceof Error ? error.message : "Command failed.";
  } finally {
    state.actionBusy = null;
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

  return `
    ${identityHtml(scooter)}
    ${statusHtml(scooter)}
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
    const matchesFilter =
      filter === "all" ||
      (filter === "online" && scooter.status === "online") ||
      (filter === "alerts" &&
        (scooter.status === "offline" || (scooter.batteryPercent ?? 100) < lowBatteryThresholdPercent));

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
