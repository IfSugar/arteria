# Changelog

What changed in each release of Arteria. The release workflow copies a version's section into its GitHub release notes, so write for people running the addon.

## 1.0.0

The first release: a live, animated map of how traffic flows between the internet, your router, its AiMesh nodes and every device.

- **Map**: an isometric view of your network. Cables are pipes and Wi-Fi links are arcs; each packet is traffic in motion, and packets grow and bunch up as throughput rises while moving at the same calm speed. Blue is download (toward the device), orange is upload (toward the internet), violet is the AiMesh backhaul. Devices behind a node stand in its zone. On a busy network the smallest devices are grouped into a *+N more* tray.
- **Flow**: a Sankey "river" from the internet (and local traffic) through the router, each band, port and node, to every device. Ribbon width follows throughput, with Download and Upload views. Rows keep a fixed order, so nothing jumps around while you watch.
- **Tap any device** to trace its path: everything else dims, and the readout shows its download and upload, its share of the total, signal, link rate and the path its traffic takes.
- **AiMesh nodes, per device.** The router reads each node's own clients over a single SSH session per node, with a key only the router holds (`arteria.sh nodekey` sets it up). Without the key, the map still shows each node's backhaul total.
- **Only while the page is open.** Sampling starts when you open the page and stops about 20 seconds after you close it or switch to another tab. Nothing runs in the background, there are no cron jobs, and samples stay in RAM.
- **Mb/s or MB/s**: a switch at the top shows every rate in megabits or megabytes per second, and the page remembers your choice.
- The *Whole network* readout splits each total into internet and local traffic (between your devices, or to the router itself), so it's clear why it's higher than the Internet figures.
- Notices for a weak or offline backhaul and for nodes that can't be read.
- A terminal menu, ready for amtm, with `amtmupdate`, `update dev [branch]` for trying unreleased changes, and a `debug` report with no names or addresses.
