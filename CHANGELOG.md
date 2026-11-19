# Changelog

What changed in each release of Arteria. The release workflow copies a version's section into its GitHub release notes, so write for people running the addon.

## 2.2.0

Wired devices show wherever they are: behind switches (by name, managed switches too), on AiMesh nodes' own ports, on bonded ports, and on ports the firmware maps its own way. Nodes behind one port each show their own traffic. On the map, devices of a kind stand together, no two drawings overlap, and each label sits right next to its device. Also Wi-Fi 7 phones that join as multi-link devices, and amtm no longer putting the release back over a development version. Thanks to everyone in the SNBForums thread who reported problems, tested development versions and posted their output.

### Wired devices, switches and nodes

- **Devices behind a switch are listed by name.** A port has one counter, so a switch still shows as one device, *Switch on LAN 3*, with the port's figures. Picking it now lists the devices behind it, named and recognised like any other. Pick one for its details (IP, MAC, maker…) or to rename it; its traffic is the switch's, as the port can't tell them apart. They were only counted (*4 devices*) before.
- **A managed switch isn't in its own list.** A managed switch has an address of its own, so the router sees it as one more device on its port, and it was listed among the devices behind itself (*Switch on Living Room* listing *Switch-02*). A device behind a port whose name says switch (*Switch-02*, *Office switch*), or that you gave a switch's icon, is now the switch itself: the switch is named after it, shows its IP and MAC in Details, renames with it, and lists only the others. A type the router detected isn't enough (it can call a TV tuner a router), nor is a switch's model name (several switches can be chained on one port): those devices are listed with a switch's icon. A device on Wi-Fi named *Switch* is still a Nintendo Switch.
- **A switch's list shows all its devices.** Below the map, the list had room for three rows and scrolled. The cards now grow to show it, up to 10 rows.
- **Devices on a switch with a node show.** A PC or a NAS on the same switch as an AiMesh node didn't show at all: the router port the switch is on counted as the node's backhaul, everything on it included. They now show on that port, as the switch's devices, with what the port carries beyond the node when the node counts its own. When it isn't read, their traffic is in its figure.
- **Bonded ports (link aggregation) show their device.** A NAS on LAN 1 and 2, bonded, showed as *Device on LAN 1* and *Device on LAN 2* with no name: the router learns its address on the bond, which Arteria didn't read. The bond is now one port, *LAN 1+2*, with the NAS on it. A node's bonded ports are read the same way.
- **A port is named and linked as the firmware's port map says.** The GT-BE98 Pro's LAN 1 is a VLAN interface whose own link reads 10 Gb/s whatever is plugged in, so it showed as *Device on 10G port*. When an interface's own link disagrees with the firmware's map of its port, the map's link and number are used: *LAN 1*, at its real speed. Ports that share one link are named by their numbers (*LAN 2–4*), not by their fastest port's speed (*2.5G port*).
- **Wired devices on AiMesh nodes show.** A device on a node's LAN port (a Pi-hole, say), or behind a switch there, didn't show at all: the node was read for its Wi-Fi devices only. The node now also reads its LAN ports and the addresses its bridges learned on them, as the router does with its own, and those devices stand in the node's zone, with their own figures from the node's port counters. The port that leads back to the router (a wired backhaul) is left out. The port is named after the node (*Hall LAN*), as Arteria doesn't know its printed number. `nodes test` says how many it found (*1 more on its wired ports*).
- **A node's port given to a VLAN is read.** A LAN port given to a VLAN (Guest Network Pro's LAN: VLAN) leaves the node's list of LAN ports and is in that VLAN's bridge alone, so the node didn't read it, and a TV on it was listed with a switch on the router's port the node is on. A node now reads every Ethernet port in any of its bridges.
- **Guest networks are named on nodes too.** A device on a node's guest network (or another of Guest Network Pro's networks) shows that network's name, as it already did on the router.
- **Nodes behind one router port show their own traffic.** Several nodes behind one of the router's ports (on a switch, or one node wired behind another) each showed that port's whole total. They all looked equally busy, so the map's zones went to the first ones in the list, and the whole network counted the port once for each of them. A node that is read now counts its own wired uplink, as it already did a Wi-Fi one: it finds it by the router's address on it. A node wired behind another is taken out of the figure of the node in front, and its readout says which node it's behind. A node that isn't read gets what the port carries beyond the others, and the whole network counts the port once.
- **A node wired behind a node on a Wi-Fi backhaul shows when it isn't read.** It's on none of the router's ports or radios, so unless it was read over SSH it showed as offline. It now shows, with the port of the node in front of it as its backhaul.
- **Fewer weak-backhaul warnings for good links.** A 5 GHz backhaul at -73 dBm running at 864 Mb/s, which AiMesh calls Great, was flagged weak, on and off. A low signal now counts only below -75 dBm (-80 dBm on 6 GHz), and not while the link runs fast (600 Mb/s or more) under traffic; a link slow under traffic (under 200 Mb/s) is still weak. The warning changes only once the new reading has held for 10 seconds.
- **A Wi-Fi 7 phone is recognised.** A Wi-Fi 7 device on a Wi-Fi 7 router can join as a multi-link device, even over one link: the radio lists the address it uses on that link, a private one made from its own (the same middle four parts), while DHCP and the router's client list have its own. So the phone showed with no name, IP or maker. A radio's private address that nothing else knows, with exactly one known address made like that, is now that device; on two links at once, it's one device with both links' traffic. Details shows the link address. Only a Wi-Fi 7 device's address is read like this, and never as a device that is on the air itself, on a cable or a node: a station can't pass itself off as one of yours by copying its address.
- **A Steam Machine is a game console.** Its name (*SteamMachine*) now says so, as a Steam Deck's does.

### The map

- **Devices of a kind stand together on the map.** In each zone, bulbs stand by bulbs, laptops by laptops, TVs by TVs: each kind takes a cluster of stands, the most common kind first. Where a device stands changes only when devices join or leave the map, never with their traffic. A busy device that comes off the tray takes a free stand: the others stay where they are.
- **Devices on the map no longer overlap.** A stand is used only where the device's drawing is clear of every other drawing (a TV needs more room than a bulb), in the page's view and the expanded one. A crowded zone shows fewer devices and the rest wait on the **+N more** tray, the smallest drawings (bulbs, plugs, sensors) first; a device on a cable keeps its place before any Wi-Fi device.
- **Labels stay next to their devices.** A label sits right above, below or beside its device, on a short line, and never over another device or label. It is no longer sent to the edge of the map on a long line: a device whose label has no room nearby goes to the tray instead. Label lines never cross, and none passes over another device.
- **A node's zone runs to the front wall in the expanded view** with one or two nodes, so a node with many devices has room for more of them.
- **A node with many devices gets a zone on the map.** With more nodes than the map has zones, the busiest got them, so a node with one camera that uploads now and then kept a zone from a node with 18 quiet devices. Traffic still decides when one node is much busier (3 times, and over 1 Mb/s). Otherwise the node with many more devices (over twice as many) gets the zone, and when the page opens, before any traffic is measured, the nodes with the most devices get them.
- **Wired links to and from a node are drawn as pipes.** The map drew every link to a node, and from a node to its devices, as a Wi-Fi arc, even a node on an Ethernet backhaul and a device on a node's LAN port. Pipes are cables and arcs are Wi-Fi there too now: a node on a wired backhaul gets a pipe on the floor from the router (or from the node it's wired behind), and a device on its port gets one from the node, routed round the other stands. A switch on a node's port is named after the node (*Switch on Living Room*), short enough to read on the map.
- **A tablet looks like a tablet on the map.** It was drawn lying on a little table, which is what it looked like; it now stands on a slim foot, wider than a phone, with its camera at the top.

### The script and amtm

- **Sampling stops as soon as the page closes.** It used to finish the pause before its next sample first, up to 10 s on a busy router.
- **No more "can't open /proc/…/cmdline" in the sampler's errors.** Arteria checks a running program by reading its command line from /proc, and a program that ended a moment before left that error in the debug report. It was harmless (the check already treated it as not running), but it looked like a fault. The router's shell opens a file before it applies the `2>/dev/null` that follows it, so these reads now silence their errors first.
- **amtm no longer puts the release back over a development version.** amtm compares a script with the release that has the same version number, and a development version differs, so amtm offered it as an "MD5 update": taking it installed the release again, and what the development version had fixed was gone (a bonded NAS was back to *Device on LAN 1* and *Device on LAN 2*). A development version now has the line amtm reads to skip that check, and through amtm it's replaced only by a newer release (amtm offers only a higher number: once the release with the development version's own number is out, `update` goes back to it). `update` still goes back to the release.

## 2.1.0

Fixes for what the SNBForums thread reported after 2.0.0: AiMesh nodes that crashed while Arteria read them, a page that took seconds to go live, a menu that stopped updating, and ports out of order on the RT-AX88U. Also a page that follows ROG and TUF routers' colours, room for more nodes than the map has zones, and four devices drawn anew. Arteria is now in amtm (7.2 and later) as **ar**. Thanks to everyone in the thread who tested development versions and posted their output.

### Fixes

- **The page is live about a second after it opens.** 2.0.0 spaced samples by how long each took, so the first sample, which does the most work (reading the ports, starting the node sessions), held the second one back by 3 to 6 seconds, and the page waited on *Connecting…* for it. The second sample now comes a second after the first, the names are written alongside instead of before it, and the page checks for samples every second until it is live.
- **AiMesh nodes where reading crashed ("Segmentation fault")** — reported on GT6, XD6, RT-AX56U, RT-AX58U, RT-AX86S and RT-BE9700 nodes:
  - Arteria no longer reads a node's uplink. On a node with a Wi-Fi backhaul, the radio's own interface is a client of the router, and the node's devices are on `wl0.1`-style interfaces; Arteria read the uplink as if devices were on it.
  - A node on an Ethernet backhaul still names its radios as possible uplinks in its settings, but its devices are on them, so Arteria reads them while they work as access points.
  - The node's login shell now runs Arteria's script, as it would run it typed in a terminal there, instead of `sh -s`.
  - The trace `nodes test` and `doctor` save when something crashes no longer needs `sh -x`, which those nodes' shells refuse (that is why `node-trace.txt` held only "invalid option -- 'x'"). It names the command that crashed and the node's shell.
  - `doctor` checks a node the way `nodes test` does. It said a node was fine when the script had never run there.
- **A node's part of Flow adds up.** The bar of a node on a Wi-Fi backhaul could be taller than the ribbons to its devices, for a few seconds after traffic changed. The router counts the backhaul every sample, but the node counts its devices once a round, and those figures reach the page a round later. In the expanded view the minimum width of each quiet device's ribbon hid the gap. The node now also counts its own uplink in the same round, and its part of Flow and the map use that figure. A node on a wired backhaul keeps the router's. A node that joins its radios' uplinks into one interface (`dpsta`, as on the RP-AX56) counts that interface alone, since it counts every packet its radios do.
- **No phantom node.** An old entry in AiMesh's own list with an address outside the router's LAN (often 192.168.50.x, ASUS's default) showed as a node that's down. Such entries are ignored.
- **Ports are numbered as printed on the router.** Arteria takes the numbers from the firmware's own port map, where it has one. On the RT-AX88U, LAN 1 to 4 showed in reverse, and LAN 5 to 8, which sit behind one link to a second switch chip, showed as a device on LAN 5 even with nothing plugged in, at that link's speed. They now show as the port that's in use (*LAN 7*), at its own speed, and nothing shows when none of them is.
- **The menu is updated when it's mounted twice.** Every addon with a page mounts the menu copy addons share (`/tmp/menuTree.js`) over the router's own. An addon that mounts it again without unmounting it first leaves two mounts, one over the other. The router's pages still show the menu, but the copy can then no longer be replaced, so Arteria's update failed ("mv: can't rename … Device or resource busy"). The menu stayed as it was without a word, and a temporary copy was left in `/tmp/arteria`. Arteria now takes the extra mounts off, replaces the copy, and mounts it once; if even that fails, it leaves the menu as it was and says so. `doctor` reports a menu mounted more than once, and `doctor fix` mounts it once.
- **`update` says when it replaces a development version** with the release of the same number (*Updating 2.0.0 (development version: … ) -> 2.0.0, the release*). It said *Updating 2.0.0 -> 2.0.0*.
- **"Weak backhaul" only when it is.** The verdict is now based on the backhaul link that carries the node's traffic. While the node is quiet, it's based on its fastest link that isn't 2.4 GHz. The speed of an idle link's last packets is no longer counted: they are control frames, sent slowly on purpose. A 6 GHz link is allowed a weaker signal (-78 dBm), as it reads lower for the same quality.
- **Network names instead of "guest".** A device on one of the router's guest networks, or on another of Guest Network Pro's networks, shows that network's name. Devices on a main network show none, even when the router serves it on a `wl0.1`-style interface: Arteria used to call every such device a guest.
- **The page's requests reach Arteria first.** The router runs the lines in `/jffs/scripts/service-event` in order, so a line before Arteria's that ended the script, or waited, kept the page's requests out: the page said *Connecting…* for ever. Arteria's lines in `service-event` and `services-start` now come first, right after `#!/bin/sh`. They only start Arteria in the background, for its own events, so they never hold up the lines after them. Installing or updating moves them.

### Safer on the router

- **`nodes test` and `doctor` take at most about 1 MB from a node**, as the page's own node sessions already did: a node that sent output without end could fill the router's RAM.
- **The menu copy addons share is edited only when it is root's own file with a single name.** A hard link to another file in `/tmp` passed the old checks, so that file's content could end up readable as the menu. Such a copy is now replaced with the firmware's menu.
- **What `doctor` and `debug` show of other programs:** another program's line in `service-event` by the name of the program it runs only (the rest of the line can hold a password or a token), the program holding the sampler's lock by its name only, and the system log only from root's own files.
- **Arteria's lines in `service-event` and `services-start` are added and removed safely.** The new file is made and checked in full first, and the old one is put back if writing it doesn't come out whole, so a full JFFS can't cut it short and lose other addons' lines.
- **The port map leaves out the AiMesh nodes' ports**, which the firmware lists after the router's own: a node's port can't light up one of the router's.

### Doctor and debug

- **`nodes test` explains a node that reads 0 devices.** It lists the node's interfaces it reads and the ones it skips as the node's uplink, with the devices on each, and `doctor` does the same. Devices on a skipped interface mean Arteria took the wrong interface for the uplink on that node.
- **`doctor` tests what the page does when it opens.** It sends the same request as the page, `start_arteria`, and says whether it reached Arteria and how long it took, and whether samples followed. It then stops sampling again. When something goes wrong it shows:
  - the router's system log lines about requests it delayed or dropped while busy with another one;
  - the sampler's own errors, which used to go nowhere;
  - the other lines in `service-event` that wait for their program on every request.
- **`doctor` also finds and fixes** a hook file saved with Windows line endings, which the router can't run at all, Arteria's line not being first, and a process left holding the sampler's lock (every sampler the page starts would give up at once).
- **`debug` shows more, still without names or addresses:**
  - each Wi-Fi interface's band setting and channel, mode and bridge, and whether its network is a main one;
  - the firmware's port map;
  - each node's backhaul links (band, signal, the speed of the last packets each way);
  - which sections the router's AiMesh client list has;
  - the sampler's last errors;
  - the system log's lines about the page's requests.

### The page

- **Labels stay off other devices on a crowded map.** With many devices, in the expanded view especially, the last labels to be placed found every spot near their device taken, and one could end up over another device's drawing or over the zoom buttons. Once all labels are placed, a label still covering a device now moves to a free spot further out, with a longer line.
- **More AiMesh nodes than the map has room for.** The map has a zone for two nodes, three in the expanded view. With more, the first ones in the list got the zones, and the others weren't drawn at all, without a word. Now the busiest nodes get the zones, and keep them unless a node without one gets much busier. The tray names the nodes without a zone (*+1 node*), and its list says their devices are in it. Flow shows every node, as before.
- **Colours that follow the router's theme.** On ROG and TUF routers, whose pages are black with red or amber, Arteria's controls, highlights and room turn black with red or amber too. The traffic's colours stay as they are everywhere.
- **Less motion.** When the device asks for less motion (Windows' animation effects off, macOS's *Reduce motion*, Android's *Remove animations*), the packets stand still. That used to happen without a word; now the map's legend says so, with an **Animate** button, which the browser remembers.
- **Four devices drawn anew:**
  - the VR headset: a curved glass visor with a soft band;
  - the car: a smooth electric saloon with a glass roof;
  - the washing machine and dryer: round porthole doors;
  - the smart plug: a round plug in a wall socket.

  Their icons match.

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
