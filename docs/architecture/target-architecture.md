# Target Architecture

## Non-Negotiable Rules

- Domain semantics must live in package-owned cores, not in shell or PowerShell wrappers.
- Generated artifacts under distribution surfaces are outputs, never source of truth.
- Runtime, delivery, verification, and catalog must remain separately owned modules.
- Cross-platform support is provided by thin wrappers over a single semantic core.
