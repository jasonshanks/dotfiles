import { Plugin } from "@opencode/plugin"
import { $ } from "bun"

export default Plugin.define({
  id: "rtk",
  async setup(ctx) {
    // Check if rtk binary is available
    try {
      await $`which rtk`.quiet()
    } catch {
      console.warn("[rtk] rtk binary not found in PATH — plugin disabled")
      return
    }

    // Register tool.execute.before hook (replaces V1 hook)
    await ctx.tool.hook("execute.before", async (event) => {
      const tool = String(event.tool ?? "").toLowerCase()
      if (tool !== "bash" && tool !== "shell") return

      const args = event.input as Record<string, unknown> | undefined
      if (!args || typeof args !== "object") return

      const command = args.command
      if (typeof command !== "string" || !command) return

      try {
        const result = await $`rtk rewrite ${command}`.quiet().nothrow()
        const rewritten = String(result.stdout).trim()
        if (rewritten && rewritten !== command) {
          args.command = rewritten
        }
      } catch {
        // rtk rewrite failed — pass through unchanged
      }
    })
  },
})