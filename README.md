# Chai Chaos

A Roblox egg-hunting, collect-and-earn game set in a loud Pakistani bazaar. Eight havelis stand in a ring around the **Chowk**. Open your radar, follow a road through the countryside into one of **8 biomes**, grab an egg and get it home before it cracks. Eggs hatch into silly desi brainrots that fill your galla with rupees every second. Then other players try to steal them.

Every biome has its own landmark, plants and desi props, all modelled in Blender (see [3D models](#3d-models-blender)).

The original design is in [docs/game-design.md](docs/game-design.md). All 36 brainrots and their catchphrases come from it.

![The world from above](docs/world-map.png)

## How a round of play goes

1. **Spawn in your haveli.** Everyone starts with **Rs 1,000** and one incubator.
2. **Check the radar** (bottom right). It shows eggs near you, an **H** for home and a **C** for the Chowk. If no egg is in range, a pip on the edge points to the nearest one.
3. **Run out through a gate** into a biome. Further biomes have rarer brainrots, but their eggs crack sooner.
4. **Pick up an egg** (hold E). A timer starts. Hazards knock time off, and other players can bonk you with a chappal to make you drop it.
5. **Get it home.** Walk into your haveli and the egg goes into a free incubator. A little later it hatches, and the brainrot walks to a plot and starts earning.
6. **Spend your rupees at the Chowk:** better gear, a better radar, haveli upgrades, Kismat Rolls, and finally a **Naya Safar** (rebirth).

## Four ways to get a brainrot

1. **Eggs (the main way):** find them in the biomes and carry them home. What hatches depends on the biome.
2. **Kismat Roll (RNG):** roll at the Kismat Kettle with Rs 5,000 or a Kismat Roll. Rolls come free with daily chai and quests, and players can buy packs with Robux.
3. **Stealing:** grab someone else's brainrot and run it through your own door. Every steal uses a **Chor Pass** (bought with Robux; you get it back if the steal fails).
4. **Collection Book rewards:** finish a rarity to earn one of 6 special quest brainrots.

## The world

**The Chowk** is a round plaza with a fountain in the middle and everything you need around it:

| Stall | What it does |
| --- | --- |
| **BECHO (Sell)** | Opens the Brainrots window with Sell buttons. Sell any brainrot for half its value. |
| **GEAR SHOP** | Speed, egg, treasure and hazard gear (see below). |
| **RADAR WALA** | Tracker upgrades. |
| **KISMAT KETTLE** | Kismat Rolls, with the odds shown. |
| **NAYA SAFAR** | The rebirth gate. |
| **QUESTS** board | Daily quests and Collection Book rewards. |

There is also a chai dhaba with a charpai, parked rickshaws, a fruit cart, a leaderboard and string lights. Eight roads lead out between the havelis, each with a road sign by the Chowk and a bunting-covered gate at the biome.

**The countryside.** The biomes are separate zones with open countryside between them. Along the roads: milestones counting down to each biome, chai dhabas with charpais and a parked truck-art truck or rickshaw, bus stops, and fruit, pakora and gola ganda stalls near the gates. In the open land: little farms (wheat, sarson and sugarcane fields, a tube well, haystacks, tractors and mud houses), ponds with reeds, kikar and mango trees, rocks, street cricket and kites.

**The 8 biomes**, from closest to furthest:

| Tier | Biome | Landmark and details | Egg lasts | Hatches in | Best rarity | Hazards | Gear that helps |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | **Khet** (Punjab fields) | A **rehat** (Persian water wheel) on a canal; wheat and sarson fields, a village of mud houses with charpais, a tandoor, matkas, a tube well, the water tank, a tractor, haystacks, kites | 60 s | 15 s | Rare 5% | muddy rice paddies | Gum Boots |
| 2 | **Jungle** (forest and river) | A **treehouse** in a giant tree with a rope ladder, a **rope bridge** over the river, the waterfall cliff; banyan trees, bamboo, ferns, mossy rocks | 55 s | 25 s | Epic 3% | the river | Life Jacket |
| 3 | **Samandar** (Arabian Sea beach) | A striped **lighthouse** on the island; coconut palms, beach huts, colourful fishing boats, nets, umbrellas, a gola ganda cart | 51 s | 35 s | Legendary 2% | the sea, big waves | Life Jacket |
| 4 | **Jheel** (lake and meadows) | A **rest house** with a veranda and a long **jetty** with rowing boats; willows, poplars, reeds, lily pads, wild flowers, snowy peaks | 46 s | 45 s | Legendary 4% | the lake | Life Jacket |
| 5 | **Registan** (Cholistan desert) | An old **desert fort** with round towers, a gate, a well and stairs to the walls; dunes, tents, sandstone rocks, dry kikar trees, camels | 42 s | 55 s | Mythic 1% | sandstorms | Sand Goggles |
| 6 | **Delta** (Indus mangroves) | A **stilt fishing village** with walkways and a pier over its pool; mangroves, reeds, nets, boats | 37 s | 65 s | Mythic 2% | mud everywhere, pools | Gum Boots, Life Jacket |
| 7 | **Pahar** (Karakoram mountains) | A **suspension bridge** over the gorge between two ridges, a stone **mountain hut**; snowy deodars, junipers, a frozen lake | 33 s | 75 s | Mythic 4% | ice, flying snowballs | Snow Boots |
| 8 | **Namak Kaan** (pink salt caves) | The **mine entrance**, a mine-cart track with carts along the tunnel, timber supports, a crystal cavern with giant glowing crystals | 28 s | 85 s | Mythic 9% | darkness, falling salt | Lantern |

![Each biome from above](docs/biome-zones.png)

Each biome has its own egg colours, its own pool of brainrots (every brainrot hatches somewhere, and the Collection Book tells you where), at least two treasure chests, and a big title when you walk in.

## Eggs

- Each biome keeps 7 eggs lying around and refills them over time.
- **The timer:** an egg cracks when its time runs out. Standing in water or a sandstorm makes it crack twice as fast; waves, snowballs and falling salt knock 8 seconds off. Inside your own haveli the timer stops.
- **Incubators:** 1 at haveli level 1, 2 at level 3, 3 at level 5 and 4 at level 7. If they are all busy, keep holding your egg at home until one frees up. Eggs keep hatching while you are offline.
- **Golden eggs** (3%) sparkle, last a bit longer, are twice as lucky and always hatch a Golden, Diamond or Rainbow brainrot. Normal eggs hatch mutated about 5% of the time.
- **Egg rushes:** every 4 minutes one biome fills up with extra eggs for 60 seconds.
- You can carry one egg at a time. A chappal bonk makes you drop it, and anyone can grab it (with the time it had left). You cannot steal while holding an egg, or pick one up while carrying a stolen brainrot.

## The radar (Radar Wala)

| Level | Cost | Tracks eggs in | Range | Extras |
| --- | --- | --- | --- | --- |
| 1 | free | Khet | 150 | |
| 2 | Rs 2,500 | + Jungle | 180 | |
| 3 | Rs 8,000 | + Samandar | 210 | golden eggs |
| 4 | Rs 25,000 | + Jheel | 240 | golden eggs |
| 5 | Rs 70,000 | + Registan | 270 | golden eggs, treasure |
| 6 | Rs 160,000 | + Delta | 300 | golden eggs, treasure |
| 7 | Rs 320,000 | + Pahar | 340 | golden eggs, treasure |
| 8 | Rs 600,000 | + Namak Kaan | 400 | golden eggs, treasure |

Every biome is open from the start; the radar just helps you find things. The radar also shows the timer of the egg you carry, hazard warnings and egg rushes.

## Gear (Gear Shop)

Gear is bought once and kept forever, even after a Naya Safar. It works by itself.

| Gear | Cost | What it does |
| --- | --- | --- |
| Joggers | Rs 3,000 | Run 10% faster |
| Gum Boots | Rs 5,000 | No more getting stuck in mud |
| Padded Tokri | Rs 6,000 | Eggs last 25% longer |
| Life Jacket | Rs 8,000 | Swim fast, eggs safe from water and waves |
| Belcha (shovel) | Rs 20,000 | Dig up buried treasure |
| Sand Goggles | Rs 30,000 | See and run through sandstorms |
| Rassi Seedhi (rope ladder) | Rs 40,000 | Climb to treasure on cliffs, towers and stilt huts |
| Peshawari Chappal | Rs 60,000 | Run 25% faster |
| Thermos Dabba | Rs 80,000 | Eggs last 60% longer |
| Snow Boots | Rs 120,000 | No slipping on ice, snowballs miss you |
| Lantern | Rs 200,000 | Light up the salt caves, dodge falling salt |

## Riding

Open the **Brainrots** window (the button on the left) and press **Ride** on any brainrot. It leaves its plot and carries you everywhere, faster the rarer it is (Common +15%, Uncommon +25%, Rare +40%, Epic +60%, Legendary +80%, Mythic +110%, and a bit more for mutations). Your ride doesn't earn rupees; the rest stay home and farm. Press **Stop riding** and it walks back to a plot. Your ride is saved and comes back when you respawn or rejoin.

## Treasure

Every biome hides treasure chests. Buried ones (under a red X) need a **Belcha**; high ones need a **Rassi Seedhi** to climb up from the glowing spot: the Khet water tank's lid, the lighthouse gallery, a desert fort tower, a stilt-hut roof, rock pillars and a ledge in the salt cavern. A chest pays more in further biomes (Rs 1,500 times the tier squared) and sometimes a free Kismat Roll. Each player can open each chest once every 10 minutes.

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

- **Naya Safar (rebirth)** at the gate in the Chowk: starts over your rupees, haveli level, radar, brainrots, eggs and ride, for +50% income forever and a new theme. You keep your gear, themes, Collection Book, Kismat Rolls and Chor Passes. The first costs Rs 1,000,000 and each one after costs 2.5 times more.
- **Daily quests:** 3 a day, like bringing eggs home from different biomes, hatching a Rare, a golden egg, opening treasure, upgrading your haveli or radar, collecting from your galla. They pay rupees and Kismat Rolls, plus 2 bonus rolls for finishing all three.
- **Collection Book:** fills in as you find brainrots and their mutations, and says which biomes each one hatches in. Finishing a rarity pays rupees and Kismat Rolls, plus that rarity's special quest brainrot.
- **Events** every 15-20 minutes, 5 minutes each. The banner shows the boosts:
  - **Basant Kite Festival:** kites fill the sky all around you. Cash x2, Luck x2.
  - **Baarish:** rain, twice as many eggs, +20% cash.
  - **Cricket Mania:** confetti, cash x1.5.
  - **Load Shedding:** night falls, Luck x3.
  - **Mela Night:** fireworks, eggs hatch twice as fast, Kismat Rolls 30% off.
  - **Sardi:** snow, eggs last 50% longer.
- **Daily chai:** a free brainrot or rupees, plus a free Kismat Roll, once a day.
- **Kismat Roll:** the odds for every rarity and mutation are shown before anyone rolls. An Epic or better is guaranteed at least every 30 rolls.
- **Robux packs:** 1 or 10 Kismat Rolls, and 1 or 5 Chor Passes. Purchases are saved straight away and never granted twice.
- **Saving** with DataStores: everything above, including eggs in incubators and your ride.

## Sounds

The game uses sounds that come with Roblox for buttons, coins, eggs (pick up, home, crack, hatch), treasure, bonks, the Chor alert, splashes, wind in the mountains and desert, upgrades, events and the Kismat Roll. They are all listed in [`src/shared/Sounds.luau`](src/shared/Sounds.luau).

There are three music slots, `MusicBazaar`, `MusicBiome` and `MusicEvent`, empty until you add your own: find a track in the Creator Store (Toolbox > Audio, try "dhol", "tabla" or "bazaar"), copy its id and paste it as `"rbxassetid://123456789"`. The right track plays for where you are. You can swap any other sound the same way, for example to add voice lines.

## 3D models (Blender)

All the landmarks, plants and props are modelled in **Blender** with Python scripts in [`blender/`](blender/), in a low-poly, flat-colour style that matches the blocky brainrots and runs well on phones. There are 74 of them:

- **Landmarks:** rehat, treehouse, rope bridge, lighthouse, rest house, jetty, desert fort, stilt village, suspension bridge, mountain hut, crystal cluster, mine entrance, mine track, mine cart, cave support.
- **Plants and nature:** kikar (green and dry), mango, banyan, jungle tree, bamboo, bushes, ferns, coconut palm, willow, poplar, deodar (green and snowy), mangrove, juniper, desert shrub, dune grass, reeds, wild flowers, lily pads, boulders, mossy, snowy and beach rocks, sandstone rocks, salt crystals, stalagmites, wheat, sarson and sugarcane fields.
- **Desi props:** charpai, milestone, matkas, tube well, chai dhaba, fruit stall, pakora stall, gola ganda cart, truck-art truck, auto rickshaw, tractor and trolley, bus stop, road sign, tandoor, haystack, mud house, water tank, beach huts, fishing boat, rowing boat, net rack, desert tent, beach umbrella, lamp post, kite line, bench, street cricket.

| Landmarks | Plants and nature | Desi props |
| --- | --- | --- |
| ![Landmarks](docs/props/landmark.jpg) | ![Plants](docs/props/plant.jpg) | ![Desi props](docs/props/desi.jpg) |

**How the game uses them.** `blender/build.py` turns every model into two things:

1. **Roblox parts** in [`src/server/PropData.luau`](src/server/PropData.luau). The game builds every prop out of parts by itself, so it all works with no importing.
2. **Meshes** in [`assets/props/ChaiChaosProps.fbx`](assets/props/ChaiChaosProps.fbx): one smoother mesh per prop, all coloured from one small palette texture. If you import them, the game uses them instead of the parts and keeps the parts as invisible walls, so you can still walk on the bridges, jetty and decks. Glowing and see-through pieces (lamps, crystals, glass) always stay parts.

**Importing the meshes into Studio (optional, once):**

1. Make sure you are logged in to Studio: the importer uploads the meshes to your account.
2. **File > Import 3D**, pick `assets/props/ChaiChaosProps.fbx` and import it. It comes in as one model with 74 meshes, each named after its prop (`Rehat`, `Lighthouse`, `KikarTree`...).
3. Rename that model to **`ChaiChaosProps`** and drag it into **ServerStorage**.
4. Press Play. Every prop that has a matching mesh uses it.

The game resizes each mesh to the right size and stands it up if the importer laid it on its side. If every mesh faces backwards, set `Config.PROP_MESH_TURN = 180`.

**Changing the models.** Open [`assets/props/ChaiChaosProps.blend`](assets/props/ChaiChaosProps.blend) in Blender to look at everything. To change a prop, edit its Python in `blender/props_landmarks.py`, `props_plants.py` or `props_desi.py` (the helpers are in `blender/kit.py`), then rebuild everything:

```bash
pip install bpy==5.2.3          # Blender as a Python module (needs Python 3.13)
python blender/build.py         # writes PropData.luau, the FBX, the .blend and the previews
```

Where each prop goes in the world is in [`BiomeBuilder.luau`](src/server/BiomeBuilder.luau) (the biomes) and [`MapBuilder.luau`](src/server/MapBuilder.luau) (the Chowk and the countryside).

## Pacing

A simulation of the egg loop (walking, radar, gear, incubators, riding and hatch odds) puts the first Naya Safar at about **37, 51 and 67 minutes** for fast, typical and casual players. All brainrot prices are the design doc's prices times `PRICE_MULTIPLIER = 2` in `Config.luau`. Raise it to slow the game down, lower it to speed it up. Egg times, hatch times and odds per biome are in `Biomes.luau`.

## Getting it into Roblox Studio

The code uses the [Rojo](https://rojo.space) layout, but you can use it without Rojo.

### Option A: open the place file (easiest)

If you have Rojo installed, build a ready-to-play place file:

```bash
rojo build -o ChaiChaos.rbxlx
```

Open `ChaiChaos.rbxlx` in Roblox Studio and press **Play**. The world builds itself when the game starts (it takes a few seconds; the terrain is big).

### Option B: live sync with Rojo

1. Install Rojo and its Studio plugin ([guide](https://rojo.space/docs/v7/getting-started/installation/)).
2. Run `rojo serve` in this folder.
3. In Studio, open a new Baseplate place, click **Rojo > Connect**, then press **Play**.

### Option C: copy the scripts by hand

Create these in Roblox Studio, then paste in each file's code. The name in Studio must match exactly (no `.luau`, no `.server` or `.client`).

| File | Create in Studio | Type |
| --- | --- | --- |
| All 12 `src/shared/*.luau` files (Biomes, Brainrots, Config, Events, Format, Gear, Motion, Mutations, Quests, Remotes, Sounds, Themes) | `ReplicatedStorage > ChaiChaos` (a Folder) | ModuleScript |
| `src/server/Main.server.luau` | `ServerScriptService > ChaiChaosServer` (a Folder), named `Main` | Script |
| The other 24 `src/server/*.luau` files | `ServerScriptService > ChaiChaosServer` | ModuleScript |
| The 11 `src/client/*.client.luau` files (Events, Haveli, Hud, Kismat, Prompts, Quests, Radar, Shops, Smooth, Sounds, Weather) | `StarterPlayer > StarterPlayerScripts > ChaiChaosClient` (a Folder) | LocalScript |
| `src/client/Ui.luau` and `src/client/SoundPlayer.luau` | `StarterPlayer > StarterPlayerScripts > ChaiChaosClient` | ModuleScript |

With this many files, Option A or B is much easier.

### Studio settings

- **Game Settings > Players:** set max players to **8**, one per haveli.
- **Workspace > StreamingEnabled** should be on (the Rojo project turns it on). The world is big, and streaming keeps it smooth on phones. Eggs and treasure chests always stream in, so the radar can see them.
- **Saving:** publish the place, then turn on **Game Settings > Security > Enable Studio Access to API Services**. Without this the game still works, it just starts fresh every time.

## Setting up the Robux packs

The Robux buttons stay hidden, and stealing stays free, until you create the products:

1. Publish the game, then open it on the [Creator Dashboard](https://create.roblox.com/dashboard/creations).
2. Go to **Monetization > Developer Products** and create four products: "1 Kismat Roll", "10 Kismat Rolls", "1 Chor Pass" and "5 Chor Passes". Set each price there.
3. Copy each product's id into `Config.ROLL_PRODUCTS` and `Config.STEAL_PRODUCTS` in [`src/shared/Config.luau`](src/shared/Config.luau).

In Studio, purchases are test purchases and cost nothing.

Other settings in `Config.luau`: `STEAL_COSTS_ROBUX = false` makes stealing free, `STEAL_REFUND_ON_FAIL` controls whether failed steals give the Chor Pass back, and `DAILY_FREE_ROLLS` / `DAILY_FREE_STEALS` set what daily chai gives.

**Roblox rules for paid random items.** Kismat Rolls bought with Robux count as paid random items on Roblox. The game shows the exact odds before anyone buys, and never offers Robux rolls to players in countries where Roblox restricts paid random items (it asks `PolicyService` for each player). Those players can still roll with rupees. Before you publish, read Roblox's current rules on paid random items on the Creator Hub, and answer the experience questionnaire honestly. Eggs, gear and the radar are never sold for Robux, and no guaranteed top-rarity brainrot is ever sold.

## Making it yours

- **Numbers:** prices, timers, haveli levels, incubators, radar levels, hazards and odds are in [`Config.luau`](src/shared/Config.luau). Each biome's egg time, hatch time, odds, brainrot pool and hazards are in [`Biomes.luau`](src/shared/Biomes.luau). Gear is in [`Gear.luau`](src/shared/Gear.luau). Brainrot prices, income and catchphrases are in [`Brainrots.luau`](src/shared/Brainrots.luau).
- **Themes, events, quests and mutations:** each has its own list you can edit or add to: [`Themes.luau`](src/shared/Themes.luau), [`Events.luau`](src/shared/Events.luau), [`Quests.luau`](src/shared/Quests.luau) and [`Mutations.luau`](src/shared/Mutations.luau). Theme decorations are in [`HaveliStyle.luau`](src/server/HaveliStyle.luau).
- **The biomes** are built from code in [`BiomeBuilder.luau`](src/server/BiomeBuilder.luau): terrain, the Blender props, chests and hazard zones. Each one is planned from a fixed seed, so the world is the same every time. The zones' shape and size are in `Biomes.luau` (`ZONE_WIDTH`).
- **Brainrot models:** each brainrot starts as a blocky placeholder in its own colour, with eyes, a rarity ring and sparkles. To use your own model, make a Folder named `Brainrots` in **ServerStorage** and put a Model in it named after the brainrot's `id`, for example `SamosaSupremo`, `RickshawRaptor` or `AmmiKiUdtiChappal`. All the ids are in `Brainrots.luau`. Make the front of the model face its -Z side (the Studio default). The script anchors it and adds the name pop-up and the rarity glow for you.
- **The map:** press Play, select `ChaiChaosMap` in the Explorer, copy it, stop the game and paste it into Workspace. Now you can decorate it. Keep the names of the important parts (`ChowkSpawn`, `Leaderboard`, the stalls with a `Shop` attribute, and inside each haveli `Floor`, `Deck`, `Plot1` to `Plot20`, `Incubator1` to `Incubator4`, `Galla`, `Door`, `Barrier`, `Sign`, `Spawn`, `GuardSpot`, `Roof` and the `Walls`, `Trim`, `Accent`, `StairGates` and `Decor` folders), and the game will use your version instead of building a new one. The terrain is not copied that way; the biomes' eggs, chests and hazard zones still follow the plan in `BiomeBuilder.luau`.

## Not built yet

The kite-flying minigame became the **Basant Kite Festival** event instead. Brainrots themselves are still blocky placeholders (they could be modelled in Blender the same way). Still to come: the 2x Cash and Extra Plots game passes, cosmetics, special behaviours for individual brainrots, and real music (the slots are ready).

## For developers

```bash
stylua src            # format
selene src            # lint (run `selene generate-roblox-std` once first)
tests/run.sh          # play through the whole game on a mock Roblox engine
python blender/build.py --no-render   # rebuild the props without the preview pictures
```

`tests/run.sh` loads the real scripts into the Luau VM with a mock of the Roblox engine. It checks every class, property, method, event and enum they touch against Roblox's API dump. Then it plays through the game (888 checks): the world (havelis facing the Chowk, the stalls, 8 separate biome zones with terrain, eggs, chests, hazard zones and their landmarks, the countryside and its rules, every Blender prop as parts and as an imported mesh, and a part budget), joining, picking up eggs, the egg timer and the radar, carrying eggs home, incubators, hatching from each biome's pool, cracking, dropping eggs, every hazard and the gear that stops it, the Gear shop, radar upgrades, golden eggs, egg rushes, hatch odds and luck, riding (speed, respawning, stopping), selling at the stall, treasure (digging, climbing, cooldowns), haveli levels and incubators, themes, the galla, quests, Collection Book rewards, Kismat Rolls with their odds and pity, stealing with every rule (including eggs), the Chowkidar, the Laser Darwaza, chappal bonks on thieves and egg carriers, events and their boosts (with the Basant kites), Robux receipts (including retries and failed saves), the paid random item restriction, Chor Passes, Naya Safar at the Chowk, saving and loading (including eggs and rides, and old saves), sounds and music slots, every theme at every level, the leaderboard and smooth movement. It needs Rust, Python 3 and curl. It catches scripting mistakes but is not a substitute for playtesting in Studio.
