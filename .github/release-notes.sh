#!/bin/sh
# Prints the GitHub release notes for a version:
#   the version's section from CHANGELOG.md (or, if there isn't one, the commit titles since
#   the previous tag), then install/update instructions and a link to the full diff.
# Usage: sh .github/release-notes.sh VERSION [PREVIOUS_TAG]
v=$1
prev=$2
repo=${GITHUB_REPOSITORY:-IfSugar/arteria}

section=$(awk -v v="$v" '
	/^## / { if (on) exit; on = ($2 == v); next }
	on { print }
' CHANGELOG.md | sed -e '/./,$!d')   # drop leading blank lines

if [ -n "$section" ]; then
	printf '%s\n' "$section"
else
	echo "CHANGELOG.md has no section for $v; using commit titles instead." >&2
	printf "## What's changed\n\n"
	if [ -n "$prev" ]; then git log --no-merges --format='- %s' "$prev..HEAD"
	else git log --no-merges --format='- %s' -20
	fi
fi

cat <<EOF

### Install or update

Over SSH on the router:

\`\`\`sh
curl -fsL --retry 3 "https://raw.githubusercontent.com/$repo/$v/arteria.sh" -o /tmp/arteria.sh && sh /tmp/arteria.sh install
\`\`\`

Already installed? Run \`/jffs/addons/arteria/arteria.sh update\`. Your settings and node access are kept.
EOF

if [ -n "$prev" ]; then
	printf '\n**Full diff:** https://github.com/%s/compare/%s...%s\n' "$repo" "$prev" "$v"
fi
