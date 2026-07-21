---
name: theming
description: >
  Set up shadcn/ui-style theming with light/dark mode and switchable design-token presets
  (e.g. AWS/Google/Microsoft-inspired design languages). Use when the user asks to add theming,
  dark mode, design tokens, or a switchable design system, or hardcodes colors/radii/spacing in
  components instead of referencing tokens.
---

# Theming: tokens, light/dark, and design-system presets

## Base rule

- Use shadcn/ui as the component base (Radix primitives + Tailwind). Never hardcode colors, radii,
  or spacing directly in components — always reference design tokens via Tailwind's semantic
  classes (`bg-primary`, `text-foreground`, `rounded-[--radius]`, `shadow-[--shadow]`).
- Never gate component logic on the theme in JS (e.g. `if (theme === "dark") return <DarkButton />`).
  Style purely through CSS variables/Tailwind classes so any preset or mode "just works" without
  touching component code.

## Light/dark tokens

Define all design tokens as CSS custom properties in `src/styles/themes.css`, scoped per theme —
see `templates/themes.css.template`. `tailwind.config.ts` maps utility classes to these variables
(`colors: { background: "hsl(var(--background))", ... }`) so components never reference raw
hex/px values.

Two independent switch axes:
- **Light/dark**: toggled by adding/removing the `dark` class on `<html>`.
- **Design preset** (optional, multi-brand/multi-layout): toggled via `data-theme="..."` on
  `<html>`, separate from the `dark` class, so a preset and light/dark mode combine freely.

Implement one `ThemeProvider` (`src/app/providers.tsx` or `src/components/ThemeProvider.tsx`)
using React Context that:
- Holds `{ mode: "light" | "dark" | "system", preset: string }` in state.
- Persists the choice to `localStorage` and reads it on load — set the class/attribute in a small
  inline script in `index.html` before React mounts, to avoid flash-of-wrong-theme.
- Exposes a `useTheme()` hook for components to read/set mode and preset.

On Next.js, use `next-themes` for the light/dark part instead of hand-rolling it; keep the
`data-theme` preset switch as a custom addition on top.

## Design-system presets (switchable design languages)

Extend the token idea into full design-language token sets — each preset captures a design
language's visual rules (palette, corner radius, spacing density, shadow/elevation, font), not
just accent colors. These are aesthetic approximations inspired by public design systems (e.g.
AWS Cloudscape, Google Material, Microsoft Fluent), not pixel-exact reproductions of a
trademarked library.

- Define a shared token shape once — see `templates/tokens-types.ts.template`
  (`DesignTokens { colors, radius, spacingUnit, shadow, fontFamily }`).
- One file per design language under `src/styles/tokens/` (`aws.ts`, `google.ts`, `microsoft.ts`,
  `default.ts`), each exporting a light + dark pair of `DesignTokens`.
- A `DesignSystemProvider` (`src/app/DesignSystemProvider.tsx`) applies the chosen token set to
  CSS variables on `document.documentElement` at runtime (`root.style.setProperty("--primary", ...)`
  etc.), so every component using the semantic Tailwind classes updates instantly with no rebuild.
- Expose `useDesignSystem()` returning `{ system: "default" | "aws" | "google" | "microsoft",
  setSystem }`, persisted to `localStorage`, independent of and combinable with light/dark mode.
- Keep the token registry in one place (`src/styles/tokens/index.ts`) mapping name → `{ light,
  dark }` so adding a new design language later is one new file + one registry entry, no
  component changes.
- Components must only ever reference the semantic Tailwind classes — never a specific design
  system's raw values — so the same component tree renders correctly under any preset.
