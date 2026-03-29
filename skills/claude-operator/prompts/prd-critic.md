# PRD Self-Critique Instructions

After generating a PRD, run it through these 5 critique lenses in sequence. Each lens can modify the PRD. Track all changes made.

## Lens 1: Product Critic

Ask yourself:
- Is this actually necessary? Would the product suffer without it?
- Is the value claim honest and specific, or vague ("improves user experience")?
- Does this solve a real user problem or is it an engineering exercise?
- Is this the right priority given the product's current stage?

If the answer to any question is concerning, revise the relevant PRD sections.

## Lens 2: Scope Optimizer

Ask yourself:
- Is this truly the smallest useful version? Can any requirement be cut while still delivering value?
- Are there requirements that are "nice to have" masquerading as "must have"?
- Could we ship something simpler first and iterate?
- Does the "Out of Scope" section exist and is it specific?

Remove anything that isn't essential for V1. Move cut items to "Out of Scope" with a note about why.

## Lens 3: Risk Analyzer

Ask yourself:
- What could break in the existing codebase when we add this?
- Are there dependencies that might not be available or compatible?
- What are the second-order effects? (e.g., adding a feature creates a support burden)
- What's the rollback plan if this doesn't work?
- Could this introduce security vulnerabilities?

Add any new risks to the Risks section. If a risk is serious enough, revise the Technical Approach.

## Lens 4: Feasibility Check

Ask yourself:
- Does the Technical Approach actually align with the codebase's patterns?
- Are there existing utilities, components, or patterns we should reuse?
- Does this depend on infrastructure that doesn't exist yet?
- Can the requirements be implemented as described, or are any technically impossible?

Revise the Technical Approach to match reality. If a requirement is infeasible, flag it as an Open Question.

## Lens 5: Experimentation Enhancer

Ask yourself:
- Is there a testable hypothesis embedded in this feature?
- Can we measure whether this actually works after shipping?
- Could this be structured as an experiment (A/B test, feature flag, gradual rollout)?
- What does success look like in measurable terms?

Add or refine the Experiment Plan section. If the feature can't be measured, note that as a risk.

## Output

After all 5 passes, produce a summary of changes:

```json
{
  "prd_version": "vN",
  "iterations": [
    { "lens": "product_critic", "change": "description of what changed" },
    { "lens": "scope_optimizer", "change": "description of what changed" },
    { "lens": "risk_analyzer", "change": "description of what changed" },
    { "lens": "feasibility", "change": "description of what changed" },
    { "lens": "experimentation", "change": "description of what changed" }
  ]
}
```

If a lens found no issues, omit it from the iterations array.
