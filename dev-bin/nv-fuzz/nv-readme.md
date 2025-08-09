chmod +x dev-bin/nv-fuzz/*.sh

# Quick end-to-end run (10 repos, medium complexity)
dev-bin/nv-fuzz/nv-suite.sh

# Deterministic, high complexity, keep repos under a folder
dev-bin/nv-fuzz/nv-suite.sh --count 5 --seed 12345 --complexity high --keep --keep-under /tmp/nv-repos

# Generate only and keep
dev-bin/nv-fuzz/nv-repo-gen.sh --count 3 --seed 42 --complexity 9 --no-cleanup --keep-repos-under /tmp/nv-repos

# Compare a list (from stdin or args)
printf '/tmp/nv-repos/nv-rand.a1b2c3\n' | dev-bin/nv-fuzz/nv-compare.sh
dev-bin/nv-fuzz/nv-compare.sh /path/to/repo1 /path/to/repo2