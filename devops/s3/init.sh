#!/bin/sh
set -eu

s3api() {
  aws --endpoint-url http://s3:8333 --cli-connect-timeout 5 --cli-read-timeout 30 s3api "$@"
}

# Creation errors (including authentication/network errors) must fail bootstrap.
# head-bucket makes repeated bootstrap safe without changing existing data.
for bucket in "$S3_RAW_BUCKET" "$S3_CURATED_BUCKET" "$S3_QUARANTINE_BUCKET" "$S3_ARTIFACTS_BUCKET" "$S3_SCRATCH_BUCKET"; do
  if ! s3api head-bucket --bucket "$bucket" 2>/dev/null; then
    if [ "$AWS_DEFAULT_REGION" = us-east-1 ]; then
      s3api create-bucket --bucket "$bucket"
    else
      s3api create-bucket --bucket "$bucket" --create-bucket-configuration "LocationConstraint=$AWS_DEFAULT_REGION"
    fi
  fi
done

# Preserve source revisions for reproducible processing.
s3api put-bucket-versioning --bucket "$S3_RAW_BUCKET" --versioning-configuration Status=Enabled
s3api put-bucket-lifecycle-configuration --bucket "$S3_SCRATCH_BUCKET" \
  --lifecycle-configuration file:///bootstrap/scratch-lifecycle.json
s3api list-buckets --query 'Buckets[].Name'
