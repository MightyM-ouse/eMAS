# Runtime JSON Contract Context

**Status:** Approved guidance  
**Canonical sources:** Enterprise Requirements v3.1, Mapping Technical Requirements v3.1, JSON Schema 1.0.0

## Mandatory principles

- The XLSM is the authoring source.
- The JSON is the immutable runtime source.
- The exact JSON version and hash loaded is the execution source.
- All three phases use the same JSON.
- PowerShell never creates or edits the JSON.

## Canonical file and schema

- Runtime filename: `eMAS_Runtime_Config.json`
- DEV filename: `eMAS_Runtime_Config.DEV.<timestamp>.json`
- Schema: `schemas/eMAS-runtime-config.schema.json`
- Dialect: JSON Schema Draft 2020-12
- Initial schema version: `1.0.0`

## Stop conditions

Stop when JSON syntax is invalid, schema major is unsupported, mandatory sections are absent, IDs/references are invalid, an executable operator is unknown, or a controlled checksum fails.

Unavailable optional customer evidence is not a configuration failure; it becomes a documented evaluation result.

## Versioning

SchemaVersion and MappingVersion are independent SemVer values. Breaking structural or code-meaning changes require a schema major version.
