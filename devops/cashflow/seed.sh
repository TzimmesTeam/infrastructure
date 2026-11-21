#!/bin/sh
set -eu

snapshot_id=${SNAPSHOT_ID:-smoke-$(date -u +%Y%m%dT%H%M%S)-$(cat /proc/sys/kernel/random/uuid)}
case "$snapshot_id" in
  [A-Za-z0-9]*) ;;
  *) echo 'SNAPSHOT_ID must start with an ASCII letter or digit' >&2; exit 1 ;;
esac
case "$snapshot_id" in
  *[!A-Za-z0-9._-]*) echo 'Invalid SNAPSHOT_ID characters' >&2; exit 1 ;;
esac
if [ "${#snapshot_id}" -gt 128 ]; then
  echo 'SNAPSHOT_ID must contain at most 128 characters' >&2
  exit 1
fi

raw_uri="s3://${S3_RAW_BUCKET}/source=core_banking/ingest_date=2022-08-31/snapshot_id=${snapshot_id}/deals.csv"
aws --endpoint-url http://s3:8333 s3 cp /fixtures/deals.csv "$raw_uri" --only-show-errors
printf '%s\n' "$snapshot_id"
