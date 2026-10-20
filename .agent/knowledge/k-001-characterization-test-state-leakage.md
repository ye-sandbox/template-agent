---
id: "k-001"
title: "Global State and Open Handle Leakage in Legacy Characterization Tests"
date: 2026-10-19
tags:
  - "legacy"
  - "testing"
  - "characterization"
  - "isolation"
  - "runtime"
severity: "medium"
affected_components:
  - ".agent/INVARIANTS.md"
  - "tests/"
  - "src/"
symptoms:
  - "Tests pass individually when executed in isolation but fail when run in full suite"
  - "Jest did not exit one second after the test run has completed (open handles)"
  - "State from previous test suite pollutes subsequent assertions with stale database records"
  - "Uncaught Exception or unhandled rejection due to lingering timers or unclosed sockets"
---

# [k-001] Global State and Open Handle Leakage in Legacy Characterization Tests

## Problem / Symptom

When introducing characterization tests ("Golden Master tests") to pin baseline legacy behavior before refactoring, legacy modules frequently rely on global mutable state, singleton service instances, unclosed database connection pools, un-mocked environment variables, or background event listeners.

While individual tests succeed when run in isolation:
```bash
npm test tests/legacy-order-service.test.js # ✅ PASS
```

Executing the entire test suite fails or hangs indefinitely:
```text
A worker process has failed to exit gracefully and has been force exited.
This is likely caused by tests leaking dual handles (TCPWRAP / Timeout / FSReqCallback).
Jest did not exit one second after the test run has completed.
'--detectOpenHandles' flag may help locate the leaks.
```

Or downstream assertions fail due to polluted in-memory state or database foreign keys left behind by preceding tests:
```text
AssertionError: expected 'active' to equal 'pending'
    at Context.<anonymous> (/app/tests/characterization/billing.test.js:84:14)
```

## Approved Solution

Ensure hermetic isolation for characterization tests without mutating fragile legacy production code:

1. **Snapshot and Restore Process Environment & Globals:**
   Capture environment variables and global objects in a setup hook and restore them deterministically in teardown:

```javascript
// tests/helpers/hermetic-sandbox.js
export function createHermeticSandbox() {
  const originalEnv = { ...process.env };
  const disposers = [];

  return {
    registerDisposer(fn) {
      disposers.push(fn);
    },
    async teardown() {
      // 1. Run all registered resource cleanup functions
      while (disposers.length > 0) {
        const cleanup = disposers.pop();
        try {
          await cleanup();
        } catch (err) {
          console.error('Error during test cleanup:', err);
        }
      }

      // 2. Restore process environment
      for (const key of Object.keys(process.env)) {
        if (!(key in originalEnv)) {
          delete process.env[key];
        }
      }
      Object.assign(process.env, originalEnv);
    }
  };
}
```

2. **Explicitly Teardown Database Pools & Background Handles:**
   In characterization test suites, explicitly close connection pools and clear pending timers in `afterAll` / `afterEach`:

```javascript
import { dbPool, legacyWorker } from '../src/legacy-module.js';

describe('Legacy Billing Characterization', () => {
  afterAll(async () => {
    // INVARIANT: Legacy worker does not automatically close idle TCP pool
    if (legacyWorker?.stop) await legacyWorker.stop();
    if (dbPool?.end) await dbPool.end();
  });

  it('captures baseline invoice tax calculation', async () => {
    // Assert current behavior
  });
});
```

3. **Force Sequential Execution When In-Process Concurrency Is Not Supported:**
   If the legacy architecture relies on process-wide singletons, configure test runners to execute sequentially (`--runInBand` in Jest, `--test-concurrency=1` in Node.js test runner) until isolation layers are introduced.

**Root Cause:** Legacy applications were frequently designed to run as single long-lived daemon processes rather than ephemeral testable modules, leaving resource lifecycles untracked.

## What NEVER to Do

- ❌ **Anti-Pattern:** Bypassing teardown with `--forceExit` (Jest) or unhandled termination flags in CI.
  - *Why:* `--forceExit` masks unclosed database connections, open sockets, and unhandled promise rejections, leaving broken async workflows unmonitored.
- ❌ **Anti-Pattern:** Artificially inflating timeouts (e.g., `testTimeout: 60000`) or adding arbitrary `sleep()` delays to wait for open handles to quietly expire.
  - *Why:* Slows down development feedback loops and creates persistent CI flakiness under varied runner CPU loads.
- ❌ **Anti-Pattern:** Refactoring the legacy database client or singleton architecture before establishing passing characterization tests.
  - *Why:* Violates Golden Rule 1 ("Characterization before refactoring") and Chesterton's Fence, risking production regressions.

## Verification

Run the characterization test suite with open handle detection enabled:

```bash
# Verify all suites execute and exit cleanly without hanging open handles
npm test -- --detectOpenHandles
```

## References
- [Working Effectively with Legacy Code (Michael Feathers) - Chapter on Characterization Tests](https://www.oreilly.com/library/view/working-effectively-with/0131177052/)
- [Jest Documentation: Troubleshooting Open Handles](https://jestjs.io/docs/troubleshooting#tests-are-failing-and-you-dont-know-why)
