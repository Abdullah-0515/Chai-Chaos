"""Character sheets for all 42 brainrots, written into README.md.

Each sheet has the look and personality, a colour palette with hex codes (the
same colours the Blender models use, from kit.py) and a ready-to-paste prompt
for an image or 3D generator such as ChatGPT. Prices, rarities and biomes come
from the game's own data files, so the sheets never drift from the game.

Run it with plain Python (no Blender needed). build.py also runs it.

    python blender/characters.py
"""

import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
README = os.path.join(ROOT, "README.md")
START = "<!-- characters:start -->"
END = "<!-- characters:end -->"

RARITY_ORDER = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Special"]
MAX_FOOTPRINT, MAX_HEIGHT = 7.4, 7.6  # the same limits as Models.luau

STYLE = (
    "Style: chunky and cute, low-poly with flat colours (no textures, no gradients), soft rounded toy-like "
    "shapes, big round cartoon eyes (white with a black pupil and a small white shine), friendly and funny, "
    "made for kids."
)

# id: (look and personality, [(colour label, kit.py colour name)], what to draw)
CHARACTERS = {
    # ------------------------------------------------------------------ Common
    "GolGappaGhostu": (
        "A crispy golden gol gappa puri who floats around like a friendly little ghost. Its bottom melts into a "
        "wavy tail of tangy tamarind water, and a few chickpeas peek out of the hole on top. Always leaking a "
        "little, always asking for more khatta.",
        [("Puri gold", "puri"), ("Crispy edge", "puricrust"), ("Imli pani", "imlipani"), ("Chickpea", "chickpea"),
         ("Blush", "blush")],
        "A round, hollow golden puri (gol gappa) that floats like a cute ghost. Its lower half melts into a wavy, "
        "see-through tail of brown tamarind water with drips falling off. A hole on top with three chickpeas "
        "peeking out. Big eyes, rosy cheeks and a small open 'ooh' mouth with its tongue out. Floating a little "
        "above the ground.",
    ),
    "SamosaSupremo": (
        "The coolest snack in the bazaar. A golden triangle samosa in black shades who stands on a white plate "
        "like it is a stage, little arms crossed. It never smiles much, because the main course does not need to.",
        [("Samosa gold", "samosa"), ("Crispy brown", "samosadark"), ("Shades", "black"), ("Plate", "white")],
        "A big golden-brown triangular samosa with crimped, crispy edges and little flaky bumps. It wears dark "
        "rectangular sunglasses, has tiny arms crossed in front, a small confident smirk, and stands on a round "
        "white plate like a stage. Short stubby legs.",
    ),
    "ChaiyooKettlesaurus": (
        "A shiny steel chai kettle that grew into a tiny dinosaur. The spout is its long neck and head, the lid is "
        "its hat and the handle is its tail. It roars puffs of steam and only drinks doodh patti with extra cheeni.",
        [("Steel", "steel"), ("Dark steel", "steeldark"), ("Lid knob", "black"), ("Steam", "steam")],
        "A round, shiny steel chai kettle shaped like a small dinosaur: the curved spout is a long neck ending in "
        "a cute dino head, the lid sits on top like a hat with a black knob, and the black handle curls out the "
        "back like a tail. Four stubby dark-steel legs. Big eyes on the head, a happy open mouth roaring little "
        "white puffs of steam.",
    ),
    "ChanaChaatChacha": (
        "A friendly old uncle made from a steel bowl of chana chaat, full of chickpeas, onion, tomato and "
        "coriander. His moustache is crunchy yellow sev and he walks with a spoon as a walking stick. Always "
        "shouting about imli.",
        [("Steel bowl", "steel"), ("Chickpea", "chickpea"), ("Sev moustache", "sev"), ("Tomato", "tomato"),
         ("Onion", "onion"), ("Coriander", "coriander")],
        "A round steel bowl (katori) filled to the top with chana chaat: chickpeas, red onion, tomato and green "
        "coriander. The bowl itself is the face of a kind old uncle with big eyes and a bushy moustache made of "
        "crunchy yellow sev. Tiny legs and little black shoes. He leans on a long steel spoon like a walking stick.",
    ),
    "KulfiKangaroo": (
        "A pistachio-and-cream kulfi on its stick who hops around like a kangaroo, with long ears and big feet. "
        "It melts a little in the sun, then freezes again. Very bouncy, a bit drippy.",
        [("Kulfi cream", "kulfi"), ("Pistachio", "pistachio"), ("Stick", "kulfistick"), ("Ice drips", "skyblue"),
         ("Blush", "blush")],
        "A cone-shaped kulfi ice cream on a wooden stick, cream coloured with a green pistachio top sprinkled "
        "with nuts. It has long kangaroo ears with pink insides, big kangaroo feet, tiny arms and a happy smile. "
        "A few icy blue drips on its sides. Mid-hop, bouncing on its stick like a pogo tail.",
    ),
    "PakoraPanda": (
        "A lumpy, crispy golden pakora shaped like a panda, with dark crispy patches for ears and eye patches. "
        "When it rains it opens a tiny umbrella and sits on its paper plate with a dab of green chutney.",
        [("Pakora gold", "pakora"), ("Crispy patches", "pakoradark"), ("Umbrella", "blue"),
         ("Paper plate", "white"), ("Chutney", "chutney")],
        "A round, lumpy, golden fried pakora shaped like a chubby panda: dark crispy brown ears, eye patches and "
        "paws. It holds a tiny blue umbrella with a white top and sits on a white paper plate with a blob of green "
        "chutney beside it. Big shiny eyes, a happy little mouth.",
    ),
    "NaanNinja": (
        "A soft teardrop naan with char spots who thinks it is a ninja. Black headband, black mask, and it throws "
        "tiny roti stars. Hiyaa!",
        [("Naan", "naan"), ("Char spots", "naanchar"), ("Headband", "black"), ("Roti star", "cream")],
        "A teardrop-shaped naan bread standing up, pale golden with dark char spots. It wears a black ninja "
        "headband with long tails flowing behind and a black mask strip across its eyes. Tiny arms and legs in an "
        "action pose, throwing a little round roti shaped like a ninja star.",
    ),
    "PyaazPehelwan": (
        "A big purple onion who is a champion wrestler. Strong arms, a curly moustache, green sprouts for hair, "
        "wrestling shorts and a gold champion belt. He makes everyone cry, but only because he is an onion.",
        [("Onion", "onion"), ("Onion skin", "onionpale"), ("Sprouts", "coriander"), ("Shorts", "red"),
         ("Champion belt", "gold"), ("Moustache", "black")],
        "A big round purple onion with thin pale layer lines, green sprouts on top like hair, a thick curly black "
        "moustache and determined eyebrows. Strong flexing arms, red wrestling shorts with a shiny gold champion "
        "belt, short legs. Tiny tear drops fly off to the sides. A proud wrestler pose.",
    ),
    # ---------------------------------------------------------------- Uncommon
    "ParathaPilot": (
        "A flaky round paratha who flies like a plane, with aviator goggles, a leather pilot cap and a scarf "
        "flapping behind. Drips of ghee fall when it comes in to land. Ghee landing in 3... 2... 1!",
        [("Paratha", "paratha"), ("Ghee", "ghee"), ("Pilot cap", "leather"), ("Scarf", "white"),
         ("Goggle lenses", "skyblue")],
        "A round, flaky, golden paratha standing on its edge like a flying disc, with swirly layer lines. It wears "
        "brown aviator goggles over big eyes, a brown leather pilot cap on top and a white scarf flapping behind. "
        "Shiny ghee drips on its edge. A surprised 'o' mouth. Flying, tilted as if banking a turn.",
    ),
    "RickshawRaptor": (
        "A green-and-yellow auto rickshaw on raptor legs, with headlight eyes, a grille full of teeth and a dino "
        "tail. Pon pon! It always asks where you want to go and never takes the short way.",
        [("Rickshaw green", "rickshawgreen"), ("Yellow trim", "yellow"), ("Canopy", "black"),
         ("Raptor feet", "green"), ("Teeth", "white")],
        "A small green auto rickshaw with a yellow stripe and a black canopy roof, walking on two strong raptor "
        "dinosaur legs with claws. The headlights are big cartoon eyes and the front grille is a wide grin with "
        "square white teeth. A green dino tail sticks out the back. Leaning forward like it is running.",
    ),
    "LassiLlama": (
        "A fluffy beige llama sitting in a tall glass of sweet lassi, with a white malai moustache and froth on "
        "its head. A red straw sticks out beside it. Very stylish, very creamy.",
        [("Llama wool", "llama"), ("Lassi", "lassi"), ("Malai", "malai"), ("Glass", "glass"), ("Straw", "red")],
        "A fluffy beige llama with tall ears sitting inside a tall clear glass full of white lassi, only its "
        "head, neck and front hooves showing over the rim. A thick white malai moustache, froth on top of its "
        "head, rosy cheeks, a red straw in the glass. Big happy eyes.",
    ),
    "BunKebabBhai": (
        "A bun kebab who works out. He stands on a little stage flexing his big arms, holding up a gold trophy, "
        "with a sweatband on his bun. Ek dum garam!",
        [("Bun", "bun"), ("Kebab", "kebab"), ("Egg", "eggyolk"), ("Lettuce", "green"), ("Sweatband", "red"),
         ("Trophy", "gold")],
        "A bun kebab burger (soft bun, brown kebab patty, egg layer and green lettuce) with a face and a proud "
        "smile. Big muscly arms: one flexing, one holding up a shiny gold trophy. A red sweatband on the top bun "
        "with sesame seeds. Standing on a small yellow-and-red stage like a bodybuilding show.",
    ),
    "RoohAfzaRhino": (
        "A glossy red rhino shaped like a bottle of rose sharbat. Its horn is the bottle neck with a gold cap, "
        "and see-through windows on its sides show the pink drink inside. Rose petals float around it. "
        "Everything is pink! (A made-up sharbat, no real brand.)",
        [("Bottle red", "rhinored"), ("Pink sharbat", "sharbat"), ("Rose petals", "rosepetal"), ("Cap", "gold")],
        "A chubby, glossy red rhino shaped like a glass sharbat bottle. Its horn is a bottle neck with a little "
        "gold cap. See-through windows on its sides show bright pink rose drink sloshing inside. Short thick legs, "
        "a small tail, big friendly eyes and a smile. Pink rose petals floating around it. No labels or brand "
        "names.",
    ),
    "GajarHalwaGorilla": (
        "A big cuddly gorilla made of grainy orange gajar halwa, sprinkled with almonds and pistachios. He wears a "
        "woolly scarf and a shawl because winter is here, and carries a steaming bowl of halwa to share.",
        [("Gajar halwa", "halwa"), ("Almonds", "almond"), ("Pistachio", "pistachio"), ("Scarf", "blue"),
         ("Shawl", "maroon"), ("Bowl", "steel")],
        "A big, chubby gorilla made of grainy orange carrot halwa with little almond and pistachio pieces on it. "
        "A blue woolly scarf around his neck and a maroon shawl over his shoulders. He holds a steel bowl of "
        "steaming halwa. Big kind eyes, a gentle smile, long arms, short legs.",
    ),
    "DoodhPattiDolphin": (
        "A milky-brown dolphin leaping out of a clay kulhad of doodh patti chai, splashing chai in an arc. Warm, "
        "playful and always steaming.",
        [("Doodh patti", "dolphin"), ("Belly", "cream2"), ("Kulhad clay", "clay"), ("Chai", "chai"),
         ("Steam", "steam")],
        "A chubby milky-brown dolphin with a cream belly leaping out of a small clay cup (kulhad) full of tea, "
        "its body curved in a happy arc. Drops of chai splash in an arc behind it and white steam rises from the "
        "cup. Big eyes, rosy cheeks, a wide smile.",
    ),
    # -------------------------------------------------------------------- Rare
    "LoadSheddingLattoo": (
        "A spinning top (lattoo) with red and yellow stripes and a light bulb for a head. When the power goes, "
        "its eyes switch off; when it comes back, it lights up and shouts 'Light aa gayi!'",
        [("Stripe red", "red"), ("Stripe yellow", "yellow"), ("Bulb", "bulb"), ("Wooden tip", "wood"),
         ("String", "rope")],
        "A wooden spinning top (lattoo) with bright red and yellow stripes, a pointy wooden tip at the bottom and "
        "a string wound around its middle. Its head is a glowing light bulb. A cheerful face on the top part with "
        "big eyes and an open happy mouth. Spinning, tilted a little.",
    ),
    "BiryaniBadshah": (
        "A royal copper degh full of biryani. Fluffy rice and saffron make his hair, a gold crown with a potato "
        "jewel sits on top, and he holds a ladle like a sceptre. He insists aloo wali biryani is the real one.",
        [("Copper degh", "copper"), ("Rice", "rice"), ("Saffron", "saffron"), ("Crown", "gold"),
         ("Potato jewel", "potato"), ("Moustache", "black")],
        "A round copper cooking pot (degh) as the body of a proud king, filled with fluffy white and saffron-orange "
        "rice that looks like hair. A gold crown on top with a round potato as its jewel. A thick black moustache, "
        "big eyes, little arms holding a long ladle like a royal sceptre. Short legs.",
    ),
    "CricketBatBhaijaan": (
        "A cricket bat who is the loudest commentator in the gali. Face on the blade, a plain green jersey with "
        "number 10, a cap on the handle and a microphone in hand. Aur yeh gaya... chauka!",
        [("Willow bat", "willow"), ("Jersey", "jersey"), ("Number", "white"), ("Cap", "blue"), ("Grip", "red")],
        "A wooden cricket bat standing upright, with a cheerful face on the blade, wearing a plain green jersey "
        "with a big white number 10 (no logos). The handle has a red grip and a blue cap on top. Tiny arms, one "
        "holding a microphone to its mouth, short legs with white shoes. Excited, mid-commentary.",
    ),
    "DhabaDragon": (
        "A chubby red dragon whose belly is a glowing clay tandoor. Small wings, a towel over the shoulder like a "
        "dhaba cook, and every time it breathes fire a hot naan flies out. Ek naan, extra garam!",
        [("Dragon red", "dragon"), ("Wings", "maroon"), ("Tandoor clay", "clay"), ("Fire glow", "flame"),
         ("Towel", "white"), ("Horns", "cream")],
        "A chubby red dragon with small dark-red bat wings and two little cream horns. Its round belly is a clay "
        "tandoor oven with a glowing orange fire inside. A white towel over one shoulder like a roadside cook. A "
        "small friendly flame comes out of its mouth and a fresh naan is flying out of the flame.",
    ),
    "GeneratorGainda": (
        "A grey rhino with a yellow generator on its back, a pull cord and a little exhaust puffing smoke. Fairy "
        "lights are wrapped around its horn. Light gayi? Main aaya! Brrrr!",
        [("Rhino grey", "rhinogrey"), ("Generator", "yellow"), ("Exhaust", "darkmetal"), ("Fairy lights", "bulb"),
         ("Smoke", "steam")],
        "A chunky grey rhino carrying a boxy yellow generator on its back, with a pull cord, a black exhaust pipe "
        "puffing grey smoke and a few wires. Colourful little fairy lights wrapped around its horn, glowing. Big "
        "eyes, a proud smile, four stubby legs.",
    ),
    "ShaadiShehnaiShark": (
        "A friendly blue shark who never misses a wedding. It stands on its tail in a maroon wedding jacket with "
        "gold buttons, wears a marigold garland and plays the shehnai. Shaadi kahan hai?",
        [("Shark blue", "shark"), ("Belly", "sharkbelly"), ("Wedding jacket", "maroon"), ("Gold buttons", "gold"),
         ("Marigolds", "marigold"), ("Shehnai", "wood")],
        "A friendly blue shark standing upright on its tail fin, with a pale belly, a big back fin and a wide grin "
        "with small white teeth. It wears a maroon wedding jacket (sherwani) with gold buttons and an orange and "
        "yellow marigold garland. Its fins hold a wooden shehnai with a gold bell to its mouth. Dancing happily.",
    ),
    # -------------------------------------------------------------------- Epic
    "ChipaSahab": (
        "A tiny round uncle with a giant curly moustache much wider than his body, round glasses and a sweater "
        "vest. His hands and feet are suction cups, so once he sticks to you he never lets go. Beta, meri baat suno...",
        [("Uncle skin", "uncle"), ("Sweater vest", "vest"), ("Moustache", "black"), ("Suction cups", "red"),
         ("Newspaper", "newspaper")],
        "A tiny, round, bald uncle with a gigantic curly black moustache much wider than his body, round black "
        "glasses over big eyes and white side hair. A navy sweater vest with white stripes. His hands and feet are "
        "red suction cups. A rolled newspaper under his arm. Arms out as if about to give advice.",
    ),
    "JalebiJinn": (
        "A chubby orange jalebi genie rising out of a pink mithai box, his lower body a big jalebi spiral. Arms "
        "crossed, curly moustache, syrup shine, and little sweets orbiting him. Three wishes... all of them sweet!",
        [("Jalebi orange", "jalebi"), ("Syrup shine", "honey"), ("Mithai box", "pink"), ("Moustache", "black"),
         ("Laddoo", "laddoo"), ("Barfi", "barfi")],
        "A chubby, glossy orange genie whose lower body is a giant curly jalebi spiral rising out of an open pink "
        "sweet box. Arms crossed, a curly black moustache, a jalebi curl on top of his head like a topknot, big "
        "friendly eyes. Little sweets (laddoo, barfi, gulab jamun) orbit around him. Fairy-tale genie, not "
        "religious.",
    ),
    "MehndiMummy": (
        "A cute, not-scary mummy wrapped in cream bandages covered in brown henna patterns of paisleys and "
        "flowers. Big eyes peek out, and she carries a henna cone to decorate everyone's hands. Haath idhar karo!",
        [("Bandages", "bandage"), ("Henna", "henna"), ("Eyes gap", "black"), ("Blush", "blush")],
        "A cute, round, friendly mummy wrapped in cream bandages decorated with brown henna patterns (paisleys, "
        "flowers, dots). A gap in the bandages shows big sparkly eyes and rosy cheeks. She holds a henna cone like "
        "a pen, ready to draw on your hand. A loose bandage end trails behind like a tail. Not scary at all.",
    ),
    "DholakDino": (
        "A chubby green dinosaur whose belly is a painted dholak drum laced with rope. It drums on its own tummy "
        "with tiny arms and dances at every celebration. Dhak dhina dhin!",
        [("Dino green", "dino"), ("Dholak red", "red"), ("Dholak bands", "yellow"), ("Rope lacing", "rope"),
         ("Ribbon", "pink")],
        "A chubby green dinosaur standing on two feet with a long tail. Its round belly is a red dholak drum with "
        "yellow painted bands and rope lacing, worn sideways. Tiny arms drumming on it, a pink ribbon, a big open "
        "happy mouth. A dancing pose with one foot up.",
    ),
    "TongaTornado": (
        "A colourful horse cart (tonga) spinning so fast that its bottom has turned into a dust tornado. A wooden "
        "horse head pokes out the front and the seat is empty. Driver kaun hai?!",
        [("Cart red", "red"), ("Canopy", "blue"), ("Wheels", "yellow"), ("Wood horse", "wood"),
         ("Dust", "sandlight")],
        "A colourful two-wheeled horse cart (tonga) with a red seat, a blue canopy with yellow tassels and two big "
        "yellow wheels. Instead of a real horse, a cute wooden horse head pokes out the front with big eyes. The "
        "bottom of the cart is a spinning swirl of sandy dust like a small tornado. The driver's seat is empty.",
    ),
    "TikkaTiger": (
        "A chubby orange tiger with grill-mark stripes who cooks his own tikka: he holds a giant skewer of tikka "
        "over the little flame at the tip of his tail. Apna tikka khud banata hoon!",
        [("Tiger orange", "tiger"), ("Grill stripes", "naanchar"), ("Tikka", "tikka"), ("Peppers", "green"),
         ("Tail flame", "flame"), ("Muzzle", "white")],
        "A chubby orange tiger cub with dark grill-mark stripes, a white muzzle and round ears. He proudly holds a "
        "long skewer of red tikka pieces with green peppers in both paws, over a small cartoon flame at the tip of "
        "his tail. Big eyes, whiskers, a happy smile.",
    ),
    "RishtaAuntyRobot": (
        "A shiny round robot aunty with cat-eye glasses, a colourful dupatta, a clipboard and a telescope eye "
        "that zooms in on everyone. Her antenna is a hair bun and she always carries her handbag. Beta, kya karte ho?",
        [("Robot silver", "robot"), ("Dupatta", "pink"), ("Cat-eye glasses", "magenta"), ("Clipboard", "wood"),
         ("Handbag", "yellow")],
        "A friendly round silver robot shaped like an aunty: a dome head with a hair-bun antenna, pink cat-eye "
        "glasses, one eye a little telescope zooming out, a bright pink dupatta over her shoulders and a pink "
        "skirt. She holds a clipboard and pen, and a yellow handbag hangs from her arm. Curious, nosy expression.",
    ),
    # --------------------------------------------------------------- Legendary
    "TruckArtTotaa": (
        "A green parrot painted all over with Pakistani truck art: bright flowers, stripes, bells and chains on "
        "the wings and a painted truck-crown crest on its head. Its tail says 'Dekh magar pyar se' (look, but "
        "with love).",
        [("Parrot green", "parrot"), ("Beak", "orange"), ("Wing blue", "blue"), ("Crest red", "red"),
         ("Truck-art gold", "gold"), ("Flower yellow", "yellow")],
        "A plump green parrot painted all over in bright Pakistani truck-art style: flowers, stripes and dots in "
        "red, yellow, blue and pink. Blue wings with painted stripes and little gold bells and chains hanging off "
        "them. A red-and-gold painted wooden crest on its head like a truck's crown, with coloured studs. Orange "
        "beak and feet. Its tail feathers carry a small white panel with the words \"Dekh magar pyar se\".",
    ),
    "SixerSher": (
        "A chubby golden lion who rules street cricket. Fluffy mane, a red T-shirt, a backwards cap, a "
        "tape-wrapped bat on his shoulder and a taped tennis ball in his paw. Chakka! Sorry, sheesha toot gaya!",
        [("Lion gold", "lion"), ("Mane", "mane"), ("T-shirt", "red"), ("Cap", "blue"), ("Bat", "willow"),
         ("Taped ball", "tennisball")],
        "A chubby golden lion cub with a big fluffy brown mane, wearing a red T-shirt with a white stripe and a "
        "blue cap on backwards. A wooden street-cricket bat wrapped in black and red tape rests on his shoulder; "
        "his other paw holds a yellow tennis ball wrapped in black tape. Confident grin, determined eyebrows.",
    ),
    "ChilgozaChachaChipka": (
        "A long brown pine-nut uncle clinging to the blade of a spinning ceiling fan for dear life, his moustache "
        "blown sideways. A drip of honey falls from him. Ghar ka pankha hoon main!",
        [("Pine nut", "pinenut"), ("Fan", "white"), ("Fan blades", "tin"), ("Moustache", "black"),
         ("Honey", "honey")],
        "A white ceiling fan with three metal blades, spinning. A long, brown pine-nut (chilgoza) uncle hangs onto "
        "one blade with both little arms, holding on for dear life, his black moustache blown sideways by the "
        "wind, mouth open, worried eyebrows. A few golden drops of honey fall from him.",
    ),
    "MelaMaharaja": (
        "A laughing Ferris wheel king from the village mela. His face is the hub, a gold crown sits on top, "
        "colourful cabins swing on the rim with light bulbs, and he walks on two little legs. Ek chakkar aur!",
        [("Rim pink", "pink"), ("Rim yellow", "yellow"), ("Face", "cream2"), ("Crown", "gold"),
         ("Cabins", "teal"), ("Bulbs", "bulb")],
        "A colourful Ferris wheel with a pink and yellow rim, white spokes, small cabins in red, teal, orange and "
        "purple, and glowing light bulbs all around. The centre hub is a laughing round face with squeezed-shut "
        "happy eyes and an open mouth. A gold crown on top of the wheel. Two little legs with red shoes underneath.",
    ),
    "CylinderCycleChacha": (
        "A living old bicycle who sells gas cylinders. His headlights are his eyes, his handlebar is a big curly "
        "moustache, his bell is his voice, and a tower of red gas cylinders is roped to his back. Cylinder le lo, "
        "cylinder!",
        [("Cycle frame", "black"), ("Headlights", "steel"), ("Gas cylinders", "red"), ("Seat", "leather"),
         ("Rope", "rope")],
        "An old black bicycle that is alive: two round steel headlights on the front are its big eyes, the curved "
        "black handlebar is a curly moustache, and a little bell is its mouth. A tall stack of red gas cylinders "
        "is tied with rope on the carrier behind the brown seat. Cheerful, proud, a bit wobbly.",
    ),
    # ------------------------------------------------------------------ Mythic
    "AmmiKiUdtiChappal": (
        "The legendary flying chappal every kid fears and loves. A big blue hawai chappal with white straps, "
        "stern-but-cute eyes on its sole, little feathered wings, whoosh lines and a glowing outline. "
        "Whoooosh! Homework kiya?",
        [("Chappal blue", "chappal"), ("Straps and top", "white"), ("Glow", "lightning"), ("Eyebrows", "navy"),
         ("Blush", "blush")],
        "A big blue rubber hawai chappal (flip-flop) flying through the air, with a white top layer and white "
        "V-straps. Its sole faces us with big stern-but-cute eyes, angry eyebrows and rosy cheeks. Small white "
        "feathered wings on its sides, white whoosh lines behind it and a soft glowing blue outline. Funny, not "
        "scary.",
    ),
    "KiteKaptaan": (
        "The captain of the sky: a huge red-and-yellow patang with a face and a captain's hat, a long ribbon "
        "tail, and a sparkly manjha string that runs down to a charkhi spool. Bo kata!",
        [("Kite red", "red"), ("Kite yellow", "yellow"), ("Bamboo", "bamboo"), ("Captain hat", "navy"),
         ("Ribbon", "pink"), ("Spool", "wood")],
        "A huge diamond-shaped paper kite (patang) in red and yellow quarters with thin bamboo sticks, flying. It "
        "has a big smiling face with rosy cheeks and wears a white-and-navy captain's hat. A long ribbon tail "
        "with little coloured bows. A sparkly string runs down to a wooden spool (charkhi) with red ends. Gold "
        "sparkles around it.",
    ),
    "ChandRaatCheetah": (
        "A sleek golden cheetah dressed for the night bazaar: colourful glass bangles stacked on its legs and "
        "tail, mehndi on its paws and a glowing crescent-moon charm on its collar. Choorian chamak rahi hain!",
        [("Cheetah gold", "cheetah"), ("Spots", "spots"), ("Bangles", "magenta"), ("Mehndi", "henna"),
         ("Moon charm", "gold"), ("Sparkles", "white")],
        "A sleek, golden cheetah cub with dark spots, a cream muzzle and big friendly eyes. Colourful glass bangles "
        "(red, green, blue, gold, pink) are stacked on its front legs and its tail. Brown henna patterns on its "
        "paws. A gold collar with a glowing crescent-moon charm. White sparkles around it, as if at a night "
        "bazaar.",
    ),
    # ----------------------------------------------------------------- Special
    "MithaiMamu": (
        "A round orange motichoor laddoo uncle with a big smile, a moustache and a little maroon vest, shining "
        "with silver warq. He carries a tray of barfi, jalebi and gulab jamun for everyone. Ek aur laddoo, beta!",
        [("Laddoo", "laddoo"), ("Saffron dots", "saffron"), ("Vest", "maroon"), ("Silver warq", "warq"),
         ("Tray", "steel"), ("Gulab jamun", "gulabjamun")],
        "A round orange motichoor laddoo with tiny bumpy dots, as a jolly uncle: big smile, rosy cheeks, a thick "
        "black moustache, a small maroon vest with gold buttons and flakes of silver warq on top. He carries a "
        "steel tray with barfi, a jalebi and gulab jamun. Short legs, little shoes.",
    ),
    "LassiLightning": (
        "A tall frothy glass of lassi who is a superhero. Lightning-bolt wings, goggles, a red cape, a straw "
        "antenna crackling with blue sparks. Thandi thandi... ZAP!",
        [("Glass", "glass"), ("Lassi", "lassi"), ("Froth", "malai"), ("Bolt wings", "yellow"),
         ("Cape and straw", "red"), ("Sparks", "lightning")],
        "A tall clear glass full of white lassi with thick froth on top, as a superhero: round goggles over big "
        "eyes, a red cape, yellow lightning-bolt shaped wings on its sides and a red straw sticking out like an "
        "antenna with a zigzag of blue electricity at the top. Blue sparks around it. Flying, heroic pose.",
    ),
    "ChowkidarChoocha": (
        "A round yellow chick who is the neighbourhood watchman. Khaki uniform and cap, a whistle in its beak, a "
        "stick and a torch, and very alert eyes. Jaagte raho!",
        [("Chick yellow", "chick"), ("Uniform", "khaki"), ("Belt", "leather"), ("Beak and feet", "orange"),
         ("Whistle", "steel"), ("Torch glow", "yellow")],
        "A round fluffy yellow chick dressed as a night watchman: a khaki uniform with gold buttons, a brown "
        "belt and a khaki cap with a black peak. A steel whistle in its orange beak, a wooden stick in one wing "
        "and a glowing torch in the other. Alert eyes with serious eyebrows, orange feet.",
    ),
    "RangeelaRaja": (
        "A plump peacock king with a gold crown and a huge fanned tail in every colour of the rainbow. Puffs of "
        "coloured powder burst around him. Rang hi rang!",
        [("Peacock blue", "peacock"), ("Teal", "peacockteal"), ("Crown", "gold"), ("Tail red", "red"),
         ("Tail yellow", "yellow"), ("Tail purple", "purple")],
        "A plump, royal-blue peacock with teal wings and a small gold crown with a green gem. Behind him a huge "
        "fanned tail with feathers in red, orange, yellow, green, teal, blue and purple, each with an eye spot at "
        "the tip. Little puffs of coloured powder (pink, yellow, green, blue) around his feet. Proud, happy face.",
    ),
    "ShalimarSultan": (
        "A floating sultan from a Mughal-style garden. His body is a tiered white marble fountain, water jets "
        "rise from his green turban like a crown, cypress trees stand at his shoulders and flowers ring his base. "
        "Bagh mein khush aamdeed!",
        [("Marble", "white"), ("Face", "cream2"), ("Turban", "green"), ("Turban band", "gold"),
         ("Water", "fountain"), ("Cypress", "cypress")],
        "A floating sultan whose body is a white marble garden fountain with two tiers and pools of blue water. "
        "On top, a round cream face with a neat black moustache and big eyes, wearing a green turban with a gold "
        "band and a red jewel. Water jets spray up from the turban like a crown. Two small cypress trees at his "
        "shoulders, little flowers around the bottom pool.",
    ),
    "TaaronWalaTonga": (
        "A magical night tonga: a deep-blue flying cart covered in stars, pulled by a glowing white winged horse, "
        "rolling on crescent-moon wheels with a lantern swinging. Chalo, taaron ki sair!",
        [("Night blue", "starnavy"), ("Stars and trim", "gold"), ("Winged horse", "white"),
         ("Glow", "lightning"), ("Lantern", "yellow")],
        "A flying horse cart (tonga) painted deep night blue with little gold stars, a gold-trimmed canopy and "
        "glowing yellow star shapes on the roof. Its wheels are glowing gold crescent moons. A small white "
        "horse with feathered wings and a glowing mane pulls it, smiling. A golden lantern hangs at the side and a "
        "trail of sparkles follows behind.",
    ),
}

TEXT_ON_MODEL = {"TruckArtTotaa"}  # the only one with writing on it


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def palette():
    found = re.findall(r'\("(\w+)", \((\d+), (\d+), (\d+)\)\)', read(os.path.join(HERE, "kit.py")))
    return {name: "#{:02X}{:02X}{:02X}".format(int(r), int(g), int(b)) for name, r, g, b in found}


def brainrots():
    text = read(os.path.join(ROOT, "src", "shared", "Brainrots.luau"))
    out = {}
    for line in text.splitlines():
        m = re.search(r'\{ id = "(\w+)", name = "([^"]+)", rarity = "(\w+)", price = (\d+), income = (\d+), '
                      r'phrase = "([^"]+)"', line)
        if m:
            i, name, rarity, price, income, phrase = m.groups()
            out[i] = {"name": name, "rarity": rarity, "price": int(price), "income": int(income),
                      "phrase": phrase, "float": "float = true" in line, "quest": "questOnly = true" in line}
    return out


def config_number(name):
    m = re.search(rf"Config\.{name} = ([\d_]+)", read(os.path.join(ROOT, "src", "shared", "Config.luau")))
    return int(m.group(1).replace("_", ""))


def collection_rewards():
    text = read(os.path.join(ROOT, "src", "shared", "Config.luau"))
    return {special: rarity for rarity, special in re.findall(r'(\w+) = \{[^}]*special = "(\w+)"', text)}


def biome_pools():
    text = read(os.path.join(ROOT, "src", "shared", "Biomes.luau"))
    pools = {}
    for block in re.finditer(r'id = "(\w+)",\s*name = "([^"]+)",\s*title = "([^"]+)".*?pool = \{(.*?)\}', text,
                             re.S):
        _, name, title, pool = block.groups()
        for i in re.findall(r'"(\w+)"', pool):
            pools.setdefault(i, []).append(f"{name} ({title})")
    return pools


def sizes():
    text = read(os.path.join(ROOT, "src", "server", "PropData.luau"))
    found = re.findall(r'\t(\w+) = \{\n\t\tcategory = "brainrot",\n\t\tsize = \{([\d.]+), ([\d.]+), ([\d.]+)\}', text)
    return {i: (float(x), float(y), float(z)) for i, x, y, z in found}


def commas(n):
    return f"{n:,}"


def sheet(i, data, hexes, pools, rewards, size, multiplier):
    look, colours, draw = CHARACTERS[i]
    name, rarity = data["name"], data["rarity"]
    for label, colour in colours:
        assert colour in hexes, f"{i}: unknown colour {colour}"
    palette_rows = "\n".join(f"| {label} | `{hexes[colour]}` |" for label, colour in colours)
    palette_text = ", ".join(f"{label.lower()} {hexes[colour]}" for label, colour in colours)
    if size:
        w, h, d = size
        scale = min(1, MAX_FOOTPRINT / max(w, d), MAX_HEIGHT / h)
        height = f"{h * scale:.1f}"
        footprint = f"{w * scale:.1f} x {d * scale:.1f}"
    else:
        height, footprint = "4", "4 x 4"
    writing = (
        "No logos or real brands, and no other writing."
        if i in TEXT_ON_MODEL
        else "No text, no logos, no real brands."
    )
    prompt = (
        f'Create a 3D cartoon character for my kid-friendly Roblox game "Chai Chaos", a funny game about '
        f"Pakistani street food, bazaars and family life.\n\n"
        f"Character: {name}. {draw}\n\n"
        f"{STYLE}\n\n"
        f"Colours: {palette_text}.\n\n"
        f"Show one character only, full body, front three-quarter view, on a plain white background with soft "
        f"light. {writing}\n\n"
        f"If you can make a 3D model: a game-ready low-poly mesh (under 10,000 triangles), flat colours, facing "
        f"forward, standing with its base on the ground, about {height} studs tall."
    )
    if data["quest"]:
        where = f"Collection Book reward for finishing every {rewards.get(i, '?')} brainrot (never hatches, cannot be stolen)"
    else:
        where = "Hatches in " + ", ".join(pools.get(i, ["(no biome yet)"]))
    floats = ", floats" if data["float"] else ""
    lines = [
        "<details>",
        f'<summary><b>{name}</b> · {rarity} · <i>"{data["phrase"]}"</i></summary>',
        "",
        f"**Look and personality.** {look}",
        "",
        "**Colour palette**",
        "",
        "| Part | Hex |",
        "| --- | --- |",
        palette_rows,
        "",
        "**Ready-to-paste prompt (ChatGPT Astra or any image or 3D generator)**",
        "",
        "```text",
        prompt,
        "```",
        "",
        f"**In the game:** id `{i}` · Rs {commas(data['price'] * multiplier)} · +Rs {commas(data['income'])}/s "
        f"· {height} studs tall, {footprint} studs wide{floats} · {where}.",
        "",
        "</details>",
    ]
    return "\n".join(lines)


def section():
    hexes, defs, pools = palette(), brainrots(), biome_pools()
    rewards, found_sizes = collection_rewards(), sizes()
    multiplier = config_number("PRICE_MULTIPLIER")
    assert set(defs) == set(CHARACTERS), (
        f"characters.py and Brainrots.luau disagree: {sorted(set(defs) ^ set(CHARACTERS))}"
    )
    parts = [
        START,
        "<!-- Generated by blender/characters.py from its own text and the game's data files. Edit it there. -->",
        "",
    ]
    for rarity in RARITY_ORDER:
        group = [i for i in defs if defs[i]["rarity"] == rarity]
        group.sort(key=lambda i: defs[i]["price"])
        title = "Special (Collection Book rewards)" if rarity == "Special" else rarity
        parts.append(f"#### {title} ({len(group)})")
        parts.append("")
        parts.append(f"![{rarity} brainrots](docs/brainrots/{rarity.lower()}.jpg)")
        parts.append("")
        for i in group:
            parts.append(sheet(i, defs[i], hexes, pools, rewards, found_sizes.get(i), multiplier))
            parts.append("")
    parts.append(END)
    return "\n".join(parts)


def write_readme():
    text = read(README)
    assert START in text and END in text, "README.md needs the characters markers"
    before = text[: text.index(START)]
    after = text[text.index(END) + len(END):]
    new = before + section() + after
    if new != text:
        with open(README, "w", encoding="utf-8") as f:
            f.write(new)
    return new != text


if __name__ == "__main__":
    print("README.md updated" if write_readme() else "README.md already up to date")
