import { expect, test } from 'claude-code/testing'

const PANE = {
  plugin: 'explorer',
  component: 'Pane',
  requestId: 'explorer',
  props: {
    title: 'Explorer',
    isFocused: false,
    bodyColumns: 50,
    placement: 'dock',
    scroll: { offset: 0, bodyRows: 40 },
    view: {},
  },
} as const

test('the pane draws the tree', async ($, on) => {
  on('command.register', (_, e) => ({ value: { command: e.name } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('session.root', () => ({ value: '/v' }))
  on('fs.list', (_, e) => ({
    value:
      e.path === '/v'
        ? [
            { name: 'drafts', kind: 'dir', size: 0, mtimeMs: 0, isLink: false },
            { name: 'CLAUDE.md', kind: 'file', size: 1, mtimeMs: 1, isLink: false },
            { name: 'page.html', kind: 'file', size: 1, mtimeMs: 1, isLink: false },
          ]
        : [{ name: 'a.md', kind: 'file', size: 1, mtimeMs: 1, isLink: false }],
  }))
  on('fs.read', () => ({ deny: 'missing' }))
  on('fs.stat', () => ({ deny: 'missing' }))
  on('fs.exists', () => ({ value: false }))
  on('fs.write', () => ({ value: undefined }))
  on('process.run', () => ({ value: { exitCode: 0, stdout: '?? CLAUDE.md\0', stderr: '', isStdoutTruncated: false } }))
  on('clock.every', () => ({ value: undefined }))

  await $.session.start({ cwd: '/v', surface: 'desktop', isInteractive: true })

  for (const surface of ['desktop', 'terminal'] as const) {
    const ui = await $.ui.mount({ ...PANE, surface })
    const row = await ui.find({ type: 'Text', text: /CLAUDE/ })
    expect(row?.text).toContain('CLAUDE.md')
    expect(await ui.find({ type: 'Text', text: /a\.md/ })).toBeUndefined()
    await ui.press({ key: 'b-drafts' })
    expect((await ui.find({ type: 'Text', text: /a\.md/ }))?.text).toContain('a.md')
    await ui.press({ key: 'b-drafts' })
    expect(await ui.find({ type: 'Text', text: /a\.md/ })).toBeUndefined()
    await ui.unmount()
  }
})

test('the pane follows the session when the app moves it out of a spare folder', async ($, on) => {
  let where = '/spare'
  on('command.register', (_, e) => ({ value: { command: e.name } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('session.root', () => ({ value: where }))
  on('fs.list', (_, e) => ({
    value:
      e.path === '/vault'
        ? [{ name: 'CLAUDE.md', kind: 'file', size: 1, mtimeMs: 1, isLink: false }]
        : [],
  }))
  on('fs.read', () => ({ deny: 'missing' }))
  on('fs.stat', () => ({ deny: 'missing' }))
  on('fs.exists', () => ({ value: false }))
  on('fs.write', () => ({ value: undefined }))
  on('process.run', () => ({ value: { exitCode: 1, stdout: '', stderr: '', isStdoutTruncated: false } }))
  on('clock.every', () => ({ value: undefined }))

  await $.session.start({ cwd: '/spare', surface: 'desktop', isInteractive: true })
  where = '/vault'
  const ui = await $.ui.mount({ ...PANE, surface: 'desktop' })
  expect((await ui.find({ type: 'Text', text: /CLAUDE/ }))?.text).toContain('CLAUDE.md')
  expect(await ui.find({ type: 'Text', text: /SPARE|spare/ })).toBeUndefined()
  await ui.unmount()
})

test('off in the /mods switchboard: no pane, /explorer says so, and on again works', async ($, on) => {
  let switches = JSON.stringify({ explorer: false })
  const isSwitches = (e: unknown) => (e as { path: string }).path.endsWith('/.claude/mods/switches.json')
  let opened = 0
  on('command.register', (_, e) => ({ value: { command: e.name } }))
  on('ui.open', () => {
    opened += 1
    return { value: { isPlaced: true } }
  })
  on('ui.close', () => ({ value: undefined }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('session.root', () => ({ value: '/v' }))
  on('fs.list', () => ({ value: [{ name: 'CLAUDE.md', kind: 'file', size: 1, mtimeMs: 1, isLink: false }] }))
  on('fs.read', (_, e) => (isSwitches(e) ? { value: switches } : { deny: 'missing' }))
  on('fs.stat', () => ({ deny: 'missing' }))
  on('fs.exists', (_, e) => ({ value: isSwitches(e) }))
  on('fs.write', () => ({ value: undefined }))
  on('process.run', () => ({ value: { exitCode: 0, stdout: '', stderr: '', isStdoutTruncated: false } }))
  on('clock.every', () => ({ value: undefined }))

  await $.session.start({ cwd: '/v', surface: 'desktop', isInteractive: true })
  expect(opened).toBe(0)
  const said = (await $.command.run({ command: 'explorer', args: '' } as never)) as { text?: string }
  expect(said.text).toContain('/mods')
  expect(opened).toBe(0)

  switches = '{}'
  const back = (await $.command.run({ command: 'explorer', args: '' } as never)) as { text?: string }
  expect(back.text).toContain('Explorer pane opened')
  expect(opened).toBe(1)
})
