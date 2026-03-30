# State File Templates

These are the initial JSON structures the operator writes during onboarding.

## state.json

Written after onboarding completes. Marks the first research cycle.

```json
{
  "status": "running",
  "phase": "research",
  "cycle": 1,
  "mode": "default",
  "current_prd": null,
  "last_completed": null
}
```

Fields:
- `status`: "running" | "paused"
- `phase`: "onboarding" | "research" | "propose" | "collaborate" | "execute" | "validate" | "update_memory"
- `cycle`: integer, increments after each complete cycle
- `mode`: "default" | "force" | "auto"
- `auto_threshold`: float (0.0-1.0), default 0.75. Only used when mode is "auto". PRDs with backlog priority_score >= this value are auto-approved; below this value routes to collaboration.
- `current_prd`: filename of the PRD being executed (e.g., "003-rate-limiting.md"), or null
- `last_completed`: ISO timestamp of the last completed cycle

## memory.json

Written during onboarding from repo analysis + user interview.

```json
{
  "product": {
    "name": "",
    "description": "",
    "stage": "",
    "customer": "",
    "problem": "",
    "revenue_model": ""
  },
  "features": [],
  "feature_history": [],
  "constraints": [],
  "assumptions": [],
  "known_gaps": [],
  "past_decisions": [],
  "experiments": [],
  "satisfaction_history": []
}
```

Fields:
- `product`: core product info from user interview
- `features`: list of strings — detected + confirmed features
- `feature_history`: array of `{ "feature": string, "source": string, "cycle": int }`
- `constraints`: things the operator must NOT do or must respect
- `assumptions`: things the operator believes but hasn't confirmed
- `known_gaps`: identified deficiencies in the codebase
- `past_decisions`: array of `{ "cycle": int, "decision": string, "prd": string }`
- `experiments`: array of experiment records
- `satisfaction_history`: array of `{ "cycle": int, "rating": int|null, "prd": string }` — tracks user satisfaction ratings per cycle

## backlog.json

Seeded during onboarding from user wishlist + detected gaps.

```json
{
  "items": []
}
```

Each item:
```json
{
  "id": "BL-001",
  "idea": "Description of the idea",
  "source": "onboarding-wishlist | onboarding-detected | research-<agent-name> | user-redirect",
  "cycle_added": 0,
  "priority_score": 0.0,
  "status": "queued",
  "notes": null
}
```

Statuses: "queued" | "proposed" | "completed" | "rejected"

## stuck.json

Written by the execution subagent when it cannot resolve after 10+ attempts.

```json
{
  "cycle": 0,
  "prd": "",
  "attempts": 0,
  "last_error": "",
  "what_was_tried": [],
  "files_changed_so_far": [],
  "committed": false
}
```

## Cycle Log (logs/cycle-NNN.json)

Written at the end of each cycle.

```json
{
  "cycle": 0,
  "timestamp": "",
  "research_findings": {},
  "proposed_idea": "",
  "user_feedback": "",
  "prd": "",
  "execution_result": "success",
  "files_changed": [],
  "tests_added": 0,
  "commit": "",
  "validation_notes": "",
  "memory_updates": [],
  "satisfaction": {
    "rating": null,
    "comment": null
  }
}
```
