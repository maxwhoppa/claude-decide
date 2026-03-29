# Custom Research Agents

Drop `.md` files in this directory to add custom research agents to the operator's research phase.

Each file is a prompt that will be dispatched as a parallel research agent alongside the 7 built-in agents. The operator automatically injects `{{memory_json}}` and `{{backlog_json}}` template variables.

## Template

```markdown
# My Custom Agent

You are a [role] analyzing a codebase for [what you're looking for].

## Product Context

{{memory_json}}

## Current Backlog (DO NOT duplicate these)

{{backlog_json}}

## Your Job

[What to analyze and find]

## Output

Return a JSON object:

{
  "agent": "my-custom-agent",
  "findings": [
    {
      "title": "Short description",
      "detail": "What you found",
      "impact": "high | medium | low",
      "category": "your_category"
    }
  ],
  "suggestions": [
    {
      "idea": "What should be done",
      "effort": "small | medium | large",
      "impact": "high | medium | low"
    }
  ]
}
```

## Examples

- `accessibility-auditor.md` — audit for WCAG compliance
- `performance-analyzer.md` — find performance bottlenecks
- `api-design-reviewer.md` — review API design consistency
- `documentation-gap.md` — find undocumented features
