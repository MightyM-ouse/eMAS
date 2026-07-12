# Assessment Phases

## 1. Pre-Sales (Lightweight Scoping)
- **Execution**: CLI only
- **Purpose**: Early complexity and confidence estimation
- **Inputs**: Minimal source path information
- **Outputs**: Complexity (Very Low–Very High), Confidence level, clarification requests
- **Rules**: Keep lightweight. Do not perform deep file validation.

## 2. Pre-Migration Readiness
- **Execution**: CLI or portable WPF
- **Purpose**: Detailed source data readiness + baseline creation
- **Key Checks**: Dossier/sequence validation, mandatory files, XML integrity, access/backup verification, zero-byte files
- **Outputs**: Readiness status (Ready / Ready with Exceptions / Blocked) + baseline
- **Rules**: Must produce auditable evidence. Apply exceptions consistently.

## 3. Post-Migration Reconciliation
- **Execution**: CLI or portable WPF
- **Purpose**: Compare migrated state against pre-migration baseline
- **Outputs**: Reconciliation status (Reconciled / Reconciled with Exceptions / Review Required / Not Reconciled)
- **Rules**: Always load and compare against the baseline produced in Phase 2.