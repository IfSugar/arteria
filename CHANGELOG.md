# Changelog

What changed in each release of Arteria. The release workflow copies a version's section into its GitHub release notes, so write for people running the addon.

## 2.0.0

Arteria's second release: rename devices right from the map, zoom into the expanded map, 24 more kinds of device, and a router that's left alone when it's struggling. Thanks to everyone in the SNBForums thread for the reports that shaped it.

### New

- **Rename devices from Arteria.** A pencil after a device's name in the live readout (or the name itself) opens a name field; while you type, the icon shows what the device will be drawn as. Enter or the check saves it in the router's own client list, so the router shows it too, with a matching icon where the router has one; Escape or the cross keeps the old name, and an empty name brings the router's own back. Offline devices can be renamed too. Each rename starts from the router's client list as it is at that moment, so it never undoes another rename or a change made in the router's own client editor, and nothing is saved when that list can't be read. Names Arteria would ignore (ones routers fill in themselves, like `ESP-…`) are refused. Each rename leaves two lines in the system log, with how many names the list holds before and after (no names or addresses).
- **Zoom and pan the expanded map**, like a whiteboard: the mouse wheel or a trackpad pinch zooms around the pointer, dragging or a two-finger scroll moves around, and **− / 100% / +** in the corner zoom in steps or show the whole map again. It never shows empty space past the map's edges, opens on the whole map each time, and a label reached with Tab comes into view. The map zooms its drawing, not a picture of it, and its animations wait while it moves, so it stays sharp and smooth even at 400% with a device traced.
- **`doctor`** (also *d* in the menu) looks for the known problems and says what fixes each; **`doctor fix`** fixes the ones it can: a hook line left by an older version or by going back to 1.0.0, files older versions left, page files any program could change, a client list copy or a node session left after the page closed. On each node it checks key login and runs Arteria's script once, traced, to name any command that crashes there. Nothing in its output names a device or an address.
- **Dual WAN**: the second WAN counts as internet too, instead of as local traffic, and the Internet readout shows what each WAN carries.
- **Guest Network Pro**: wired devices on a Guest Network Pro network (a LAN port in a VLAN profile) are placed on their port.
- **Short rates show their unit**: *47k*, *2.1m* and *1.25g* in bits, *47K*, *2.1M* and *1.25G* in bytes. Megabits used to show as a bare number.

### Safer on the router

- **Arteria keeps out of the way of a struggling router.** While it samples it watches the load and the memory available. On a busy router (a load of 2 per CPU core, or under 48 MB available) it samples a third as often and opens no new node sessions; on an overloaded one (4 per core, or under 24 MB, when the page opens or for three samples in a row), or one that needs over 15 s for two samples in a row, it stops for 2 minutes. The page says why, the system log gets a line, and `status` shows the load, the memory and the last pause. A router that's slow to sample is sampled less often, up to every 10 seconds.
- **A quieter system log.** The page keeps sampling going with a request every so often, and the router writes two lines to its system log for each. The page now asks every 45 seconds instead of every 8 (every 8 until the first sample comes, and again right away if samples stop): about 160 lines an hour instead of 900. The map and Flow still update every 2 seconds. Closing or pausing the page still stops sampling at once; a hidden tab stops it after 2 minutes instead of 20 seconds (`IDLE_STOP`, now at least 120).
- **The page stops asking after a minute without samples**, says what to check, and its **Stopped** button tries again. It used to ask every 8 seconds for as long as it was open.
- **The service-event hook starts Arteria for its own events only.** It used to start the script for every service event on the router. Installing or updating replaces the old line.
- **Only root can change the page's files.** The router starts Arteria with nothing masked, so its data files and their folder were writable by any program on the router.
- **The README explains how to get a struggling router back without a factory reset**: turn off *JFFS custom scripts and configs*, reboot, then uninstall over SSH.

### AiMesh nodes

- **Routers already set up for passwordless logins to their nodes work as they are.** If root on the router has a key that opens the nodes (`~/.ssh/id_dropbear`, as the forum's guide and the Wireless Report addon set up), Arteria uses it and trusts each node as root's `known_hosts` does: no `nodekey`, no password. `nodekey` still sends a password only to a node whose identity you confirmed there.
- **Slow nodes count as answering**: a node is judged by its own pace (up to a round every 30 seconds), not by 3 rounds of 2 seconds.
- **A node where something crashes says so** (*Segmentation fault*), instead of "isn't answering".
- **`nodes test` shows whether the page can read each node**: besides key login, it runs one round of the page's script there and reports how many devices it read and how long that took, or why it failed (addresses and user names taken out), and which key works. It, `nodekey` and `doctor` answer sooner: they look every 0.2 seconds, not every second.
- **`nodekey` changes only what it must**: it adds Arteria's key to the router's list only for nodes no key reaches yet, and warns when the list already has other keys (nodes with ASUS's own firmware take only the first). With *Allow Password Login* off it no longer tries a password: the key goes into the router's list, and it says to reboot the node, which is when a node loads that list. It no longer leaves `node_key.new.pub` behind.
- **`debug`** shows each node's pace, how fresh its output is, how many stations it reports and its last SSH message, plus which keys the router has for its nodes. It no longer lists nodes as down while the page is closed.

### Devices

- **24 more kinds**, 51 in all, each with its own drawing and icon: LED strip (Govee, WLED, TV backlights), boiler (and boiler gateways: EMS-ESP, ebusd, Vitoconnect), air purifier or humidifier, smart switch, door sensor, washing machine, dryer, dishwasher, Raspberry Pi, streaming stick, smart speaker (Echo, HomePod, Nest Audio), smart display (Echo Show, Nest Hub), projector, VR headset, 3D printer, car, EV charger, solar inverter or home battery, robot mower, sprinkler, garage door, smart blinds, pet device and fitness equipment.
- **Words run together are recognised**: *JohnsNas*, *KidsTV*, *nas01* and *office_printer* are read like *John's NAS*, so the same rules work for everyone's names.
- **A nickname wins over the icon the router guessed**: when the router's icon is just its own guess, or a computer, phone, tablet, watch or console icon on a device named after a home device, the name decides (*Lounge Daikin AC* is an air conditioner, not the console the router guessed). Icons you picked still come first. A nickname the router saved by itself ("dhcpcd-6 8 2…", the maker's name) isn't used as a name.
- **Many more names and makers**, including the names devices give themselves: Tapo and Kasa model numbers (`L630`, `P110`, `C200`), Govee (`ihoment_H6159_…`), Bosch, Siemens and Neff machines by model, printers (`NPI…`, `BRW…`, `hpenvy-…`), Ring cameras, Echo speakers (`amazon-…`), Daikin's Wi-Fi adapters, Sony and Samsung TVs by model number, and many phones, tablets, TVs, speakers, locks, lights, hubs and vacuums.

### The page

- **Labels never sit on one another or on another device's drawing**: on a crowded floor a label moves further out, beside the floor if need be.
- **Tap a device's drawing** to trace it, as with its label. Anything cut short with "…" shows in full when you point at it.
- **Flow rows stay put**: a row keeps the room its traffic needed lately instead of resizing with every sample. The expanded Flow view fits the window even during a speed test.
- **A calmer tab bar**: the totals keep their width as the numbers change, the buttons and switches match, and the line of text under the title is gone, leaving more room for the map.

### Fixes

- **`check` no longer warns when the router has no Wi-Fi clients of its own** (all of them on a node, say): it notes that the counters will be checked once one connects.

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
