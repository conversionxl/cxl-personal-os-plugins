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
