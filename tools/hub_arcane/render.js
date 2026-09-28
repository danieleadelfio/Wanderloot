// Esporta gli asset dell'hub arcano da hub_arcane.html (headless Chromium via Playwright).
// Uso: node tools/hub_arcane/render.js [cartella_progetto]  → assets/sprites/hub_*.png
// Scala mondo = 1,25 x coordinate del mockup (1408x768 → 1760x960 px, origine al centro).
// ground e prop a 2x (sprite a scala 0,5, come gli altri sprite); glow a 1x (scala 1, e' solo sfumatura).
const path = require('path'), fs = require('fs');
const { chromium } = require('playwright');
const K = 1.25;
const root = process.argv[2] || path.join(__dirname, '..', '..');
const page_url = 'file://' + path.join(__dirname, 'hub_arcane.html');
const out = (n) => path.join(root, 'assets', 'sprites', n);
(async () => {
  const b = await chromium.launch(process.env.CHROMIUM ? { executablePath: process.env.CHROMIUM } : {});
  const shot = async (query, file, dsf, w, h) => {
    const p = await b.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: dsf });
    await p.goto(page_url + query); await p.waitForFunction(() => window.READY === true);
    await (await p.$('#out')).screenshot({ path: file, omitBackground: true });
    const props = await p.evaluate(() => window.PROPS); await p.close(); return props;
  };
  const props = await shot('?mode=ground', out('hub_ground.png'), K * 2, 1408, 768);
  await shot('?mode=glow', out('hub_glow.png'), K, 1408, 768);
  const layout = {};
  for (const [name, p] of Object.entries(props)) {
    await shot('?mode=prop&name=' + name, out('hub_' + name + '.png'), K * 2, Math.ceil(2 * p.r), Math.ceil(2 * p.r));
    layout[name] = { x: +((p.x - 704) * K).toFixed(1), y: +((p.y - 384) * K).toFixed(1) };
  }
  // Bordi delle isole raggiungibili, campionati dal path SVG, in coordinate mondo (per hub_collision.py).
  const p = await b.newPage(); await p.goto(page_url + '?mode=glow'); await p.waitForFunction(() => window.READY === true);
  const floors = await p.evaluate(() => window.floorPaths().map((d) => {
    const el = document.createElementNS('http://www.w3.org/2000/svg', 'path'); el.setAttribute('d', d);
    document.querySelector('#out').appendChild(el); const L = el.getTotalLength(), pts = [];
    for (let i = 0; i < 96; i++) { const q = el.getPointAtLength(L * i / 96); pts.push([q.x, q.y]); } return pts; }));
  await p.close();
  const world = ([x, y]) => [+((x - 704) * K).toFixed(1), +((y - 384) * K).toFixed(1)];
  fs.writeFileSync(path.join(__dirname, 'hub_layout.json'), JSON.stringify({ scale: K, props: layout, floors: floors.map((f) => f.map(world)) }, null, 1));
  console.log(JSON.stringify(layout));
  await b.close();
})();
