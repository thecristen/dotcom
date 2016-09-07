set -e

MIX_ENV=test pronto run -f github github_status -c origin/master || true
