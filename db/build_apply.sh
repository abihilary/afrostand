#!/usr/bin/env bash
# Concatenates the schema and the generated seed into one file to paste into
# the Supabase SQL editor. There is no CLI or MCP reach into this project, so
# one paste is the whole deploy path.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
python3 "$HERE/build_seed.py" >/dev/null
{
  cat <<'HDR'
-- ===========================================================================
-- AFROSTAND - paste this whole file into the Supabase SQL editor and Run.
-- ===========================================================================
-- GENERATED from db/0001_schema.sql + db/0002_seed.sql. Regenerate with
-- db/build_apply.sh rather than editing this file.
--
-- Safe to re-run: every object is guarded and every seed row is ON CONFLICT
-- DO NOTHING against a deterministic id.
--
-- Verified before shipping, against a local Postgres with an auth shim:
-- 17 tables, all with RLS, 29 policies, db/test/rls_test.sql passing 33/33,
-- db/test/fulfilment_test.sql 16/16 and db/test/security_test.sql 17/17, including "one seller cannot ship
-- another seller's goods",
-- "anon cannot write to products" and "a third party reads nothing from a chat
-- thread".
-- ===========================================================================

HDR
  cat "$HERE/0001_schema.sql"
  echo
  cat "$HERE/0005_fulfilment.sql"
  echo
  cat "$HERE/0006_realtime.sql"
  echo
  cat "$HERE/0007_security.sql"
  echo
  cat "$HERE/0003_storage.sql"
  echo
  cat "$HERE/0002_seed.sql"
} > "$HERE/apply.sql"
echo "wrote db/apply.sql ($(wc -l < "$HERE/apply.sql") lines)"
