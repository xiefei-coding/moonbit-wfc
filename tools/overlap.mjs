import { readFile } from 'node:fs/promises';
import { overlap } from '../web/engine.mjs';

// A JSON job avoids ambiguous positional options and supports Unicode samples.
// node tools/overlap.mjs job.json
try {
  if (process.argv.length !== 3) throw new Error('Usage: node tools/overlap.mjs job.json');
  const job = JSON.parse(await readFile(process.argv[2], 'utf8'));
  const { sample, size = 2, width = 16, height = 16, seed = 1,
    periodic = false, symmetry = false } = job;
  if (typeof sample !== 'string' || sample.length > 65536 ||
      !Number.isInteger(size) || size < 1 || size > 8 ||
      !Number.isInteger(width) || width < 1 || width > 256 ||
      !Number.isInteger(height) || height < 1 || height > 256 ||
      !Number.isInteger(seed) || seed < 0 || seed > 4294967295 ||
      typeof periodic !== 'boolean' || typeof symmetry !== 'boolean') throw new Error('Invalid job parameters');
  const result = overlap(sample, size, width, height, seed, periodic, symmetry);
  if (result.startsWith('ERROR:')) throw new Error(result);
  process.stdout.write(result + '\n');
  if (result === 'UNSAT') process.exitCode = 2;
} catch (error) { console.error(error.message); process.exitCode = 1; }
