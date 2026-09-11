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

function args(argv) {
  const out = {};
  for (let i = 2; i < argv.length; i += 2) {
    const key = argv[i];
    const value = argv[i + 1];
    if (!key?.startsWith('--') || !value) throw new Error(`Bad argument near ${key}`);
    out[key.slice(2)] = value;
  }
  return out;
}

function must(text, regex, label) {
  const m = text.match(regex);
  if (!m) throw new Error(`Could not parse ${label}`);
  return m;
}

function decode(s) {
  return s
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replace(/\s+/g, ' ')
    .trim();
}

function strip(s) {
  return decode(s.replace(/<[^>]+>/g, ' '));
}

function expression(html, name, endMarker) {
  const token = `const ${name}=`;
  const start = html.indexOf(token);
  if (start < 0) throw new Error(`Missing ${token}`);
  const exprStart = start + token.length;
  const end = html.indexOf(endMarker, exprStart);
  if (end < 0) throw new Error(`Missing ${endMarker} after ${token}`);
  let e = html.slice(exprStart, end).trim();
  if (e.endsWith(';')) e = e.slice(0, -1).trim();
  return e;
}

function evaluate(expr, label) {
  try {
    return vm.runInNewContext(`(${expr})`, Object.create(null), { timeout: 1000 });
  } catch (error) {
    throw new Error(`Could not evaluate ${label}: ${error.message}`);
  }
}

function bundleName(slug, role, original) {
  return `${slug}__${role}__${original.replaceAll('/', '_').replace(/[\r\n\t]/g, ' ')}`;
}

function encodePath(rel) {
  return rel.split('/').map(encodeURIComponent).join('/');
}

function landing(rootHtml) {
  const backgroundByClass = new Map();
  for (const m of rootHtml.matchAll(/\.([A-Za-z0-9]+Thumb)\{[^}]*background:url\(['"]([^'"]+)['"]\)[^}]*\}/g)) {
    backgroundByClass.set(m[1], m[2]);
  }

  const albums = [];
  const anchorRe = /<a\s+class="album live"\s+href="(dies-[^"]+)\/"[\s\S]*?<\/a>/g;
  for (const m of rootHtml.matchAll(anchorRe)) {
    const slug = m[1];
    const block = m[0];
    const roman = strip(must(block, /<(?:div|span)\s+class="numberPlate">([\s\S]*?)<\/(?:div|span)>/, `${slug} roman`)[1]);
    const thumbClass = must(block, /class="([A-Za-z0-9]+Thumb)"/, `${slug} thumbnail`)[1];
    const bannerPath = backgroundByClass.get(thumbClass);
    if (!bannerPath) throw new Error(`No banner for ${slug}`);
    const portraitPath = must(block, /<img\s+class="[^"]*Portrait"\s+src="([^"]+)"/, `${slug} portrait`)[1];
    albums.push({ slug, roman, bannerPath, portraitPath });
  }

  const order = albums.map(a => a.slug);
  if (JSON.stringify(order) !== JSON.stringify(EXPECTED_ORDER)) {
    throw new Error(`Landing order mismatch: ${order.join(', ')}`);
  }
  return albums;
}

function parseAlbum(sourceRoot, base) {
  const html = fs.readFileSync(path.join(sourceRoot, base.slug, 'index.html'), 'utf8');
  const h1 = must(html, /<h1>\s*([^<]+?)\s*<span>([\s\S]*?)<\/span>\s*<\/h1>/, `${base.slug} title`);
  const title = strip(h1[1]);
  const subtitle = strip(h1[2]);
  const hero = must(html, /<header\s+class="hero"[\s\S]*?<\/header>/, `${base.slug} hero`)[0];
  const description = strip(must(hero, /<p>([\s\S]*?)<\/p>/, `${base.slug} description`)[1]);

  if (base.slug === 'dies-akita') {
    const films = Array.from(evaluate(expression(html, 'films', '\nconst player='), 'films'));
    if (films.length !== EXPECTED[base.slug]) throw new Error(`${base.slug}: wrong film count`);
    return { ...base, title, subtitle, description, kind: 'video', releaseTag: base.slug, films };
  }

  const releaseTag = must(html, /const\s+RELEASE_TAG\s*=\s*['"]([^'"]+)['"]/, `${base.slug} release tag`)[1];
  const tracks = Array.from(evaluate(expression(html, 'tracks', '\nconst $='), `${base.slug} tracks`));
  if (tracks.length !== EXPECTED[base.slug]) throw new Error(`${base.slug}: wrong track count ${tracks.length}`);
  return { ...base, title, subtitle, description, kind: 'audio', releaseTag, tracks };
}

const a = args(process.argv);
const sourceRoot = path.resolve(a.source);
const outputJson = path.resolve(a['output-json']);
const outputManifest = path.resolve(a['output-manifest']);
const assetDir = path.resolve(a['asset-dir']);
const sourceCommit = execFileSync('git', ['-C', sourceRoot, 'rev-parse', 'HEAD'], { encoding: 'utf8' }).trim();
const rootHtml = fs.readFileSync(path.join(sourceRoot, 'index.html'), 'utf8');
const albums = landing(rootHtml).map(x => parseAlbum(sourceRoot, x));
const rawBase = `https://raw.githubusercontent.com/bryanzzai/bryanmackayne/${sourceCommit}`;
const resources = [];

function imageResource(album, role, relPath, forced = null) {
  const resource = forced || bundleName(album, role, path.basename(relPath));
  resources.push({
    kind: 'image', album, resource,
    url: `${rawBase}/${encodePath(relPath)}`,
  });
  return resource;
}

const facadeBackgroundResource = imageResource(
  'facade', 'background', 'assets/bulgarian-ballerina.png', 'facade__background__bulgarian-ballerina.png'
);

let audioCount = 0;
let videoCount = 0;
let artCount = 0;

for (const album of albums) {
  album.bannerResource = imageResource(album.slug, 'banner', album.bannerPath);
  album.portraitResource = imageResource(album.slug, 'portrait', album.portraitPath);

  if (album.kind === 'audio') {
    album.tracks = album.tracks.map(track => {
      const mediaResource = bundleName(album.slug, 'audio', track.file);
      const artworkResource = imageResource(album.slug, 'art', `${album.slug}/art/${track.art}`);
      resources.push({
        kind: 'audio', album: album.slug, resource: mediaResource,
        url: `https://github.com/bryanzzai/bryanmackayne/releases/download/${encodeURIComponent(album.releaseTag)}/${encodeURIComponent(track.file)}`,
      });
      audioCount += 1;
      artCount += 1;
      return { title: track.title, mediaResource, artworkResource };
    });
    album.films = [];
  } else {
    album.films = album.films.map(film => {
      const mediaResource = bundleName(album.slug, 'video', film.file);
      resources.push({
        kind: 'video', album: album.slug, resource: mediaResource,
        url: `https://github.com/bryanzzai/bryanmackayne/releases/download/${encodeURIComponent(album.releaseTag)}/${encodeURIComponent(film.file)}`,
      });
      videoCount += 1;
      return { title: film.title, mediaResource, durationLabel: film.duration || '' };
    });
    album.tracks = [];
  }
}

if (audioCount !== 229 || videoCount !== 9 || artCount !== 229) {
  throw new Error(`Catalog count mismatch audio=${audioCount} video=${videoCount} art=${artCount}`);
}

const cleanAlbums = albums.map(album => ({
  roman: album.roman,
  slug: album.slug,
  title: album.title,
  subtitle: album.subtitle,
  description: album.description,
  kind: album.kind,
  bannerResource: album.bannerResource,
  portraitResource: album.portraitResource,
  tracks: album.tracks,
  films: album.films,
}));

fs.mkdirSync(path.dirname(outputJson), { recursive: true });
fs.mkdirSync(path.dirname(outputManifest), { recursive: true });
fs.mkdirSync(assetDir, { recursive: true });

fs.writeFileSync(outputJson, JSON.stringify({ sourceCommit, facadeBackgroundResource, albums: cleanAlbums }, null, 2) + '\n');
fs.copyFileSync(
  path.join(sourceRoot, 'assets', 'bulgarian-ballerina.png'),
  path.join(assetDir, facadeBackgroundResource),
);

const manifest = [
  '# kind\talbum\tresource\turl',
  ...resources.map(r => [r.kind, r.album, r.resource, r.url].join('\t')),
].join('\n') + '\n';
fs.writeFileSync(outputManifest, manifest);

console.log(`Android catalog source: ${sourceCommit}`);
console.log(`Albums: ${cleanAlbums.length}/12`);
console.log(`Audio: ${audioCount}/229`);
console.log(`Video: ${videoCount}/9`);
console.log(`Artwork: ${artCount}/229`);
console.log(`Manifest resources: ${resources.length}`);
