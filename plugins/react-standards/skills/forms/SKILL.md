---
name: forms
description: >
  Build forms with React Hook Form + Zod + @hookform/resolvers. Use when the user asks to add,
  build, or validate a form, or writes form/input JSX by hand without this stack.
---

# Forms and validation

Install (already done by `app-scaffold`, list here for standalone use): `react-hook-form`, `zod`,
`@hookform/resolvers`.

## Rules

- Use React Hook Form for all form state/validation, Zod for schema validation, and
  `@hookform/resolvers` to connect them. Never hand-roll form state with `useState` per field.
- Define one Zod schema per form and infer the TS type from it with `z.infer` — don't hand-write a
  separate form type; the two will drift.
- Place each form's Zod schema next to the component using it (e.g. `features/auth/schemas.ts`),
  not in a shared global schemas file, unless the schema is genuinely reused across features.
- If the project uses shadcn/ui, use its `Form` component wrapper — it's already built on this
  exact stack (RHF + Zod context) and saves re-wiring `errors`/`register` by hand.
- A form component stays a pure component per the `component-design` skill: it receives
  `onSubmit` as a prop from the caller when submission triggers a mutation, rather than calling an
  API directly inside the form.

## Pattern

```tsx
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";

const schema = z.object({
  email: z.string().email("Invalid email"),
  password: z.string().min(8, "Must be at least 8 characters"),
});

type FormData = z.infer<typeof schema>;

function LoginForm() {
  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const onSubmit = (data: FormData) => { /* ... */ };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register("email")} />
      {errors.email && <p>{errors.email.message}</p>}
      <input type="password" {...register("password")} />
      {errors.password && <p>{errors.password.message}</p>}
      <button type="submit">Submit</button>
    </form>
  );
}
```
