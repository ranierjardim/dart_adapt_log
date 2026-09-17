/// Painel web servido em `GET /`. Autossuficiente: sem dependências externas.
const String panelHtml = r'''<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>adapt_log</title>
<style>
  :root {
    --bg: #f3f5f8; --surface: #ffffff; --surface-2: #e9edf2; --line: #d4dbe4;
    --ink: #172230; --ink-2: #566374; --accent: #0b7a9e; --accent-soft: #d9eef5;
    --console-bg: #14191f; --console-ink: #d7e0ea;
    --debug: #56616f; --debug-bg: #e6eaef; --info: #0b6a8a; --info-bg: #d9eef5;
    --warning: #8a5e0c; --warning-bg: #f6e9c9; --error: #a63d34; --error-bg: #f7dfdb;
    --mono: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
    --sans: -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  }
  @media (prefers-color-scheme: dark) {
    :root:not([data-theme="light"]) {
      --bg: #0f151c; --surface: #161e27; --surface-2: #1e2833; --line: #2b3847;
      --ink: #e6ebf1; --ink-2: #a1acb9; --accent: #63c4e3; --accent-soft: #143441;
      --console-bg: #0b0f14; --console-ink: #d7e0ea;
      --debug: #aeb8c4; --debug-bg: #242e39; --info: #7fcbe6; --info-bg: #143441;
      --warning: #e4ba5e; --warning-bg: #3a2d0f; --error: #f09b91; --error-bg: #3e1c19;
    }
  }
  :root[data-theme="dark"] {
    --bg: #0f151c; --surface: #161e27; --surface-2: #1e2833; --line: #2b3847;
    --ink: #e6ebf1; --ink-2: #a1acb9; --accent: #63c4e3; --accent-soft: #143441;
    --console-bg: #0b0f14; --console-ink: #d7e0ea;
    --debug: #aeb8c4; --debug-bg: #242e39; --info: #7fcbe6; --info-bg: #143441;
    --warning: #e4ba5e; --warning-bg: #3a2d0f; --error: #f09b91; --error-bg: #3e1c19;
  }
  * { box-sizing: border-box; }
  html, body { height: 100%; }
  body { margin: 0; background: var(--bg); color: var(--ink); font: 14px/1.5 var(--sans); display: flex; flex-direction: column; }
  code, pre { font-family: var(--mono); }
  button, select, input { font: inherit; color: inherit; }
  .top { display: flex; align-items: center; gap: 1rem; padding: .6rem 1rem; border-bottom: 1px solid var(--line); background: var(--surface); }
  .brand { font-weight: 600; letter-spacing: -.01em; }
  .brand .project { margin-left: .5rem; font-weight: 400; color: var(--ink-2); }
  .status { display: flex; align-items: center; gap: .4rem; color: var(--ink-2); font-size: .85rem; margin-left: auto; }
  .dot { width: .6rem; height: .6rem; border-radius: 50%; background: var(--line); }
  .dot.on { background: #2e9e6a; } .dot.off { background: var(--error); }
  .ghost { background: transparent; border: 1px solid var(--line); border-radius: 6px; padding: .3rem .7rem; cursor: pointer; }
  .ghost:hover { border-color: var(--accent); color: var(--accent); }
  .keyform { max-width: 26rem; margin: 3rem auto; padding: 1.5rem; background: var(--surface); border: 1px solid var(--line); border-radius: 10px; }
  .keyform form { display: flex; flex-direction: column; gap: .6rem; }
  .keyform input { padding: .5rem .6rem; border: 1px solid var(--line); border-radius: 6px; background: var(--bg); }
  .keyform button { padding: .5rem; border: 0; border-radius: 6px; background: var(--accent); color: #fff; cursor: pointer; }
  .error { color: var(--error); margin: .6rem 0 0; }
  main { flex: 1; display: flex; flex-direction: column; min-height: 0; }
  .filters { display: flex; flex-wrap: wrap; gap: .5rem; align-items: center; padding: .6rem 1rem; border-bottom: 1px solid var(--line); background: var(--surface); }
  .filters select, .filters input { padding: .35rem .5rem; border: 1px solid var(--line); border-radius: 6px; background: var(--bg); }
  .filters input { min-width: 14rem; }
  .count { color: var(--ink-2); font-size: .85rem; margin-left: auto; font-variant-numeric: tabular-nums; }
  .split { flex: 1; display: grid; grid-template-columns: minmax(20rem, 28rem) 1fr; min-height: 0; }
  .list { list-style: none; margin: 0; padding: 0; overflow: auto; border-right: 1px solid var(--line); background: var(--surface); }
  .row { display: grid; grid-template-columns: auto 1fr; gap: .2rem .6rem; padding: .55rem 1rem; border-bottom: 1px solid var(--line); cursor: pointer; }
  .row:hover { background: var(--surface-2); }
  .row.selected { background: var(--accent-soft); }
  .row .msg { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .row .meta { grid-column: 2; color: var(--ink-2); font-size: .78rem; font-variant-numeric: tabular-nums; }
  .chip { display: inline-block; font: 600 .68rem/1 var(--mono); letter-spacing: .06em; text-transform: uppercase; padding: .32em .5em; border-radius: 999px; align-self: start; margin-top: .15rem; }
  .chip.debug { color: var(--debug); background: var(--debug-bg); }
  .chip.info { color: var(--info); background: var(--info-bg); }
  .chip.warning { color: var(--warning); background: var(--warning-bg); }
  .chip.error { color: var(--error); background: var(--error-bg); }
  .detail { overflow: auto; padding: 1.25rem 1.5rem; display: flex; flex-direction: column; gap: 1.25rem; }
  .detail .empty { color: var(--ink-2); }
  .dhead h2 { margin: .4rem 0 .6rem; font-size: 1.15rem; line-height: 1.3; white-space: pre-wrap; }
  .facts { display: grid; grid-template-columns: auto 1fr; gap: .2rem .8rem; margin: 0; font-size: .85rem; }
  .facts dt { color: var(--ink-2); } .facts dd { margin: 0; overflow-wrap: anywhere; }
  .detail h3 { margin: 0 0 .5rem; font-size: .8rem; letter-spacing: .08em; text-transform: uppercase; color: var(--ink-2); }
  .detail h3 .sub { text-transform: none; letter-spacing: 0; font-weight: 400; margin-left: .5rem; }
  .errline { margin: 0; padding: .6rem .8rem; background: var(--error-bg); color: var(--error); border-radius: 6px; overflow-wrap: anywhere; }
  pre { margin: 0; padding: .8rem 1rem; border-radius: 8px; overflow: auto; font-size: .82rem; line-height: 1.5; }
  pre.console { background: var(--console-bg); color: var(--console-ink); }
  pre.stack { background: var(--surface-2); }
  img.shot { display: block; max-width: 100%; max-height: 70vh; border: 1px solid var(--line); border-radius: 10px; background: var(--surface-2); }
  .kv { border-collapse: collapse; width: 100%; font-size: .85rem; }
  .kv th { text-align: left; font-weight: 500; color: var(--ink-2); padding: .3rem .6rem .3rem 0; vertical-align: top; white-space: nowrap; }
  .kv td { padding: .3rem 0; overflow-wrap: anywhere; font-family: var(--mono); font-size: .8rem; }
  .kv tr { border-bottom: 1px solid var(--line); }
  a { color: var(--accent); }
  @media (max-width: 900px) {
    .split { grid-template-columns: 1fr; grid-template-rows: minmax(0, 45%) 1fr; }
    .list { border-right: 0; border-bottom: 1px solid var(--line); }
  }
</style>
</head>
<body>
<header class="top">
  <div class="brand">adapt_log <span id="project" class="project"></span></div>
  <div class="status"><span id="live" class="dot"></span><span id="liveText">desconectado</span></div>
  <button id="changeKey" class="ghost" type="button">chave</button>
</header>
<section id="keyForm" class="keyform" hidden>
  <form id="keyFormEl">
    <label for="apiKey">Chave de API do projeto</label>
    <input id="apiKey" type="password" autocomplete="off" required>
    <button type="submit">Entrar</button>
  </form>
  <p id="keyError" class="error" hidden></p>
</section>
<main id="app" hidden>
  <div class="filters">
    <select id="level" aria-label="nível">
      <option value="">todos os níveis</option>
      <option value="error">error</option>
      <option value="warning">warning</option>
      <option value="info">info</option>
      <option value="debug">debug</option>
    </select>
    <select id="session" aria-label="sessão"><option value="">todas as sessões</option></select>
    <input id="search" type="search" placeholder="buscar na mensagem" aria-label="buscar">
    <button id="reload" class="ghost" type="button">atualizar</button>
    <span id="count" class="count"></span>
  </div>
  <div class="split">
    <ul id="list" class="list"></ul>
    <article id="detail" class="detail"><p class="empty">Selecione uma entry.</p></article>
  </div>
</main>
<script>
(function () {
  const $ = (id) => document.getElementById(id);
  const state = { key: '', entries: [], selected: null, ws: null, sessions: [] };
  try { state.key = localStorage.getItem('adaptLogKey') || ''; } catch (e) {}
  // Pontos de extensão (a prévia estática substitui a URL da imagem).
  const panelApi = window.adaptLogPanel = Object.assign({
    screenshotUrl: (id) => '/v1/logs/' + encodeURIComponent(id) + '/screenshot?key=' + encodeURIComponent(state.key),
  }, window.adaptLogPanel || {});

  function esc(value) {
    return String(value).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  }
  function fmtTime(iso) {
    const d = new Date(iso);
    if (isNaN(d)) return iso;
    return d.toLocaleString('pt-BR', { hour12: false }) + '.' + String(d.getMilliseconds()).padStart(3, '0');
  }
  function shortId(id) { return id ? id.slice(-6) : ''; }

  async function api(path) {
    const r = await fetch(path, { headers: { authorization: 'Bearer ' + state.key } });
    if (r.status === 401 || r.status === 403) throw new Error('chave recusada pelo servidor');
    if (!r.ok) throw new Error('erro ' + r.status);
    return r.json();
  }

  function filters() {
    return { level: $('level').value, session: $('session').value, search: $('search').value.trim() };
  }
  function matches(e) {
    const f = filters();
    if (f.level && e.level !== f.level) return false;
    if (f.session && e.sessionId !== f.session) return false;
    if (f.search && !String(e.message).toLowerCase().includes(f.search.toLowerCase())) return false;
    return true;
  }

  async function load() {
    const f = filters();
    const q = new URLSearchParams({ limit: '200' });
    if (f.level) q.set('level', f.level);
    if (f.session) q.set('session', f.session);
    if (f.search) q.set('search', f.search);
    const data = await api('/v1/logs?' + q.toString());
    state.entries = data.entries;
    if (state.selected && !state.entries.some((e) => e.id === state.selected.id)) state.selected = null;
    if (!state.selected && state.entries.length) {
      state.selected = state.entries.find((e) => e.level === 'error') || state.entries[0];
    }
    renderList();
    renderDetail();
  }
  async function loadSessions() {
    const data = await api('/v1/sessions?limit=200');
    state.sessions = data.sessions;
    const sel = $('session');
    const current = sel.value;
    sel.innerHTML = '<option value="">todas as sessões</option>' + state.sessions.map((s) => {
      const label = s.metadata['app.name'] || s.metadata['app.version'] || '';
      return '<option value="' + esc(s.id) + '">' + esc(shortId(s.id)) + (label ? ' · ' + esc(label) : '') + ' · ' + s.errorCount + ' erros</option>';
    }).join('');
    sel.value = current;
  }

  function setLive(on) {
    $('live').className = 'dot ' + (on ? 'on' : 'off');
    $('liveText').textContent = on ? 'ao vivo' : 'reconectando…';
  }
  function connect() {
    if (state.ws) { state.ws.onclose = null; state.ws.close(); }
    const proto = location.protocol === 'https:' ? 'wss' : 'ws';
    const ws = state.ws = new WebSocket(proto + '://' + location.host + '/v1/stream?key=' + encodeURIComponent(state.key));
    ws.onopen = () => setLive(true);
    ws.onmessage = (m) => {
      let ev;
      try { ev = JSON.parse(m.data); } catch (e) { return; }
      if (ev.type === 'hello') { $('project').textContent = ev.project; return; }
      if (ev.type !== 'entry') return;
      const row = Object.assign({ sessionId: ev.sessionId }, ev.entry);
      if (row.metadata && row.metadata.isScreenshot === true && row.metadata.screenshotFor) {
        const target = state.entries.find((x) => x.id === row.metadata.screenshotFor);
        if (target) {
          target.metadata = Object.assign({}, target.metadata, { hasScreenshot: true });
          if (state.selected && state.selected.id === target.id) renderDetail();
          else renderList();
        }
      }
      if (!state.sessions.some((s) => s.id === ev.sessionId)) loadSessions().catch(() => {});
      if (!matches(row)) return;
      state.entries.unshift(row);
      if (state.entries.length > 500) state.entries.pop();
      renderList();
    };
    ws.onclose = () => { setLive(false); setTimeout(connect, 3000); };
    ws.onerror = () => ws.close();
  }

  function renderList() {
    $('count').textContent = state.entries.length + ' entries';
    $('list').innerHTML = state.entries.map((e) => {
      const md = e.metadata || {};
      const prints = Array.isArray(md.recentPrints) ? md.recentPrints.length : 0;
      const selected = state.selected && state.selected.id === e.id ? ' selected' : '';
      return '<li class="row' + selected + '" data-id="' + esc(e.id) + '">'
        + '<span class="chip ' + esc(e.level) + '">' + esc(e.level) + '</span>'
        + '<span class="msg">' + esc(String(e.message).split('\n')[0]) + '</span>'
        + '<span class="meta">' + (md.isReport === true ? 'report · ' : '') + (md.isScreenshot === true ? 'screenshot · ' : '')
        + (md.hasScreenshot === true && md.isScreenshot !== true ? 'tela · ' : '') + (prints ? prints + ' prints · ' : '')
        + esc(fmtTime(e.timestamp)) + ' · ' + esc(shortId(e.sessionId)) + '</span></li>';
    }).join('');
  }
  function select(id) {
    state.selected = state.entries.find((e) => e.id === id) || null;
    renderList();
    renderDetail();
  }
  function renderDetail() {
    const e = state.selected;
    const d = $('detail');
    if (!e) { d.innerHTML = '<p class="empty">Selecione uma entry.</p>'; return; }
    const md = Object.assign({}, e.metadata || {});
    const prints = Array.isArray(md.recentPrints) ? md.recentPrints : null;
    const isReport = md.isReport === true;
    const reportContext = md.reportContext;
    const reportFor = md.reportFor;
    const isScreenshot = md.isScreenshot === true;
    const screenshotFor = md.screenshotFor;
    const hasScreenshot = md.hasScreenshot === true;
    ['recentPrints', 'isReport', 'reportContext', 'reportTimestamp', 'reportFor', 'isScreenshot', 'screenshotFor',
      'hasScreenshot', 'screenshot', 'screenshotFormat', 'screenshotWidth', 'screenshotHeight'].forEach((k) => delete md[k]);

    let html = '<header class="dhead"><span class="chip ' + esc(e.level) + '">' + esc(e.level) + '</span>'
      + '<h2>' + esc(e.message) + '</h2><dl class="facts">'
      + '<dt>quando</dt><dd>' + esc(fmtTime(e.timestamp)) + '</dd>'
      + '<dt>sessão</dt><dd><code>' + esc(e.sessionId) + '</code></dd>'
      + '<dt>id</dt><dd><code>' + esc(e.id) + '</code></dd>'
      + (e.receivedAt ? '<dt>recebido</dt><dd>' + esc(fmtTime(e.receivedAt)) + '</dd>' : '')
      + '</dl></header>';
    if (e.error) html += '<section><h3>Erro</h3><p class="errline"><code>' + esc(e.errorType || '') + '</code> ' + esc(e.error) + '</p></section>';
    if (hasScreenshot && !isScreenshot) html += '<section><h3>Tela no momento do erro</h3><img class="shot" alt="tela no momento do erro" src="' + esc(panelApi.screenshotUrl(e.id)) + '"></section>';
    if (isScreenshot) {
      html += '<section><h3>Screenshot</h3>'
        + (screenshotFor ? '<p>tela capturada após o erro <a href="#" data-goto="' + esc(screenshotFor) + '"><code>' + esc(screenshotFor) + '</code></a></p>' : '')
        + '<img class="shot" alt="screenshot" src="' + esc(panelApi.screenshotUrl(e.id)) + '"></section>';
    }
    if (prints && prints.length) html += '<section><h3>Prints antes do erro<span class="sub">' + prints.length + ' linhas de debugPrint</span></h3><pre class="console">' + prints.map(esc).join('\n') + '</pre></section>';
    if (e.stackTrace) html += '<section><h3>Stack trace</h3><pre class="stack">' + esc(e.stackTrace) + '</pre></section>';
    if (isReport) {
      html += '<section><h3>Report</h3>'
        + (reportFor ? '<p>disparado pelo erro <a href="#" data-goto="' + esc(reportFor) + '"><code>' + esc(reportFor) + '</code></a></p>' : '')
        + (reportContext ? '<pre class="console">' + esc(reportContext) + '</pre>' : '') + '</section>';
    }
    const keys = Object.keys(md);
    if (keys.length) {
      html += '<section><h3>Metadata</h3><table class="kv">' + keys.map((k) => {
        const v = md[k];
        return '<tr><th>' + esc(k) + '</th><td>' + esc(v !== null && typeof v === 'object' ? JSON.stringify(v) : v) + '</td></tr>';
      }).join('') + '</table></section>';
    }
    d.innerHTML = html;
  }

  function debounce(fn, ms) { let t; return () => { clearTimeout(t); t = setTimeout(fn, ms); }; }
  function showKeyForm(message) {
    $('app').hidden = true;
    $('keyForm').hidden = false;
    const err = $('keyError');
    err.hidden = !message;
    err.textContent = message || '';
    $('apiKey').focus();
  }
  function showError(err) {
    if (String(err.message).includes('chave')) showKeyForm(err.message); else console.error(err);
  }
  async function start() {
    if (!state.key) { showKeyForm(); return; }
    try { await loadSessions(); await load(); } catch (err) { showKeyForm(err.message); return; }
    $('keyForm').hidden = true;
    $('app').hidden = false;
    connect();
  }

  $('list').addEventListener('click', (ev) => { const li = ev.target.closest('li[data-id]'); if (li) select(li.dataset.id); });
  $('detail').addEventListener('click', (ev) => {
    const a = ev.target.closest('a[data-goto]');
    if (!a) return;
    ev.preventDefault();
    const id = a.dataset.goto;
    if (state.entries.some((e) => e.id === id)) { select(id); return; }
    api('/v1/logs/' + encodeURIComponent(id)).then((entry) => { state.entries.push(entry); select(id); }).catch(showError);
  });
  ['level', 'session'].forEach((id) => $(id).addEventListener('change', () => load().catch(showError)));
  $('search').addEventListener('input', debounce(() => load().catch(showError), 300));
  $('reload').addEventListener('click', () => Promise.all([loadSessions(), load()]).catch(showError));
  $('changeKey').addEventListener('click', () => showKeyForm());
  $('keyFormEl').addEventListener('submit', (ev) => {
    ev.preventDefault();
    state.key = $('apiKey').value.trim();
    try { localStorage.setItem('adaptLogKey', state.key); } catch (e) {}
    start();
  });
  start();
})();
</script>
</body>
</html>
''';
