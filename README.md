# Chai Chaos

A Roblox egg-hunting, collect-and-earn game set in a loud Pakistani bazaar. Eight havelis stand in a ring around the **Chowk**, inside the busy **Lahore bazaar**. Outside the town wall, the world is cut into **4 regions of Pakistan with 3 rings each: 12 zones**, from the free Mango Bagh to the snowy Barfani Pahar. Unlock their gates, **drive** out on a motorbike, rickshaw, taxi or painted truck, grab eggs and get them home before they crack. Eggs hatch into silly desi brainrots that fill your galla with rupees every second. Then other players try to steal them.

Every zone has its own landmarks, plants and desi props, and every brainrot and vehicle has its own model, all made in Blender (see [3D models](#3d-models-blender)).

The original design is in [docs/game-design.md](docs/game-design.md). All 36 original brainrots and their catchphrases come from it.

![The world from above](docs/world-map.png)

![The Chowk, where the game starts](docs/chowk-preview.jpg)

*The Chowk, rendered in Blender from the game's own models (the havelis and shop stalls are simple stand-ins here). It follows the reference picture in [`docs/reference-chowk.jpg`](docs/reference-chowk.jpg).*

## How a round of play goes

1. **Spawn in your haveli.** Everyone starts with **Rs 1,000**, one incubator and the free **Mango Bagh** zone. New players get a **guide**: a card at the top says what to do next, and a yellow line on the ground leads to a glowing beacon.
2. **Check the radar** (bottom right). It shows eggs in your open zones, wild brainrots (**W**), an **H** for home and a **C** for the Chowk. If no egg is in range, a pip on the edge points to the nearest one.
3. **Head out through a town gate.** Walk at first; soon you can buy a **Motorbike** at the Gaari Showroom in the bazaar. Farther zones cost more to unlock and have rarer brainrots, but their eggs crack sooner.
4. **Pick up an egg** (hold E). A timer starts. On foot you carry one egg; a vehicle's boot carries more. Hazards knock time off, and other players can bonk you with a chappal to make you drop one.
5. **Get it home.** Walk into your haveli, or drive up to your door, and the egg goes into a free incubator. A little later it hatches, and the brainrot walks to a plot and starts earning.
6. **Spend your rupees:** unlock new zones at their gates, buy and upgrade vehicles, fill up with petrol, get gear and a better radar, upgrade your haveli, roll the Kismat Kettle, and finally start a **Naya Safar** (rebirth), which opens the ring 3 zones one by one.

## Six ways to get a brainrot

1. **Eggs (the main way):** find them in the zones you have unlocked and carry them home. What hatches depends on the zone.
2. **Wild brainrots:** now and then a Rare or better brainrot roams a zone (a **W** on everyone's radar). Walk up and hold E to catch it, and it walks into your haveli. It is like a lucky egg from that zone: the zone's own odds, but never below Rare (and never Secret). Vehicles that drive close and horns scare it away, so park and sneak up on foot. One turns up every 90 seconds (at most 4 at a time, inner zones more often), and each wanders off after 5 minutes.
3. **The Mandi lane:** brainrots walk out of the **Brainrot Mandi** arch and all the way round the brick lane in front of the haveli doors. Press E to buy one with rupees before it walks back into the Mandi. Lane brainrots are mostly Common and Uncommon (never Legendary or better) and cost 2.5 times their value, so they are for filling an empty plot fast, not for getting rich.
4. **Kismat Roll (RNG):** roll at the Kismat Kettle with Rs 5,000 or a Kismat Roll. Rolls come free with daily chai and quests, and players can buy packs with Robux. (Secret brainrots never come from rolls.)
5. **Stealing:** grab someone else's brainrot and run it through your own door. Every steal uses a **Chor Pass** (bought with Robux; you get it back if the steal fails).
6. **Collection Book rewards:** finish a rarity to earn one of 6 special quest brainrots.

## The world

The world is one big circle, about 1,500 studs across.

**The Chowk** is a round plaza in the middle with a fountain and everything you need around it:

| Stall | What it does |
| --- | --- |
| **BECHO (Sell)** | Opens the Brainrots window with Sell buttons. Sell any brainrot for half its value. |
| **GEAR SHOP** | Speed, egg, treasure and hazard gear (see below). |
| **RADAR WALA** | Tracker upgrades. |
| **KISMAT KETTLE** | Kismat Rolls, with the odds shown. |
| **NAYA SAFAR** | The rebirth gate. |
| **QUESTS** board | Daily quests and Collection Book rewards. |

The Chowk is paved in terracotta brick with a pale stone kerb. The big **Chai Dhaba** stands on it, with a teal sign and scalloped awning, a brick counter with a band of diamonds, a kettle, glasses of chai, a tandoor, a milk can, string lights and a charpai outside. A **red-brick arch** with cream stones, a teal and gold band and battlements stands over each of the four roads out (named Punjab, Sindh, Thar and KPK), with a tree in a planter on each side. By the fountain a **Samosa Supremo statue** stands on a white pedestal, rickshaws are parked, and a kite flies overhead on a string from the dhaba's roof. Warm string lights run all the way round. The stalls stand between the roads, so every way out is clear. There is also a fruit cart and a leaderboard. The **8 havelis** stand in a ring around the Chowk, facing the fountain. Four roads lead out between them to the four town gates. **The Mandi lane**, a brick path with arrows, runs all the way round the Chowk just in front of the haveli doors; brainrots for sale come out of the **Brainrot Mandi** arch beside the Punjab road.

**The Lahore bazaar** is the town ring between the havelis and the town wall: two rows of stalls with bright awnings along a round bazaar street under string lights, and six sectors: **Brainrot Mandi**, **Kite Point** (a kite tower), **Cricket Gali** (a street-cricket pitch), **Mela Ground** (a Ferris wheel and a stage), **Chai Dhaba Bazaar** (with **Ustad's Workshop**, where vehicles are upgraded) and the **Rickshaw Stand** (with the **Gaari Showroom**, where vehicles are sold).

**The 12 zones.** Outside the town wall are 4 regions, each cut into 3 rings. Farther out always costs more: every ring 2 zone costs more than every ring 1 zone, and ring 3 zones open with rebirths. Unlocks are kept forever, even after a Naya Safar.

| Region | Ring 1 | Ring 2 | Ring 3 |
| --- | --- | --- | --- |
| **Punjab** | **Mango Bagh** · free · up to Rare | **Sarson Fields** · Rs 500,000 · up to Legendary | **Lahore Qila** · 1 rebirth · up to Mythic |
| **Sindh** | **Railway Junction** · Rs 15,000 · up to Epic | **Sahil Beach** · Rs 1,200,000 · up to Mythic | **Karachi Port** · 2 rebirths · up to Mythic |
| **Thar** | **Camel Mela** · Rs 50,000 · up to Epic | **Thar Desert** · Rs 3,000,000 · up to Mythic | **Mohenjo-daro** · 3 rebirths · up to Mythic |
| **KPK** | **Qissa Khawani** · Rs 150,000 · up to Legendary | **Namak Caves** · Rs 7,000,000 · up to Mythic | **Barfani Pahar** · 4 rebirths · up to **Secret** |

| Zone | Landmarks and details | Egg lasts | Hatches in | Hazards | What helps |
| --- | --- | --- | --- | --- | --- |
| **Mango Bagh** | Mango trees, tube wells, charpais, buffaloes, the water tank | 60 s | 15 s | muddy puddles | Gum Boots, Tyres 1 |
| **Railway Junction** | A red-brick station with a clock, a curved railway track, a crossing light and a **train** that runs it | 58 s | 20 s | the train | watch the light! |
| **Camel Mela** | Striped fair tents with bunting, camels, snack stalls | 56 s | 28 s | none | |
| **Qissa Khawani** | Tall houses with carved wooden balconies, the **Ghanta Ghar** clock tower, kahwa and dry-fruit stalls, a storyteller's stage | 54 s | 35 s | none | |
| **Sarson Fields** | Rows of yellow mustard, a tractor, scarecrows, muddy paths | 50 s | 42 s | mud | Gum Boots, Tyres 1 |
| **Sahil Beach** | Sand, beach huts and umbrellas, camels, palms, fishing boats, a lighthouse, the sea | 48 s | 50 s | the sea, big waves | Life Jacket |
| **Thar Desert** | Dunes, an old desert fort, dry kikar trees | 46 s | 60 s | sandstorms, sand | Sand Goggles, Tyres 2 |
| **Namak Caves** | Pink salt hills, the mine entrance, glowing crystals, mine carts | 44 s | 70 s | darkness, falling salt rocks | Lantern |
| **Lahore Qila** | A curved red fort wall with the great gate, round towers, a moat and white pavilions | 42 s | 80 s | the moat | Life Jacket |
| **Karachi Port** | Stacks of shipping containers, giant cranes, a cargo ship, the harbour | 40 s | 90 s | the water | Life Jacket |
| **Mohenjo-daro** | Brick ruins in rows, the **Great Bath**, the citadel mound | 38 s | 100 s | sandstorms, sand | Sand Goggles, Tyres 2 |
| **Barfani Pahar** | Ice caves, frozen lakes, snowmen, a mountain hut, snowy mountains | 36 s | 120 s | ice, snowballs | Snow Boots, Tyres 3 |

**Gates and roads.** The gate into a ring 1 zone is in the town wall in the middle of its region. The gate into ring 2 is turned 30 degrees one way and the gate into ring 3 30 degrees the other way, so you zigzag through every zone. A road runs from the Chowk through every gate to a **rickshaw stand** at the far end of each ring 3 zone (a free ride back to the Chowk; the rickshaw wala only takes people, so park your vehicle and leave your eggs, which must make the trip home the slow way). The roads are always safe: no water, mud or ice on a road. Walk up to a gate and hold E to unlock it; you must unlock the zone in front of a gate first.

**Shortcut doors.** Every fence between two regions has a blue door in each ring. It opens for you once you have unlocked the zones on both sides.

**Petrol pumps** stand in the bazaar by every town gate and by every gate out of ring 1 and ring 2.

Each zone has its own egg colours, its own pool of brainrots (every brainrot hatches somewhere, and the Collection Book tells you where), treasure chests and a big title when you drive in. The radar names the bazaar sector you are in too.

## Eggs

- Each zone keeps 8 eggs lying around and refills them over time. You can only collect eggs in zones you have unlocked.
- **The timer:** an egg cracks when its time runs out. Standing in water or a sandstorm makes it crack twice as fast; waves, snowballs, salt rocks and the train knock 8 seconds off. At your own haveli the timer stops.
- **Incubators:** 1 at haveli level 1, 2 at level 3, 3 at level 5 and 4 at level 7. If they are all busy, keep your egg at home until one frees up. Eggs keep hatching while you are offline.
- **Golden eggs** (3%) sparkle, last a bit longer, are twice as lucky and always hatch a Golden, Diamond or Rainbow brainrot. Normal eggs hatch mutated about 5% of the time.
- **Egg rushes:** every 4 minutes one zone fills up with extra eggs for 60 seconds.
- On foot you carry one egg. In a vehicle, eggs go in the **boot** (as many as its Egg Space) and count down there too. A chappal bonk makes you drop one, and anyone can grab it (with the time it had left). You cannot steal while holding an egg, or pick one up while carrying a stolen brainrot.

## The radar (Radar Wala)

The radar shows eggs in every zone you have unlocked. Each level sees further:

| Level | Cost | Range | Extras |
| --- | --- | --- | --- |
| 1 | free | 180 | |
| 2 | Rs 2,500 | 220 | |
| 3 | Rs 8,000 | 260 | golden eggs |
| 4 | Rs 25,000 | 300 | golden eggs |
| 5 | Rs 70,000 | 340 | golden eggs, treasure |
| 6 | Rs 160,000 | 390 | golden eggs, treasure |
| 7 | Rs 320,000 | 440 | golden eggs, treasure |
| 8 | Rs 600,000 | 520 | golden eggs, treasure |

It also shows wild brainrots (a **W** in their rarity's colour), the timer of the egg that will crack first (and how many more you carry), hazard warnings, egg rushes and which zone or bazaar sector you are in.

## Gear (Gear Shop)

Gear is bought once and kept forever, even after a Naya Safar. It works by itself when you are on foot.

| Gear | Cost | What it does |
| --- | --- | --- |
| Joggers | Rs 3,000 | Run 10% faster |
| Gum Boots | Rs 5,000 | No more getting stuck in mud |
| Padded Tokri | Rs 6,000 | Eggs last 25% longer |
| Life Jacket | Rs 8,000 | Swim fast, eggs safe from water and waves |
| Belcha (shovel) | Rs 20,000 | Dig up buried treasure |
| Sand Goggles | Rs 30,000 | See and run through sandstorms |
| Rassi Seedhi (rope ladder) | Rs 40,000 | Climb to treasure on towers, gates, cranes and ice caves |
| Peshawari Chappal | Rs 60,000 | Run 25% faster |
| Thermos Dabba | Rs 80,000 | Eggs last 60% longer |
| Snow Boots | Rs 120,000 | No slipping on ice, snowballs miss you |
| Lantern | Rs 200,000 | Light up the salt caves and see the falling salt rocks in time |

## Vehicles

Buy vehicles at the **Gaari Showroom** (Rickshaw Stand, in the bazaar), then press **Gaari** (on the left) and **Drive**. Your vehicle appears under you and you sit in it. Push the stick (or WASD) the way you want to go and it turns towards it like a car. Press **Park** on the dashboard to get out, or just drive up to your haveli door: the eggs in your boot go straight into your incubators and the vehicle parks itself. Vehicles and their upgrades are yours forever, even after a Naya Safar.

| Vehicle | Cost | Speed | Range (full tank) | Boot | Tyres | Friends |
| --- | --- | --- | --- | --- | --- | --- |
| **Motorbike** | Rs 3,000 | 34 | 1,500 studs | 1 egg | 0 | 1 |
| **Rickshaw** | Rs 25,000 | 38 | 2,000 studs | 2 eggs | 0 | 2 |
| **Pili Taxi** | Rs 150,000 | 46 | 2,800 studs | 3 eggs | 1 | 3 |
| **Phool Patti Truck** | Rs 1,200,000 | 42 | 4,500 studs | 6 eggs | 2 | 1 |

Walking speed is 20 (more with Joggers or a Peshawari Chappal).

**Crashes.** Every vehicle has a solid bumper the size of the vehicle, raised a little off the road so kerbs don't stop it. It stops at walls, trees, buildings, fences, lasers and other vehicles, but never shoves other players. Hit something at speed and you hear a crunch, bounce back and stop for a moment.

**The horn.** Press **H** or the **Horn** button on the dashboard. Every vehicle sounds different: the motorbike beeps high, the rickshaw goes *pon pon*, the taxi honks once and the truck blares three times. Everyone nearby hears it, and wild brainrots run away from it. (The horn uses a built-in beep until you paste a real horn sound's id into `Sounds.luau`.)

**Upgrades at Ustad's Workshop** (Chai Dhaba Bazaar). Each level costs 1.8 times more than the last; prices grow with the vehicle.

| Upgrade | Levels | What it does |
| --- | --- | --- |
| **Engine** | 5 | +10% top speed per level |
| **Fuel Tank** | 5 | +25% range per level |
| **Egg Space** | 3 | +1 egg in the boot per level |
| **Tyres** | up to grip 3 | Grip 1 drives through mud, 2 through sand and sandstorms, 3 on ice without sliding |

**Fuel.** Every stud you drive uses a stud of fuel. With an empty tank your vehicle crawls at walking speed. Petrol pumps fill you up for Rs 0.25 per stud (a full motorbike tank is Rs 375), and parked vehicles fill up slowly for free while you are at your haveli.

**Grip.** Without good enough tyres, mud, sand and ice slow your vehicle down, and on ice it slides. Deep water always slows vehicles.

**Friends.** Other players can hop on with the **Ride along** prompt on your vehicle's seats, and jump to hop off.

**The boot.** Eggs you pick up while driving go in the boot. If you park away from home, you take one egg in your hands and the rest fall out (anyone can grab them). You can't steal from a vehicle, and you can't drive with a stolen brainrot.

**Paint jobs (Robux, looks only):** **Phool Patti** (truck-art colours), **Sona** (gold), **Rangeela** (rainbow, always changing) and **Chamak** (glowing). Buy them at Ustad's Workshop and switch between them in the Gaari window. They never change speed or anything else.

## Treasure

Every zone hides treasure chests. Buried ones (under a red X) need a **Belcha**; high ones need a **Rassi Seedhi** to climb up from the glowing spot: the water tank lids in Mango Bagh, Sarson Fields and Camel Mela, the Ghanta Ghar gallery, the lighthouse gallery, a desert fort tower, the Qila gate, a port crane's cab, the Mohenjo-daro citadel and an ice cave roof. A chest pays more in farther zones (Rs 1,200 times the tier squared) and sometimes a free Kismat Roll. You can only open chests in zones you have unlocked, and each chest once every 10 minutes.

## Havelis

- 8 big havelis with a courtyard, stairs, a second floor, a rooftop and incubator nests.
- **9 levels**, from 4 plots up to 20. Level 3 adds the **Laser Darwaza** (your Taala physically blocks the door, and anyone inside gets moved out). Level 4 adds a garden, level 5 opens the **second floor**, level 6 hires a **Chowkidar** who catches thieves, and level 8 adds a rooftop with chhatris and kites.
- **8 themes**, each with its own colours, decorations and a small perk: Mughal Marble (+5% income), Bagh Garden (thieves 15% slower), Truck Art (walk 12% faster), Chai Dhaba (cheaper Kismat Rolls), Sheesh Mahal (longer Taala), Basant Rooftop (mutations twice as likely in your rolls), Cricket Maidan (chappal reaches twice as far) and Mela Lights (+25% income during events). The first two are free; each Naya Safar unlocks the next.
- **Lockers:** plots 1 and 2 can never be robbed, and your two most valuable brainrots always move into them.
- **Galla:** every brainrot drops rupees into your galla each second. Walk into it to collect.

## Stealing and defending

- Hold E on someone else's brainrot. It rides on your back until you run through your own haveli door, and you walk slower the rarer it is.
- The owner gets a "Chor! Chor!" alert, and anyone can bonk the thief with their **Chappal**.
- **Fair-play rules:** a 15 second steal cooldown, no robbing the same haveli twice within 2 minutes, 3 minutes of protection after joining, and brainrots worth over Rs 16,000 can only be stolen by players who have rebirthed.
- **Taala (lock):** locks your haveli for 30 seconds, then needs 60 seconds to recharge.

## Progress

- **Naya Safar (rebirth)** at the gate in the Chowk: starts over your rupees, haveli level, radar, brainrots and eggs, for +50% income forever and a new theme. Rebirths 1 to 4 also open the ring 3 zones: Lahore Qila, Karachi Port, Mohenjo-daro and Barfani Pahar. You keep your gear, vehicles, unlocked zones, themes, Collection Book, Kismat Rolls and Chor Passes. The first costs Rs 2,500,000 and each one after costs 4 times more.
- **Haveli levels** cost Rs 4,000, 15,000, 40,000, 120,000, 300,000, 600,000, 1,100,000 and 2,000,000 (levels 2 to 9).
- **Daily quests:** 3 a day, like bringing eggs home from different zones, hatching a Rare, a golden egg, catching a wild brainrot, buying on the Mandi lane, opening treasure, upgrading your haveli or radar, collecting from your galla. They pay rupees and Kismat Rolls, plus 2 bonus rolls for finishing all three.
- **Collection Book:** fills in as you find brainrots and their mutations, and says which zones each one hatches in. Finishing a rarity pays rupees and Kismat Rolls, plus that rarity's special quest brainrot (Secret pays Rs 20,000,000 and 20 rolls).
- **Events** every 15-20 minutes, 5 minutes each. The banner shows the boosts:
  - **Basant Kite Festival:** kites fill the sky all around you. Cash x2, Luck x2.
  - **Baarish:** rain, twice as many eggs, +20% cash.
  - **Cricket Mania:** confetti, cash x1.5.
  - **Load Shedding:** night falls, Luck x3.
  - **Mela Night:** fireworks, eggs hatch twice as fast, Kismat Rolls 30% off.
  - **Sardi:** snow, eggs last 50% longer.
- **The guide** walks new players through 8 steps: reach Mango Bagh, pick up an egg, carry it home, wait for it to hatch, collect from the galla, buy a Motorbike, drive it, and unlock a zone. Finishing it pays 2 Kismat Rolls (once). It skips steps you have already done, and you can hide it or start it again in the Menu.
- **Daily chai:** a free brainrot or rupees, plus a free Kismat Roll, once a day. Come back day after day for a **streak**: 1 extra roll from day 3, and 2 extra rolls every day from day 7. Miss a day and it starts again.
- **Offline earnings:** while you are away your brainrots keep earning 10% of their income, for up to 4 hours. It waits in your galla.
- **Codes:** type a promo code in the Menu for rupees and rolls. Each player can use a code once. The codes are in `Config.CODES` (two starter codes are in there: `CHAICHAOS` and `PONPON`).
- **Game passes:** **2x Cash** (your brainrots earn twice as much) and **Extra Plots** (2 more plots, as far as your haveli has room). Hidden until you add their ids.
- **Badges** for first-time moments: joining, your first egg, first Rare, first vehicle, first wild catch, all of ring 1, your first Naya Safar and your first Secret. Off until you add their ids.
- **The Menu** (button on the left) has the game passes, codes, your streak, switches for music and sounds, and the guide.
- **Kismat Roll:** the odds for every rarity and mutation are shown before anyone rolls. An Epic or better is guaranteed at least every 30 rolls.
- **Robux packs:** 1 or 10 Kismat Rolls, 1 or 5 Chor Passes, and vehicle paint jobs (looks only). Purchases are saved straight away and never granted twice.
- **Fair play:** eggs crack if they travel faster than any vehicle can (teleport cheats), every purchase and action is checked on the server, and vehicles can't be spawned faster than the server can build them.
- **Saving** with DataStores (a save belongs to one server at a time, so hopping servers quickly never loses progress; failed saves are tried again): everything above, including eggs in incubators, unlocked zones and your vehicles with their upgrades and fuel. Old saves keep working: the brainrot you used to ride walks back to a plot (or pays its full value if every plot is full), and eggs from the old biomes still hatch.

## Sounds

The game uses sounds that come with Roblox for buttons, coins, eggs (pick up, home, crack, hatch), treasure, bonks, the Chor alert, splashes, wind in the snowy mountains and in sandstorms, vehicle horns and crashes, upgrades, events and the Kismat Roll. They are all listed in [`src/shared/Sounds.luau`](src/shared/Sounds.luau).

There are three music slots, `MusicBazaar`, `MusicBiome` and `MusicEvent`, empty until you add your own: find a track in the Creator Store (Toolbox > Audio, try "dhol", "tabla" or "bazaar"), copy its id and paste it as `"rbxassetid://123456789"`. The right track plays for where you are. You can swap any other sound the same way, for example to add voice lines.

## 3D models (Blender)

All the landmarks, plants, props and vehicles, and all 46 brainrots (see [The 46 brainrots](#the-46-brainrots)), are modelled in **Blender** with Python scripts in [`blender/`](blender/), in a chunky, low-poly, flat-colour style that runs well on phones. There are 118 props and vehicles:

- **Zone landmarks and the bazaar:** the railway station and train, the Ghanta Ghar, Qissa Khawani's tall houses, kahwa and dry-fruit stalls, Lahore Qila's gate, walls, towers and pavilions, shipping containers, a port crane, a cargo ship, Mohenjo-daro's brick ruins, the Great Bath and the citadel mound, an ice cave, snowmen, camels, fair tents, a scarecrow, the petrol pump, the zone gate arch, the Gaari Showroom, Ustad's Workshop, bazaar stalls, a Ferris wheel, the kite tower and the mela stage, plus the Chowk's big Chai Dhaba, its brick arches and its trees in planters.
- **Vehicles:** motorbike, rickshaw, Pili Taxi and Phool Patti Truck (their painted panels change with paint jobs).

- **Landmarks:** rehat, treehouse, rope bridge, lighthouse, rest house, jetty, desert fort, stilt village, suspension bridge, mountain hut, crystal cluster, mine entrance, mine track, mine cart, cave support.
- **Plants and nature:** kikar (green and dry), mango, banyan, jungle tree, bamboo, bushes, ferns, coconut palm, willow, poplar, deodar (green and snowy), mangrove, juniper, desert shrub, dune grass, reeds, wild flowers, lily pads, boulders, mossy, snowy and beach rocks, sandstone rocks, salt crystals, stalagmites, wheat, sarson and sugarcane fields.
- **Desi props:** charpai, milestone, matkas, tube well, chai dhaba, fruit stall, pakora stall, gola ganda cart, truck-art truck, auto rickshaw, tractor and trolley, bus stop, road sign, tandoor, haystack, mud house, water tank, beach huts, fishing boat, rowing boat, net rack, desert tent, beach umbrella, lamp post, kite line, bench, street cricket.

| Zone landmarks | Vehicles |
| --- | --- |
| ![Zone landmarks](docs/props/zone.jpg) | ![Vehicles](docs/props/vehicle.jpg) |

| Landmarks | Plants and nature | Desi props |
| --- | --- | --- |
| ![Landmarks](docs/props/landmark.jpg) | ![Plants](docs/props/plant.jpg) | ![Desi props](docs/props/desi.jpg) |

**How the game uses them.** `blender/build.py` turns every model into two things:

1. **Roblox parts** in [`src/server/PropData.luau`](src/server/PropData.luau). The game builds every prop out of parts by itself, so it all works with no importing.
2. **Meshes** in [`assets/props/ChaiChaosProps.fbx`](assets/props/ChaiChaosProps.fbx): one smoother mesh per prop and per brainrot, all coloured from one small palette texture. If you import them, the game uses them instead of the parts and keeps the parts as invisible walls, so you can still walk on the bridges, jetty and decks. Glowing and see-through pieces (lamps, crystals, glass) always stay parts. Golden, Diamond and Rainbow brainrots always use parts, so they can be tinted while their eyes keep their colour.

**Importing the meshes into Studio (optional, once):**

1. Make sure you are logged in to Studio: the importer uploads the meshes to your account.
2. **File > Import 3D**, pick `assets/props/ChaiChaosProps.fbx` and import it. It comes in as one model with 164 meshes, each named after its prop, vehicle or brainrot (`GhantaGhar`, `QilaGate`, `KikarTree`, `SamosaSupremo`...).
3. Rename that model to **`ChaiChaosProps`** and drag it into **ServerStorage**.
4. Press Play. Every prop and brainrot that has a matching mesh uses it. (Vehicles always use parts, so paint jobs can recolour them.)

The game resizes each mesh to the right size and stands it up if the importer laid it on its side. If every mesh faces backwards, set `Config.PROP_MESH_TURN = 180`.

**Changing the models.** Open [`assets/props/ChaiChaosProps.blend`](assets/props/ChaiChaosProps.blend) in Blender to look at everything. To change a prop, edit its Python in `blender/props_zones.py` (zone landmarks and the bazaar), `props_landmarks.py`, `props_plants.py` or `props_desi.py`; vehicles are in `vehicles.py`; the brainrots are in `brainrots_a.py` (Common and Uncommon), `brainrots_b.py` (Rare and Epic), `brainrots_c.py` (Legendary, Mythic and Special) and `brainrots_d.py` (Secret). The helpers are in `blender/kit.py` and `blender/brainrot_kit.py` (eyes, smiles, moustaches, arms, legs, crowns, caps, wings). Then rebuild everything:

```bash
pip install bpy==5.2.3          # Blender as a Python module (needs Python 3.13)
python blender/build.py         # writes PropData.luau, the FBX, the .blend, the previews and the character sheets
```

Where each prop goes in the world is in [`BiomeBuilder.luau`](src/server/BiomeBuilder.luau) (the zones) and [`MapBuilder.luau`](src/server/MapBuilder.luau) (the Chowk, the bazaar, walls, gates, roads and pumps).

## The 46 brainrots

Every brainrot has a chunky, cute Blender model with big eyes, in the same flat-colour style as the props. The game builds it from parts by itself (or uses its mesh if you imported the FBX). It is shrunk if needed so it always fits on an 8 x 8 plot. If you make your own model for a brainrot, the game uses yours instead (see [Making it yours](#making-it-yours)).

Each character sheet below has:

- **Look and personality:** what it looks like and how it acts.
- **Colour palette:** the exact colours of the Blender model, as hex codes.
- **A ready-to-paste prompt:** copy it into ChatGPT Astra (or any image or 3D generator) to get a detailed picture or model of the character in the same style. Paste the same prompt again and ask for "the same character from the side and the back" to get a turnaround.
- **In the game:** its id, price, income, size and where it hatches.

There are 36 brainrots from the design doc, 4 **Secret** brainrots that only hatch in Barfani Pahar (Kahwa Yeti, Gola Ganda Golem, Barfi Barfani Bagh and Jalebi Markhor) and 6 special quest brainrots from the Collection Book.

Click a name to open its sheet. The pictures are the Blender models, one per rarity.

<!-- characters:start -->
<!-- Generated by blender/characters.py from its own text and the game's data files. Edit it there. -->

#### Common (8)

![Common brainrots](docs/brainrots/common.jpg)

<details>
<summary><b>Gol Gappa Ghostu</b> · Common · <i>"Thora aur khatta daalo!"</i></summary>

**Look and personality.** A crispy golden gol gappa puri who floats around like a friendly little ghost. Its bottom melts into a wavy tail of tangy tamarind water, and a few chickpeas peek out of the hole on top. Always leaking a little, always asking for more khatta.

**Colour palette**

| Part | Hex |
| --- | --- |
| Puri gold | `#E2AA50` |
| Crispy edge | `#BE7D37` |
| Imli pani | `#968C3C` |
| Chickpea | `#E1C378` |
| Blush | `#FF96A0` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Gol Gappa Ghostu. A round, hollow golden puri (gol gappa) that floats like a cute ghost. Its lower half melts into a wavy, see-through tail of brown tamarind water with drips falling off. A hole on top with three chickpeas peeking out. Big eyes, rosy cheeks and a small open 'ooh' mouth with its tongue out. Floating a little above the ground.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: puri gold #E2AA50, crispy edge #BE7D37, imli pani #968C3C, chickpea #E1C378, blush #FF96A0.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 4.0 studs tall.
```

**In the game:** id `GolGappaGhostu` · Rs 50 · +Rs 1/s · 4.0 studs tall, 2.8 x 3.0 studs wide, floats · Hatches in Mango Bagh (Punjab Mango Orchards), Qissa Khawani (Peshawar Storytellers' Bazaar), Sahil Beach (Arabian Sea Beach).

</details>

<details>
<summary><b>Chana Chaat Chacha</b> · Common · <i>"Imli wali, imli wali!"</i></summary>

**Look and personality.** A friendly old uncle made from a steel bowl of chana chaat, full of chickpeas, onion, tomato and coriander. His moustache is crunchy yellow sev and he walks with a spoon as a walking stick. Always shouting about imli.

**Colour palette**

| Part | Hex |
| --- | --- |
| Steel bowl | `#C8CDD4` |
| Chickpea | `#E1C378` |
| Sev moustache | `#F0BE46` |
| Tomato | `#DC3C28` |
| Onion | `#A53C78` |
| Coriander | `#3C9632` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Chana Chaat Chacha. A round steel bowl (katori) filled to the top with chana chaat: chickpeas, red onion, tomato and green coriander. The bowl itself is the face of a kind old uncle with big eyes and a bushy moustache made of crunchy yellow sev. Tiny legs and little black shoes. He leans on a long steel spoon like a walking stick.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: steel bowl #C8CDD4, chickpea #E1C378, sev moustache #F0BE46, tomato #DC3C28, onion #A53C78, coriander #3C9632.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 2.7 studs tall.
```

**In the game:** id `ChanaChaatChacha` · Rs 80 · +Rs 2/s · 2.7 studs tall, 3.6 x 3.5 studs wide · Hatches in Railway Junction (Sindh Railway Junction), Qissa Khawani (Peshawar Storytellers' Bazaar).

</details>

<details>
<summary><b>Samosa Supremo</b> · Common · <i>"Main course main hoon!"</i></summary>

**Look and personality.** The coolest snack in the bazaar. A golden triangle samosa in black shades who stands on a white plate like it is a stage, little arms crossed. It never smiles much, because the main course does not need to.

**Colour palette**

| Part | Hex |
| --- | --- |
| Samosa gold | `#D79646` |
| Crispy brown | `#AF6E2D` |
| Shades | `#232328` |
| Plate | `#FAFAFA` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Samosa Supremo. A big golden-brown triangular samosa with crimped, crispy edges and little flaky bumps. It wears dark rectangular sunglasses, has tiny arms crossed in front, a small confident smirk, and stands on a round white plate like a stage. Short stubby legs.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: samosa gold #D79646, crispy brown #AF6E2D, shades #232328, plate #FAFAFA.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 3.4 studs tall.
```

**In the game:** id `SamosaSupremo` · Rs 100 · +Rs 2/s · 3.4 studs tall, 3.8 x 3.8 studs wide · Hatches in Railway Junction (Sindh Railway Junction), Camel Mela (Thar Camel Fair).

</details>

<details>
<summary><b>Naan Ninja</b> · Common · <i>"Roti star! Hiyaa!"</i></summary>

**Look and personality.** A soft teardrop naan with char spots who thinks it is a ninja. Black headband, black mask, and it throws tiny roti stars. Hiyaa!

**Colour palette**

| Part | Hex |
| --- | --- |
| Naan | `#EECD91` |
| Char spots | `#966437` |
| Headband | `#232328` |
| Roti star | `#FAEBC8` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Naan Ninja. A teardrop-shaped naan bread standing up, pale golden with dark char spots. It wears a black ninja headband with long tails flowing behind and a black mask strip across its eyes. Tiny arms and legs in an action pose, throwing a little round roti shaped like a ninja star.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: naan #EECD91, char spots #966437, headband #232328, roti star #FAEBC8.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 3.9 studs tall.
```

**In the game:** id `NaanNinja` · Rs 120 · +Rs 2/s · 3.9 studs tall, 3.5 x 1.4 studs wide · Hatches in Mango Bagh (Punjab Mango Orchards), Camel Mela (Thar Camel Fair).

</details>

<details>
<summary><b>Kulfi Kangaroo</b> · Common · <i>"Pighla... phir jam gaya!"</i></summary>

**Look and personality.** A pistachio-and-cream kulfi on its stick who hops around like a kangaroo, with long ears and big feet. It melts a little in the sun, then freezes again. Very bouncy, a bit drippy.

**Colour palette**

| Part | Hex |
| --- | --- |
| Kulfi cream | `#F5E8BE` |
| Pistachio | `#AACD78` |
| Stick | `#CDA56E` |
| Ice drips | `#78BEFF` |
| Blush | `#FF96A0` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Kulfi Kangaroo. A cone-shaped kulfi ice cream on a wooden stick, cream coloured with a green pistachio top sprinkled with nuts. It has long kangaroo ears with pink insides, big kangaroo feet, tiny arms and a happy smile. A few icy blue drips on its sides. Mid-hop, bouncing on its stick like a pogo tail.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: kulfi cream #F5E8BE, pistachio #AACD78, stick #CDA56E, ice drips #78BEFF, blush #FF96A0.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 5.0 studs tall.
```

**In the game:** id `KulfiKangaroo` · Rs 150 · +Rs 3/s · 5.0 studs tall, 2.0 x 2.3 studs wide · Hatches in Mango Bagh (Punjab Mango Orchards), Sarson Fields (Punjab Mustard Fields).

</details>

<details>
<summary><b>Pyaaz Pehelwan</b> · Common · <i>"Ro kyun rahe ho?"</i></summary>

**Look and personality.** A big purple onion who is a champion wrestler. Strong arms, a curly moustache, green sprouts for hair, wrestling shorts and a gold champion belt. He makes everyone cry, but only because he is an onion.

**Colour palette**

| Part | Hex |
| --- | --- |
| Onion | `#A53C78` |
| Onion skin | `#E1AFCD` |
| Sprouts | `#3C9632` |
| Shorts | `#DC3232` |
| Champion belt | `#F0BE3C` |
| Moustache | `#232328` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Pyaaz Pehelwan. A big round purple onion with thin pale layer lines, green sprouts on top like hair, a thick curly black moustache and determined eyebrows. Strong flexing arms, red wrestling shorts with a shiny gold champion belt, short legs. Tiny tear drops fly off to the sides. A proud wrestler pose.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: onion #A53C78, onion skin #E1AFCD, sprouts #3C9632, shorts #DC3232, champion belt #F0BE3C, moustache #232328.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 4.2 studs tall.
```

**In the game:** id `PyaazPehelwan` · Rs 180 · +Rs 4/s · 4.2 studs tall, 4.8 x 2.9 studs wide · Hatches in Camel Mela (Thar Camel Fair), Qissa Khawani (Peshawar Storytellers' Bazaar).

</details>

<details>
<summary><b>Chaiyoo Kettlesaurus</b> · Common · <i>"Doodh patti, extra cheeni."</i></summary>

**Look and personality.** A shiny steel chai kettle that grew into a tiny dinosaur. The spout is its long neck and head, the lid is its hat and the handle is its tail. It roars puffs of steam and only drinks doodh patti with extra cheeni.

**Colour palette**

| Part | Hex |
| --- | --- |
| Steel | `#C8CDD4` |
| Dark steel | `#8C919B` |
| Lid knob | `#232328` |
| Steam | `#F0F0F5` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Chaiyoo Kettlesaurus. A round, shiny steel chai kettle shaped like a small dinosaur: the curved spout is a long neck ending in a cute dino head, the lid sits on top like a hat with a black knob, and the black handle curls out the back like a tail. Four stubby dark-steel legs. Big eyes on the head, a happy open mouth roaring little white puffs of steam.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: steel #C8CDD4, dark steel #8C919B, lid knob #232328, steam #F0F0F5.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 4.3 studs tall.
```

**In the game:** id `ChaiyooKettlesaurus` · Rs 200 · +Rs 4/s · 4.3 studs tall, 2.5 x 5.8 studs wide · Hatches in Railway Junction (Sindh Railway Junction), Sahil Beach (Arabian Sea Beach).

</details>

<details>
<summary><b>Pakora Panda</b> · Common · <i>"Baarish? Pakora time!"</i></summary>

**Look and personality.** A lumpy, crispy golden pakora shaped like a panda, with dark crispy patches for ears and eye patches. When it rains it opens a tiny umbrella and sits on its paper plate with a dab of green chutney.

**Colour palette**

| Part | Hex |
| --- | --- |
| Pakora gold | `#C38232` |
| Crispy patches | `#6E411E` |
| Umbrella | `#326EDC` |
| Paper plate | `#FAFAFA` |
| Chutney | `#3CA03C` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Pakora Panda. A round, lumpy, golden fried pakora shaped like a chubby panda: dark crispy brown ears, eye patches and paws. It holds a tiny blue umbrella with a white top and sits on a white paper plate with a blob of green chutney beside it. Big shiny eyes, a happy little mouth.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: pakora gold #C38232, crispy patches #6E411E, umbrella #326EDC, paper plate #FAFAFA, chutney #3CA03C.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 4.3 studs tall.
```

**In the game:** id `PakoraPanda` · Rs 240 · +Rs 5/s · 4.3 studs tall, 4.4 x 3.6 studs wide · Hatches in Mango Bagh (Punjab Mango Orchards), Sarson Fields (Punjab Mustard Fields).

</details>

#### Uncommon (7)

![Uncommon brainrots](docs/brainrots/uncommon.jpg)

<details>
<summary><b>Paratha Pilot</b> · Uncommon · <i>"Ghee landing in 3... 2... 1!"</i></summary>

**Look and personality.** A flaky round paratha who flies like a plane, with aviator goggles, a leather pilot cap and a scarf flapping behind. Drips of ghee fall when it comes in to land. Ghee landing in 3... 2... 1!

**Colour palette**

| Part | Hex |
| --- | --- |
| Paratha | `#E1B96E` |
| Ghee | `#FFD75A` |
| Pilot cap | `#82502D` |
| Scarf | `#FAFAFA` |
| Goggle lenses | `#78BEFF` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Paratha Pilot. A round, flaky, golden paratha standing on its edge like a flying disc, with swirly layer lines. It wears brown aviator goggles over big eyes, a brown leather pilot cap on top and a white scarf flapping behind. Shiny ghee drips on its edge. A surprised 'o' mouth. Flying, tilted as if banking a turn.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: paratha #E1B96E, ghee #FFD75A, pilot cap #82502D, scarf #FAFAFA, goggle lenses #78BEFF.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 4.1 studs tall.
```

**In the game:** id `ParathaPilot` · Rs 600 · +Rs 10/s · 4.1 studs tall, 3.7 x 4.0 studs wide, floats · Hatches in Railway Junction (Sindh Railway Junction), Qissa Khawani (Peshawar Storytellers' Bazaar).

</details>

<details>
<summary><b>Lassi Llama</b> · Uncommon · <i>"Malai moochh, full style!"</i></summary>

**Look and personality.** A fluffy beige llama sitting in a tall glass of sweet lassi, with a white malai moustache and froth on its head. A red straw sticks out beside it. Very stylish, very creamy.

**Colour palette**

| Part | Hex |
| --- | --- |
| Llama wool | `#E8CDA5` |
| Lassi | `#F0F5EB` |
| Malai | `#FFFAE6` |
| Glass | `#B4DCFF` |
| Straw | `#DC3232` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Lassi Llama. A fluffy beige llama with tall ears sitting inside a tall clear glass full of white lassi, only its head, neck and front hooves showing over the rim. A thick white malai moustache, froth on top of its head, rosy cheeks, a red straw in the glass. Big happy eyes.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: llama wool #E8CDA5, lassi #F0F5EB, malai #FFFAE6, glass #B4DCFF, straw #DC3232.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 4.7 studs tall.
```

**In the game:** id `LassiLlama` · Rs 800 · +Rs 13/s · 4.7 studs tall, 2.3 x 2.4 studs wide · Hatches in Mango Bagh (Punjab Mango Orchards), Sarson Fields (Punjab Mustard Fields).

</details>

<details>
<summary><b>Gajar Halwa Gorilla</b> · Uncommon · <i>"Sardi aa gayi!"</i></summary>

**Look and personality.** A big cuddly gorilla made of grainy orange gajar halwa, sprinkled with almonds and pistachios. He wears a woolly scarf and a shawl because winter is here, and carries a steaming bowl of halwa to share.

**Colour palette**

| Part | Hex |
| --- | --- |
| Gajar halwa | `#F07323` |
| Almonds | `#E6C8A0` |
| Pistachio | `#AACD78` |
| Scarf | `#326EDC` |
| Shawl | `#821E32` |
| Bowl | `#C8CDD4` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Gajar Halwa Gorilla. A big, chubby gorilla made of grainy orange carrot halwa with little almond and pistachio pieces on it. A blue woolly scarf around his neck and a maroon shawl over his shoulders. He holds a steel bowl of steaming halwa. Big kind eyes, a gentle smile, long arms, short legs.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: gajar halwa #F07323, almonds #E6C8A0, pistachio #AACD78, scarf #326EDC, shawl #821E32, bowl #C8CDD4.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 4.1 studs tall.
```

**In the game:** id `GajarHalwaGorilla` · Rs 1,000 · +Rs 15/s · 4.1 studs tall, 4.0 x 2.9 studs wide · Hatches in Mango Bagh (Punjab Mango Orchards), Sarson Fields (Punjab Mustard Fields), Namak Caves (Pink Salt Caves).

</details>

<details>
<summary><b>Rickshaw Raptor</b> · Uncommon · <i>"Pon pon! Kahan jaana hai?"</i></summary>

**Look and personality.** A green-and-yellow auto rickshaw on raptor legs, with headlight eyes, a grille full of teeth and a dino tail. Pon pon! It always asks where you want to go and never takes the short way.

**Colour palette**

| Part | Hex |
| --- | --- |
| Rickshaw green | `#289646` |
| Yellow trim | `#FFCD28` |
| Canopy | `#232328` |
| Raptor feet | `#28A050` |
| Teeth | `#FAFAFA` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Rickshaw Raptor. A small green auto rickshaw with a yellow stripe and a black canopy roof, walking on two strong raptor dinosaur legs with claws. The headlights are big cartoon eyes and the front grille is a wide grin with square white teeth. A green dino tail sticks out the back. Leaning forward like it is running.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: rickshaw green #289646, yellow trim #FFCD28, canopy #232328, raptor feet #28A050, teeth #FAFAFA.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 4.1 studs tall.
```

**In the game:** id `RickshawRaptor` · Rs 1,200 · +Rs 18/s · 4.1 studs tall, 2.4 x 6.4 studs wide · Hatches in Railway Junction (Sindh Railway Junction), Thar Desert (Thar Sand Dunes).

</details>

<details>
<summary><b>Bun Kebab Bhai</b> · Uncommon · <i>"Ek dum garam!"</i></summary>

**Look and personality.** A bun kebab who works out. He stands on a little stage flexing his big arms, holding up a gold trophy, with a sweatband on his bun. Ek dum garam!

**Colour palette**

| Part | Hex |
| --- | --- |
| Bun | `#CD8C46` |
| Kebab | `#7D4628` |
| Egg | `#FAD250` |
| Lettuce | `#28A050` |
| Sweatband | `#DC3232` |
| Trophy | `#F0BE3C` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Bun Kebab Bhai. A bun kebab burger (soft bun, brown kebab patty, egg layer and green lettuce) with a face and a proud smile. Big muscly arms: one flexing, one holding up a shiny gold trophy. A red sweatband on the top bun with sesame seeds. Standing on a small yellow-and-red stage like a bodybuilding show.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: bun #CD8C46, kebab #7D4628, egg #FAD250, lettuce #28A050, sweatband #DC3232, trophy #F0BE3C.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 3.8 studs tall.
```

**In the game:** id `BunKebabBhai` · Rs 1,600 · +Rs 24/s · 3.8 studs tall, 4.3 x 2.7 studs wide · Hatches in Camel Mela (Thar Camel Fair), Thar Desert (Thar Sand Dunes).

</details>

<details>
<summary><b>Doodh Patti Dolphin</b> · Uncommon · <i>"Chai mein chhalaang!"</i></summary>

**Look and personality.** A milky-brown dolphin leaping out of a clay kulhad of doodh patti chai, splashing chai in an arc. Warm, playful and always steaming.

**Colour palette**

| Part | Hex |
| --- | --- |
| Doodh patti | `#B9875F` |
| Belly | `#FFF0CD` |
| Kulhad clay | `#BE6941` |
| Chai | `#B47846` |
| Steam | `#F0F0F5` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Doodh Patti Dolphin. A chubby milky-brown dolphin with a cream belly leaping out of a small clay cup (kulhad) full of tea, its body curved in a happy arc. Drops of chai splash in an arc behind it and white steam rises from the cup. Big eyes, rosy cheeks, a wide smile.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: doodh patti #B9875F, belly #FFF0CD, kulhad clay #BE6941, chai #B47846, steam #F0F0F5.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 4.1 studs tall.
```

**In the game:** id `DoodhPattiDolphin` · Rs 1,800 · +Rs 26/s · 4.1 studs tall, 4.2 x 3.2 studs wide, floats · Hatches in Qissa Khawani (Peshawar Storytellers' Bazaar), Sahil Beach (Arabian Sea Beach).

</details>

<details>
<summary><b>Rooh Afza Rhino</b> · Uncommon · <i>"Sab kuch pink!"</i></summary>

**Look and personality.** A glossy red rhino shaped like a bottle of rose sharbat. Its horn is the bottle neck with a gold cap, and see-through windows on its sides show the pink drink inside. Rose petals float around it. Everything is pink! (A made-up sharbat, no real brand.)

**Colour palette**

| Part | Hex |
| --- | --- |
| Bottle red | `#D71E37` |
| Pink sharbat | `#FF6E96` |
| Rose petals | `#DC2850` |
| Cap | `#F0BE3C` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Rooh Afza Rhino. A chubby, glossy red rhino shaped like a glass sharbat bottle. Its horn is a bottle neck with a little gold cap. See-through windows on its sides show bright pink rose drink sloshing inside. Short thick legs, a small tail, big friendly eyes and a smile. Pink rose petals floating around it. No labels or brand names.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: bottle red #D71E37, pink sharbat #FF6E96, rose petals #DC2850, cap #F0BE3C.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 3.3 studs tall.
```

**In the game:** id `RoohAfzaRhino` · Rs 2,000 · +Rs 30/s · 3.3 studs tall, 3.2 x 5.5 studs wide · Hatches in Camel Mela (Thar Camel Fair), Sahil Beach (Arabian Sea Beach), Namak Caves (Pink Salt Caves).

</details>

#### Rare (6)

![Rare brainrots](docs/brainrots/rare.jpg)

<details>
<summary><b>Load Shedding Lattoo</b> · Rare · <i>"Light aa gayi!"</i></summary>

**Look and personality.** A spinning top (lattoo) with red and yellow stripes and a light bulb for a head. When the power goes, its eyes switch off; when it comes back, it lights up and shouts 'Light aa gayi!'

**Colour palette**

| Part | Hex |
| --- | --- |
| Stripe red | `#DC3232` |
| Stripe yellow | `#FFCD28` |
| Bulb | `#FFF096` |
| Wooden tip | `#96643C` |
| String | `#C8AF82` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Load Shedding Lattoo. A wooden spinning top (lattoo) with bright red and yellow stripes, a pointy wooden tip at the bottom and a string wound around its middle. Its head is a glowing light bulb. A cheerful face on the top part with big eyes and an open happy mouth. Spinning, tilted a little.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: stripe red #DC3232, stripe yellow #FFCD28, bulb #FFF096, wooden tip #96643C, string #C8AF82.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 4.8 studs tall.
```

**In the game:** id `LoadSheddingLattoo` · Rs 3,000 · +Rs 40/s · 4.8 studs tall, 3.2 x 3.4 studs wide · Hatches in Railway Junction (Sindh Railway Junction), Qissa Khawani (Peshawar Storytellers' Bazaar), Namak Caves (Pink Salt Caves).

</details>

<details>
<summary><b>Cricket Bat Bhaijaan</b> · Rare · <i>"Aur yeh gaya... chauka!"</i></summary>

**Look and personality.** A cricket bat who is the loudest commentator in the gali. Face on the blade, a plain green jersey with number 10, a cap on the handle and a microphone in hand. Aur yeh gaya... chauka!

**Colour palette**

| Part | Hex |
| --- | --- |
| Willow bat | `#E6CD96` |
| Jersey | `#1E8C46` |
| Number | `#FAFAFA` |
| Cap | `#326EDC` |
| Grip | `#DC3232` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Cricket Bat Bhaijaan. A wooden cricket bat standing upright, with a cheerful face on the blade, wearing a plain green jersey with a big white number 10 (no logos). The handle has a red grip and a blue cap on top. Tiny arms, one holding a microphone to its mouth, short legs with white shoes. Excited, mid-commentary.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: willow bat #E6CD96, jersey #1E8C46, number #FAFAFA, cap #326EDC, grip #DC3232.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 5.2 studs tall.
```

**In the game:** id `CricketBatBhaijaan` · Rs 4,000 · +Rs 55/s · 5.2 studs tall, 2.3 x 1.3 studs wide · Hatches in Mango Bagh (Punjab Mango Orchards), Sarson Fields (Punjab Mustard Fields), Lahore Qila (The Old Fort of Lahore).

</details>

<details>
<summary><b>Generator Gainda</b> · Rare · <i>"Light gayi? Main aaya! Brrrr!"</i></summary>

**Look and personality.** A grey rhino with a yellow generator on its back, a pull cord and a little exhaust puffing smoke. Fairy lights are wrapped around its horn. Light gayi? Main aaya! Brrrr!

**Colour palette**

| Part | Hex |
| --- | --- |
| Rhino grey | `#8C8C96` |
| Generator | `#FFCD28` |
| Exhaust | `#50555A` |
| Fairy lights | `#FFF096` |
| Smoke | `#F0F0F5` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Generator Gainda. A chunky grey rhino carrying a boxy yellow generator on its back, with a pull cord, a black exhaust pipe puffing grey smoke and a few wires. Colourful little fairy lights wrapped around its horn, glowing. Big eyes, a proud smile, four stubby legs.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: rhino grey #8C8C96, generator #FFCD28, exhaust #50555A, fairy lights #FFF096, smoke #F0F0F5.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 4.5 studs tall.
```

**In the game:** id `GeneratorGainda` · Rs 5,000 · +Rs 65/s · 4.5 studs tall, 2.3 x 4.5 studs wide · Hatches in Railway Junction (Sindh Railway Junction), Sarson Fields (Punjab Mustard Fields), Namak Caves (Pink Salt Caves), Karachi Port (The Big Harbour).

</details>

<details>
<summary><b>Biryani Badshah</b> · Rare · <i>"Aloo wali biryani hi asli hai!"</i></summary>

**Look and personality.** A royal copper degh full of biryani. Fluffy rice and saffron make his hair, a gold crown with a potato jewel sits on top, and he holds a ladle like a sceptre. He insists aloo wali biryani is the real one.

**Colour palette**

| Part | Hex |
| --- | --- |
| Copper degh | `#BE6E3C` |
| Rice | `#FAF5E6` |
| Saffron | `#F5961E` |
| Crown | `#F0BE3C` |
| Potato jewel | `#C8A05A` |
| Moustache | `#232328` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Biryani Badshah. A round copper cooking pot (degh) as the body of a proud king, filled with fluffy white and saffron-orange rice that looks like hair. A gold crown on top with a round potato as its jewel. A thick black moustache, big eyes, little arms holding a long ladle like a royal sceptre. Short legs.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: copper degh #BE6E3C, rice #FAF5E6, saffron #F5961E, crown #F0BE3C, potato jewel #C8A05A, moustache #232328.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 3.8 studs tall.
```

**In the game:** id `BiryaniBadshah` · Rs 6,000 · +Rs 75/s · 3.8 studs tall, 4.4 x 3.7 studs wide · Hatches in Qissa Khawani (Peshawar Storytellers' Bazaar), Thar Desert (Thar Sand Dunes), Lahore Qila (The Old Fort of Lahore).

</details>

<details>
<summary><b>Dhaba Dragon</b> · Rare · <i>"Ek naan, extra garam!"</i></summary>

**Look and personality.** A chubby red dragon whose belly is a glowing clay tandoor. Small wings, a towel over the shoulder like a dhaba cook, and every time it breathes fire a hot naan flies out. Ek naan, extra garam!

**Colour palette**

| Part | Hex |
| --- | --- |
| Dragon red | `#CD3728` |
| Wings | `#821E32` |
| Tandoor clay | `#BE6941` |
| Fire glow | `#FF961E` |
| Towel | `#FAFAFA` |
| Horns | `#FAEBC8` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Dhaba Dragon. A chubby red dragon with small dark-red bat wings and two little cream horns. Its round belly is a clay tandoor oven with a glowing orange fire inside. A white towel over one shoulder like a roadside cook. A small friendly flame comes out of its mouth and a fresh naan is flying out of the flame.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: dragon red #CD3728, wings #821E32, tandoor clay #BE6941, fire glow #FF961E, towel #FAFAFA, horns #FAEBC8.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 4.2 studs tall.
```

**In the game:** id `DhabaDragon` · Rs 8,000 · +Rs 100/s · 4.2 studs tall, 4.4 x 5.8 studs wide · Hatches in Camel Mela (Thar Camel Fair), Sahil Beach (Arabian Sea Beach), Thar Desert (Thar Sand Dunes).

</details>

<details>
<summary><b>Shaadi Shehnai Shark</b> · Rare · <i>"Shaadi kahan hai?"</i></summary>

**Look and personality.** A friendly blue shark who never misses a wedding. It stands on its tail in a maroon wedding jacket with gold buttons, wears a marigold garland and plays the shehnai. Shaadi kahan hai?

**Colour palette**

| Part | Hex |
| --- | --- |
| Shark blue | `#5A82BE` |
| Belly | `#E6EBF0` |
| Wedding jacket | `#821E32` |
| Gold buttons | `#F0BE3C` |
| Marigolds | `#FAA51E` |
| Shehnai | `#96643C` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Shaadi Shehnai Shark. A friendly blue shark standing upright on its tail fin, with a pale belly, a big back fin and a wide grin with small white teeth. It wears a maroon wedding jacket (sherwani) with gold buttons and an orange and yellow marigold garland. Its fins hold a wooden shehnai with a gold bell to its mouth. Dancing happily.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: shark blue #5A82BE, belly #E6EBF0, wedding jacket #821E32, gold buttons #F0BE3C, marigolds #FAA51E, shehnai #96643C.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 5.1 studs tall.
```

**In the game:** id `ShaadiShehnaiShark` · Rs 10,000 · +Rs 120/s · 5.1 studs tall, 2.4 x 3.9 studs wide · Hatches in Sahil Beach (Arabian Sea Beach), Karachi Port (The Big Harbour).

</details>

#### Epic (7)

![Epic brainrots](docs/brainrots/epic.jpg)

<details>
<summary><b>Chipa Sahab</b> · Epic · <i>"Beta, meri baat suno..."</i></summary>

**Look and personality.** A tiny round uncle with a giant curly moustache much wider than his body, round glasses and a sweater vest. His hands and feet are suction cups, so once he sticks to you he never lets go. Beta, meri baat suno...

**Colour palette**

| Part | Hex |
| --- | --- |
| Uncle skin | `#CD966E` |
| Sweater vest | `#5A5A8C` |
| Moustache | `#232328` |
| Suction cups | `#DC3232` |
| Newspaper | `#EBE6D7` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Chipa Sahab. A tiny, round, bald uncle with a gigantic curly black moustache much wider than his body, round black glasses over big eyes and white side hair. A navy sweater vest with white stripes. His hands and feet are red suction cups. A rolled newspaper under his arm. Arms out as if about to give advice.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: uncle skin #CD966E, sweater vest #5A5A8C, moustache #232328, suction cups #DC3232, newspaper #EBE6D7.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 2.9 studs tall.
```

**In the game:** id `ChipaSahab` · Rs 16,000 · +Rs 180/s · 2.9 studs tall, 4.5 x 2.5 studs wide · Hatches in Qissa Khawani (Peshawar Storytellers' Bazaar), Namak Caves (Pink Salt Caves), Barfani Pahar (The Snowy North).

</details>

<details>
<summary><b>Mehndi Mummy</b> · Epic · <i>"Haath idhar karo!"</i></summary>

**Look and personality.** A cute, not-scary mummy wrapped in cream bandages covered in brown henna patterns of paisleys and flowers. Big eyes peek out, and she carries a henna cone to decorate everyone's hands. Haath idhar karo!

**Colour palette**

| Part | Hex |
| --- | --- |
| Bandages | `#F0E4C8` |
| Henna | `#964B23` |
| Eyes gap | `#232328` |
| Blush | `#FF96A0` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Mehndi Mummy. A cute, round, friendly mummy wrapped in cream bandages decorated with brown henna patterns (paisleys, flowers, dots). A gap in the bandages shows big sparkly eyes and rosy cheeks. She holds a henna cone like a pen, ready to draw on your hand. A loose bandage end trails behind like a tail. Not scary at all.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: bandages #F0E4C8, henna #964B23, eyes gap #232328, blush #FF96A0.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 4.3 studs tall.
```

**In the game:** id `MehndiMummy` · Rs 20,000 · +Rs 230/s · 4.3 studs tall, 2.2 x 4.2 studs wide · Hatches in Thar Desert (Thar Sand Dunes), Mohenjo-daro (The Ancient Brick City).

</details>

<details>
<summary><b>Tikka Tiger</b> · Epic · <i>"Apna tikka khud banata hoon!"</i></summary>

**Look and personality.** A chubby orange tiger with grill-mark stripes who cooks his own tikka: he holds a giant skewer of tikka over the little flame at the tip of his tail. Apna tikka khud banata hoon!

**Colour palette**

| Part | Hex |
| --- | --- |
| Tiger orange | `#F58C1E` |
| Grill stripes | `#966437` |
| Tikka | `#B44628` |
| Peppers | `#28A050` |
| Tail flame | `#FF961E` |
| Muzzle | `#FAFAFA` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Tikka Tiger. A chubby orange tiger cub with dark grill-mark stripes, a white muzzle and round ears. He proudly holds a long skewer of red tikka pieces with green peppers in both paws, over a small cartoon flame at the tip of his tail. Big eyes, whiskers, a happy smile.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: tiger orange #F58C1E, grill stripes #966437, tikka #B44628, peppers #28A050, tail flame #FF961E, muzzle #FAFAFA.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 4.5 studs tall.
```

**In the game:** id `TikkaTiger` · Rs 24,000 · +Rs 270/s · 4.5 studs tall, 3.1 x 2.8 studs wide · Hatches in Sarson Fields (Punjab Mustard Fields), Lahore Qila (The Old Fort of Lahore).

</details>

<details>
<summary><b>Jalebi Jinn</b> · Epic · <i>"Teen wishes... teeno meethi!"</i></summary>

**Look and personality.** A chubby orange jalebi genie rising out of a pink mithai box, his lower body a big jalebi spiral. Arms crossed, curly moustache, syrup shine, and little sweets orbiting him. Three wishes... all of them sweet!

**Colour palette**

| Part | Hex |
| --- | --- |
| Jalebi orange | `#FA9119` |
| Syrup shine | `#F0AA28` |
| Mithai box | `#FF69B4` |
| Moustache | `#232328` |
| Laddoo | `#FA9628` |
| Barfi | `#FAF0DC` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Jalebi Jinn. A chubby, glossy orange genie whose lower body is a giant curly jalebi spiral rising out of an open pink sweet box. Arms crossed, a curly black moustache, a jalebi curl on top of his head like a topknot, big friendly eyes. Little sweets (laddoo, barfi, gulab jamun) orbit around him. Fairy-tale genie, not religious.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: jalebi orange #FA9119, syrup shine #F0AA28, mithai box #FF69B4, moustache #232328, laddoo #FA9628, barfi #FAF0DC.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 5.5 studs tall.
```

**In the game:** id `JalebiJinn` · Rs 30,000 · +Rs 320/s · 5.5 studs tall, 3.7 x 3.6 studs wide, floats · Hatches in Sahil Beach (Arabian Sea Beach), Lahore Qila (The Old Fort of Lahore), Mohenjo-daro (The Ancient Brick City).

</details>

<details>
<summary><b>Dholak Dino</b> · Epic · <i>"Dhak dhina dhin!"</i></summary>

**Look and personality.** A chubby green dinosaur whose belly is a painted dholak drum laced with rope. It drums on its own tummy with tiny arms and dances at every celebration. Dhak dhina dhin!

**Colour palette**

| Part | Hex |
| --- | --- |
| Dino green | `#5AAA50` |
| Dholak red | `#DC3232` |
| Dholak bands | `#FFCD28` |
| Rope lacing | `#C8AF82` |
| Ribbon | `#FF69B4` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Dholak Dino. A chubby green dinosaur standing on two feet with a long tail. Its round belly is a red dholak drum with yellow painted bands and rope lacing, worn sideways. Tiny arms drumming on it, a pink ribbon, a big open happy mouth. A dancing pose with one foot up.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: dino green #5AAA50, dholak red #DC3232, dholak bands #FFCD28, rope lacing #C8AF82, ribbon #FF69B4.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 4.6 studs tall.
```

**In the game:** id `DholakDino` · Rs 40,000 · +Rs 400/s · 4.6 studs tall, 2.4 x 4.8 studs wide · Hatches in Camel Mela (Thar Camel Fair), Sarson Fields (Punjab Mustard Fields), Lahore Qila (The Old Fort of Lahore).

</details>

<details>
<summary><b>Rishta Aunty Robot</b> · Epic · <i>"Beta, kya karte ho?"</i></summary>

**Look and personality.** A shiny round robot aunty with cat-eye glasses, a colourful dupatta, a clipboard and a telescope eye that zooms in on everyone. Her antenna is a hair bun and she always carries her handbag. Beta, kya karte ho?

**Colour palette**

| Part | Hex |
| --- | --- |
| Robot silver | `#C8C8D7` |
| Dupatta | `#FF69B4` |
| Cat-eye glasses | `#E62896` |
| Clipboard | `#96643C` |
| Handbag | `#FFCD28` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Rishta Aunty Robot. A friendly round silver robot shaped like an aunty: a dome head with a hair-bun antenna, pink cat-eye glasses, one eye a little telescope zooming out, a bright pink dupatta over her shoulders and a pink skirt. She holds a clipboard and pen, and a yellow handbag hangs from her arm. Curious, nosy expression.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: robot silver #C8C8D7, dupatta #FF69B4, cat-eye glasses #E62896, clipboard #96643C, handbag #FFCD28.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 5.3 studs tall.
```

**In the game:** id `RishtaAuntyRobot` · Rs 50,000 · +Rs 500/s · 5.3 studs tall, 2.9 x 2.6 studs wide · Hatches in Namak Caves (Pink Salt Caves), Karachi Port (The Big Harbour), Barfani Pahar (The Snowy North).

</details>

<details>
<summary><b>Tonga Tornado</b> · Epic · <i>"Driver kaun hai?!"</i></summary>

**Look and personality.** A colourful horse cart (tonga) spinning so fast that its bottom has turned into a dust tornado. A wooden horse head pokes out the front and the seat is empty. Driver kaun hai?!

**Colour palette**

| Part | Hex |
| --- | --- |
| Cart red | `#DC3232` |
| Canopy | `#326EDC` |
| Wheels | `#FFCD28` |
| Wood horse | `#96643C` |
| Dust | `#EBCD96` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Tonga Tornado. A colourful two-wheeled horse cart (tonga) with a red seat, a blue canopy with yellow tassels and two big yellow wheels. Instead of a real horse, a cute wooden horse head pokes out the front with big eyes. The bottom of the cart is a spinning swirl of sandy dust like a small tornado. The driver's seat is empty.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: cart red #DC3232, canopy #326EDC, wheels #FFCD28, wood horse #96643C, dust #EBCD96.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 4.1 studs tall.
```

**In the game:** id `TongaTornado` · Rs 60,000 · +Rs 600/s · 4.1 studs tall, 3.2 x 3.7 studs wide · Hatches in Railway Junction (Sindh Railway Junction), Thar Desert (Thar Sand Dunes), Karachi Port (The Big Harbour).

</details>

#### Legendary (5)

![Legendary brainrots](docs/brainrots/legendary.jpg)

<details>
<summary><b>Truck Art Totaa</b> · Legendary · <i>"Dekh magar pyar se!"</i></summary>

**Look and personality.** A green parrot painted all over with Pakistani truck art: bright flowers, stripes, bells and chains on the wings and a painted truck-crown crest on its head. Its tail says 'Dekh magar pyar se' (look, but with love).

**Colour palette**

| Part | Hex |
| --- | --- |
| Parrot green | `#32B450` |
| Beak | `#FA8C28` |
| Wing blue | `#326EDC` |
| Crest red | `#DC3232` |
| Truck-art gold | `#F0BE3C` |
| Flower yellow | `#FFCD28` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Truck Art Totaa. A plump green parrot painted all over in bright Pakistani truck-art style: flowers, stripes and dots in red, yellow, blue and pink. Blue wings with painted stripes and little gold bells and chains hanging off them. A red-and-gold painted wooden crest on its head like a truck's crown, with coloured studs. Orange beak and feet. Its tail feathers carry a small white panel with the words "Dekh magar pyar se".

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: parrot green #32B450, beak #FA8C28, wing blue #326EDC, crest red #DC3232, truck-art gold #F0BE3C, flower yellow #FFCD28.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No logos or real brands, and no other writing.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 5.6 studs tall.
```

**In the game:** id `TruckArtTotaa` · Rs 80,000 · +Rs 800/s · 5.6 studs tall, 2.8 x 3.8 studs wide · Hatches in Sahil Beach (Arabian Sea Beach), Karachi Port (The Big Harbour), Barfani Pahar (The Snowy North).

</details>

<details>
<summary><b>Sixer Sher</b> · Legendary · <i>"Chakka! Sorry, sheesha toot gaya!"</i></summary>

**Look and personality.** A chubby golden lion who rules street cricket. Fluffy mane, a red T-shirt, a backwards cap, a tape-wrapped bat on his shoulder and a taped tennis ball in his paw. Chakka! Sorry, sheesha toot gaya!

**Colour palette**

| Part | Hex |
| --- | --- |
| Lion gold | `#E6A032` |
| Mane | `#B45F1E` |
| T-shirt | `#DC3232` |
| Cap | `#326EDC` |
| Bat | `#E6CD96` |
| Taped ball | `#D2E63C` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Sixer Sher. A chubby golden lion cub with a big fluffy brown mane, wearing a red T-shirt with a white stripe and a blue cap on backwards. A wooden street-cricket bat wrapped in black and red tape rests on his shoulder; his other paw holds a yellow tennis ball wrapped in black tape. Confident grin, determined eyebrows.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: lion gold #E6A032, mane #B45F1E, t-shirt #DC3232, cap #326EDC, bat #E6CD96, taped ball #D2E63C.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 5.7 studs tall.
```

**In the game:** id `SixerSher` · Rs 150,000 · +Rs 1,400/s · 5.7 studs tall, 3.7 x 4.0 studs wide · Hatches in Sarson Fields (Punjab Mustard Fields), Lahore Qila (The Old Fort of Lahore), Barfani Pahar (The Snowy North).

</details>

<details>
<summary><b>Chilgoza Chacha Chipka</b> · Legendary · <i>"Ghar ka pankha hoon main!"</i></summary>

**Look and personality.** A long brown pine-nut uncle clinging to the blade of a spinning ceiling fan for dear life, his moustache blown sideways. A drip of honey falls from him. Ghar ka pankha hoon main!

**Colour palette**

| Part | Hex |
| --- | --- |
| Pine nut | `#AF7D55` |
| Fan | `#FAFAFA` |
| Fan blades | `#AFB4B9` |
| Moustache | `#232328` |
| Honey | `#F0AA28` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Chilgoza Chacha Chipka. A white ceiling fan with three metal blades, spinning. A long, brown pine-nut (chilgoza) uncle hangs onto one blade with both little arms, holding on for dear life, his black moustache blown sideways by the wind, mouth open, worried eyebrows. A few golden drops of honey fall from him.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: pine nut #AF7D55, fan #FAFAFA, fan blades #AFB4B9, moustache #232328, honey #F0AA28.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 6.0 studs tall.
```

**In the game:** id `ChilgozaChachaChipka` · Rs 200,000 · +Rs 1,800/s · 6.0 studs tall, 5.3 x 4.9 studs wide · Hatches in Qissa Khawani (Peshawar Storytellers' Bazaar), Namak Caves (Pink Salt Caves), Mohenjo-daro (The Ancient Brick City).

</details>

<details>
<summary><b>Cylinder Cycle Chacha</b> · Legendary · <i>"Cylinder le lo, cylinder!"</i></summary>

**Look and personality.** A living old bicycle who sells gas cylinders. His headlights are his eyes, his handlebar is a big curly moustache, his bell is his voice, and a tower of red gas cylinders is roped to his back. Cylinder le lo, cylinder!

**Colour palette**

| Part | Hex |
| --- | --- |
| Cycle frame | `#232328` |
| Headlights | `#C8CDD4` |
| Gas cylinders | `#DC3232` |
| Seat | `#82502D` |
| Rope | `#C8AF82` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Cylinder Cycle Chacha. An old black bicycle that is alive: two round steel headlights on the front are its big eyes, the curved black handlebar is a curly moustache, and a little bell is its mouth. A tall stack of red gas cylinders is tied with rope on the carrier behind the brown seat. Cheerful, proud, a bit wobbly.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: cycle frame #232328, headlights #C8CDD4, gas cylinders #DC3232, seat #82502D, rope #C8AF82.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 5.7 studs tall.
```

**In the game:** id `CylinderCycleChacha` · Rs 240,000 · +Rs 2,200/s · 5.7 studs tall, 4.4 x 4.4 studs wide · Hatches in Thar Desert (Thar Sand Dunes), Karachi Port (The Big Harbour).

</details>

<details>
<summary><b>Mela Maharaja</b> · Legendary · <i>"Ek chakkar aur!"</i></summary>

**Look and personality.** A laughing Ferris wheel king from the village mela. His face is the hub, a gold crown sits on top, colourful cabins swing on the rim with light bulbs, and he walks on two little legs. Ek chakkar aur!

**Colour palette**

| Part | Hex |
| --- | --- |
| Rim pink | `#FF69B4` |
| Rim yellow | `#FFCD28` |
| Face | `#FFF0CD` |
| Crown | `#F0BE3C` |
| Cabins | `#1EAAAA` |
| Bulbs | `#FFF096` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Mela Maharaja. A colourful Ferris wheel with a pink and yellow rim, white spokes, small cabins in red, teal, orange and purple, and glowing light bulbs all around. The centre hub is a laughing round face with squeezed-shut happy eyes and an open mouth. A gold crown on top of the wheel. Two little legs with red shoes underneath.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: rim pink #FF69B4, rim yellow #FFCD28, face #FFF0CD, crown #F0BE3C, cabins #1EAAAA, bulbs #FFF096.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 6.6 studs tall.
```

**In the game:** id `MelaMaharaja` · Rs 300,000 · +Rs 2,600/s · 6.6 studs tall, 5.0 x 1.9 studs wide · Hatches in Thar Desert (Thar Sand Dunes), Lahore Qila (The Old Fort of Lahore), Mohenjo-daro (The Ancient Brick City).

</details>

#### Mythic (3)

![Mythic brainrots](docs/brainrots/mythic.jpg)

<details>
<summary><b>Ammi ki Udti Chappal</b> · Mythic · <i>"Whoooosh! Homework kiya?"</i></summary>

**Look and personality.** The legendary flying chappal every kid fears and loves. A big blue hawai chappal with white straps, stern-but-cute eyes on its sole, little feathered wings, whoosh lines and a glowing outline. Whoooosh! Homework kiya?

**Colour palette**

| Part | Hex |
| --- | --- |
| Chappal blue | `#3C6ED2` |
| Straps and top | `#FAFAFA` |
| Glow | `#5AB4FF` |
| Eyebrows | `#1E285A` |
| Blush | `#FF96A0` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Ammi ki Udti Chappal. A big blue rubber hawai chappal (flip-flop) flying through the air, with a white top layer and white V-straps. Its sole faces us with big stern-but-cute eyes, angry eyebrows and rosy cheeks. Small white feathered wings on its sides, white whoosh lines behind it and a soft glowing blue outline. Funny, not scary.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: chappal blue #3C6ED2, straps and top #FAFAFA, glow #5AB4FF, eyebrows #1E285A, blush #FF96A0.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 6.0 studs tall.
```

**In the game:** id `AmmiKiUdtiChappal` · Rs 500,000 · +Rs 4,000/s · 6.0 studs tall, 4.8 x 1.9 studs wide, floats · Hatches in Namak Caves (Pink Salt Caves), Karachi Port (The Big Harbour), Mohenjo-daro (The Ancient Brick City).

</details>

<details>
<summary><b>Chand Raat Cheetah</b> · Mythic · <i>"Choorian chamak rahi hain!"</i></summary>

**Look and personality.** A sleek golden cheetah dressed for the night bazaar: colourful glass bangles stacked on its legs and tail, mehndi on its paws and a glowing crescent-moon charm on its collar. Choorian chamak rahi hain!

**Colour palette**

| Part | Hex |
| --- | --- |
| Cheetah gold | `#FAD250` |
| Spots | `#5A371E` |
| Bangles | `#E62896` |
| Mehndi | `#964B23` |
| Moon charm | `#F0BE3C` |
| Sparkles | `#FAFAFA` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Chand Raat Cheetah. A sleek, golden cheetah cub with dark spots, a cream muzzle and big friendly eyes. Colourful glass bangles (red, green, blue, gold, pink) are stacked on its front legs and its tail. Brown henna patterns on its paws. A gold collar with a glowing crescent-moon charm. White sparkles around it, as if at a night bazaar.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: cheetah gold #FAD250, spots #5A371E, bangles #E62896, mehndi #964B23, moon charm #F0BE3C, sparkles #FAFAFA.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 5.5 studs tall.
```

**In the game:** id `ChandRaatCheetah` · Rs 800,000 · +Rs 6,500/s · 5.5 studs tall, 5.1 x 6.7 studs wide · Hatches in Thar Desert (Thar Sand Dunes), Mohenjo-daro (The Ancient Brick City), Barfani Pahar (The Snowy North).

</details>

<details>
<summary><b>Kite Kaptaan</b> · Mythic · <i>"Bo kata!"</i></summary>

**Look and personality.** The captain of the sky: a huge red-and-yellow patang with a face and a captain's hat, a long ribbon tail, and a sparkly manjha string that runs down to a charkhi spool. Bo kata!

**Colour palette**

| Part | Hex |
| --- | --- |
| Kite red | `#DC3232` |
| Kite yellow | `#FFCD28` |
| Bamboo | `#C8AF5F` |
| Captain hat | `#1E285A` |
| Ribbon | `#FF69B4` |
| Spool | `#96643C` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Kite Kaptaan. A huge diamond-shaped paper kite (patang) in red and yellow quarters with thin bamboo sticks, flying. It has a big smiling face with rosy cheeks and wears a white-and-navy captain's hat. A long ribbon tail with little coloured bows. A sparkly string runs down to a wooden spool (charkhi) with red ends. Gold sparkles around it.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: kite red #DC3232, kite yellow #FFCD28, bamboo #C8AF5F, captain hat #1E285A, ribbon #FF69B4, spool #96643C.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 7.6 studs tall.
```

**In the game:** id `KiteKaptaan` · Rs 1,000,000 · +Rs 8,000/s · 7.6 studs tall, 5.3 x 1.9 studs wide, floats · Hatches in Sahil Beach (Arabian Sea Beach), Lahore Qila (The Old Fort of Lahore), Barfani Pahar (The Snowy North).

</details>

#### Secret (4)

![Secret brainrots](docs/brainrots/secret.jpg)

<details>
<summary><b>Kahwa Yeti</b> · Secret · <i>"Ek cup kahwa, garam garam!"</i></summary>

**Look and personality.** A big, fluffy, friendly yeti from the snowy north who always has a hot brass samovar of green kahwa to share. Frosty blue eyebrows, cardamom pods for buttons and a huge warm smile. Ek cup kahwa, garam garam!

**Colour palette**

| Part | Hex |
| --- | --- |
| Yeti fur | `#FAFAFA` |
| Frosty face | `#78BEFF` |
| Samovar brass | `#BE6E3C` |
| Cardamom | `#AACD78` |
| Steam | `#F0F0F5` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Kahwa Yeti. A big, round, fluffy white yeti with tufts of fur all over, a pale blue face, frosty icy-blue eyebrows and a big happy open mouth. Green cardamom pods as buttons down its tummy. It holds a shiny brass samovar (a tall tea urn with a little tap) of green kahwa in its arms, with white steam curling up. Big blue feet.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: yeti fur #FAFAFA, frosty face #78BEFF, samovar brass #BE6E3C, cardamom #AACD78, steam #F0F0F5.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 7.5 studs tall.
```

**In the game:** id `KahwaYeti` · Rs 2,400,000 · +Rs 15,000/s · 7.5 studs tall, 5.0 x 6.1 studs wide · Hatches in Barfani Pahar (The Snowy North).

</details>

<details>
<summary><b>Gola Ganda Golem</b> · Secret · <i>"Thanda thanda, rang birangi!"</i></summary>

**Look and personality.** A giant golem built from crushed-ice gola gandas, with rainbow syrup dripping all over and wooden gola sticks for fingers. Big and strong, but it just wants everyone to cool down. Thanda thanda, rang birangi!

**Colour palette**

| Part | Hex |
| --- | --- |
| Crushed ice | `#BEE1F5` |
| Red syrup | `#DC3232` |
| Orange syrup | `#FA8C28` |
| Green syrup | `#28A050` |
| Pink syrup | `#FF69B4` |
| Gola sticks | `#BE915F` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Gola Ganda Golem. A giant, chunky golem made of icy-blue crushed-ice balls (gola ganda): a big round body, a round head and lumpy ice arms and legs. Splashes of bright red, orange, green, pink and blue syrup on the ice, with drips running down. Its fingers are wooden ice-lolly sticks. Big friendly eyes, a gentle smile.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: crushed ice #BEE1F5, red syrup #DC3232, orange syrup #FA8C28, green syrup #28A050, pink syrup #FF69B4, gola sticks #BE915F.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 7.6 studs tall.
```

**In the game:** id `GolaGandaGolem` · Rs 3,600,000 · +Rs 21,000/s · 7.6 studs tall, 7.0 x 3.4 studs wide · Hatches in Barfani Pahar (The Snowy North).

</details>

<details>
<summary><b>Barfi Barfani Bagh</b> · Secret · <i>"Barf bhi, barfi bhi!"</i></summary>

**Look and personality.** A snow leopard made of white and pistachio barfi squares, with shiny silver warq for spots, a long fluffy tail and a woolly Chitrali cap (pakol). Barf (snow) and barfi in one. Barf bhi, barfi bhi!

**Colour palette**

| Part | Hex |
| --- | --- |
| White barfi | `#FAFAFA` |
| Pistachio barfi | `#AACD78` |
| Silver warq | `#DCDCE6` |
| Pakol cap | `#EECD91` |
| Cap rim | `#966437` |
| Blush | `#FF96A0` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Barfi Barfani Bagh. A cute snow leopard cub built from soft square sweets (barfi) in white and pistachio green, with little shiny silver squares as its spots. A boxy head with big eyes and rosy cheeks, a long thick fluffy tail curling up, and a round woolly beige cap with a rolled brown rim (a Chitrali pakol). Standing on four short legs, shown from three-quarters.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: white barfi #FAFAFA, pistachio barfi #AACD78, silver warq #DCDCE6, pakol cap #EECD91, cap rim #966437, blush #FF96A0.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 5.4 studs tall.
```

**In the game:** id `BarfiBarfaniBagh` · Rs 5,000,000 · +Rs 28,000/s · 5.4 studs tall, 4.9 x 7.4 studs wide · Hatches in Barfani Pahar (The Snowy North).

</details>

<details>
<summary><b>Jalebi Markhor</b> · Secret · <i>"Seengh meethe, dil bhi meetha!"</i></summary>

**Look and personality.** A proud markhor, Pakistan's national animal, whose huge spiral horns are golden jalebis. It wears a warm maroon shawl with a gold border and a collar of little bells. Seengh meethe, dil bhi meetha!

**Colour palette**

| Part | Hex |
| --- | --- |
| Markhor coat | `#E8CDA5` |
| Jalebi horns | `#FA9119` |
| Syrup shine | `#F0AA28` |
| Shawl | `#821E32` |
| Shawl border | `#F0BE3C` |
| Beard | `#966437` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Jalebi Markhor. A friendly markhor (a wild mountain goat) with a beige coat, a cream muzzle and a dark pointed beard. Its two huge horns twist up in spirals and are made of glossy orange jalebi sweets. A maroon shawl with a gold border over its back, a red collar with small gold bells, big kind eyes. Standing on four legs.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: markhor coat #E8CDA5, jalebi horns #FA9119, syrup shine #F0AA28, shawl #821E32, shawl border #F0BE3C, beard #966437.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 7.6 studs tall.
```

**In the game:** id `JalebiMarkhor` · Rs 7,000,000 · +Rs 36,000/s · 7.6 studs tall, 2.8 x 5.2 studs wide · Hatches in Barfani Pahar (The Snowy North).

</details>

#### Special (Collection Book rewards) (6)

![Special brainrots](docs/brainrots/special.jpg)

<details>
<summary><b>Mithai Mamu</b> · Special · <i>"Ek aur laddoo, beta!"</i></summary>

**Look and personality.** A round orange motichoor laddoo uncle with a big smile, a moustache and a little maroon vest, shining with silver warq. He carries a tray of barfi, jalebi and gulab jamun for everyone. Ek aur laddoo, beta!

**Colour palette**

| Part | Hex |
| --- | --- |
| Laddoo | `#FA9628` |
| Saffron dots | `#F5961E` |
| Vest | `#821E32` |
| Silver warq | `#DCDCE6` |
| Tray | `#C8CDD4` |
| Gulab jamun | `#6E2814` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Mithai Mamu. A round orange motichoor laddoo with tiny bumpy dots, as a jolly uncle: big smile, rosy cheeks, a thick black moustache, a small maroon vest with gold buttons and flakes of silver warq on top. He carries a steel tray with barfi, a jalebi and gulab jamun. Short legs, little shoes.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: laddoo #FA9628, saffron dots #F5961E, vest #821E32, silver warq #DCDCE6, tray #C8CDD4, gulab jamun #6E2814.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 3.5 studs tall.
```

**In the game:** id `MithaiMamu` · Rs 4,000 · +Rs 60/s · 3.5 studs tall, 2.9 x 4.0 studs wide · Collection Book reward for finishing every COLLECTION_REWARDS brainrot (never hatches, cannot be stolen).

</details>

<details>
<summary><b>Lassi Lightning</b> · Special · <i>"Thandi thandi... ZAP!"</i></summary>

**Look and personality.** A tall frothy glass of lassi who is a superhero. Lightning-bolt wings, goggles, a red cape, a straw antenna crackling with blue sparks. Thandi thandi... ZAP!

**Colour palette**

| Part | Hex |
| --- | --- |
| Glass | `#B4DCFF` |
| Lassi | `#F0F5EB` |
| Froth | `#FFFAE6` |
| Bolt wings | `#FFCD28` |
| Cape and straw | `#DC3232` |
| Sparks | `#5AB4FF` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Lassi Lightning. A tall clear glass full of white lassi with thick froth on top, as a superhero: round goggles over big eyes, a red cape, yellow lightning-bolt shaped wings on its sides and a red straw sticking out like an antenna with a zigzag of blue electricity at the top. Blue sparks around it. Flying, heroic pose.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: glass #B4DCFF, lassi #F0F5EB, froth #FFFAE6, bolt wings #FFCD28, cape and straw #DC3232, sparks #5AB4FF.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 5.4 studs tall.
```

**In the game:** id `LassiLightning` · Rs 16,000 · +Rs 220/s · 5.4 studs tall, 4.3 x 3.4 studs wide, floats · Collection Book reward for finishing every Uncommon brainrot (never hatches, cannot be stolen).

</details>

<details>
<summary><b>Chowkidar Choocha</b> · Special · <i>"Jaagte raho!"</i></summary>

**Look and personality.** A round yellow chick who is the neighbourhood watchman. Khaki uniform and cap, a whistle in its beak, a stick and a torch, and very alert eyes. Jaagte raho!

**Colour palette**

| Part | Hex |
| --- | --- |
| Chick yellow | `#FFE146` |
| Uniform | `#BEAA6E` |
| Belt | `#82502D` |
| Beak and feet | `#FA8C28` |
| Whistle | `#C8CDD4` |
| Torch glow | `#FFCD28` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Chowkidar Choocha. A round fluffy yellow chick dressed as a night watchman: a khaki uniform with gold buttons, a brown belt and a khaki cap with a black peak. A steel whistle in its orange beak, a wooden stick in one wing and a glowing torch in the other. Alert eyes with serious eyebrows, orange feet.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: chick yellow #FFE146, uniform #BEAA6E, belt #82502D, beak and feet #FA8C28, whistle #C8CDD4, torch glow #FFCD28.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 3.4 studs tall.
```

**In the game:** id `ChowkidarChoocha` · Rs 60,000 · +Rs 800/s · 3.4 studs tall, 3.2 x 2.9 studs wide · Collection Book reward for finishing every Rare brainrot (never hatches, cannot be stolen).

</details>

<details>
<summary><b>Rangeela Raja</b> · Special · <i>"Rang hi rang!"</i></summary>

**Look and personality.** A plump peacock king with a gold crown and a huge fanned tail in every colour of the rainbow. Puffs of coloured powder burst around him. Rang hi rang!

**Colour palette**

| Part | Hex |
| --- | --- |
| Peacock blue | `#1E5AC8` |
| Teal | `#14A096` |
| Crown | `#F0BE3C` |
| Tail red | `#DC3232` |
| Tail yellow | `#FFCD28` |
| Tail purple | `#8C46C8` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Rangeela Raja. A plump, royal-blue peacock with teal wings and a small gold crown with a green gem. Behind him a huge fanned tail with feathers in red, orange, yellow, green, teal, blue and purple, each with an eye spot at the tip. Little puffs of coloured powder (pink, yellow, green, blue) around his feet. Proud, happy face.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: peacock blue #1E5AC8, teal #14A096, crown #F0BE3C, tail red #DC3232, tail yellow #FFCD28, tail purple #8C46C8.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 5.1 studs tall.
```

**In the game:** id `RangeelaRaja` · Rs 240,000 · +Rs 3,000/s · 5.1 studs tall, 6.2 x 2.8 studs wide · Collection Book reward for finishing every Epic brainrot (never hatches, cannot be stolen).

</details>

<details>
<summary><b>Shalimar Sultan</b> · Special · <i>"Bagh mein khush aamdeed!"</i></summary>

**Look and personality.** A floating sultan from a Mughal-style garden. His body is a tiered white marble fountain, water jets rise from his green turban like a crown, cypress trees stand at his shoulders and flowers ring his base. Bagh mein khush aamdeed!

**Colour palette**

| Part | Hex |
| --- | --- |
| Marble | `#FAFAFA` |
| Face | `#FFF0CD` |
| Turban | `#28A050` |
| Turban band | `#F0BE3C` |
| Water | `#78C8FF` |
| Cypress | `#1E6E3C` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Shalimar Sultan. A floating sultan whose body is a white marble garden fountain with two tiers and pools of blue water. On top, a round cream face with a neat black moustache and big eyes, wearing a green turban with a gold band and a red jewel. Water jets spray up from the turban like a crown. Two small cypress trees at his shoulders, little flowers around the bottom pool.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: marble #FAFAFA, face #FFF0CD, turban #28A050, turban band #F0BE3C, water #78C8FF, cypress #1E6E3C.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 4.8 studs tall.
```

**In the game:** id `ShalimarSultan` · Rs 1,000,000 · +Rs 11,000/s · 4.8 studs tall, 3.4 x 3.4 studs wide, floats · Collection Book reward for finishing every Legendary brainrot (never hatches, cannot be stolen).

</details>

<details>
<summary><b>Taaron Wala Tonga</b> · Special · <i>"Chalo, taaron ki sair!"</i></summary>

**Look and personality.** A magical night tonga: a deep-blue flying cart covered in stars, pulled by a glowing white winged horse, rolling on crescent-moon wheels with a lantern swinging. Chalo, taaron ki sair!

**Colour palette**

| Part | Hex |
| --- | --- |
| Night blue | `#1E2364` |
| Stars and trim | `#F0BE3C` |
| Winged horse | `#FAFAFA` |
| Glow | `#5AB4FF` |
| Lantern | `#FFCD28` |

**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**

```text
Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about Pakistani street food, bazaars and family life.

Character: Taaron Wala Tonga. A flying horse cart (tonga) painted deep night blue with little gold stars, a gold-trimmed canopy and glowing yellow star shapes on the roof. Its wheels are glowing gold crescent moons. A small white horse with feathered wings and a glowing mane pulls it, smiling. A golden lantern hangs at the side and a trail of sparkles follows behind.

Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, made for kids.

Colours: night blue #1E2364, stars and trim #F0BE3C, winged horse #FAFAFA, glow #5AB4FF, lantern #FFCD28.

Show one character only, full body, front three-quarter view, on a plain white background with soft light. No text, no logos, no real brands.

If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing forward, standing with its base on the ground, about 3.3 studs tall.
```

**In the game:** id `TaaronWalaTonga` · Rs 4,000,000 · +Rs 40,000/s · 3.3 studs tall, 2.9 x 7.4 studs wide, floats · Collection Book reward for finishing every Mythic brainrot (never hatches, cannot be stolen).

</details>

<!-- characters:end -->

To change a sheet, edit its text in [`blender/characters.py`](blender/characters.py) and run `python blender/characters.py` (plain Python, no Blender needed). Prices, rarities, zones and sizes come from the game's own files, so they stay correct.

## Pacing

`tests/run.sh pacing` plays the game 300 times for each of three kinds of player and prints when they reach each milestone. It uses the game's real numbers and map: the walk or drive from your haveli door out through the gates (zigzag and all), hazards, egg timers, boot space, incubators and hatch times, plots filling up, the Mandi lane, wild brainrots, quests, free rolls, petrol, and buying vehicles, haveli levels, zones, gear and Naya Safar in a sensible order. It leaves out events, treasure, paid rolls, stealing and Robux, so real players with events running will be a little quicker. The three kinds of player only differ in skill: fast players take direct routes and rarely stand around, casual players take longer routes, stand around a third of the time and lose more eggs.

Minutes of play, median (and the middle half of players):

| Milestone | Fast | Typical | Casual |
| --- | --- | --- | --- |
| Motorbike | 2.8 (2-4) | 3.7 (2-5) | 4.6 (3-6) |
| Railway Junction | 7.4 (6-9) | 8.3 (6-9) | 9.2 (8-12) |
| Rs 100/s income | 5.9 (4-8) | 7.6 (5-10) | 11.0 (8-15) |
| Camel Mela | 13.8 (11-16) | 15.4 (13-18) | 18.1 (16-21) |
| Rickshaw | 16.7 (14-19) | 18.9 (16-21) | 21.8 (19-26) |
| Qissa Khawani (all of ring 1) | 20.4 (18-23) | 22.9 (20-26) | 27.8 (23-32) |
| Sarson Fields (first ring 2 zone) | 33.1 (28-36) | 35.8 (32-41) | 43.7 (36-50) |
| **1st Naya Safar** | **47.1 (41-52)** | **53.4 (46-59)** | **64.2 (57-73)** |
| Sahil Beach | 57.2 (52-63) | 65.7 (58-73) | 83.8 (75-94) |
| 2nd Naya Safar | 65.8 (60-72) | 79.0 (71-85) | 103.8 (92-115) |
| Thar Desert | 76.0 (70-83) | 91.0 (83-97) | 119.8 (109-131) |
| 3rd Naya Safar | 91.3 (85-98) | 109.9 (102-117) | 147.0 (134-158) |
| Namak Caves | 102.6 (96-109) | 123.7 (114-132) | 163.0 (152-177) |
| 4th Naya Safar (every zone open) | 121.5 (115-129) | 149.5 (141-159) | 202.7 (190-218) |

What the simulation found, and what changed because of it:

- **The game was too fast, not too slow.** With the old prices a typical player reached the first Naya Safar in about 30 minutes. Every zone tier roughly doubles what an egg is worth, so income grows fast once you reach the better zones, and Rs 1,000,000 was only a few minutes of mid-game income. Zones you have opened stay open after a Naya Safar, so you don't need all of ring 2 before your first one.
- **Wild brainrots were the biggest income** when they could be any Rare to Mythic from the zone's pool. Now they use the zone's own odds (Rare or better), turn up every 90 seconds instead of 40 and at most 4 at a time.
- **New prices:** zones Rs 15,000 / 50,000 / 150,000 (ring 1) and Rs 500,000 / 1,200,000 / 3,000,000 / 7,000,000 (ring 2); haveli levels Rs 4,000 up to Rs 2,000,000; the first Naya Safar Rs 2,500,000, then 4 times more each time. The lane's brainrots cost 2.5 times their value and are mostly Common and Uncommon.
- **Fast and casual players end up closer than you might think:** skill matters most early, when trips are what you wait for; later your brainrots' income does most of the work.
- The script fails if the typical first Naya Safar leaves 50-75 minutes (and a few other targets), so a change that breaks the pacing shows up straight away.

The knobs: zone prices, egg times, hatch times and odds are in `Biomes.luau`; haveli level prices, rebirth prices, wild brainrots, the Mandi lane, fuel prices and egg settings are in `Config.luau`; brainrot prices are the design doc's prices times `PRICE_MULTIPLIER = 2`, and income is in `Brainrots.luau`; vehicle prices, speeds and upgrade costs are in `Vehicles.luau`. The player behaviour and the targets are at the top of [`tests/pacing.luau`](tests/pacing.luau). It is a model, so still playtest with real players before you publish.

## Getting it into Roblox Studio

The code uses the [Rojo](https://rojo.space) layout, but you can use it without Rojo.

### Option A: open the place file (easiest)

A ready-to-play place file, [`ChaiChaos.rbxlx`](ChaiChaos.rbxlx), is in the repo. Download it, open it in Roblox Studio and press **Play**. The world builds itself when the game starts (it takes a few seconds; the terrain is big).

After changing the code, rebuild it with [Rojo](https://rojo.space):

```bash
rojo build -o ChaiChaos.rbxlx
```

### Option B: live sync with Rojo

1. Install Rojo and its Studio plugin ([guide](https://rojo.space/docs/v7/getting-started/installation/)).
2. Run `rojo serve` in this folder.
3. In Studio, open a new Baseplate place, click **Rojo > Connect**, then press **Play**.

### Option C: copy the scripts by hand

Create these in Roblox Studio, then paste in each file's code. The name in Studio must match exactly (no `.luau`, no `.server` or `.client`).

| File | Create in Studio | Type |
| --- | --- | --- |
| All 14 `src/shared/*.luau` files (Biomes, Brainrots, Config, Events, Format, Gear, Motion, Mutations, Quests, Remotes, Sounds, Themes, Tutorial, Vehicles) | `ReplicatedStorage > ChaiChaos` (a Folder) | ModuleScript |
| `src/server/Main.server.luau` | `ServerScriptService > ChaiChaosServer` (a Folder), named `Main` | Script |
| The other 31 `src/server/*.luau` files | `ServerScriptService > ChaiChaosServer` | ModuleScript |
| The 16 `src/client/*.client.luau` files (Driving, Events, Garage, Haveli, Hud, Kismat, Menu, Prompts, Quests, Radar, Shops, Smooth, Sounds, Tutorial, Weather, Zones) | `StarterPlayer > StarterPlayerScripts > ChaiChaosClient` (a Folder) | LocalScript |
| `src/client/Ui.luau` and `src/client/SoundPlayer.luau` | `StarterPlayer > StarterPlayerScripts > ChaiChaosClient` | ModuleScript |

With this many files, Option A or B is much easier.

### Studio settings

- **Game Settings > Players:** set max players to **8**, one per haveli.
- **Workspace > StreamingEnabled** should be on (the Rojo project turns it on). The world is big, and streaming keeps it smooth on phones. Eggs and treasure chests always stream in, so the radar can see them.
- **Saving:** publish the place, then turn on **Game Settings > Security > Enable Studio Access to API Services**. Without this the game still works, it just starts fresh every time.

## Setting up the Robux packs

The Robux buttons stay hidden, and stealing stays free, until you create the products:

1. Publish the game, then open it on the [Creator Dashboard](https://create.roblox.com/dashboard/creations).
2. Go to **Monetization > Developer Products** and create the products: "1 Kismat Roll", "10 Kismat Rolls", "1 Chor Pass", "5 Chor Passes", and the four paint jobs "Phool Patti", "Sona", "Rangeela" and "Chamak". Set each price there.
3. Copy each product's id into `Config.ROLL_PRODUCTS`, `Config.STEAL_PRODUCTS` and `Config.PAINT_PRODUCTS` in [`src/shared/Config.luau`](src/shared/Config.luau). A paint job with id 0 stays hidden.

In Studio, purchases are test purchases and cost nothing.

**Game passes.** Go to **Monetization > Passes**, create "2x Cash" and "Extra Plots", and copy their ids into `Config.GAME_PASSES`. They then show up in the Menu. A pass bought on the game's page works the next time the player joins.

**Badges.** Go to **Engagement > Badges**, create the eight badges listed in `Config.BADGES` (Welcome, FirstEgg, FirstRare, Driver, WildCatcher, Explorer, NayaSafar, SecretKeeper) and copy their ids in. Badges with id 0 are skipped.

Other settings in `Config.luau`: `STEAL_COSTS_ROBUX = false` makes stealing free, `STEAL_REFUND_ON_FAIL` controls whether failed steals give the Chor Pass back, and `DAILY_FREE_ROLLS` / `DAILY_FREE_STEALS` set what daily chai gives.

**Roblox rules for paid random items.** Kismat Rolls bought with Robux count as paid random items on Roblox. The game shows the exact odds before anyone buys, and never offers Robux rolls to players in countries where Roblox restricts paid random items (it asks `PolicyService` for each player). Those players can still roll with rupees. Before you publish, read Roblox's current rules on paid random items on the Creator Hub, and answer the experience questionnaire honestly. Eggs, gear, the radar, zones, vehicles, upgrades and petrol are never sold for Robux (paint jobs change looks only), and no guaranteed top-rarity brainrot is ever sold. The two game passes speed things up (2x Cash, Extra Plots) but never give anything you can't earn by playing.

## Making it yours

- **Numbers:** prices, timers, haveli levels, incubators, radar levels, hazards, odds, wild brainrots and the Mandi lane are in [`Config.luau`](src/shared/Config.luau). After changing prices, run `tests/run.sh pacing` to see what it does to the pacing. Each zone's gate price or rebirths, egg time, hatch time, odds, brainrot pool and hazards are in [`Biomes.luau`](src/shared/Biomes.luau). Vehicles, upgrades and paint jobs are in [`Vehicles.luau`](src/shared/Vehicles.luau). Gear is in [`Gear.luau`](src/shared/Gear.luau). Brainrot prices, income and catchphrases are in [`Brainrots.luau`](src/shared/Brainrots.luau).
- **Themes, events, quests and mutations:** each has its own list you can edit or add to: [`Themes.luau`](src/shared/Themes.luau), [`Events.luau`](src/shared/Events.luau), [`Quests.luau`](src/shared/Quests.luau) and [`Mutations.luau`](src/shared/Mutations.luau). Theme decorations are in [`HaveliStyle.luau`](src/server/HaveliStyle.luau).
- **The zones** are built from code in [`BiomeBuilder.luau`](src/server/BiomeBuilder.luau): terrain, the Blender props, chests and hazard areas. Each one is planned from a fixed seed, so the world is the same every time. The layout (ring sizes, region angles, where the gates, roads, shortcut doors and petrol pumps go, the train's track) is in `Biomes.luau`.
- **Brainrot models:** every brainrot has a Blender model (see [The 46 brainrots](#the-46-brainrots)). To use your own model instead, for example one you made from a character sheet's prompt, make a Folder named `Brainrots` in **ServerStorage** and put a Model in it named after the brainrot's `id`, for example `SamosaSupremo`, `RickshawRaptor` or `AmmiKiUdtiChappal`. All the ids are on the character sheets and in `Brainrots.luau`. Make the front of the model face its -Z side (the Studio default). The script anchors it and adds the name pop-up, the rarity glow and the mutation tint for you. Name its eye parts `Eye` and they keep their colour on Golden, Diamond and Rainbow brainrots.
- **The map:** press Play, select `ChaiChaosMap` in the Explorer, copy it, stop the game and paste it into Workspace. Now you can decorate it. Keep the names of the important parts (`ChowkSpawn`, `Leaderboard`, the stalls with a `Shop` attribute, and inside each haveli `Floor`, `Deck`, `Plot1` to `Plot20`, `Incubator1` to `Incubator4`, `Galla`, `Door`, `Barrier`, `Sign`, `Spawn`, `GuardSpot`, `Roof` and the `Walls`, `Trim`, `Accent`, `StairGates` and `Decor` folders, plus the `GateBarrier`, `ShortcutDoor` and `PumpPad` parts), and the game will use your version instead of building a new one. The terrain is not copied that way; the zones' eggs, chests and hazard areas still follow the plan in `BiomeBuilder.luau`.

## Not built yet

The kite-flying minigame became the **Basant Kite Festival** event instead. Brainrots stand still apart from bobbing and hopping (no walk cycles or animations yet), and wild and lane brainrots glide along their paths. Vehicles are still driven by moving your character (with car-like steering and a solid bumper that crashes), not by Roblox's physics car parts, so there is no suspension, drifting or rolling over. Still to come: an all-time leaderboard across servers, trading, real horn and engine sounds and other cosmetics, special behaviours for individual brainrots, and real music (the slots are ready).

## For developers

```bash
stylua src            # format
selene src            # lint (run `selene generate-roblox-std` once first)
tests/run.sh          # play through the whole game on a mock Roblox engine
tests/run.sh pacing   # simulate hundreds of players and print the pacing (see Pacing)
python blender/build.py --no-render   # rebuild the props and brainrots without the preview pictures
python blender/characters.py          # rewrite the brainrot character sheets in this README
python blender/chowk_preview.py       # render docs/chowk-preview.jpg, a picture of the Chowk
```

`tests/run.sh` loads the real scripts into the Luau VM with a mock of the Roblox engine. It checks every class, property, method, event and enum they touch against Roblox's API dump. Then it plays through the game (1995 checks): the world (havelis facing the Chowk, the stalls and bazaar shops, 12 zones in 4 regions and 3 rings with terrain, eggs, chests, hazard areas and their landmarks, prices that grow outward, zigzag gates, shortcut doors, roads, petrol pumps, the train schedule, the bazaar, the Mandi lane and its arch, every Blender prop as parts and as an imported mesh, and a part budget), every brainrot's Blender model (eyes, size limits, welds, mutation tints, imported meshes, custom models first, the parrot's tail lettering, and old saves with renamed brainrots), joining, picking up eggs, locked zones and unlocking gates, the egg timer and the radar, carrying eggs home, incubators, hatching from each zone's pool, cracking, dropping eggs, every hazard (including the train, waves and salt rocks that push you back) and the gear that stops it, the Gear shop, radar upgrades, golden eggs, egg rushes, hatch odds and luck (including Secret brainrots), selling at the stall, vehicles (the showroom, driving and steering, the solid bumper and crashes, horns, fuel, the boot, driving home, free refills, running out of petrol, petrol pumps, workshop upgrades, grip on mud and sand, paint jobs, friends riding along, parking, dying, and the rickshaw home that only takes people), wild brainrots (wandering, the radar, getting scared by vehicles and horns, catching, locked zones, full havelis, wandering off), the Mandi lane (walking round, prices, buying, walking off), the new-player guide (every step, skipping, starting again, the card and the beacon), the Menu (settings, promo codes, game passes, the daily streak, offline earnings), badges, safe saving (waiting for another server, never saving over a newer save, crashed servers) and the egg speed check, treasure (digging, climbing, cooldowns), haveli levels and incubators, themes, the galla, quests, Collection Book rewards, Kismat Rolls with their odds and pity, stealing with every rule (including eggs), the Chowkidar, the Laser Darwaza, chappal bonks on thieves and egg carriers, events and their boosts (with the Basant kites), Robux receipts (including retries and failed saves), the paid random item restriction, Chor Passes, Naya Safar at the Chowk, saving and loading (including eggs, zones and vehicles, and old saves), sounds and music slots, every theme at every level, the leaderboard and smooth movement. It needs Rust, Python 3 and curl. It catches scripting mistakes but is not a substitute for playtesting in Studio.
