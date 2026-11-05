# Chai Chaos

A Roblox collect-and-earn tycoon set in a loud Pakistani bazaar. Silly desi brainrots walk down Bazaar Lane, you buy them with rupees, they stand in your haveli and fill your galla with rupees every second. Then other players try to steal them.

The full game design is in [docs/game-design.md](docs/game-design.md). This repo builds the full game from it.

## Three ways to get a brainrot

1. **Bazaar Lane (the conveyor belt):** buy brainrots with rupees as they walk past.
2. **Kismat Roll (RNG):** roll for a random brainrot with Rs 5,000 or with a Kismat Roll. Rolls come free with daily chai and quests, and players can buy packs with Robux.
3. **Stealing:** every steal uses a **Chor Pass**, bought with Robux. If the steal fails (the thief gets bonked, caught by the Chowkidar, dies or the owner leaves), the thief gets the Chor Pass back.

## What is in the game

**The bazaar**
- A long, bright Bazaar Lane with string lights, bunting, palm trees, chai and paratha stalls, fruit carts and parked rickshaws. At the end is the Chowk, with a fountain, the giant Kismat Kettle and a leaderboard of the top players.
- Warm, colourful lighting with a day and night cycle. Nights pass twice as fast.
- Brainrots walk, hop and bob smoothly on every screen. Each player's screen animates them, so they don't stutter.

**Brainrots**
- All 36 brainrots from the design doc, with their catchphrases and spawn odds (Common 60%, Uncommon 25%, Rare 10%, Epic 4%, Legendary 0.9%, Mythic 0.1%). Chand Raat Cheetah only spawns at night, Pakora Panda only in the rain (Baarish) and Gajar Halwa Gorilla only in winter (Sardi).
- **Mutations:** any brainrot can appear as a Golden (x2 income), Diamond (x4) or Rainbow (x8) version. They glitter, and Rainbow ones change colour.
- **6 special quest brainrots** (Mithai Mamu, Lassi Lightning, Chowkidar Choocha, Rangeela Raja, Shalimar Sultan and Taaron Wala Tonga), earned from the Collection Book. They can't be stolen or sold.

**Havelis**
- 8 big havelis with a courtyard, stairs, a second floor and a rooftop. Everyone starts with **Rs 1,000**.
- **9 haveli levels**, from 4 plots up to 20. Level 3 adds the **Laser Darwaza** (your Taala physically blocks the door, and anyone inside gets moved out). Level 4 adds a garden, level 5 opens the **second floor**, level 6 hires a **Chowkidar** who catches thieves, and level 8 adds a rooftop with chhatris and kites.
- **8 themes**, each with its own colours, decorations and a small perk: Mughal Marble (+5% income), Bagh Garden (thieves 15% slower), Truck Art (walk 12% faster), Chai Dhaba (cheaper Kismat Rolls), Sheesh Mahal (longer Taala), Basant Rooftop (mutations twice as likely in your rolls), Cricket Maidan (chappal reaches twice as far) and Mela Lights (+25% income during events). The first two are free; each Naya Safar unlocks the next.
- **Lockers:** plots 1 and 2 can never be robbed, and your two most valuable brainrots always move into them.
- **Galla:** every brainrot drops rupees into your galla each second. Walk into it to collect.

**Stealing and defending**
- Hold E on someone else's brainrot. It rides on your back until you run through your own haveli door, and you walk slower the rarer it is.
- The owner gets a "Chor! Chor!" alert, the thief is highlighted, and anyone can bonk the thief with their **Chappal**.
- **Fair-play rules:** a 15 second steal cooldown, no robbing the same haveli twice within 2 minutes, 3 minutes of protection after joining, and brainrots worth over Rs 16,000 can only be stolen by players who have rebirthed.
- **Taala (lock):** locks your haveli for 30 seconds, then needs 60 seconds to recharge.

**Progress**
- **Naya Safar (rebirth):** reset your rupees, haveli level and brainrots for +50% income forever and a new theme. The first costs Rs 1,000,000 and each one after costs 2.5 times more.
- **Daily quests:** 3 quests a day (buy brainrots, collect from your galla, find a mutation, upgrade your haveli and more). They pay rupees and Kismat Rolls, plus 2 bonus rolls for finishing all three.
- **Collection Book:** fills in as you find brainrots and their mutations. Finishing a rarity pays rupees and Kismat Rolls, plus that rarity's special quest brainrot (claimable again after every Naya Safar).
- **Events:** every 15-20 minutes a 5 minute event starts: Baarish (rain, +20% income), Basant Kite Night (kites, mutations x2), Cricket Mania (+50% income), Load Shedding (blackout, night brainrots, Diamond and Rainbow x3), Mela Night (fireworks, rolls 30% off) and Sardi (snow, faster spawns).
- **Daily chai:** a free brainrot or rupees, plus a free Kismat Roll, once a day.
- **Kismat Roll:** the odds for every rarity and mutation are shown before anyone rolls, including any boost from your theme or the current event. A roll animation reveals the result, and an Epic or better is guaranteed at least every 30 rolls.
- **Robux packs:** 1 or 10 Kismat Rolls, and 1 or 5 Chor Passes. Purchases are saved straight away and are never granted twice.
- **Saving** with DataStores: everything above.

Not built yet: the rooftop kite-flying minigame, the 2x Cash and Extra Plots game passes, the Lucky Spawn product and cosmetics, special behaviours like the Load Shedding Lattoo going dark, and sounds.

## Pacing

The economy is tuned so a typical kid reaches their first Naya Safar in about an hour. A simulation of different players (fast, typical and casual, with 8 players sharing one lane) put the first rebirth at about 34, 42 and 51 minutes. Real players walk around, get robbed and play less efficiently, so about an hour is the expected result. All brainrot prices are the design doc's prices times `PRICE_MULTIPLIER = 2` in `Config.luau`. Raise it to slow the game down, lower it to speed it up.

## Getting it into Roblox Studio

The code uses the [Rojo](https://rojo.space) layout, but you can use it without Rojo.

### Option A: open the place file (easiest)

If you have Rojo installed, build a ready-to-play place file:

```bash
rojo build -o ChaiChaos.rbxlx
```

Open `ChaiChaos.rbxlx` in Roblox Studio and press **Play**. The bazaar builds itself when the game starts.

### Option B: live sync with Rojo

1. Install Rojo and its Studio plugin ([guide](https://rojo.space/docs/v7/getting-started/installation/)).
2. Run `rojo serve` in this folder.
3. In Studio, open a new Baseplate place, click **Rojo > Connect**, then press **Play**.

### Option C: copy the scripts by hand

Create these in Roblox Studio, then paste in each file's code. The name in Studio must match exactly (no `.luau`, no `.server` or `.client`).

| File | Create in Studio | Type |
| --- | --- | --- |
| All 9 `src/shared/*.luau` files (Brainrots, Config, Events, Format, Motion, Mutations, Quests, Remotes, Themes) | `ReplicatedStorage > ChaiChaos` (a Folder) | ModuleScript |
| `src/server/Main.server.luau` | `ServerScriptService > ChaiChaosServer` (a Folder), named `Main` | Script |
| The other 16 `src/server/*.luau` files | `ServerScriptService > ChaiChaosServer` | ModuleScript |
| The 7 `src/client/*.client.luau` files (Events, Haveli, Hud, Kismat, Prompts, Quests, Smooth) | `StarterPlayer > StarterPlayerScripts > ChaiChaosClient` (a Folder) | LocalScript |
| `src/client/Ui.luau` | `StarterPlayer > StarterPlayerScripts > ChaiChaosClient`, named `Ui` | ModuleScript |

With this many files, Option A or B is much easier.

### Studio settings

- **Game Settings > Players:** set max players to **8**, one per haveli.
- **Saving:** publish the place, then turn on **Game Settings > Security > Enable Studio Access to API Services**. Without this the game still works, it just starts fresh every time.

## Setting up the Robux packs

The Robux buttons stay hidden, and stealing stays free, until you create the products:

1. Publish the game, then open it on the [Creator Dashboard](https://create.roblox.com/dashboard/creations).
2. Go to **Monetization > Developer Products** and create four products: "1 Kismat Roll", "10 Kismat Rolls", "1 Chor Pass" and "5 Chor Passes". Set each price there.
3. Copy each product's id into `Config.ROLL_PRODUCTS` and `Config.STEAL_PRODUCTS` in [`src/shared/Config.luau`](src/shared/Config.luau).

In Studio, purchases are test purchases and cost nothing.

Other settings in `Config.luau`: `STEAL_COSTS_ROBUX = false` makes stealing free, `STEAL_REFUND_ON_FAIL` controls whether failed steals give the Chor Pass back, and `DAILY_FREE_ROLLS` / `DAILY_FREE_STEALS` set what daily chai gives.

**Roblox rules for paid random items.** Kismat Rolls bought with Robux count as paid random items on Roblox. The game already shows the exact odds before anyone buys. It also never offers Robux rolls to players in countries where Roblox restricts paid random items (it asks `PolicyService` for each player). Those players can still roll with rupees. Before you publish, read Roblox's current rules on paid random items on the Creator Hub, and answer the experience questionnaire honestly. If you change `Config.ROLL_ODDS`, the odds shown in the game update by themselves.

## Making it yours

- **Numbers:** every price, timer, haveli level and odds value is in [`src/shared/Config.luau`](src/shared/Config.luau). Brainrot prices, income and catchphrases are in [`src/shared/Brainrots.luau`](src/shared/Brainrots.luau).
- **Themes, events, quests and mutations:** each has its own list you can edit or add to: [`Themes.luau`](src/shared/Themes.luau), [`Events.luau`](src/shared/Events.luau), [`Quests.luau`](src/shared/Quests.luau) and [`Mutations.luau`](src/shared/Mutations.luau). Theme decorations are in [`HaveliStyle.luau`](src/server/HaveliStyle.luau).
- **Brainrot models:** each brainrot starts as a blocky placeholder in its own colour, with eyes, a rarity ring and sparkles. To use your own model, make a Folder named `Brainrots` in **ServerStorage** and put a Model in it named after the brainrot's `id`, for example `SamosaSupremo`, `RickshawRaptor` or `AmmiKiUdtiChappal`. All the ids are in `Brainrots.luau`. Make the front of the model face its -Z side (the Studio default). The script anchors it and adds the name pop-up and the rarity glow for you.
- **The map:** press Play, select `ChaiChaosMap` in the Explorer, copy it, stop the game and paste it into Workspace. Now you can decorate it. Keep the names of the important parts (`SpawnGate`, `LaneEnd`, `Leaderboard`, and inside each haveli `Floor`, `Deck`, `Plot1` to `Plot20`, `Galla`, `Door`, `Barrier`, `Sign`, `Spawn`, `GuardSpot`, `Roof` and the `Walls`, `Trim`, `Accent`, `StairGates` and `Decor` folders), and the game will use your version instead of building a new one.

## For developers

```bash
stylua src            # format
selene src            # lint (run `selene generate-roblox-std` once first)
tests/run.sh          # play through the whole game on a mock Roblox engine
```

`tests/run.sh` loads the real scripts into the Luau VM with a mock of the Roblox engine. It checks every class, property, method, event and enum they touch against Roblox's API dump. Then it plays through the game (325 checks): joining, buying, mutations, haveli levels, the second floor and stairs, themes and their perks, every theme at every level, the galla, quests and Collection Book rewards, Kismat Rolls with their odds, boosts and pity, stealing with every rule, the slowdown, the Chowkidar and the Laser Darwaza, the chappal, selling, Naya Safar, events, Robux receipts (including retries and failed saves), the paid random item restriction, Chor Pass steals and refunds, saving, loading old saves, spawn odds, the chappal freeze, the leaderboard and the smooth movement on screen. It needs Rust, Python 3 and curl. It catches scripting mistakes but is not a substitute for playtesting in Studio.
