set -e

pronto run -f github github_status -c origin/master || true
