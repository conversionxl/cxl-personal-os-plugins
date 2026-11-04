export type Change = { path: string; kind: 'A' | 'M'; at: number }

declare module 'claude-code' {
  interface PluginState {
    explorer: {
      expanded: Shaped<string[]>
      changes: Shaped<Change[]>
      tick: number
      active: string | null
      showMap: boolean
      legendOpen: boolean
    }
  }
}
