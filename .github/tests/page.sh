#!/bin/sh
# Checks arteria.asp without a router or a browser:
#  1. the page's own JavaScript parses (node --check), with the router's <% %> template tags stubbed;
#  2. it stays inside its private (function () { ... })(); scope, exporting only initial() and
#     Arteria: a global $ or store() would replace the firmware's own and break the router's menu;
#  3. it has no '<%' of its own inside the script: httpd would run it as a template tag;
#  4. page-units.js: device kinds and their drawings, model shapes, private addresses, the device report.
# Usage: .github/tests/page.sh [path/to/arteria.asp]   (needs node, python3)
set -eu
here=$(cd "$(dirname "$0")" && pwd)
page=${1:-$here/../../arteria.asp}
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
fail=0

python3 - "$page" "$t/page.js" <<'EOF'
import re, sys
page = open(sys.argv[1], encoding='utf-8').read()
js = '\n'.join(re.findall(r'<script type="text/javascript">(.*?)</script>', page, re.S))
if not js.strip():
    sys.exit('no inline script found')
icons = re.search(r'var ICON = \{(.*?)\n\};', js, re.S)
keys = re.findall(r'^\t(\w+):', icons.group(1), re.M) if icons else []
dup = sorted(set(k for k in keys if keys.count(k) > 1))
if dup:
    sys.exit('ICON lists an icon twice (the first one is lost): ' + ', '.join(dup))
if '<%' in js:
    sys.exit("the page's script contains '<%', which the router's web server would run as a template tag")
open(sys.argv[2], 'w', encoding='utf-8').write(js)
EOF

if node --check "$t/page.js"; then echo "ok    the page's JavaScript parses"; else echo "FAIL  the page's JavaScript doesn't parse"; fail=1; fi

if grep -q '^(function () {$' "$page" && grep -q '^})();$' "$page"; then
	echo "ok    the page code is wrapped in (function () { ... })();"
else
	echo "FAIL  the page code must stay wrapped in (function () { ... })(); so it can't clash with the firmware's globals"
	fail=1
fi

# Run the script on its own and list the globals it leaves behind: only initial and Arteria.
cat > "$t/globals.js" <<'EOF'
const fs = require('fs'), vm = require('vm');
const el = () => new Proxy(function () {}, { get: (o, k) => k === Symbol.toPrimitive ? () => '' : el(), apply: () => el(), set: () => true });
const sandbox = { document: el(), navigator: { userAgent: 'node' }, location: { pathname: '/user1.asp' }, setTimeout() {}, clearTimeout() {}, setInterval() {}, clearInterval() {}, console };
sandbox.window = sandbox;
const before = new Set(Object.keys(sandbox));
vm.runInNewContext(fs.readFileSync(process.argv[2], 'utf8'), sandbox);
const added = Object.keys(sandbox).filter(k => !before.has(k)).sort();
console.log(added.join(' '));
EOF
g=$(node "$t/globals.js" "$t/page.js")
if [ "$g" = "Arteria initial" ]; then echo "ok    globals: only initial and Arteria"
else echo "FAIL  the page script defines these globals: $g (only initial and Arteria are allowed)"; fail=1
fi

# Parts of the page run in Node: device kinds, drawings, model shapes, private addresses, the device report.
node "$here/page-units.js" "$t/page.js" || fail=1

[ $fail -eq 0 ] && echo "Page: all checks passed."
exit $fail
