import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';

test('baremetal core contract files exist', () => {
  assert.ok(existsSync('AGENTS.md'), 'AGENTS.md should exist');
  assert.ok(existsSync('.agent/BASELINE.md'), '.agent/BASELINE.md should exist');
  assert.ok(existsSync('.agent/INVARIANTS.md'), '.agent/INVARIANTS.md should exist');
  assert.ok(existsSync('.agent/TUNINGS.md'), '.agent/TUNINGS.md should exist');
  assert.ok(existsSync('.agent/skills/baremetal-tuning/SKILL.md'), 'baremetal-tuning skill should exist');
  assert.ok(existsSync('.agent/TASK.md'), '.agent/TASK.md should exist');
  assert.ok(existsSync('.agent/NOTES.md'), '.agent/NOTES.md should exist');
});
