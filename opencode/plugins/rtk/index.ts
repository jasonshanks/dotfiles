import { Plugin } from "@opencode/plugin"
import { $ } from "bun"

export default Plugin.define({
  id: "rtk",
  async setup(ctx) {
    // Probe once at setup; if rtk isn't installed, this plugin does nothing.
    try {
      const probe = await $`which rtk`.quiet().nothrow()
      if (probe.exitCode !== 0) {
        console.warn("[rtk] rtk binary not found in PATH — plugin disabled")
        return
      }
    } catch {
      console.warn("[rtk] could not probe for rtk binary — plugin disabled")
      return
    }

    await ctx.tool.hook("execute.before", async (event) => {
      const tool = String(event.tool ?? "").toLowerCase()
      if (tool !== "bash" && tool !== "shell") return

      const args = event.input as Record<string, unknown> | undefined
      const command =
        args && typeof args.command === "string" ? args.command : undefined
      if (!command) return

      let result
      try {
        result = await $`rtk rewrite ${command}`.quiet().nothrow()
      } catch {
        // rtk itself failed to run — pass the command through unchanged
        return
      }

      const rewritten = String(result.stdout).trim()

      // rtk rewrite exit codes: 0 = rewrite + auto-allow, 1 = no rewrite,
      // 2 = deny (blocks the command), 3 = rewrite + host must ask.
      if (result.exitCode === 2) {
        throw new Error(rewritten || `command blocked by rtk: ${command}`)
      }

      if (rewritten && rewritten !== command) {
        args.command = rewritten
      }
    })
  },
})
