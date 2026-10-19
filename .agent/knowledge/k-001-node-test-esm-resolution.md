---
id: "k-001"
title: "Explicit File Extensions in ESM Import Resolution for Node Test Runner"
date: 2026-10-19
tags:
  - "nodejs"
  - "node-test"
  - "esm"
  - "modules"
  - "runtime"
severity: "medium"
affected_components:
  - "package.json"
  - "tests/smoke.test.js"
symptoms:
  - "ERR_MODULE_NOT_FOUND"
  - "Cannot find module ... Did you mean to import ...js?"
  - "Directory import ... is not supported resolving ES modules"
---

# [k-001] Explicit File Extensions in ESM Import Resolution for Node Test Runner

## Problem / Symptom

When running native tests using Node.js's built-in test runner (`node --test`), ECMAScript Module (ESM) resolution does not perform automatic extension lookups (such as appending `.js` or `.mjs`) or directory index resolution (`./utils` resolving to `./utils/index.js`), unlike legacy CommonJS `require()`.

Attempting to import a module without its explicit `.js` extension yields a fatal runtime resolution error:

```text
node:internal/modules/esm/resolve:265
    throw new ERR_MODULE_NOT_FOUND(
    ^

Error [ERR_MODULE_NOT_FOUND]: Cannot find module '/app/src/math' imported from /app/tests/smoke.test.js
Did you mean to import /app/src/math.js?
    at finalizeResolution (node:internal/modules/esm/resolve:265:11)
    at moduleResolve (node:internal/modules/esm/resolve:933:10)
    at defaultResolve (node:internal/modules/esm/resolve:1157:11)
```

## Approved Solution

Always include full, explicit file extensions in relative and local import statements within ESM modules:

```javascript
// ✅ CORRECT: Explicit file extension for relative imports
import { calculateSum } from '../src/math.js';
import { dbConfig } from './config.js';

// ✅ CORRECT: Explicit index.js for directory targets
import { formatters } from '../src/utils/index.js';
```

If package-level exports are used, define explicit subpath exports in `package.json`:

```json
{
  "name": "my-app",
  "type": "module",
  "exports": {
    "./utils": "./src/utils/index.js"
  }
}
```

**Root Cause:** ECMAScript specification mandates deterministic URL/path resolution without filesystem probing. Node.js ESM implementation intentionally disabled automatic extension and index lookup to avoid filesystem latency and ambiguity.

## What NEVER to Do

- ❌ **Anti-Pattern:** Passing `--experimental-specifier-resolution=node` to Node.js CLI flags.
  - *Why:* This flag is deprecated in modern Node.js runtimes and produces unstable behavior across different deployment environments and CI runners.
- ❌ **Anti-Pattern:** Transpiling tests on-the-fly with heavy, unpinned bundler wrappers when running zero-dependency tests.
  - *Why:* Bypassing standard ESM syntax adds unnecessary external dependencies and creates parity gaps between test and production runtimes.

## Verification

Run the test suite using standard zero-dependency `npm test`:

```bash
npm test
# Verify that all test suites execute and report passing tests without ERR_MODULE_NOT_FOUND
```

## References
- [Node.js ESM Modules Documentation: Mandatory file extensions](https://nodejs.org/api/esm.html#mandatory-file-extensions)
