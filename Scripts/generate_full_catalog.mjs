#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { execFileSync } from 'node:child_process';

const EXPECTED = {
  'dies-iovis': 25,
  'dies-solis': 24,
  'dies-martis': 20,
  'dies-albini': 24,
  'dies-tigris': 24,
  'dies-delfini': 24,
  'dies-canis': 24,
  'dies-felis': 24,
  'dies-tauri': 8,
  'dies-ursi': 24,
  'dies-apri': 8,
  'dies-akita': 9,
};

const EXPECTED_ORDER = [
  'dies-iovis', 'dies-solis', 'dies-martis', 'dies-albini',
  'dies-tigris', 'dies-delfini', 'dies-canis', 'dies-felis',
  'dies-tauri', 'dies-ursi', 'dies-apri', 'dies-akita',
];

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i += 1) {
    const key = argv[i];
    if (!key.startsWith('--')) throw new Error(`Unexpected argument: ${key}`);
    const value = argv[++i];
    if (!value) throw new Error(`Missing value for ${key}`);
    args[key.slice(2)] = value;
  }
  return args;
}

function mustMatch(text, regex, label) {
  const m = text.match(regex);
  if (!m) throw new Error(`Could not parse ${label}`);
  return m;
}

function decodeEntities(s) {
  return s
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replace(/\s+/g, ' ')
    .trim();
}

function stripTags(s) {
  return decodeEntities(s.replace(/<[^>]+>/g, ' '));
}

function encodePath(rel) {
  return rel.split('/').map(encodeURIComponent).join('/');
}

function swiftString(value) {
  return `"${String(value)
    .replaceAll('\\', '\\\\')
    .replaceAll('"', '\\"')
    .replaceAll('\n', '\\n')
    .replaceAll('\r', '\\r')
    .replaceAll('\t', '\\t')}"`;
}

function bundleName(slug, role, original) {
  return `${slug}__${role}__${original.replaceAll('/', '_').replace(/[\r\n\t]/g, ' ')}`;
}

function extractConstExpression(html, name, endMarker) {
  const token = `const ${name}=`;
  const start = html.indexOf(token);
  if (start < 0) throw new Error(`Missing ${token}`);
  const exprStart = start + token.length;
  const end = html.indexOf(endMarker, exprStart);
  if (end < 0) throw new Error(`Missing end marker after ${token}: ${endMarker}`);
  let expr = html.slice(exprStart, end).trim();
  if (expr.endsWith(';')) expr = expr.slice(0, -1).trim();
  return expr;
}

function evalTrustedExpression(expr, label) {
  try {
    return vm.runInNewContext(`(${expr})`, Object.create(null), { timeout: 1000 });
  } catch (error) {
    throw new Error(`Could not evaluate ${label}: ${error.message}`);
  }
}

function parseLanding(rootHtml) {
  const backgroundByClass = new Map();
  for (const m of rootHtml.matchAll(/\.([A-Za-z0-9]+Thumb)\{[^}]*background:url\(['"]([^'"]+)['"]\)[^}]*\}/g)) {
    backgroundByClass.set(m[1], m[2]);
  }

  const albums = [];
  const anchorRe = /<a\s+class="album live"\s+href="(dies-[^"]+)\/"[\s\S]*?<\/a>/g;
  for (const m of rootHtml.matchAll(anchorRe)) {
    const slug = m[1];
    const block = m[0];
    const roman = stripTags(mustMatch(block, /<(?:div|span)\s+class="numberPlate">([\s\S]*?)<\/(?:div|span)>/, `${slug} roman`)[1]);
    const displayName = stripTags(mustMatch(block, /<div\s+class="namePlate">([\s\S]*?)<\/div>/, `${slug} name`)[1]);
    const thumbClass = mustMatch(block, /class="([A-Za-z0-9]+Thumb)"/, `${slug} thumbnail class`)[1];
    const bannerPath = backgroundByClass.get(thumbClass);
    if (!bannerPath) throw new Error(`No background asset found for ${slug} / ${thumbClass}`);
    const portraitPath = mustMatch(block, /<img\s+class="[^"]*Portrait"\s+src="([^"]+)"/, `${slug} portrait`)[1];
    albums.push({ slug, roman, displayName, bannerPath, portraitPath });
  }

  if (albums.length !== 12) throw new Error(`Landing page exposes ${albums.length} live albums, expected 12`);
  const order = albums.map(a => a.slug);
  if (JSON.stringify(order) !== JSON.stringify(EXPECTED_ORDER)) {
    throw new Error(`Landing order mismatch: ${order.join(', ')}`);
  }
  return albums;
}

function parseAlbumPage(sourceRoot, landingAlbum) {
  const { slug } = landingAlbum;
  const htmlPath = path.join(sourceRoot, slug, 'index.html');
  const html = fs.readFileSync(htmlPath, 'utf8');
  const h1 = mustMatch(html, /<h1>\s*([^<]+?)\s*<span>([\s\S]*?)<\/span>\s*<\/h1>/, `${slug} title`);
  const title = stripTags(h1[1]);
  const subtitle = stripTags(h1[2]);
  const hero = mustMatch(html, /<header\s+class="hero"[\s\S]*?<\/header>/, `${slug} hero`)[0];
  const description = stripTags(mustMatch(hero, /<p>([\s\S]*?)<\/p>/, `${slug} description`)[1]);

  if (slug === 'dies-akita') {
    const expr = extractConstExpression(html, 'films', '\nconst player=');
    const films = Array.from(evalTrustedExpression(expr, `${slug} films`));
    if (films.length !== EXPECTED[slug]) throw new Error(`${slug}: ${films.length} films, expected ${EXPECTED[slug]}`);
    for (const film of films) {
      if (!film.title || !film.file || !film.file.endsWith('.mp4')) throw new Error(`${slug}: malformed film entry`);
    }
    return { ...landingAlbum, title, subtitle, description, kind: 'video', releaseTag: slug, films };
  }

  const releaseTag = mustMatch(html, /const\s+RELEASE_TAG\s*=\s*['"]([^'"]+)['"]/, `${slug} release tag`)[1];
  const expr = extractConstExpression(html, 'tracks', '\nconst $=');
  const tracks = Array.from(evalTrustedExpression(expr, `${slug} tracks`));
  if (tracks.length !== EXPECTED[slug]) throw new Error(`${slug}: ${tracks.length} tracks, expected ${EXPECTED[slug]}`);
  for (const track of tracks) {
    if (!track.title || !track.file || !track.art) throw new Error(`${slug}: malformed track entry`);
    if (!track.file.endsWith('.web.m4a')) throw new Error(`${slug}: non-browser audio referenced: ${track.file}`);
  }
  return { ...landingAlbum, title, subtitle, description, kind: 'audio', releaseTag, tracks };
}

const args = parseArgs(process.argv);
const sourceRoot = path.resolve(args.source || 'source-site');
const mediaRoot = args['media-root'] ? path.resolve(args['media-root']) : null;
const ciResourceDir = args['ci-resource-dir'] ? path.resolve(args['ci-resource-dir']) : null;
const outputSwift = path.resolve(args['output-swift'] || 'App/Sources/Catalog.generated.swift');
const outputManifest = path.resolve(args['output-manifest'] || 'App/Generated/ResourceManifest.tsv');
const outputReport = path.resolve(args['output-report'] || 'App/Generated/CatalogReport.txt');

if (!fs.existsSync(path.join(sourceRoot, 'index.html'))) throw new Error(`Source site not found: ${sourceRoot}`);
const sourceCommit = execFileSync('git', ['-C', sourceRoot, 'rev-parse', 'HEAD'], { encoding: 'utf8' }).trim();
const rootHtml = fs.readFileSync(path.join(sourceRoot, 'index.html'), 'utf8');
const landingAlbums = parseLanding(rootHtml);
const albums = landingAlbums.map(a => parseAlbumPage(sourceRoot, a));

const resources = new Map();
function addResource(kind, album, bundle, url, localPath) {
  if (resources.has(bundle)) {
    const old = resources.get(bundle);
    if (old.url !== url) throw new Error(`Resource collision for ${bundle}`);
    return;
  }
  resources.set(bundle, { kind, album, bundle, url, localPath });
}

const rawBase = `https://raw.githubusercontent.com/bryanzzai/bryanmackayne/${sourceCommit}`;
function addSourceImage(album, role, relPath, forcedBundle = null) {
  const bundle = forcedBundle || bundleName(album, role, path.basename(relPath));
  const url = `${rawBase}/${encodePath(relPath)}`;
  addResource('image', album, bundle, url, path.join(sourceRoot, relPath));
  return bundle;
}

const facadeBackgroundResource = addSourceImage('facade', 'background', 'assets/bulgarian-ballerina.png', 'facade__background__bulgarian-ballerina.png');
let audioCount = 0;
let videoCount = 0;
let artworkCount = 0;

for (const album of albums) {
  album.bannerResource = addSourceImage(album.slug, 'banner', album.bannerPath);
  album.portraitResource = addSourceImage(album.slug, 'portrait', album.portraitPath);

  if (album.kind === 'audio') {
    for (const track of album.tracks) {
      const mediaBundle = bundleName(album.slug, 'audio', track.file);
      const mediaUrl = `https://github.com/bryanzzai/bryanmackayne/releases/download/${encodeURIComponent(album.releaseTag)}/${encodeURIComponent(track.file)}`;
      const mediaLocal = mediaRoot ? path.join(mediaRoot, album.slug, track.file) : null;
      addResource('audio', album.slug, mediaBundle, mediaUrl, mediaLocal);
      const artRel = `${album.slug}/art/${track.art}`;
      const artBundle = addSourceImage(album.slug, 'art', artRel);
      track.mediaResource = mediaBundle;
      track.artworkResource = artBundle;
      audioCount += 1;
      artworkCount += 1;
    }
  } else {
    for (const film of album.films) {
      const mediaBundle = bundleName(album.slug, 'video', film.file);
      const mediaUrl = `https://github.com/bryanzzai/bryanmackayne/releases/download/${encodeURIComponent(album.releaseTag)}/${encodeURIComponent(film.file)}`;
      const mediaLocal = mediaRoot ? path.join(mediaRoot, album.slug, film.file) : null;
      addResource('video', album.slug, mediaBundle, mediaUrl, mediaLocal);
      film.mediaResource = mediaBundle;
      videoCount += 1;
    }
  }
}

if (audioCount !== 229) throw new Error(`Audio total ${audioCount}, expected 229`);
if (videoCount !== 9) throw new Error(`Video total ${videoCount}, expected 9`);
if (artworkCount !== 229) throw new Error(`Artwork total ${artworkCount}, expected 229`);

fs.mkdirSync(path.dirname(outputSwift), { recursive: true });
fs.mkdirSync(path.dirname(outputManifest), { recursive: true });

const swiftAlbums = albums.map(album => {
  const tracks = album.kind === 'audio'
    ? album.tracks.map(t => `            TrackDefinition(title: ${swiftString(t.title)}, mediaResource: ${swiftString(t.mediaResource)}, artworkResource: ${swiftString(t.artworkResource)})`).join(',\n')
    : '';
  const films = album.kind === 'video'
    ? album.films.map(f => `            FilmDefinition(title: ${swiftString(f.title)}, mediaResource: ${swiftString(f.mediaResource)}, durationLabel: ${swiftString(f.duration || '')})`).join(',\n')
    : '';
  return `    AlbumDefinition(\n        roman: ${swiftString(album.roman)},\n        slug: ${swiftString(album.slug)},\n        title: ${swiftString(album.title)},\n        subtitle: ${swiftString(album.subtitle)},\n        description: ${swiftString(album.description)},\n        kind: .${album.kind},\n        bannerResource: ${swiftString(album.bannerResource)},\n        portraitResource: ${swiftString(album.portraitResource)},\n        tracks: [\n${tracks}\n        ],\n        films: [\n${films}\n        ]\n    )`;
}).join(',\n');

const swift = `// GENERATED FROM bryanzzai/bryanmackayne @ ${sourceCommit}\n// Do not hand-edit. Regenerate with Scripts/generate_full_catalog.mjs.\n\nlet sourceSiteCommit = ${swiftString(sourceCommit)}\nlet facadeBackgroundResource = ${swiftString(facadeBackgroundResource)}\n\nlet concertAlbums: [AlbumDefinition] = [\n${swiftAlbums}\n]\n`;
fs.writeFileSync(outputSwift, swift, 'utf8');

const manifestLines = [
  `# The 12 Day Dancer native resource manifest`,
  `# source-commit\t${sourceCommit}`,
  `# kind\talbum\tbundle-name\turl\tsource-path`,
];
for (const r of resources.values()) {
  const sourcePath = r.localPath ? String(r.localPath) : '';
  manifestLines.push([r.kind, r.album, r.bundle, r.url, sourcePath].join('\t'));
}
fs.writeFileSync(outputManifest, `${manifestLines.join('\n')}\n`, 'utf8');

if (ciResourceDir) {
  if (!mediaRoot) throw new Error('--ci-resource-dir requires --media-root');
  fs.rmSync(ciResourceDir, { recursive: true, force: true });
  fs.mkdirSync(ciResourceDir, { recursive: true });
  for (const r of resources.values()) {
    if (!r.localPath || !fs.existsSync(r.localPath)) throw new Error(`Missing local source for ${r.bundle}: ${r.localPath}`);
    const st = fs.statSync(r.localPath);
    if (!st.isFile() || st.size === 0) throw new Error(`Empty/non-file resource: ${r.localPath}`);
    fs.copyFileSync(r.localPath, path.join(ciResourceDir, r.bundle));
  }
}

const imageCount = Array.from(resources.values()).filter(r => r.kind === 'image').length;
const report = [
  `Source site commit: ${sourceCommit}`,
  `Albums: 12/12`,
  ...albums.map(a => `${a.roman} ${a.title}: ${a.kind === 'audio' ? a.tracks.length + ' tracks' : a.films.length + ' films'}`),
  `Audio: ${audioCount} *.web.m4a`,
  `Video: ${videoCount} *.mp4`,
  `Original/non-web M4A: 0 referenced`,
  `Artwork: ${artworkCount}`,
  `Images total (facade + banners + portraits + artwork): ${imageCount}`,
  `Manifest resources total: ${resources.size}`,
];
fs.writeFileSync(outputReport, `${report.join('\n')}\n`, 'utf8');
console.log(report.join('\n'));
