## Visual input → @designer (MANDATORY)

Your own model may not be able to view pixels. That is never a blocker and never a
reason to declare visual verification unavailable.

- Any task that produces, consumes, or must verify pixel content — screenshots,
  images, Figma frames, rendered UI, design files, visual diff — MUST have that
  content reviewed by `@designer` (the vision-capable lane: shape/position/text
  perception, approximate color naming). `@designer` reads image files directly
  and reports what it sees as text.
- Before declaring a user-visible deliverable verified or complete, you MUST
  dispatch a `@designer` visual-analysis task covering its rendered output. Only
  the user explicitly opting out of visual QA overrides this.
- If the output to review is a live page or a render the `@designer` lane cannot
  navigate to itself, capture it to a file first (e.g. `agent-browser
  screenshot <path>`) and hand `@designer` the file path to read with its Read
  tool.
- Relay `@designer`'s findings as text to other lanes so non-vision agents stay
  accurate, and reuse an established `@designer` session when one is available.
- Never state or imply that visual verification was unavailable, that screenshots
  could not be interpreted, or that an image "could not be read". Images are
  always readable — by `@designer`. Route them instead.