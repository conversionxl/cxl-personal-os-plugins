import { atom, read, update } from 'claude-code'
import type { EngineInterface as Engine, Register } from 'claude-code'

import type { Change } from '../types'

// Explorer: the project's folder as a tree beside the chat, like VS Code's.
//
//   - Folders open and close on a click; tree lines show the hierarchy; each
//     file carries a plain badge with its extension (md, json, html).
//   - Git status, as VS Code marks it: U untracked, A added, M modified,
//     R renamed, and ↑ for committed but not pushed. The key under
//     the header says what each means. Folders holding such files are coloured and carry a dot.
//   - "Just changed by Claude": the files Claude wrote or edited this session.
//   - Plugin map (/plugin-map or the header button switches it): a thin
//     coloured line on each row says which CXL plugin's folder it sits in, with
//     a legend, the plugin's name on each folder it sets up and each file a
//     plugin command or skill created, and a banner while a plugin is running.
//     What the plugins created is kept in .claude/plugin-map.json.

const PANE = 'explorer'
const TITLE = 'Explorer'
const MAP_FILE = '.claude/plugin-map.json'
const HIDDEN = new Set(['.git', 'node_modules', '.DS_Store', '.venv', '__pycache__', '.obsidian', '.trash'])
const MAX_ROWS = 600
const RECENT = 8
const REFRESH_MS = 4000
const HOVER_LIMIT = 60

const expanded = atom({ plugin: 'explorer', key: 'expanded' } as const, [], { shape: 'expanded-1' })
const changes = atom({ plugin: 'explorer', key: 'changes' } as const, [], { shape: 'changes-1' })
const tick = atom({ plugin: 'explorer', key: 'tick' } as const, 0)
const active = atom({ plugin: 'explorer', key: 'active' } as const, null)
const showMap = atom({ plugin: 'explorer', key: 'showMap' } as const, true)
const legendOpen = atom({ plugin: 'explorer', key: 'legendOpen' } as const, false)

type Entry = { name: string; kind: 'file' | 'dir' | 'other' }
type Row = { path: string; name: string; isDir: boolean; isOpen: boolean; guide: string }
type GitMark = 'U' | 'A' | 'M' | 'R' | 'D' | '↑'
type Attribution = { plugin: string; action: 'created' | 'edited'; via?: string; at?: string }

let root = ''
let git: Map<string, GitMark> = new Map()
let isRepo = false
let files: Record<string, Attribution> = {}
let activeVia: string | undefined
let folders: Record<string, string> = {}
let isPlain = false


// Live activity: what Claude is writing right now, and what it just finished.
type Live = { kind: 'creating' | 'editing' | 'created' | 'edited'; since: number }
const live = new Map<string, Live>()
let frame = 0
let animator: { cancel: () => void } | null = null
const FLASH_MS = 3500
const SPIN = ['◐', '◓', '◑', '◒']
const LIVE_STYLE = {
  creating: { bg: '#1F7A45', fg: '#FFFFFF', label: 'creating' },
  editing: { bg: '#9A6B00', fg: '#FFFFFF', label: 'editing' },
  created: { bg: '#2EA043', fg: '#FFFFFF', label: 'created' },
  edited: { bg: '#D29922', fg: '#1A1A1A', label: 'edited' },
} as const

const PLUGINS: Record<string, { color: string }> = {
  'personal-os': { color: '#3BA7AA' },
  'marketing-brain': { color: '#D61F2C' },
  'campaign-engine': { color: '#E08A00' },
  'reporting-agent': { color: '#5B7CFA' },
  'visual-brain': { color: '#A855F7' },
  'product-visual': { color: '#16A34A' },
  'cxl-plugin': { color: '#8B8F98' },
}

// Standard paths, from each plugin's setup.sh. The longest match wins.
const RULES: Array<[string, string]> = [
  ['projects', 'personal-os'],
  ['wiki', 'personal-os'],
  ['raw', 'personal-os'],
  ['drafts', 'personal-os'],
  ['frameworks', 'personal-os'],
  ['daily-logs', 'personal-os'],
  ['team-updates', 'personal-os'],
  ['.claude', 'personal-os'],
  ['CLAUDE.md', 'personal-os'],
  ['AGENTS.md', 'personal-os'],
  ['wiki/brand', 'marketing-brain'],
  ['raw/voc', 'marketing-brain'],
  ['raw/brand', 'marketing-brain'],
  ['raw/strategy', 'marketing-brain'],
  ['raw/performance', 'marketing-brain'],
  ['projects/marketing-brain', 'marketing-brain'],
  ['raw/campaigns', 'campaign-engine'],
  ['projects/campaigns', 'campaign-engine'],
  ['projects/campaign-engine', 'campaign-engine'],
  ['projects/reporting-agent', 'reporting-agent'],
  ['raw/performance/reporting-agent', 'reporting-agent'],
  ['wiki/brand/visual-guide.md', 'visual-brain'],
  ['projects/visual-brain', 'visual-brain'],
  ['raw/visuals', 'visual-brain'],
  ['projects/product-visual', 'product-visual'],
  ['raw/visuals/products', 'product-visual'],
]

// .claude/folders.json keys and the standard path each stands for (lib-folders.sh).
const FOLDER_KEYS: Array<[string, string]> = [
  ['brand-wiki', 'wiki/brand'],
  ['voc', 'raw/voc'],
  ['brand-inputs', 'raw/brand'],
  ['strategy', 'raw/strategy'],
  ['performance', 'raw/performance'],
  ['campaign-inputs', 'raw/campaigns'],
  ['campaigns', 'projects/campaigns'],
  ['projects', 'projects'],
  ['raw', 'raw'],
  ['wiki', 'wiki'],
  ['drafts', 'drafts'],
  ['frameworks', 'frameworks'],
  ['daily-logs', 'daily-logs'],
  ['team-updates', 'team-updates'],
]

const GIT_INFO: Record<GitMark, { color: string; label: string; text: string }> = {
  U: { color: '#2EA043', label: 'new', text: 'Untracked: a new file git has never saved. Not on GitHub.' },
  A: { color: '#2EA043', label: 'added', text: 'Added: a new file staged for the next commit. Not on GitHub yet.' },
  M: { color: '#D29922', label: 'modified', text: 'Modified: changed since the last commit. Not on GitHub yet.' },
  R: { color: '#2EA043', label: 'renamed', text: 'Renamed: moved or renamed since the last commit. Not on GitHub yet.' },
  D: { color: '#F85149', label: 'deleted', text: 'Deleted: removed since the last commit.' },
  '↑': { color: '#58A6FF', label: 'not pushed', text: 'Committed but not pushed: saved on this computer, not on GitHub yet.' },
}

function abs(path: string) {
  return root === '' ? path : `${root}/${path}`
}

function join(a: string, b: string) {
  return a === '' ? b : `${a}/${b}`
}

function ancestors(path: string) {
  const parts = path.split('/').slice(0, -1)
  return parts.map((_, i) => parts.slice(0, i + 1).join('/'))
}

function rel(path: string | undefined) {
  if (root === '' || typeof path !== 'string') return null
  if (path.startsWith(`${root}/`)) return path.slice(root.length + 1)
  if (!path.startsWith('/')) return path.replace(/^\.\//, '')
  return null
}

function badge(name: string) {
  const dot = name.lastIndexOf('.')
  const ext = dot > 0 ? name.slice(dot + 1).toLowerCase() : name.startsWith('.') ? 'cfg' : ''
  return (ext === '' ? '·' : ext.slice(0, 4)).padEnd(4, ' ')
}

function cleanMapped(value: unknown) {
  if (typeof value !== 'string') return null
  const v = value.replace(/^\.\//, '').replace(/\/$/, '')
  if (v === '' || v.startsWith('/') || v.includes('..') || v.includes('\\') || /^[A-Za-z]:/.test(v)) return null
  return v
}

function reroute(path: string, mapped: Record<string, string>) {
  let best: [string, string] | null = null
  for (const [key, std] of FOLDER_KEYS) {
    const to = mapped[key]
    if (to === undefined) continue
    if (path !== std && !path.startsWith(`${std}/`)) continue
    if (best === null || std.length > best[0].length) best = [std, to]
  }
  return best === null ? path : best[1] + path.slice(best[0].length)
}

function pluginOf(name: string | undefined) {
  if (typeof name !== 'string' || !name.includes(':')) return null
  const plugin = name.replace(/^\//, '').split(':')[0] ?? ''
  return plugin in PLUGINS ? plugin : null
}

function territoryOf(path: string) {
  const own = files[path]?.plugin
  if (own !== undefined) return own
  let best: string | null = null
  let bestLength = -1
  for (const [folder, plugin] of Object.entries(folders)) {
    if ((path === folder || path.startsWith(`${folder}/`)) && folder.length > bestLength) {
      best = plugin
      bestLength = folder.length
    }
  }
  return best
}

function colorOf(plugin: string) {
  return PLUGINS[plugin]?.color ?? '#8B8F98'
}

async function loadFolders($: Engine) {
  const mapped: Record<string, string> = {}
  const text = await $.fs.read(abs('.claude/folders.json')).catch(() => null)
  if (text !== null) {
    try {
      const json = JSON.parse(String(text)) as Record<string, unknown>
      for (const [key] of FOLDER_KEYS) {
        const v = cleanMapped(json[key])
        if (v !== null) mapped[key] = v
      }
    } catch {
      // Unreadable folders.json: the standard folders.
    }
  }
  const next: Record<string, string> = {}
  for (const [path, plugin] of RULES) next[reroute(path, mapped)] = plugin
  folders = next
}

async function loadAttributions($: Engine) {
  const text = await $.fs.read(abs(MAP_FILE)).catch(() => null)
  if (text === null) return
  try {
    const json = JSON.parse(String(text)) as { files?: Record<string, Attribution>; show?: boolean }
    files = json.files ?? {}
    if (json.show === false) await update($, showMap, () => false)
  } catch {
    files = {}
  }
}

async function saveAttributions($: Engine) {
  const body = {
    about: 'Written by the explorer mod. folders: what each plugin sets up. files: what Claude wrote while a plugin command or skill ran.',
    show: await read($, showMap),
    folders,
    files,
  }
  const text = `${JSON.stringify(body, null, 2)}\n`
  const old = await $.fs.read(abs(MAP_FILE)).catch(() => null)
  if (old !== text) await $.fs.write(abs(MAP_FILE), text)
}

async function refreshGit($: Engine) {
  const status = await $.process
    .run(['git', '-C', root, 'status', '--porcelain=v1', '-uall', '-z'], { timeoutMs: 5000 })
    .catch(() => null)
  if (status === null || status.exitCode !== 0) {
    isRepo = false
    git = new Map()
    return
  }
  isRepo = true
  const next = new Map<string, GitMark>()
  const unpushed = await $.process
    .run(['git', '-C', root, 'log', '@{u}..HEAD', '--name-only', '--format='], { timeoutMs: 5000 })
    .catch(() => null)
  if (unpushed !== null && unpushed.exitCode === 0) {
    for (const line of unpushed.stdout.split('\n')) if (line.trim() !== '') next.set(line.trim(), '↑')
  }
  const parts = status.stdout.split('\0')
  for (let i = 0; i < parts.length; i++) {
    const entry = parts[i] ?? ''
    if (entry.length < 4) continue
    const x = entry[0]
    const y = entry[1]
    const path = entry.slice(3)
    let mark: GitMark = 'M'
    if (x === '?' && y === '?') mark = 'U'
    else if (x === 'R' || x === 'C') {
      mark = 'R'
      i += 1
    } else if (x === 'A') mark = 'A'
    else if (x === 'D' || y === 'D') mark = 'D'
    next.set(path, mark)
  }
  git = next
}

async function bump($: Engine) {
  await update($, tick, n => (n + 1) % 1_000_000)
}

async function registerCommands($: Engine) {
  await $.command.register({
    name: 'explorer',
    description: 'Show the Explorer pane: the files and folders in this project',
  }).catch(() => undefined)
  await $.command.register({
    name: 'plugin-map',
    description: 'Switch plugin colours on or off in the Explorer',
  }).catch(() => undefined)
}

// The desktop app starts sessions ahead of time in a spare folder and moves
// them to the chosen project when you open one, so the folder is read fresh
// every time rather than kept from the start.
async function syncRoot($: Engine) {
  const now = await $.session.root()
  if (now === root) return
  root = now
  await loadFolders($)
  await loadAttributions($)
  await refreshGit($)
}

async function refresh($: Engine) {
  await syncRoot($)
  await refreshGit($)
  await bump($)
}

async function toggle($: Engine, path: string) {
  await update($, expanded, list =>
    list.includes(path) ? list.filter(p => p !== path && !p.startsWith(`${path}/`)) : [...list, path],
  )
}

const BROWSER_EXTS = new Set(['html', 'htm', 'svg'])

function isBrowserFile(name: string) {
  const dot = name.lastIndexOf('.')
  return dot > 0 && BROWSER_EXTS.has(name.slice(dot + 1).toLowerCase())
}

// Opens the file in the desktop app's Files pane beside the chat.
async function openFile($: Engine, path: string) {
  const shown = await $.tool
    .call({ tool: 'mcp__ccd_view__show_pane', pane: 'file', path: abs(path) })
    .catch((error: unknown) => ({ deny: String(error) }))
  if (shown !== null && typeof shown === 'object' && 'deny' in shown && shown.deny) {
    $.ui.toast(`Could not open ${path}: ${String(shown.deny)}`)
  }
}

// Opens an HTML or SVG file rendered, in the desktop app's Browser pane.
async function openBrowser($: Engine, path: string) {
  const url = `file://${encodeURI(abs(path))}`
  const shown = await $.tool
    .call({ tool: 'mcp__Claude_Browser__navigate', url })
    .catch((error: unknown) => ({ deny: String(error) }))
  if (shown !== null && typeof shown === 'object' && 'deny' in shown && shown.deny) {
    $.ui.toast(`Could not open ${path} in the browser: ${String(shown.deny)}`)
  }
}

async function collapseAll($: Engine) {
  await update($, expanded, () => [])
}

async function toggleLegend($: Engine) {
  await update($, legendOpen, isOpen => !isOpen)
}

async function toggleMap($: Engine) {
  await update($, showMap, isOn => !isOn)
  await saveAttributions($)
}

async function setActive($: Engine, plugin: string | null, via?: string) {
  activeVia = via
  await update($, active, () => plugin)
}

async function animate($: Engine) {
  if (animator !== null) return
  animator = $.clock.every(220, () => {
    frame = (frame + 1) % 1000
    void (async () => {
      const now = await $.clock.now()
      for (const [path, one] of live) {
        const isDone = one.kind === 'created' || one.kind === 'edited'
        if (isDone && now - one.since > FLASH_MS) live.delete(path)
      }
      if (live.size === 0 && animator !== null) {
        animator.cancel()
        animator = null
      }
      await bump($)
    })()
  })
}

async function startLive($: Engine, path: string | undefined, isNew: boolean) {
  const r = rel(path)
  if (r === null || r === '') return
  live.set(r, { kind: isNew ? 'creating' : 'editing', since: await $.clock.now() })
  await update($, expanded, list => [...new Set([...list, ...ancestors(r)])])
  await animate($)
  await bump($)
  void $.ui.scroll({ to: { key: `f-${r}` }, in: PANE, block: 'nearest' }).catch(() => undefined)
}

async function finishLive($: Engine, path: string | undefined) {
  const r = rel(path)
  if (r === null || r === '') return
  const one = live.get(r)
  if (one === undefined) return
  live.set(r, { kind: one.kind === 'creating' ? 'created' : 'edited', since: await $.clock.now() })
  await animate($)
}

async function record($: Engine, path: string | undefined, existed: boolean | null) {
  const r = rel(path)
  if (r === null || r === '') return
  const now = await $.clock.now()
  await update($, changes, list => {
    const before = list.find(one => one.path === r)
    const kind: Change['kind'] = before?.kind === 'A' || existed === false ? 'A' : 'M'
    return [...list.filter(one => one.path !== r), { path: r, kind, at: now }].slice(-300)
  })
  await update($, expanded, list => [...new Set([...list, ...ancestors(r)])])

  const plugin = await read($, active)
  if (plugin !== null && r !== MAP_FILE) {
    const before = files[r]
    if (!(before?.action === 'created' && existed !== false)) {
      const at = new Date(now).toISOString().slice(0, 10)
      files = { ...files, [r]: { plugin, action: existed === false ? 'created' : 'edited', via: activeVia, at } }
      await saveAttributions($)
    }
  }
  await refresh($)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await registerCommands($)
    await syncRoot($)
    void $.ui.open({ id: PANE, title: TITLE })
    $.clock.every(REFRESH_MS, () => refresh($))
    return next(e)
  })

  on('session.attach', async ($, e, next) => {
    const ran = await next(e)
    await registerCommands($)
    await syncRoot($)
    await bump($)
    return ran
  })

  on('command.run', { command: 'explorer' }, async ($, e) => {
    isPlain = e.args.trim() === 'plain'
    await bump($)
    await $.ui.open({ id: PANE, title: TITLE })
    return { text: isPlain ? 'Explorer opened in plain mode (names only). Run /explorer to go back.' : 'Explorer pane opened.' }
  })

  on('command.run', { command: 'plugin-map' }, async $ => {
    await toggleMap($)
    await $.ui.open({ id: PANE, title: TITLE })
    const isOn = await read($, showMap)
    return {
      text: isOn
        ? 'Plugin map on: a coloured line on each row of the Explorer shows which plugin set that folder up.'
        : 'Plugin map off: the Explorer shows the plain tree.',
    }
  })

  on('prompt.submit', async ($, e, next) => {
    const first = e.text.trim().split(/\s+/)[0] ?? ''
    const plugin = first.startsWith('/') ? pluginOf(first) : null
    await setActive($, plugin, plugin === null ? undefined : first)
    return next(e)
  })

  on('tool.call', { tool: 'Skill' }, async ($, e, next) => {
    const plugin = pluginOf(e.skill)
    if (plugin !== null) await setActive($, plugin, e.skill)
    return next(e)
  })

  on('tool.call', { tool: 'Write' }, async ($, e, next) => {
    const existed = await $.fs.exists(e.file_path).catch(() => null)
    await startLive($, e.file_path, existed === false)
    const ran = await next(e)
    await finishLive($, e.file_path)
    await record($, e.file_path, existed)
    return ran
  })

  on('tool.call', { tool: 'Edit' }, async ($, e, next) => {
    await startLive($, e.file_path, false)
    const ran = await next(e)
    await finishLive($, e.file_path)
    await record($, e.file_path, true)
    return ran
  })

  on('tool.call', { tool: 'NotebookEdit' }, async ($, e, next) => {
    await startLive($, e.notebook_path, false)
    const ran = await next(e)
    await finishLive($, e.notebook_path)
    await record($, e.notebook_path, true)
    return ran
  })

  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    const ran = await next(e)
    await refresh($)
    return ran
  })

  on('turn.complete', async ($, e, next) => {
    await setActive($, null)
    return next(e)
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text, Button } = $.ui.resolve(e)
    await read($, tick)
    await syncRoot($)
    const isMap = await read($, showMap)
    const isLegend = await read($, legendOpen)
    const running = isMap ? await read($, active) : null

    const open = new Set(await read($, expanded))
    const changed = await read($, changes)

    // Folders that hold git changes: coloured, with a dot, as in VS Code.
    const dirty = new Map<string, number>()
    for (const [path] of git) for (const dir of ancestors(path)) dirty.set(dir, (dirty.get(dir) ?? 0) + 1)

    const rows: Row[] = []
    let isCut = false
    const walk = async (dir: string, depth: number, prefix: string) => {
      const list: Entry[] = await $.fs.list(dir === '' ? root : `${root}/${dir}`).catch(() => [])
      const names = new Set(list.map(one => one.name))
      for (const [path] of live) {
        const parent = ancestors(path).pop() ?? ''
        const isUnder = dir === '' ? true : path.startsWith(`${dir}/`)
        if (!isUnder) continue
        const rest = dir === '' ? path : path.slice(dir.length + 1)
        const first = rest.split('/')[0] ?? ''
        if (first === '' || names.has(first)) continue
        names.add(first)
        list.push({ name: first, kind: rest.includes('/') ? 'dir' : 'file' })
        void parent
      }
      const sorted = list
        .filter(one => !HIDDEN.has(one.name))
        .sort((a, b) => {
          const ad = a.kind === 'dir' ? 0 : 1
          const bd = b.kind === 'dir' ? 0 : 1
          return ad - bd || a.name.localeCompare(b.name, undefined, { sensitivity: 'base' })
        })
      for (const [index, one] of sorted.entries()) {
        if (rows.length >= MAX_ROWS) {
          isCut = true
          return
        }
        const isLast = index === sorted.length - 1
        const path = join(dir, one.name)
        const isDir = one.kind === 'dir'
        const isOpen = isDir && open.has(path)
        const guide = depth === 0 ? '' : `${prefix}${isLast ? '└ ' : '├ '}`
        rows.push({ path, name: one.name, isDir, isOpen, guide })
        if (isOpen) await walk(path, depth + 1, depth === 0 ? '' : `${prefix}${isLast ? '  ' : '│ '}`)
      }
    }
    await walk('', 0, '')

    const shown = new Set<string>()
    if (isMap) {
      for (const row of rows) {
        const owner = territoryOf(row.path)
        if (owner !== null) shown.add(owner)
      }
    }

    // The desktop app draws nothing once a pane holds too many hover
    // elements (it failed at about 130), so hover is rationed.
    let hoverLeft = HOVER_LIMIT

    // A thin line in the colour of the plugin whose folder the row sits in.
    // Hovering it says which plugin, and for a file a plugin wrote, how.
    const stripe = (path: string) => {
      if (!isMap) return null
      const owner = territoryOf(path)
      if (owner === null) return <Text>{'  '}</Text>
      const line = <Text color={colorOf(owner)} weight="bold">{'▏ '}</Text>
      // Only a folder the plugin set up (or a file it made) answers hover, and
      // only while the pane's hover allowance lasts: the desktop app stops
      // drawing a pane that holds too many hover elements.
      const isOwnRow = folders[path] === owner || files[path]?.plugin === owner
      if (!isOwnRow || hoverLeft <= 0) return line
      hoverLeft -= 1
      return (
        <Box flexShrink={0}>
          {line}
        </Box>
      )
    }

    // The status letter at the row's end, with its meaning revealed on hover.
    const status = (mark: GitMark | null, count: number) => {
      if (mark === null && count === 0) return null
      const info = mark === null ? null : GIT_INFO[mark]
      const letter = mark ?? '●'
      const color = info?.color ?? GIT_INFO.M.color
      if (hoverLeft <= 0) return <Text color={color} weight="bold"> {letter} </Text>
      hoverLeft -= 1
      return (
        <Box flexShrink={0}>
          <Text color={color} weight="bold"> {letter} </Text>
        </Box>
      )
    }

    // Live styling: a coloured highlight with a spinner while Claude writes,
    // then a pulsing flash that fades out once the write is done.
    const liveOf = (path: string, isDir: boolean) => {
      const own = live.get(path)
      if (own !== undefined) return own
      if (!isDir) return null
      for (const [p, one] of live) if (p.startsWith(`${path}/`)) return one
      return null
    }
    const liveBadge = (one: Live | null) => {
      if (one === null) return null
      const style = LIVE_STYLE[one.kind]
      const isWorking = one.kind === 'creating' || one.kind === 'editing'
      return (
        <Text color={style.bg} weight="bold">
          {' '}
          {isWorking ? SPIN[frame % SPIN.length] : '✓'} {style.label}
          {isWorking ? '.'.repeat((frame % 3) + 1) : ''}
        </Text>
      )
    }
    const liveName = (one: Live | null) => {
      if (one === null) return {}
      const style = LIVE_STYLE[one.kind]
      const isWorking = one.kind === 'creating' || one.kind === 'editing'
      const isBright = isWorking || frame % 4 < 2
      return isBright ? { backgroundColor: style.bg, color: style.fg } : { color: style.bg }
    }

    const recent = [...changed].sort((a, b) => b.at - a.at).slice(0, RECENT)
    const folderName = root.split('/').pop() ?? root
    if (isPlain) {
      return (
        <Box flexDirection="column">
          <Text weight="bold">{folderName.toUpperCase()} (plain mode)</Text>
          {rows.map(row => (
            <Text>
              {row.guide}
              {row.isDir ? `${row.isOpen ? '▾' : '▸'} ${row.name}/` : `  ${row.name}`}
            </Text>
          ))}
        </Box>
      )
    }
    return (
      <Box flexDirection="column">
        <Box columnGap={2}>
          <Text weight="bold">{folderName.toUpperCase()}</Text>
          <Button key="collapse" plain dimColor label="Collapse all" onPress={() => collapseAll($)} />
          <Button key="map" plain dimColor label={isMap ? 'Hide plugin map' : 'Show plugin map'} onPress={() => toggleMap($)} />
        </Box>
        {(isMap || isRepo) && (
          <Box flexDirection="column" marginTop={1}>
            <Button key="legend" plain dimColor onPress={() => toggleLegend($)}>
              {isLegend ? '▾ Key' : '▸ Key'}
              <Text dimColor>{''}</Text>
            </Button>
            {isLegend && isMap && (
              <Box flexDirection="column">
                {Object.entries(PLUGINS)
                  .filter(([plugin]) => shown.has(plugin))
                  .map(([plugin, info]) => (
                    <Text>
                      <Text color={info.color} weight="bold">  ▏</Text>
                      <Text color={info.color}>{plugin}</Text>
                      <Text dimColor> set up this folder or created this file</Text>
                    </Text>
                  ))}
                <Text dimColor>   no line: your own folders</Text>
              </Box>
            )}
            {isLegend && isRepo && (
              <Box flexDirection="column">
                {(['U', 'A', 'M', 'R', '↑'] as GitMark[]).map(mark => (
                  <Text>
                    <Text color={GIT_INFO[mark].color} weight="bold">  {mark} </Text>
                    <Text dimColor>{GIT_INFO[mark].text}</Text>
                  </Text>
                ))}
                <Text>
                  <Text color={GIT_INFO.M.color} weight="bold">  ● </Text>
                  <Text dimColor>Folder holds files that are not on GitHub yet.</Text>
                </Text>
              </Box>
            )}
          </Box>
        )}
        {running !== null && (
          <Text>
            <Text color={colorOf(running)} weight="bold">▶ {running}</Text>
            <Text dimColor> is running: files it writes are tagged to it</Text>
          </Text>
        )}
        {recent.length > 0 && (
          <Box flexDirection="column" marginTop={1}>
            <Text dimColor weight="semibold">Just changed by Claude</Text>
            {recent.map(one => (
              <Text>
                <Text color={one.kind === 'A' ? GIT_INFO.U.color : GIT_INFO.M.color}>{one.kind === 'A' ? '+ ' : '~ '}</Text>
                {one.path}
              </Text>
            ))}
          </Box>
        )}
        <Box flexDirection="column" marginTop={1}>
          {rows.length === 0 && <Text dimColor>This folder is empty.</Text>}
          {rows.map(row => {
            if (row.isDir) {
              const count = dirty.get(row.path) ?? 0
              const color = count > 0 ? GIT_INFO.M.color : undefined
              return (
                <Box key={`d-${row.path}`} justifyContent="space-between">
                  <Box flexShrink={1}>
                    {stripe(row.path)}
                    <Button key={`b-${row.path}`} plain onPress={() => toggle($, row.path)}>
                      <Text dimColor>{row.guide}</Text>
                      <Text dimColor>{row.isOpen ? '▾ ' : '▸ '}</Text>
                      {row.isOpen ? '📂 ' : '📁 '}
                      <Text color={color} weight="semibold" {...liveName(live.get(row.path) ?? null)}>
                        {row.name}/
                      </Text>
                    </Button>
                    {row.isOpen ? null : liveBadge(liveOf(row.path, true))}
                  </Box>
                  {status(null, count)}
                </Box>
              )
            }
            const mark = git.get(row.path) ?? null
            const color = mark === null ? undefined : GIT_INFO[mark].color
            return (
              <Box key={`f-${row.path}`} justifyContent="space-between">
                <Box flexShrink={1}>
                  {stripe(row.path)}
                  <Text dimColor>{row.guide}  </Text>
                  <Text size="caption" mono color="#E6E6E6" backgroundColor="#4A4E57">
                    {badge(row.name)}
                  </Text>
                  <Button key={`o-${row.path}`} plain onPress={() => openFile($, row.path)}>
                    <Text color={color}> </Text>
                    <Text color={color} {...liveName(liveOf(row.path, false))}>
                      {` ${row.name} `}
                    </Text>
                  </Button>
                  {liveBadge(liveOf(row.path, false))}
                  {isBrowserFile(row.name) && (
                    <Button key={`w-${row.path}`} plain dimColor label=" ↗ browser" onPress={() => openBrowser($, row.path)} />
                  )}
                </Box>
                {status(mark, 0)}
              </Box>
            )
          })}
          {isCut && <Text dimColor>Showing the first {MAX_ROWS} rows. Collapse a folder to see more.</Text>}
        </Box>
      </Box>
    )
  })
}
