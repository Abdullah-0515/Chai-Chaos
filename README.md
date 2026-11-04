# Chai Chaos

A Roblox collect-and-earn tycoon set in a loud Pakistani bazaar. Silly desi brainrots walk down Bazaar Lane, you buy them with rupees, they stand in your haveli and fill your galla with rupees every second. Then other players try to steal them.

The full game design is in [docs/game-design.md](docs/game-design.md). This repo is the first playable version of it.

## What works in this version

- **Bazaar Lane:** a new brainrot walks from the Spawn Gate to the Chowk every 4 seconds. Press **E** to buy it before it walks off.
- **All 36 brainrots** from the design doc, with their prices, income, catchphrases and spawn odds (Common 60%, Uncommon 25%, Rare 10%, Epic 4%, Legendary 0.9%, Mythic 0.1%). Chand Raat Cheetah only spawns at night.
- **8 havelis** with 10 plots each. You start with 3 plots and unlock more for Rs 500, 2,000, 5,000 and up.
- **Lockers:** plots 1 and 2 can never be robbed, and your two most valuable brainrots always move into them.
- **Galla:** every brainrot drops rupees into your galla (cash box) each second. Walk into it to collect.
- **Selling:** press E on your own brainrot to sell it for half price.
- **Stealing:** hold E for 1.5 seconds on someone else's brainrot. It rides on your back until you run through **your own** haveli door. The owner gets a "Chor! Chor!" alert and the thief is highlighted in red.
- **Getting it back:** every player has a **Chappal**. Bonk a thief with it and the brainrot walks home. Thieves who die, fall off the map, reset or leave also drop it.
- **Fair-play rules:** 15 second steal cooldown, no robbing the same haveli twice within 2 minutes, 3 minutes of protection after joining, and brainrots over Rs 8,000 can only be stolen by players who have rebirthed.
- **Taala (lock):** locks your haveli for 30 seconds, then needs 60 seconds to recharge.
- **Naya Safar (rebirth):** at Rs 1,000,000, reset your rupees and plots for +50% income forever and a new haveli colour.
- **Daily chai:** once a day you get a free brainrot or a rupee boost.
- **Collection Book:** fills in as you discover brainrots.
- **Ammi ki Udti Chappal:** when it appears, every other brainrot freezes in fear.
- **Saving** with DataStores: rupees, plots, brainrots, rebirths and your collection.

Not built yet (see the design doc): two-floor havelis and the rooftop kite minigame, events (festival nights, Basant, Cricket Mania), game passes and other monetization, special behaviours like the Load Shedding Lattoo going dark, sounds, and a physical leaderboard at the Chowk.

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
| `src/shared/*.luau` (Brainrots, Config, Format, Remotes) | `ReplicatedStorage > ChaiChaos` (a Folder) | ModuleScript |
| `src/server/Main.server.luau` | `ServerScriptService > ChaiChaosServer` (a Folder), named `Main` | Script |
| The other `src/server/*.luau` files (Havelis, MapBuilder, Models, Mover, PlayerData, Spawner, State, Stealing) | `ServerScriptService > ChaiChaosServer` | ModuleScript |
| `src/client/Hud.client.luau` and `Prompts.client.luau` | `StarterPlayer > StarterPlayerScripts > ChaiChaosClient` (a Folder), named `Hud` and `Prompts` | LocalScript |

### Studio settings

- **Game Settings > Players:** set max players to **8**, one per haveli.
- **Saving:** publish the place, then turn on **Game Settings > Security > Enable Studio Access to API Services**. Without this the game still works, it just starts fresh every time.

## Making it yours

- **Numbers:** every price, timer and odds value is in [`src/shared/Config.luau`](src/shared/Config.luau). Brainrot prices, income and catchphrases are in [`src/shared/Brainrots.luau`](src/shared/Brainrots.luau).
- **Brainrot models:** each brainrot starts as a blocky placeholder in its own colour, with eyes, a rarity ring and sparkles. To use your own model, make a Folder named `Brainrots` in **ServerStorage** and put a Model in it named after the brainrot's `id`, for example `SamosaSupremo`, `RickshawRaptor` or `AmmiKiUdtiChappal`. All the ids are in `Brainrots.luau`. Make the front of the model face its -Z side (the Studio default). The script anchors it and adds the name pop-up and the rarity glow for you.
- **The map:** press Play, select `ChaiChaosMap` in the Explorer, copy it, stop the game and paste it into Workspace. Now you can decorate it. Keep the names of the important parts (`SpawnGate`, `LaneEnd`, and inside each haveli `Floor`, `Plot1` to `Plot10`, `Galla`, `Door`, `Barrier`, `Sign`, `Spawn`, `Walls`), and the game will use your version instead of building a new one.

## For developers

```bash
stylua src            # format
selene src            # lint (run `selene generate-roblox-std` once first)
tests/run.sh          # play through the whole game on a mock Roblox engine
```

`tests/run.sh` loads the real scripts into the Luau VM with a mock of the Roblox engine. It checks every class, property, method, event and enum they touch against Roblox's API dump. Then it plays through the game: joining, buying, plots and lockers, the galla, stealing and every steal rule, the chappal, the Taala, selling, rebirth, saving and rejoining, spawn odds, the night-only cheetah and the chappal freeze. It needs Rust, Python 3 and curl. It catches scripting mistakes but is not a substitute for playtesting in Studio.
