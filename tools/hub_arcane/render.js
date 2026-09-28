// Esporta gli asset dell'hub arcano da hub_arcane.html (headless Chromium via Playwright).
// Uso: node tools/hub_arcane/render.js [cartella_progetto]  → assets/sprites/hub_*.png + tools/hub_arcane/hub_layout.json
// Scala mondo = 1,25 x coordinate del mockup (1408x768 → 1760x960 px, origine al centro).
// Strati del pavimento: cielo e nebbia a 1x (scala 1), isole a 2x (scala 0,5, come gli altri sprite);
// glow a 1x; oggetti (prop), rocce e fiamma a 2x.
const path = require('path'), fs = require('fs');
const { chromium } = require('playwright');
const K = 1.25;
const root = process.argv[2] || path.join(__dirname, '..', '..');
const page_url = 'file://' + path.join(__dirname, 'hub_arcane.html');
const out = (n) => path.join(root, 'assets', 'sprites', n);
const world = ([x, y]) => [+((x - 704) * K).toFixed(1), +((y - 384) * K).toFixed(1)];
const LAYERS = { sky: [1, false], main: [2, false], nw: [2, true], ne: [2, true], s: [2, true], fog: [1, true] };
(async () => {
  const b = await chromium.launch(process.env.CHROMIUM ? { executablePath: process.env.CHROMIUM } : {});
  const open = async (query, dsf, w, h) => {
    const p = await b.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: dsf });
    await p.goto(page_url + query); await p.waitForFunction(() => window.READY === true); return p;
  };
  const layout = { scale: K, layers: {}, props: {}, flames: [], floors: [] };
  let props, flames;
  for (const [name, [mult, crop]] of Object.entries(LAYERS)) {
    const p = await open('?mode=ground&layer=' + name, K * mult, 1408, 768);
    let box = { x: 0, y: 0, width: 1408, height: 768 };
    if (crop) box = await p.evaluate(() => {
      const r = document.querySelector('#art').getBBox(), m = 14, svg = document.querySelector('#out');
      const bx = { x: Math.floor(r.x - m), y: Math.floor(r.y - m), width: Math.ceil(r.width + 2 * m), height: Math.ceil(r.height + 2 * m) };
      svg.setAttribute('viewBox', `${bx.x} ${bx.y} ${bx.width} ${bx.height}`); svg.setAttribute('width', bx.width); svg.setAttribute('height', bx.height); return bx; });
    await (await p.$('#out')).screenshot({ path: out('hub_' + (name === 'main' ? 'ground' : 'layer_' + name) + '.png'), omitBackground: true });
    const c = world([box.x + box.width / 2, box.y + box.height / 2]);
    layout.layers[name] = { x: c[0], y: c[1], scale: 1 / mult };
    if (!props) { props = await p.evaluate(() => window.PROPS); flames = await p.evaluate(() => window.FLAMES); }
    await p.close();
  }
  const g = await open('?mode=glow', K, 1408, 768);
  await (await g.$('#out')).screenshot({ path: out('hub_glow.png'), omitBackground: true });
  // Bordi delle isole raggiungibili, campionati dal path SVG (per hub_nodes.py).
  layout.floors = (await g.evaluate(() => window.floorPaths().map((d) => {
    const el = document.createElementNS('http://www.w3.org/2000/svg', 'path'); el.setAttribute('d', d);
    document.querySelector('#out').appendChild(el); const L = el.getTotalLength(), pts = [];
    for (let i = 0; i < 96; i++) { const q = el.getPointAtLength(L * i / 96); pts.push([q.x, q.y]); } return pts; }))).map((f) => f.map(world));
  await g.close();
  for (const [name, p] of Object.entries(props)) {
    const pg = await open('?mode=prop&name=' + name, K * 2, Math.ceil(2 * p.r), Math.ceil(2 * p.r));
    await (await pg.$('#out')).screenshot({ path: out('hub_' + name + '.png'), omitBackground: true }); await pg.close();
    const c = world([p.x, p.y]); layout.props[name] = { x: c[0], y: c[1] };
  }
  // Fiamma disegnata con scala 1,4 e ancorata 6 unita' sotto il centro dello sprite.
  layout.flames = flames.map((f) => { const c = world([f.x, f.y - 6 * f.sc / 1.4]); return { x: c[0], y: c[1], scale: +(0.5 * f.sc / 1.4).toFixed(3) }; });
  fs.writeFileSync(path.join(__dirname, 'hub_layout.json'), JSON.stringify(layout, null, 1));
  console.log(Object.keys(layout.props).join(' '), '| fiamme', layout.flames.length, '| strati', JSON.stringify(layout.layers));
  await b.close();
})();
