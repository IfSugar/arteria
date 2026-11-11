# Security policy

Arteria runs as root on your router, adds a page to its web interface, logs in to your AiMesh nodes with an SSH key,
and shows data that devices on your network can influence (every device picks its own host name), so security
problems matter. Thanks for reporting them responsibly.

## Reporting a problem

Report it privately through GitHub: **[Report a vulnerability](https://github.com/IfSugar/arteria/security/advisories/new)**.
Please don't open a public issue, discussion or pull request for it.

Useful to include: your router and node models, firmware version, Arteria version (`arteria.sh version`) and the
steps to reproduce. Never include router passwords, SSH keys, your WAN IP address or DDNS name. Your devices' names
and MAC addresses aren't needed: replace them with made-up ones.

You'll get an answer within a few days. Please allow up to 90 days for a fix before publishing details; problems that
put users at risk right now are fixed and disclosed sooner.

## What's in scope

- **Device names.** Any device can send any host name over DHCP. Anything that lets one run script in the Arteria
  page, run something through the router's page templates (`<% … %>`), break the data files, or run a command on the
  router.
- **The page and its data files.** Reading the data files (`/ext/arteria/*.htm`) or the page without the router
  login, starting the sampler without it, or getting the page to send data anywhere.
- **The node key and sessions.** Anything that exposes the router's node key (`/jffs/addons/arteria/node_key`), sends
  a password anywhere but the node it was typed for, or lets a node (or something pretending to be one) run a command
  on the router or break the page.
- **The script on the router.** Anything that makes it write outside its own folders, follow a link planted in
  `/tmp`, or run with someone else's input as code.
- **Install and update.** Getting a router to run code that isn't from this repository. Updates download from GitHub
  over HTTPS.
- **The release workflow.**

## Not in scope

- Asuswrt-Merlin itself, AiMesh, amtm, Entware packages and other addons: report those to their projects (the
  [SNBForums Asuswrt-Merlin AddOns forum](https://www.snbforums.com/forums/asuswrt-merlin-addons.60/) is a good
  place to start).
- Anything that needs someone who can already log in to the router's web interface or over SSH: they can see the same
  devices and counters, and run any command anyway.
- The node key being a full admin login on each node, like your own SSH key would be: that's how the nodes' SSH works.
  It never leaves the router, and removing its line from a node's *Authorized Keys* revokes it.

## Supported versions

Only the latest release gets fixes. Update with `/jffs/addons/arteria/arteria.sh update`.
