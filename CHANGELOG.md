# Changelog

What changed in each release of Arteria. The release workflow copies a version's section into its GitHub release notes, so write for people running the addon.

## Unreleased

- **`nodes test` shows whether the page can read each node.** Besides key login, it runs one round of the script the page runs on each node, and reports how many devices it read and how long that took, or why it failed (with addresses and user names taken out). A node that is too slow for the page says so. `debug` no longer lists nodes as down while the page is closed, and shows each node's last SSH message.

## 1.0.0

The first release: a live, animated map of how traffic flows between the internet, your router, its AiMesh nodes and every device.

- **Map**: an isometric view of your network. Cables are pipes and Wi-Fi links are arcs; each packet is traffic in motion, and packets grow and bunch up as throughput rises while moving at the same calm speed. Blue is download (toward the device), orange is upload (toward the internet), violet is the AiMesh backhaul. Devices behind a node stand in its zone. On a busy network the smallest devices are grouped into a *+N more* tray.
- **Flow**: a Sankey "river" from the internet (and local traffic) through the router, each band, port and node, to every device. Ribbon width follows throughput, with Download and Upload views. Rows keep a fixed order, so nothing jumps around while you watch.
- **Tap any device** to trace its path: everything else dims, and the readout shows its download and upload, its share of the total, signal, link rate and the path its traffic takes. **Details** shows its IP and MAC address, host name, maker, system, Wi-Fi standard and channel width (or port and speed), connection time, IPv6 and DHCP lease.
- **27 kinds of device**, each with its own drawing and icon: desktop PCs, Mac desktops, laptops, phones, tablets, watches, TVs, streaming boxes, speakers, soundbars, game consoles, printers, NAS, cameras, doorbells, smart locks, thermostats, lights, smart-home hubs, air conditioners, robot vacuums, appliances, smart plugs, sensors and more. The icon you choose in the router's client list always wins; otherwise the device's name, what the router detected, and its maker decide.
- **AiMesh nodes and the router drawn as what they are**: plug-in extenders, towers, cubes, pucks, gaming routers and classic routers, by model.
- **The *+N more* tray opens a list**: tap it to see the grouped devices, busiest first, and tap any of them to trace it.
- **Private Wi-Fi addresses** are marked as such, and a device whose private address changed is recognised by its host name when that's unambiguous, so it keeps its name and icon.
- **Expanded view**: a button opens a bigger view that fills the window (or the screen), with a stand for every device on a typical home network, a third line on each label, Flow rows with address, signal and link rate, and the readout's traffic and details together.
- A **Device report** (at the bottom of the page) shows how each device was recognised, without names or addresses, for issues about a device drawn as the wrong thing.
- **AiMesh nodes, per device.** The router reads each node's own clients over a single SSH session per node, with a key only the router holds (`arteria.sh nodekey` sets it up, shows a node's fingerprint before trusting it, and keeps the key on the nodes across AiMesh syncs). Without the key, the map still shows each node's backhaul total.
- **Only while the page is open.** Sampling starts when you open the page and stops about 20 seconds after you close it or switch to another tab. Nothing runs in the background, there are no cron jobs, and samples stay in RAM.
- **Mb/s or MB/s**: a switch at the top shows every rate in megabits or megabytes per second, and the page remembers your choice.
- The *Whole network* readout splits each total into internet and local traffic (between your devices, or to the router itself), so it's clear why it's higher than the Internet figures.
- Notices for a weak or offline backhaul and for nodes that can't be read.
- A terminal menu, ready for amtm, with `amtmupdate`, `update dev [branch]` for trying unreleased changes, and a `debug` report with no names or addresses.
