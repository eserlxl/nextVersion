chmod +x comparator/*.sh

# Quick end-to-end run (10 repos, medium complexity)
comparator/nv-suite.sh

# Deterministic, high complexity, keep repos under a folder
comparator/nv-suite.sh --count 5 --seed 12345 --complexity high --keep --keep-under /tmp/nv-repos

# Dependencies
Requires `fake-repo` to generate repositories. Install it and ensure it is in your PATH.

# Manual generation examples with fake-repo
fake-repo                               # Generate in a secure temp directory under /tmp
fake-repo /tmp/test-repo                # Generate in /tmp/test-repo
fake-repo --files 20-50 --commits 10-30 /tmp/repo
fake-repo --chaos --verbose /tmp/chaos-repo
fake-repo --complexity 7 /tmp/medium-repo

# Compare a list (from stdin or args)
printf '/tmp/nv-repos/nv-rand.a1b2c3\n' | comparator/nv-compare.sh
comparator/nv-compare.sh /path/to/repo1 /path/to/repo2