const tokenStorageKey = "isoko-admin-token";
const apiStorageKey = "isoko-admin-api-base-url";
const defaultApiBaseUrl = window.__ISOKO_ADMIN_CONFIG__?.apiBaseUrl ?? "http://localhost:3000";

const state = {
  apiBaseUrl: localStorage.getItem(apiStorageKey) ?? defaultApiBaseUrl,
  token: localStorage.getItem(tokenStorageKey) ?? "",
  fleet: null,
  query: "",
  filter: "all",
  selectedId: null,
  loading: false,
  actionBusy: null,
  error: null,
  notice: null
};

const root = document.getElementById("root");

root.innerHTML = `
  <main class="shell">
    <header class="topbar">
      <div class="brand">
        <div class="brand-mark">IS</div>
        <div>
          <h1>ISOKO Admin</h1>
          <p>Fleet operations</p>
        </div>
      </div>
      <button class="icon-button" id="refresh-button" type="button" title="Refresh fleet">↻</button>
    </header>

    <section class="connection-panel">
      <label>
        API base URL
        <input id="api-base-url" />
      </label>
      <label>
        Admin token
        <input id="admin-token" type="password" placeholder="Paste JWT from npm run admin:token" />
      </label>
      <button class="primary-button" id="connect-button" type="button">Connect</button>
    </section>

    <div id="status-area"></div>

    <section class="metrics-grid" id="metrics-grid"></section>

    <section class="controls">
      <div class="search">
        <span>⌕</span>
        <input id="query-input" placeholder="Search device ID" />
      </div>
      <div class="segments" aria-label="Fleet filter">
        <button data-filter="all" class="active" type="button">All</button>
        <button data-filter="online" type="button">Online</button>
        <button data-filter="alerts" type="button">Alerts</button>
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

const apiBaseUrlInput = document.getElementById("api-base-url");
const tokenInput = document.getElementById("admin-token");
const refreshButton = document.getElementById("refresh-button");
const connectButton = document.getElementById("connect-button");
const queryInput = document.getElementById("query-input");
const statusArea = document.getElementById("status-area");
const metricsGrid = document.getElementById("metrics-grid");
const fleetTable = document.getElementById("fleet-table");
const detailsPanel = document.getElementById("details-panel");
const eventsPanel = document.getElementById("events-panel");

apiBaseUrlInput.value = state.apiBaseUrl;
tokenInput.value = state.token;
queryInput.value = state.query;

apiBaseUrlInput.addEventListener("input", () => {
  state.apiBaseUrl = apiBaseUrlInput.value.trim();
  localStorage.setItem(apiStorageKey, state.apiBaseUrl);
});

tokenInput.addEventListener("input", () => {
  state.token = tokenInput.value.trim();
  if (state.token) {
    localStorage.setItem(tokenStorageKey, state.token);
  } else {
    localStorage.removeItem(tokenStorageKey);
  }
});

queryInput.addEventListener("input", () => {
  state.query = queryInput.value;
  render();
});

document.querySelectorAll("[data-filter]").forEach((button) => {
  button.addEventListener("click", () => {
    state.filter = button.dataset.filter;
    document.querySelectorAll("[data-filter]").forEach((item) => item.classList.toggle("active", item === button));
    render();
  });
});

refreshButton.addEventListener("click", () => refreshFleet());
connectButton.addEventListener("click", () => refreshFleet());

render();

if (state.token) {
  void refreshFleet();
}

async function refreshFleet() {
  if (!state.token) {
    state.error = "Paste an admin token before loading the fleet.";
    state.notice = null;
    render();
    return;
  }

  state.loading = true;
  state.error = null;
  render();

  try {
    const response = await requestJson(`/admin/fleet?limit=500`, { method: "GET" });
    state.fleet = response;
    state.notice = `Fleet loaded: ${response.scooters.length} scooter${response.scooters.length === 1 ? "" : "s"}.`;
    if (!state.selectedId) {
      state.selectedId = response.scooters[0]?.id ?? null;
    }
  } catch (error) {
    state.error = error instanceof Error ? error.message : "Unable to load fleet.";
  } finally {
    state.loading = false;
    render();
  }
}

async function runAction(scooter, action) {
  state.actionBusy = `${scooter.id}:${action}`;
  state.notice = null;
  state.error = null;
  render();

  try {
    await requestJson(actionPath(scooter.id, action), { method: "POST" });
    state.notice = `${label(action)} command sent for ${displayCode(scooter)}.`;
    await refreshFleet();
  } catch (error) {
    state.error = error instanceof Error ? error.message : "Command failed.";
  } finally {
    state.actionBusy = null;
    render();
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

  const response = await fetch(new URL(path, normalizeBaseUrl(state.apiBaseUrl)), {
    method: options.method,
    headers,
    ...(options.body !== undefined ? { body: JSON.stringify(options.body) } : {})
  });

  const bodyText = await response.text();
  const body = parseResponseBody(bodyText);

  if (!response.ok) {
    const detail = typeof body === "string" ? body : body?.message;
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

function render() {
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

  document.getElementById("api-base-url").value = state.apiBaseUrl;
  document.getElementById("admin-token").value = state.token;
  document.getElementById("query-input").value = state.query;
  refreshButton.classList.toggle("spin", state.loading);
  refreshButton.disabled = state.loading;
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
      <div class="metric-icon">●</div>
      <div>
        <span>${escapeHtml(label)}</span>
        <strong>${value}</strong>
        <small>${escapeHtml(caption)}</small>
      </div>
    </article>
  `;
}

function tableHtml(scooters, selected) {
  if (scooters.length === 0) {
    return `<div class="empty">No scooters match this view.</div>`;
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
    return `<div class="empty">No scooter selected.</div>`;
  }

  return `
    ${identityHtml(scooter)}
    ${statusHtml(scooter)}
    <dl>
      <dt>Lock</dt><dd>${lockLabel(scooter.lockState)}</dd>
      <dt>Ride</dt><dd>${rideLabel(scooter.rideState)}</dd>
      <dt>Battery</dt><dd>${batteryLabel(scooter)}</dd>
      <dt>Signal</dt><dd>${scooter.signalStrength ?? "--"}%</dd>
      <dt>CCID</dt><dd>${escapeHtml(scooter.simCcid ?? "--")}</dd>
      <dt>GPS</dt><dd>${gpsLabel(scooter)}</dd>
    </dl>
    ${expandedActionsHtml(scooter)}
  `;
}

function eventsHtml(events) {
  return events
    .map(
      (event) => `
        <article class="event ${event.severity}">
          <div>•</div>
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
      <div>■</div>
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
              ${expanded ? escapeHtml(labelText) : labelText[0]}
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
    render();
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
    if ((scooter.batteryPercent ?? 100) <= 20) {
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
  if (events.length === 0) {
    events.push({
      id: "fleet-ready",
      title: "Fleet ready",
      detail: "No operational alerts in the current snapshot.",
      severity: "info",
      createdAt: new Date().toISOString()
    });
  }
  return events
    .sort((a, b) => Date.parse(b.createdAt ?? "") - Date.parse(a.createdAt ?? ""))
    .slice(0, 6);
}

function filterScooters(scooters, query, filter) {
  const q = query.trim().toLowerCase();
  return scooters.filter((scooter) => {
    const matchesQuery = !q || scooter.deviceId.toLowerCase().includes(q);
    const matchesFilter =
      filter === "all" ||
      (filter === "online" && scooter.status === "online") ||
      (filter === "alerts" && scooterNeedsAttention(scooter));
    return matchesQuery && matchesFilter;
  });
}

function scooterNeedsAttention(scooter) {
  return scooter.status === "offline" || scooter.lockState === "unlocked" || (scooter.batteryPercent ?? 100) <= 20;
}

function emptyMetrics() {
  return { total: 0, online: 0, offline: 0, locked: 0, unlocked: 0, inRide: 0, lowBattery: 0, alerts: 0 };
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
      return `/admin/scooters/${scooterId}`;
  }
}

function displayCode(scooter) {
  return scooter.publicCode ?? scooter.deviceId;
}

function batteryLabel(scooter) {
  return scooter.batteryPercent == null ? "--" : `${scooter.batteryPercent}%`;
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
