-- PhantomGamble Addon for Turtle WoW (1.12 compatible)
-- Features: Regular Gambling + Death Roll + Trivia
-- MODIFIED VERSION: Gold betting removed from Trivia mode only

-- ============================================
-- VARIABLES
-- ============================================

local AcceptOnes = "false"
local AcceptRolls = "false"
local totalrolls = 0
local tierolls = 0
local theMax
local lowname = ""
local highname = ""
local low = 0
local high = 0
local tie = 0
local highbreak = 0
local lowbreak = 0
local tiehigh = 0
local tielow = 0
local whispermethod = false

local DR_Active = false
local DR_Player1 = nil
local DR_Player2 = nil
local DR_CurrentRoller = nil
local DR_CurrentMax = 0
local DR_StartNumber = 100
local DR_GoldWager = 100
local DR_AcceptingPlayers = false
local DR_WaitingForRoll = false

local debtsNeedUpdate = true
local sortedDebts = {}
local debtLines = {}
local MAX_DEBT_LINES = 50

local currentMode = 1
local modeNames = { "Regular Gamble", "Death Roll", "Trivia" }

local chatmethods = { "RAID", "GUILD", "PARTY", "SAY" }
local chatmethod = chatmethods[1]

PG_Settings = { MinimapPos = 75 }

local sortedStats = {}
local statsNeedUpdate = true
local statsLines = {}
local STATS_LINE_HEIGHT = 16
local MAX_STATS_LINES = 50

-- Trivia variables (GOLD REMOVED - CHANGE #1)
local TR_Active = false
local TR_CurrentRound = 0
local TR_TotalRounds = 5
local TR_WaitingForAnswers = false
local TR_CurrentQuestion = nil
local TR_CurrentAnswer = nil
local TR_CurrentAltAnswers = nil
local TR_AnswerOrder = {}
local TR_Scores = {}
local TR_QuestionTimer = 0
local TR_TimerActive = false
local TR_AnswerTimeout = 30
local TR_SelectedExpansion = "All"
local TR_UsedQuestions = {}
local TR_PointsPerQuestion = 5
-- ============================================
-- TRIVIA QUESTION DATABASE
-- ============================================
local TriviaQuestions = {}

TriviaQuestions["Vanilla"] = {
	{ q = "What is the name of the final boss in Blackwing Lair?", a = "Nefarian", alt = {"nefarian", "nef"} },
	{ q = "Which city is the capital of the Undead Forsaken?", a = "Undercity", alt = {"undercity", "uc"} },
	{ q = "What is the name of Ragnaros' domain?", a = "Molten Core", alt = {"molten core", "mc"} },
	{ q = "What is the maximum number of players in a classic 40-man raid?", a = "40", alt = {"40", "forty"} },
	{ q = "What is the name of the Horde Warchief during Vanilla WoW?", a = "Thrall", alt = {"thrall"} },
	{ q = "Which dungeon is located inside Blackrock Mountain and is famous for its lava?", a = "Blackrock Depths", alt = {"blackrock depths", "brd"} },
	{ q = "What material do you need to craft Sulfuras, Hand of Ragnaros?", a = "Sulfuron Ingot", alt = {"sulfuron ingot", "sulfuron"} },
	{ q = "Which class can use poisons on their weapons?", a = "Rogue", alt = {"rogue", "rogues"} },
	{ q = "How many talent trees does each class have in Vanilla?", a = "3", alt = {"3", "three"} },
	{ q = "Which battleground features a mine, blacksmith, stables, lumber mill, and farm?", a = "Arathi Basin", alt = {"arathi basin", "ab"} },
	{ q = "What is the name of Onyxia's human disguise in Stormwind?", a = "Katrana Prestor", alt = {"katrana prestor", "katrana", "lady prestor"} },
	{ q = "Which zone is home to the Crossroads, a famous Horde quest hub?", a = "The Barrens", alt = {"the barrens", "barrens"} },
	{ q = "Which Vanilla raid instance is located in Silithus?", a = "Temple of Ahn'Qiraj", alt = {"temple of ahn'qiraj", "aq40", "aq"} },
	{ q = "What level do you need to be to enter Molten Core?", a = "60", alt = {"60", "level 60"} },
	{ q = "Which zone contains the Scarlet Monastery?", a = "Tirisfal Glades", alt = {"tirisfal glades", "tirisfal"} },
	{ q = "What is the name of the world dragon boss found in Duskwood?", a = "Emeriss", alt = {"emeriss"} },
	{ q = "What is the name of the dragon guarding Upper Blackrock Spire?", a = "Rend Blackhand", alt = {"rend", "rend blackhand"} },
	{ q = "Which race was NOT playable in Vanilla WoW: Gnome, Blood Elf, or Dwarf?", a = "Blood Elf", alt = {"blood elf", "blood elves"} },
	{ q = "What is the name of the Defias Brotherhood leader in The Deadmines?", a = "Edwin VanCleef", alt = {"edwin vancleef", "vancleef"} },
	{ q = "Which profession lets you disenchant magical items?", a = "Enchanting", alt = {"enchanting"} },
	{ q = "What is the name of the Alliance capital in Teldrassil?", a = "Darnassus", alt = {"darnassus"} },
	{ q = "Which dungeon is led by the necromancer Ras Frostwhisper?", a = "Scholomance", alt = {"scholomance", "scholo"} },
	{ q = "What is the name of the Horde capital city in Durotar?", a = "Orgrimmar", alt = {"orgrimmar", "org"} },
	{ q = "Which battleground has players fight over flags in a capture the flag style?", a = "Warsong Gulch", alt = {"warsong gulch", "wsg"} },
	{ q = "What is the name of the bear form druid trainer in Moonglade?", a = "Keeper Remulos", alt = {"keeper remulos", "remulos"} },
	{ q = "Which raid features the boss C'Thun?", a = "Temple of Ahn'Qiraj", alt = {"temple of ahn'qiraj", "aq40"} },
	{ q = "What is the max level in Vanilla WoW?", a = "60", alt = {"60", "level 60"} },
	{ q = "Which class can resurrect players during combat?", a = "Shaman", alt = {"shaman"} },
	{ q = "What is the name of the dwarf capital city?", a = "Ironforge", alt = {"ironforge", "if"} },
	{ q = "Which zone is known for being a PvP zone with Tarren Mill and Southshore?", a = "Hillsbrad Foothills", alt = {"hillsbrad foothills", "hillsbrad"} },
	{ q = "What mount can only be obtained from Baron Rivendare in Stratholme?", a = "Deathcharger", alt = {"deathcharger", "rivendare's deathcharger"} },
	{ q = "Which class uses totems?", a = "Shaman", alt = {"shaman"} },
	{ q = "What is the name of the blue dragonflight leader?", a = "Malygos", alt = {"malygos"} },
	{ q = "Which profession creates bags and armor from cloth?", a = "Tailoring", alt = {"tailoring"} },
	{ q = "What is the name of the gnome capital city?", a = "Gnomeregan", alt = {"gnomeregan"} },
	{ q = "Which dungeon features the final boss Archaedas?", a = "Uldaman", alt = {"uldaman"} },
	{ q = "What is the name of the green dragonflight leader?", a = "Ysera", alt = {"ysera"} },
	{ q = "Which zone contains the entrance to Blackrock Mountain?", a = "Burning Steppes", alt = {"burning steppes"} },
	{ q = "What is the name of the red dragonflight leader?", a = "Alexstrasza", alt = {"alexstrasza"} },
	{ q = "Which class can tame beasts as pets?", a = "Hunter", alt = {"hunter"} },
	{ q = "What is the name of the final boss in Stratholme?", a = "Baron Rivendare", alt = {"baron rivendare", "rivendare"} },
	{ q = "Which profession allows you to create potions and elixirs?", a = "Alchemy", alt = {"alchemy"} },
	{ q = "What is the name of the Naxxramas final boss?", a = "Kel'Thuzad", alt = {"kel'thuzad", "kelthuzad"} },
	{ q = "Which race starts in Mulgore?", a = "Tauren", alt = {"tauren"} },
	{ q = "What is the name of the black dragonflight leader?", a = "Nefarian", alt = {"nefarian", "deathwing"} },
}

TriviaQuestions["The Burning Crusade"] = {
	{ q = "What is the name of the main villain of The Burning Crusade?", a = "Illidan Stormrage", alt = {"illidan", "illidan stormrage"} },
	{ q = "Which new race was added to the Alliance in TBC?", a = "Draenei", alt = {"draenei"} },
	{ q = "Which new race was added to the Horde in TBC?", a = "Blood Elf", alt = {"blood elf", "blood elves"} },
	{ q = "What is the name of the Draenei capital city?", a = "The Exodar", alt = {"exodar", "the exodar"} },
	{ q = "What is the final boss of the Black Temple raid?", a = "Illidan Stormrage", alt = {"illidan", "illidan stormrage"} },
	{ q = "Which zone serves as the main hub in Outland for both factions?", a = "Shattrath City", alt = {"shattrath", "shattrath city"} },
	{ q = "What level does the Dark Portal become accessible in TBC?", a = "58", alt = {"58", "level 58"} },
	{ q = "Which dungeon in TBC features a chess event?", a = "Karazhan", alt = {"karazhan", "kara"} },
	{ q = "What is the name of the Naaru that assists players in Shattrath?", a = "A'dal", alt = {"a'dal", "adal"} },
	{ q = "What is the name of the final boss in Karazhan?", a = "Prince Malchezaar", alt = {"prince malchezaar", "malchezaar"} },
	{ q = "Which TBC zone is known for its mushroom-filled landscape?", a = "Zangarmarsh", alt = {"zangarmarsh"} },
	{ q = "What is the name of the pit lord boss in Magtheridon's Lair?", a = "Magtheridon", alt = {"magtheridon"} },
	{ q = "What is the name of Lady Vashj's raid instance?", a = "Serpentshrine Cavern", alt = {"serpentshrine cavern", "ssc"} },
	{ q = "What new PvP feature was introduced in TBC?", a = "Arena", alt = {"arena", "arenas"} },
	{ q = "What is the name of the Blood Elf capital city?", a = "Silvermoon City", alt = {"silvermoon", "silvermoon city"} },
	{ q = "What is the name of Kael'thas Sunstrider's raid instance?", a = "Tempest Keep", alt = {"tempest keep", "the eye"} },
	{ q = "What flying mount requires exalted with Sha'tari Skyguard?", a = "Nether Ray", alt = {"nether ray"} },
	{ q = "What is the name of the Burning Legion's home world?", a = "Argus", alt = {"argus"} },
	{ q = "Which profession was introduced in TBC?", a = "Jewelcrafting", alt = {"jewelcrafting", "jc"} },
	{ q = "What heroic dungeon key is needed for Tempest Keep instances?", a = "Warpforged Key", alt = {"warpforged key"} },
	{ q = "What is the max level in TBC?", a = "70", alt = {"70", "level 70"} },
	{ q = "Which zone is the first Horde zone in Outland?", a = "Hellfire Peninsula", alt = {"hellfire peninsula", "hellfire"} },
	{ q = "What is the name of the ethereal city in Netherstorm?", a = "Area 52", alt = {"area 52"} },
	{ q = "Which raid features the boss Gruul the Dragonkiller?", a = "Gruul's Lair", alt = {"gruul's lair", "gruuls lair"} },
	{ q = "What is the name of the ogre city in Nagrand?", a = "Halaa", alt = {"halaa"} },
	{ q = "Which dungeon is located in Coilfang Reservoir?", a = "Slave Pens", alt = {"slave pens", "the slave pens"} },
	{ q = "What is the name of the first boss in Black Temple?", a = "High Warlord Naj'entus", alt = {"high warlord naj'entus", "najentus"} },
	{ q = "Which zone features the Auchindoun dungeon complex?", a = "Terokkar Forest", alt = {"terokkar forest", "terokkar"} },
	{ q = "What is the name of Illidan's demon hunter trainer?", a = "Akama", alt = {"akama"} },
	{ q = "Which TBC heroic dungeon has the most bosses?", a = "Tempest Keep", alt = {"tempest keep", "the mechanar"} },
	{ q = "What is the name of the draenei Prophet?", a = "Velen", alt = {"velen"} },
	{ q = "Which raid tier was released first in TBC?", a = "Karazhan", alt = {"karazhan", "tier 4"} },
	{ q = "What is the name of the final boss in Sunwell Plateau?", a = "Kil'jaeden", alt = {"kil'jaeden", "kiljaeden"} },
	{ q = "Which zone is known for its floating islands?", a = "Nagrand", alt = {"nagrand"} },
	{ q = "What is the name of the Aldor faction's rival?", a = "The Scryers", alt = {"the scryers", "scryers"} },
	{ q = "Which dungeon features the boss Murmur?", a = "Shadow Labyrinth", alt = {"shadow labyrinth", "shadow labs"} },
	{ q = "What is the name of the first flying mount in WoW?", a = "Gryphon", alt = {"gryphon", "wind rider", "wyvern"} },
	{ q = "Which zone contains the Blade's Edge Mountains?", a = "Outland", alt = {"outland", "blade's edge", "blades edge"} },
	{ q = "What is the name of the raid before Black Temple?", a = "Hyjal Summit", alt = {"hyjal summit", "mount hyjal", "battle for mount hyjal"} },
	{ q = "Which boss drops the legendary bow Thori'dal?", a = "Kil'jaeden", alt = {"kil'jaeden", "kiljaeden"} },
	{ q = "What is the name of the blood elf racial mount?", a = "Hawkstrider", alt = {"hawkstrider"} },
	{ q = "Which faction controls the Sunwell?", a = "Shattered Sun Offensive", alt = {"shattered sun offensive", "shattered sun"} },
	{ q = "What is the name of the daily quest hub introduced in Patch 2.1?", a = "Isle of Quel'Danas", alt = {"isle of quel'danas", "quel'danas"} },
	{ q = "Which raid features Archimonde?", a = "Hyjal Summit", alt = {"hyjal summit", "mount hyjal"} },
	{ q = "What is the name of the demon hunter starting zone in lore?", a = "Mardum", alt = {"mardum", "black temple"} },
}

TriviaQuestions["Wrath of the Lich King"] = {
	{ q = "What is the name of the Lich King?", a = "Arthas Menethil", alt = {"arthas", "arthas menethil"} },
	{ q = "What new class was introduced in WotLK?", a = "Death Knight", alt = {"death knight", "dk"} },
	{ q = "What is the name of the final raid in WotLK?", a = "Icecrown Citadel", alt = {"icecrown citadel", "icc"} },
	{ q = "What is the name of Arthas's runeblade?", a = "Frostmourne", alt = {"frostmourne"} },
	{ q = "What is the name of the Old God imprisoned beneath Ulduar?", a = "Yogg-Saron", alt = {"yogg-saron", "yogg saron", "yogg"} },
	{ q = "What major city serves as the main hub in Northrend?", a = "Dalaran", alt = {"dalaran"} },
	{ q = "What is the name of Arthas's horse?", a = "Invincible", alt = {"invincible"} },
	{ q = "What is the name of the Argent Crusade leader?", a = "Tirion Fordring", alt = {"tirion fordring", "tirion"} },
	{ q = "Which WotLK dungeon is themed after the Culling of Stratholme?", a = "Culling of Stratholme", alt = {"culling of stratholme", "cos"} },
	{ q = "Which zone is the starting area for Death Knights?", a = "Ebon Hold", alt = {"ebon hold", "acherus"} },
	{ q = "What is the name of the titan city found in Storm Peaks?", a = "Ulduar", alt = {"ulduar"} },
	{ q = "What is the name of the dragon aspect of magic who went insane?", a = "Malygos", alt = {"malygos"} },
	{ q = "What is the name of the vrykul king in Utgarde Pinnacle?", a = "King Ymiron", alt = {"king ymiron", "ymiron"} },
	{ q = "Which dungeon is set in a Nerubian underground kingdom?", a = "Azjol-Nerub", alt = {"azjol-nerub", "azjol nerub"} },
	{ q = "What achievement system was introduced in WotLK?", a = "Achievements", alt = {"achievements", "achievement"} },
	{ q = "What vehicle-based raid features jousting?", a = "Trial of the Crusader", alt = {"trial of the crusader", "toc"} },
	{ q = "What is the name of the Lich King's fortress?", a = "Icecrown Citadel", alt = {"icecrown citadel", "icc"} },
	{ q = "What is the name of the Forsaken plague used at the Wrathgate?", a = "Blight", alt = {"blight", "the blight"} },
	{ q = "What profession was introduced in WotLK?", a = "Inscription", alt = {"inscription"} },
	{ q = "Which WotLK zone features the Nexus dungeon?", a = "Borean Tundra", alt = {"borean tundra"} },
	{ q = "What is the max level in WotLK?", a = "80", alt = {"80", "level 80"} },
	{ q = "Which raid features Kel'Thuzad as the final boss?", a = "Naxxramas", alt = {"naxxramas", "naxx"} },
	{ q = "What is the name of the tuskarr village in Borean Tundra?", a = "Kaskala", alt = {"kaskala"} },
	{ q = "Which zone contains the Wyrmrest Temple?", a = "Dragonblight", alt = {"dragonblight"} },
	{ q = "What is the name of the first raid released in WotLK?", a = "Naxxramas", alt = {"naxxramas", "naxx"} },
	{ q = "Which dungeon features the boss Anub'arak?", a = "Azjol-Nerub", alt = {"azjol-nerub", "trial of the crusader"} },
	{ q = "What is the name of the Argent Tournament daily quest hub?", a = "Argent Tournament Grounds", alt = {"argent tournament grounds", "argent tournament"} },
	{ q = "Which zone is home to the Kalu'ak faction?", a = "Howling Fjord", alt = {"howling fjord", "borean tundra"} },
	{ q = "What is the name of the final boss in Ulduar?", a = "Yogg-Saron", alt = {"yogg-saron", "yogg saron", "algalon"} },
	{ q = "Which WotLK raid features dragon bosses?", a = "The Obsidian Sanctum", alt = {"the obsidian sanctum", "obsidian sanctum"} },
	{ q = "What is the name of the red dragonflight sanctum?", a = "The Ruby Sanctum", alt = {"the ruby sanctum", "ruby sanctum"} },
	{ q = "Which zone contains Icecrown Citadel?", a = "Icecrown", alt = {"icecrown"} },
	{ q = "What is the name of the WotLK pre-launch event?", a = "Scourge Invasion", alt = {"scourge invasion", "zombie invasion"} },
	{ q = "Which boss guards the gates of Ulduar?", a = "Flame Leviathan", alt = {"flame leviathan"} },
	{ q = "What is the name of the blood elf prince who aids the Lich King?", a = "Prince Arthas", alt = {"arthas", "prince arthas"} },
	{ q = "Which dungeon is located in the Dragonblight?", a = "The Obsidian Sanctum", alt = {"the obsidian sanctum", "obsidian sanctum"} },
	{ q = "What is the name of the titan keeper in Ulduar?", a = "Mimiron", alt = {"mimiron"} },
	{ q = "Which zone features the Sons of Hodir faction?", a = "Storm Peaks", alt = {"storm peaks"} },
	{ q = "What is the name of the first boss in Icecrown Citadel?", a = "Lord Marrowgar", alt = {"lord marrowgar", "marrowgar"} },
	{ q = "Which raid features the boss Sindragosa?", a = "Icecrown Citadel", alt = {"icecrown citadel", "icc"} },
	{ q = "What is the name of the Death Knight racial mount?", a = "Deathcharger", alt = {"deathcharger", "acherus deathcharger"} },
	{ q = "Which boss drops the legendary mace Val'anyr?", a = "Yogg-Saron", alt = {"yogg-saron", "yogg"} },
	{ q = "What is the name of the PvP zone added in WotLK?", a = "Wintergrasp", alt = {"wintergrasp"} },
	{ q = "Which raid features Algalon the Observer?", a = "Ulduar", alt = {"ulduar"} },
	{ q = "What is the name of the gunship battle raid?", a = "Icecrown Citadel", alt = {"icecrown citadel", "icc"} },
}

TriviaQuestions["Cataclysm"] = {
	{ q = "Which dragon caused the Cataclysm?", a = "Deathwing", alt = {"deathwing", "neltharion"} },
	{ q = "What is Deathwing's original name?", a = "Neltharion", alt = {"neltharion"} },
	{ q = "Which two new races were added in Cataclysm?", a = "Worgen and Goblin", alt = {"worgen and goblin", "goblin and worgen"} },
	{ q = "What is the name of the final raid in Cataclysm?", a = "Dragon Soul", alt = {"dragon soul"} },
	{ q = "What is the name of the underwater zone introduced in Cataclysm?", a = "Vashj'ir", alt = {"vashj'ir", "vashjir"} },
	{ q = "Who is the final boss of the Firelands raid?", a = "Ragnaros", alt = {"ragnaros"} },
	{ q = "What new secondary profession was added in Cataclysm?", a = "Archaeology", alt = {"archaeology", "archeology"} },
	{ q = "What is the max level cap in Cataclysm?", a = "85", alt = {"85", "level 85"} },
	{ q = "What feature let you fly in Azeroth for the first time?", a = "Flight Master's License", alt = {"flight master's license", "azeroth flying"} },
	{ q = "Which Worgen starting zone tells the story of the Gilnean curse?", a = "Gilneas", alt = {"gilneas"} },
	{ q = "What is the name of Al'Akir's raid?", a = "Throne of the Four Winds", alt = {"throne of the four winds"} },
	{ q = "Which heroic dungeon features the Echo of Sylvanas?", a = "End Time", alt = {"end time"} },
	{ q = "What new guild feature allowed guilds to level up?", a = "Guild Leveling", alt = {"guild leveling", "guild levels"} },
	{ q = "Which classic zone was split in half by lava?", a = "The Barrens", alt = {"the barrens", "barrens"} },
	{ q = "What is the name of the elemental plane of fire raid?", a = "Firelands", alt = {"firelands"} },
	{ q = "Which dungeon was revised featuring a troll theme?", a = "Zul'Aman", alt = {"zul'aman", "za"} },
	{ q = "What is the name of the Twilight Hammer leader?", a = "Cho'gall", alt = {"cho'gall", "chogall"} },
	{ q = "Which raid tier features Nefarian resurrected?", a = "Blackwing Descent", alt = {"blackwing descent", "bwd"} },
	{ q = "What is the name of the water elemental plane raid?", a = "Throne of the Tides", alt = {"throne of the tides"} },
	{ q = "Which Cataclysm zone is on Mount Hyjal?", a = "Mount Hyjal", alt = {"mount hyjal", "hyjal"} },
	{ q = "What is the goblin starting zone?", a = "Kezan", alt = {"kezan", "lost isles"} },
	{ q = "Which elemental lord rules Deepholm?", a = "Therazane", alt = {"therazane"} },
	{ q = "What is the name of the final boss in Dragon Soul?", a = "Deathwing", alt = {"deathwing", "madness of deathwing"} },
	{ q = "Which dungeon features Ozruk as a boss?", a = "The Stonecore", alt = {"the stonecore", "stonecore"} },
	{ q = "What is the name of the Cataclysm pre-launch event?", a = "Elemental Invasion", alt = {"elemental invasion"} },
	{ q = "Which zone contains the Maelstrom?", a = "Deepholm", alt = {"deepholm", "the maelstrom"} },
	{ q = "What is the name of Thrall's new title in Cataclysm?", a = "World Shaman", alt = {"world shaman", "thrall"} },
	{ q = "Which raid features Sinestra as a hard mode boss?", a = "Bastion of Twilight", alt = {"bastion of twilight", "bot"} },
	{ q = "What is the name of the druid legendary staff?", a = "Dragonwrath", alt = {"dragonwrath"} },
	{ q = "Which zone was destroyed by Deathwing at the start of Cataclysm?", a = "Auberdine", alt = {"auberdine", "darkshore"} },
	{ q = "What is the name of the troll raid added in patch 4.1?", a = "Zul'Gurub", alt = {"zul'gurub", "zg"} },
	{ q = "Which boss drops tier tokens in Firelands?", a = "Ragnaros", alt = {"ragnaros", "all bosses"} },
	{ q = "What is the name of the Twilight's Hammer cult leader?", a = "Cho'gall", alt = {"cho'gall", "deathwing"} },
	{ q = "Which dungeon is accessed through Stormwind Harbor?", a = "Deadmines", alt = {"deadmines", "the deadmines"} },
	{ q = "What is the name of the elemental plane of air?", a = "Skywall", alt = {"skywall"} },
	{ q = "Which raid features the Omnotron Defense System?", a = "Blackwing Descent", alt = {"blackwing descent", "bwd"} },
	{ q = "What is the name of Deathwing's consort?", a = "Sintharia", alt = {"sintharia", "sinestra"} },
	{ q = "Which zone contains Grim Batol?", a = "Twilight Highlands", alt = {"twilight highlands"} },
	{ q = "What is the name of the legendary rogue daggers?", a = "Fangs of the Father", alt = {"fangs of the father", "the sleeper", "the dreamer"} },
	{ q = "Which boss is known for the Atramedes encounter?", a = "Atramedes", alt = {"atramedes"} },
	{ q = "What is the name of the new Horde Warchief after Thrall?", a = "Garrosh Hellscream", alt = {"garrosh", "garrosh hellscream"} },
	{ q = "Which zone contains the Well of Eternity dungeon?", a = "Caverns of Time", alt = {"caverns of time"} },
	{ q = "What is the name of the aspect that betrayed the others?", a = "Deathwing", alt = {"deathwing", "neltharion"} },
	{ q = "Which raid features Majordomo Staghelm?", a = "Firelands", alt = {"firelands"} },
	{ q = "What is the name of the worgen racial mount?", a = "Mountain Horse", alt = {"mountain horse", "horse"} },
}

TriviaQuestions["Mists of Pandaria"] = {
	{ q = "What new race was introduced in Mists of Pandaria?", a = "Pandaren", alt = {"pandaren"} },
	{ q = "What new class was introduced in MoP?", a = "Monk", alt = {"monk"} },
	{ q = "What is the name of the continent discovered in MoP?", a = "Pandaria", alt = {"pandaria"} },
	{ q = "What negative emotion entities threaten Pandaria?", a = "The Sha", alt = {"the sha", "sha"} },
	{ q = "Who becomes the final boss of the Siege of Orgrimmar?", a = "Garrosh Hellscream", alt = {"garrosh", "garrosh hellscream"} },
	{ q = "What is the max level in MoP?", a = "90", alt = {"90", "level 90"} },
	{ q = "What is the name of the Pandaren starting zone on a giant turtle?", a = "Wandering Isle", alt = {"wandering isle", "the wandering isle"} },
	{ q = "Which MoP raid features the Thunder King?", a = "Throne of Thunder", alt = {"throne of thunder", "tot"} },
	{ q = "What is the name of the Thunder King?", a = "Lei Shen", alt = {"lei shen"} },
	{ q = "What new feature allows Pokemon-like battles?", a = "Pet Battles", alt = {"pet battles", "pet battle"} },
	{ q = "Which zone in Pandaria is known for its brewery?", a = "Valley of the Four Winds", alt = {"valley of the four winds"} },
	{ q = "What is the name of the celestial tournament island?", a = "Timeless Isle", alt = {"timeless isle"} },
	{ q = "What is the name of the Sha of Fear's raid?", a = "Terrace of Endless Spring", alt = {"terrace of endless spring", "toes"} },
	{ q = "What new feature let you grow crops on a personal farm?", a = "Halfhill Farm", alt = {"halfhill farm", "the farm", "sunsong ranch"} },
	{ q = "What ancient empire fell to the Sha?", a = "Mogu Empire", alt = {"mogu", "mogu empire"} },
	{ q = "What faction controls the Golden Lotus dailies?", a = "Golden Lotus", alt = {"golden lotus"} },
	{ q = "What challenge mode feature gave cosmetic rewards?", a = "Challenge Modes", alt = {"challenge modes", "challenge mode"} },
	{ q = "What is the name of the final raid in MoP?", a = "Siege of Orgrimmar", alt = {"siege of orgrimmar", "soo"} },
	{ q = "Which Pandaren helped the Alliance?", a = "Aysa Cloudsinger", alt = {"aysa", "aysa cloudsinger"} },
	{ q = "What is the name of the first MoP raid?", a = "Mogu'shan Vaults", alt = {"mogu'shan vaults", "msv", "mogushan vaults"} },
	{ q = "Which Pandaren helped the Horde?", a = "Ji Firepaw", alt = {"ji firepaw", "ji"} },
	{ q = "What is the name of the Pandaren emperor?", a = "Shaohao", alt = {"shaohao"} },
	{ q = "Which zone contains the Shado-Pan Monastery?", a = "Kun-Lai Summit", alt = {"kun-lai summit", "kun lai"} },
	{ q = "What is the name of the black ox celestial?", a = "Niuzao", alt = {"niuzao"} },
	{ q = "Which raid features the Sha of Pride?", a = "Siege of Orgrimmar", alt = {"siege of orgrimmar", "soo"} },
	{ q = "What is the name of the legendary cloak questline?", a = "Wrathion's Questline", alt = {"wrathion", "legendary cloak"} },
	{ q = "Which zone contains the Jade Temple?", a = "Jade Forest", alt = {"jade forest", "the jade forest"} },
	{ q = "What is the name of the red crane celestial?", a = "Chi-Ji", alt = {"chi-ji", "chiji"} },
	{ q = "Which dungeon features the Sha of Doubt?", a = "Temple of the Jade Serpent", alt = {"temple of the jade serpent"} },
	{ q = "What is the name of the white tiger celestial?", a = "Xuen", alt = {"xuen"} },
	{ q = "Which zone is home to the Grummles?", a = "Kun-Lai Summit", alt = {"kun-lai summit"} },
	{ q = "What is the name of the jade serpent celestial?", a = "Yu'lon", alt = {"yu'lon", "yulon"} },
	{ q = "Which faction represents the Alliance in Pandaria?", a = "Operation: Shieldwall", alt = {"operation: shieldwall", "shieldwall"} },
	{ q = "What is the name of Garrosh's true form?", a = "Y'Shaarj", alt = {"y'shaarj", "yshaarj"} },
	{ q = "Which zone contains the Dread Wastes?", a = "Pandaria", alt = {"pandaria", "dread wastes"} },
	{ q = "What is the name of the Zandalari king in MoP?", a = "Rastakhan", alt = {"rastakhan"} },
	{ q = "Which raid features the Dark Animus?", a = "Throne of Thunder", alt = {"throne of thunder", "tot"} },
	{ q = "What is the name of Chen Stormstout's niece?", a = "Li Li", alt = {"li li"} },
	{ q = "Which dungeon is themed after a brewery?", a = "Stormstout Brewery", alt = {"stormstout brewery"} },
	{ q = "What is the name of the mogu emperor?", a = "Lei Shen", alt = {"lei shen"} },
	{ q = "Which raid features Spoils of Pandaria?", a = "Siege of Orgrimmar", alt = {"siege of orgrimmar", "soo"} },
	{ q = "What is the name of the Isle of Thunder faction?", a = "Kirin Tor Offensive", alt = {"kirin tor offensive", "sunreaver onslaught"} },
	{ q = "Which zone is the Pandaren starting area?", a = "Wandering Isle", alt = {"wandering isle", "the wandering isle"} },
	{ q = "What is the name of the final boss before Garrosh?", a = "Paragons of the Klaxxi", alt = {"paragons of the klaxxi", "klaxxi"} },
	{ q = "Which rare spawn drops the Heavenly Onyx Cloud Serpent?", a = "Alani", alt = {"alani"} },
}

TriviaQuestions["Warlords of Draenor"] = {
	{ q = "Who travels back in time to create the Iron Horde?", a = "Garrosh Hellscream", alt = {"garrosh", "garrosh hellscream"} },
	{ q = "What player housing feature was introduced in WoD?", a = "Garrisons", alt = {"garrisons", "garrison"} },
	{ q = "What is the max level in WoD?", a = "100", alt = {"100", "level 100"} },
	{ q = "What is the name of the final raid in WoD?", a = "Hellfire Citadel", alt = {"hellfire citadel", "hfc"} },
	{ q = "Who is the final boss of Hellfire Citadel?", a = "Archimonde", alt = {"archimonde"} },
	{ q = "What is the name of Grommash Hellscream's weapon?", a = "Gorehowl", alt = {"gorehowl"} },
	{ q = "What is the name of the first raid in WoD?", a = "Highmaul", alt = {"highmaul"} },
	{ q = "Who is the final boss of Highmaul?", a = "Imperator Mar'gok", alt = {"imperator mar'gok", "mar'gok", "margok"} },
	{ q = "What is the name of the second raid in WoD?", a = "Blackrock Foundry", alt = {"blackrock foundry", "brf"} },
	{ q = "Which zone in WoD has Draenei settlements?", a = "Shadowmoon Valley", alt = {"shadowmoon valley", "shadowmoon"} },
	{ q = "What new feature let you collect toys in a UI?", a = "Toy Box", alt = {"toy box", "toybox"} },
	{ q = "Which orc leads the Bleeding Hollow clan?", a = "Kilrogg Deadeye", alt = {"kilrogg", "kilrogg deadeye"} },
	{ q = "What new PvP zone featured ongoing faction battles?", a = "Ashran", alt = {"ashran"} },
	{ q = "Who is Gul'dan's master in the Burning Legion?", a = "Kil'jaeden", alt = {"kil'jaeden", "kiljaeden"} },
	{ q = "What flying achievement unlocks flying in Draenor?", a = "Draenor Pathfinder", alt = {"draenor pathfinder", "pathfinder"} },
	{ q = "What is the name of the alternate timeline planet?", a = "Draenor", alt = {"draenor"} },
	{ q = "Which WoD zone features a massive ogre empire?", a = "Gorgrond", alt = {"gorgrond"} },
	{ q = "What Garrison building lets you send followers on missions?", a = "Command Table", alt = {"command table", "mission table", "town hall"} },
	{ q = "Which orc clan is led by Blackhand?", a = "Blackrock Clan", alt = {"blackrock", "blackrock clan"} },
	{ q = "What is the name of the Draenei prophet?", a = "Velen", alt = {"velen", "prophet velen"} },
	{ q = "Which zone contains Shattrath City in WoD?", a = "Talador", alt = {"talador"} },
	{ q = "What is the name of Grommash's son?", a = "Garrosh", alt = {"garrosh", "garrosh hellscream"} },
	{ q = "Which dungeon is themed after a train?", a = "Grimrail Depot", alt = {"grimrail depot"} },
	{ q = "What is the name of the legendary ring questline?", a = "Khadgar's Questline", alt = {"khadgar", "legendary ring"} },
	{ q = "Which zone features the Arakkoa?", a = "Spires of Arak", alt = {"spires of arak"} },
	{ q = "What is the name of the Horde Garrison location?", a = "Frostwall", alt = {"frostwall"} },
	{ q = "Which boss is known for the rolling balls mechanic?", a = "Blackhand", alt = {"blackhand"} },
	{ q = "What is the name of the Alliance Garrison location?", a = "Lunarfall", alt = {"lunarfall"} },
	{ q = "Which raid features the Iron Maidens?", a = "Blackrock Foundry", alt = {"blackrock foundry", "brf"} },
	{ q = "What is the name of the Tanaan Jungle faction?", a = "Hand of the Prophet", alt = {"hand of the prophet", "vol'jin's headhunters"} },
	{ q = "Which dungeon features the final boss Yalnu?", a = "The Everbloom", alt = {"the everbloom", "everbloom"} },
	{ q = "What is the name of the plant boss in Highmaul?", a = "The Butcher", alt = {"the butcher", "brackenspore"} },
	{ q = "Which zone is the Horde starting area in Draenor?", a = "Frostfire Ridge", alt = {"frostfire ridge"} },
	{ q = "What is the name of the legendary ring?", a = "Mage's Ring", alt = {"legendary ring", "mages ring"} },
	{ q = "Which orc leads the Warsong clan in WoD?", a = "Grommash Hellscream", alt = {"grommash", "grommash hellscream"} },
	{ q = "What is the name of the shipyard feature added later?", a = "Naval Missions", alt = {"naval missions", "shipyard"} },
	{ q = "Which boss features a mythic-only phase?", a = "Archimonde", alt = {"archimonde"} },
	{ q = "What is the name of the time-travel bronze dragon?", a = "Kairozdormu", alt = {"kairozdormu", "kairoz"} },
	{ q = "Which zone contains the Seat of the Naaru?", a = "Shadowmoon Valley", alt = {"shadowmoon valley"} },
	{ q = "What is the name of the ogre king in Highmaul?", a = "Imperator Mar'gok", alt = {"imperator mar'gok", "margok"} },
	{ q = "Which dungeon is set in an iron fortress?", a = "Iron Docks", alt = {"iron docks"} },
	{ q = "What is the name of the Shadowmoon orc leader?", a = "Ner'zhul", alt = {"ner'zhul", "nerzhul"} },
	{ q = "Which boss drops the mythic mount in Hellfire Citadel?", a = "Archimonde", alt = {"archimonde"} },
	{ q = "What is the name of the zone with floating rocks?", a = "Nagrand", alt = {"nagrand"} },
	{ q = "Which raid features Gorefiend?", a = "Hellfire Citadel", alt = {"hellfire citadel", "hfc"} },
}

TriviaQuestions["Legion"] = {
	{ q = "What new class was introduced in Legion?", a = "Demon Hunter", alt = {"demon hunter", "dh"} },
	{ q = "What is the max level in Legion?", a = "110", alt = {"110", "level 110"} },
	{ q = "What is the name of the final raid in Legion?", a = "Antorus, the Burning Throne", alt = {"antorus", "antorus the burning throne"} },
	{ q = "What powerful weapon system was given to each spec?", a = "Artifact Weapons", alt = {"artifact weapons", "artifacts"} },
	{ q = "What is the name of the Demon Hunter starting zone?", a = "Mardum", alt = {"mardum"} },
	{ q = "Who is the leader of the Nightborne in Suramar?", a = "Elisande", alt = {"elisande"} },
	{ q = "What is the name of the Old God-themed raid?", a = "The Emerald Nightmare", alt = {"emerald nightmare", "the emerald nightmare", "en"} },
	{ q = "Which zone features mana-addicted ancient elves?", a = "Suramar", alt = {"suramar"} },
	{ q = "What feature replaced Garrisons?", a = "Class Order Halls", alt = {"class order halls", "order halls"} },
	{ q = "What is the name of the Broken Shore scenario?", a = "The Battle for the Broken Shore", alt = {"broken shore", "the broken shore"} },
	{ q = "What new dungeon difficulty scales infinitely?", a = "Mythic Plus", alt = {"mythic plus", "mythic+", "m+"} },
	{ q = "What is the name of the Broken Isles capital city?", a = "Dalaran", alt = {"dalaran"} },
	{ q = "What is Xe'ra?", a = "A Naaru", alt = {"naaru", "a naaru"} },
	{ q = "Which Titan facility houses the Pillars of Creation?", a = "Tomb of Sargeras", alt = {"tomb of sargeras", "tos"} },
	{ q = "What is the name of Illidan's prison?", a = "Vault of the Wardens", alt = {"vault of the wardens"} },
	{ q = "What is the name of the druid class hall?", a = "Dreamgrove", alt = {"dreamgrove", "the dreamgrove"} },
	{ q = "What is the artifact weapon for Retribution Paladins?", a = "Ashbringer", alt = {"ashbringer"} },
	{ q = "What is the name of the world soul on Argus?", a = "Argus the Unmaker", alt = {"argus the unmaker", "argus"} },
	{ q = "Who sacrificed themselves to imprison Sargeras?", a = "Illidan", alt = {"illidan"} },
	{ q = "What is the name of the Nighthold's final boss?", a = "Gul'dan", alt = {"gul'dan", "guldan"} },
	{ q = "Which zone contains Highmountain?", a = "Broken Isles", alt = {"broken isles", "highmountain"} },
	{ q = "What is the name of the first raid in Legion?", a = "The Emerald Nightmare", alt = {"the emerald nightmare", "emerald nightmare"} },
	{ q = "Which dungeon features the final boss Advisor Melandrus?", a = "Court of Stars", alt = {"court of stars"} },
	{ q = "What is the name of Odyn's hall in Stormheim?", a = "Halls of Valor", alt = {"halls of valor", "hov"} },
	{ q = "Which artifact weapon did Frost Death Knights receive?", a = "The Blades of the Fallen Prince", alt = {"blades of the fallen prince", "frostmourne"} },
	{ q = "What is the name of the Broken Shore faction?", a = "Armies of Legionfall", alt = {"armies of legionfall", "legionfall"} },
	{ q = "Which raid features Avatar of Sargeras?", a = "Tomb of Sargeras", alt = {"tomb of sargeras", "tos"} },
	{ q = "What is the name of the demon world added in 7.3?", a = "Argus", alt = {"argus"} },
	{ q = "Which dungeon is themed around a cathedral?", a = "Cathedral of Eternal Night", alt = {"cathedral of eternal night"} },
	{ q = "What is the name of the legendary system in Legion?", a = "Legendary Items", alt = {"legendary items", "legendaries"} },
	{ q = "Which zone features the Val'sharah storyline?", a = "Val'sharah", alt = {"val'sharah", "valsharah"} },
	{ q = "What is the name of the mage class hall?", a = "Hall of the Guardian", alt = {"hall of the guardian"} },
	{ q = "Which raid features Xavius?", a = "The Emerald Nightmare", alt = {"the emerald nightmare", "emerald nightmare"} },
	{ q = "What is the name of the Suramar city scenario?", a = "Insurrection", alt = {"insurrection"} },
	{ q = "Which boss drops the Midnight mount?", a = "Attumen the Huntsman", alt = {"attumen", "attumen the huntsman"} },
	{ q = "What is the name of the Warlock class hall?", a = "Dreadscar Rift", alt = {"dreadscar rift"} },
	{ q = "Which raid features Helya?", a = "Trial of Valor", alt = {"trial of valor", "tov"} },
	{ q = "What is the name of the demon hunter artifact weapon?", a = "Twinblades of the Deceiver", alt = {"twinblades of the deceiver", "aldrachi warblades"} },
	{ q = "Which zone contains Black Rook Hold?", a = "Val'sharah", alt = {"val'sharah"} },
	{ q = "What is the name of the Monk class hall?", a = "Peak of Serenity", alt = {"peak of serenity"} },
	{ q = "Which raid tier introduced tier 20 sets?", a = "Tomb of Sargeras", alt = {"tomb of sargeras"} },
	{ q = "What is the name of the final boss in Antorus?", a = "Argus the Unmaker", alt = {"argus the unmaker", "argus"} },
	{ q = "Which dungeon is set in a prison?", a = "Vault of the Wardens", alt = {"vault of the wardens", "votw"} },
	{ q = "What is the name of the Paladin class hall?", a = "Sanctum of Light", alt = {"sanctum of light"} },
	{ q = "Which Allied Race was added for the Horde in Legion?", a = "Nightborne", alt = {"nightborne"} },
}

TriviaQuestions["Battle for Azeroth"] = {
	{ q = "What resource do players collect from Azeroth's wounds?", a = "Azerite", alt = {"azerite"} },
	{ q = "What is the name of the Alliance continent in BfA?", a = "Kul Tiras", alt = {"kul tiras"} },
	{ q = "What is the name of the Horde continent in BfA?", a = "Zandalar", alt = {"zandalar"} },
	{ q = "Who burned down Teldrassil?", a = "Sylvanas Windrunner", alt = {"sylvanas", "sylvanas windrunner"} },
	{ q = "What is the max level in BfA?", a = "120", alt = {"120", "level 120"} },
	{ q = "Who is the final boss of Ny'alotha?", a = "N'Zoth", alt = {"n'zoth", "nzoth"} },
	{ q = "What is the name of the troll empire capital in Zandalar?", a = "Dazar'alor", alt = {"dazar'alor", "dazaralor"} },
	{ q = "What new feature let you explore random islands?", a = "Island Expeditions", alt = {"island expeditions", "islands"} },
	{ q = "Who is the king of the Zandalari trolls?", a = "Rastakhan", alt = {"rastakhan"} },
	{ q = "What corruption system was added in the final patch?", a = "Corrupted Gear", alt = {"corrupted gear", "corruption"} },
	{ q = "What mega-dungeon was introduced in BfA?", a = "Operation: Mechagon", alt = {"mechagon", "operation mechagon"} },
	{ q = "What vision system lets you enter corrupted Stormwind/Orgrimmar?", a = "Horrific Visions", alt = {"horrific visions", "visions"} },
	{ q = "Which Old God is the primary antagonist of BfA?", a = "N'Zoth", alt = {"n'zoth", "nzoth"} },
	{ q = "What is the pirate-themed zone in Kul Tiras?", a = "Tiragarde Sound", alt = {"tiragarde sound", "tiragarde"} },
	{ q = "What feature lets you play as allied races?", a = "Allied Races", alt = {"allied races"} },
	{ q = "What is the Heart of Azeroth?", a = "A necklace", alt = {"necklace", "a necklace", "heart of azeroth"} },
	{ q = "What warfront features Arathi?", a = "Battle for Stromgarde", alt = {"stromgarde", "battle for stromgarde"} },
	{ q = "What is the name of the final raid in BfA?", a = "Ny'alotha", alt = {"ny'alotha", "nyalotha"} },
	{ q = "What allied race features dark-skinned orcs?", a = "Mag'har Orc", alt = {"mag'har orc", "mag'har"} },
	{ q = "What is the name of the sea serpent boss in Crucible of Storms?", a = "Uu'nat", alt = {"uu'nat", "uunat"} },
	{ q = "Which zone in Kul Tiras features witches?", a = "Drustvar", alt = {"drustvar"} },
	{ q = "What is the name of the first raid in BfA?", a = "Uldir", alt = {"uldir"} },
	{ q = "Which Horde zone features dinosaurs and blood trolls?", a = "Nazmir", alt = {"nazmir"} },
	{ q = "What is the name of the naga zone added in 8.2?", a = "Nazjatar", alt = {"nazjatar"} },
	{ q = "Which raid features Jaina Proudmoore?", a = "Battle of Dazar'alor", alt = {"battle of dazar'alor", "dazaralor"} },
	{ q = "What is the name of the underwater zone in BfA?", a = "Nazjatar", alt = {"nazjatar"} },
	{ q = "Which dungeon is themed after a snake temple?", a = "Temple of Sethraliss", alt = {"temple of sethraliss"} },
	{ q = "What is the name of the mechagnome zone?", a = "Mechagon", alt = {"mechagon"} },
	{ q = "Which raid features G'huun?", a = "Uldir", alt = {"uldir"} },
	{ q = "What is the name of the Horde zone with sand trolls?", a = "Vol'dun", alt = {"vol'dun", "voldun"} },
	{ q = "Which allied race features fox people?", a = "Vulpera", alt = {"vulpera"} },
	{ q = "What is the name of the warfront added in patch 8.1?", a = "Battle for Darkshore", alt = {"darkshore", "battle for darkshore"} },
	{ q = "Which dungeon features the final boss King Gobbamak?", a = "Operation: Mechagon", alt = {"operation: mechagon", "mechagon"} },
	{ q = "What is the name of Azshara's raid?", a = "The Eternal Palace", alt = {"the eternal palace", "eternal palace"} },
	{ q = "Which zone features the Tortollan faction?", a = "Zuldazar", alt = {"zuldazar", "all zones"} },
	{ q = "What is the name of the Kul Tiran druid form?", a = "Drust", alt = {"drust", "drust forms"} },
	{ q = "Which raid features Rastakhan?", a = "Battle of Dazar'alor", alt = {"battle of dazar'alor"} },
	{ q = "What is the name of the essence system?", a = "Azerite Essences", alt = {"azerite essences", "essences"} },
	{ q = "Which Allied Race joins the Alliance as gnomes?", a = "Mechagnomes", alt = {"mechagnomes", "mechagnome"} },
	{ q = "What is the name of the Alliance zone with shipwrecks?", a = "Stormsong Valley", alt = {"stormsong valley"} },
	{ q = "Which dungeon is set in a gold mine?", a = "The MOTHERLODE!!", alt = {"motherlode", "the motherlode"} },
	{ q = "What is the name of the Horde war campaign?", a = "The Fourth War", alt = {"the fourth war", "war campaign"} },
	{ q = "Which boss transforms into a kraken?", a = "Queen Azshara", alt = {"queen azshara", "azshara"} },
	{ q = "What is the name of the PvP island?", a = "Seething Shore", alt = {"seething shore"} },
	{ q = "Which raid features Il'gynoth?", a = "Ny'alotha", alt = {"ny'alotha"} },
}

TriviaQuestions["Shadowlands"] = {
	{ q = "What are the four covenants in Shadowlands?", a = "Kyrian, Venthyr, Night Fae, Necrolord", alt = {"kyrian venthyr night fae necrolord"} },
	{ q = "What is the name of the zone ruled by the Kyrian?", a = "Bastion", alt = {"bastion"} },
	{ q = "What is the max level in Shadowlands?", a = "60", alt = {"60", "level 60"} },
	{ q = "Who is the Jailer's real name?", a = "Zovaal", alt = {"zovaal"} },
	{ q = "What is the name of the Jailer's prison?", a = "The Maw", alt = {"the maw", "maw"} },
	{ q = "What is the name of the hub city in Shadowlands?", a = "Oribos", alt = {"oribos"} },
	{ q = "What roguelike dungeon feature was introduced?", a = "Torghast", alt = {"torghast"} },
	{ q = "Which covenant is associated with vampires?", a = "Venthyr", alt = {"venthyr"} },
	{ q = "What is the name of the Night Fae zone?", a = "Ardenweald", alt = {"ardenweald"} },
	{ q = "What is the name of the Necrolord zone?", a = "Maldraxxus", alt = {"maldraxxus"} },
	{ q = "Who is the leader of the Venthyr?", a = "Sire Denathrius", alt = {"denathrius", "sire denathrius"} },
	{ q = "What is the name of the first raid?", a = "Castle Nathria", alt = {"castle nathria", "nathria"} },
	{ q = "What feature replaced Artifact Power?", a = "Anima", alt = {"anima"} },
	{ q = "What system lets you customize covenant abilities?", a = "Soulbinds", alt = {"soulbinds", "soulbind"} },
	{ q = "What is the Arbiter's role?", a = "Judge souls", alt = {"judge souls", "sorting souls", "judging souls"} },
	{ q = "What mega-dungeon was introduced?", a = "Tazavesh", alt = {"tazavesh"} },
	{ q = "What is the name of the final raid?", a = "Sepulcher of the First Ones", alt = {"sepulcher", "sepulcher of the first ones"} },
	{ q = "What powerful sword does the Jailer seek?", a = "Kingsmourne", alt = {"kingsmourne"} },
	{ q = "What is the name of the afterlife realm?", a = "The Shadowlands", alt = {"shadowlands", "the shadowlands"} },
	{ q = "What is Anduin's corrupted form called?", a = "Dominated Anduin", alt = {"dominated anduin", "anduin"} },
	{ q = "Which zone is themed around nature and rebirth?", a = "Ardenweald", alt = {"ardenweald"} },
	{ q = "What is the name of the second raid?", a = "Sanctum of Domination", alt = {"sanctum of domination", "sod"} },
	{ q = "Which covenant features House of Constructs?", a = "Necrolord", alt = {"necrolord", "necrolords"} },
	{ q = "What is the name of the legendary crafting system?", a = "Runecarving", alt = {"runecarving", "legendary crafting"} },
	{ q = "Which dungeon is set in a theater?", a = "Theater of Pain", alt = {"theater of pain"} },
	{ q = "What is the name of the Winter Queen?", a = "Winter Queen", alt = {"winter queen", "the winter queen"} },
	{ q = "Which raid features Sylvanas Windrunner?", a = "Sanctum of Domination", alt = {"sanctum of domination", "sod"} },
	{ q = "What is the name of the Kyrian leader?", a = "The Archon", alt = {"the archon", "archon"} },
	{ q = "Which zone is themed around war and strength?", a = "Maldraxxus", alt = {"maldraxxus"} },
	{ q = "What is the name of the Primus?", a = "The Primus", alt = {"the primus", "primus"} },
	{ q = "Which covenant ability lets you teleport?", a = "Door of Shadows", alt = {"door of shadows"} },
	{ q = "What is the name of the broker auction house?", a = "Cartel Au", alt = {"cartel au"} },
	{ q = "Which dungeon features the final boss Mueh'zala?", a = "De Other Side", alt = {"de other side"} },
	{ q = "What is the name of the Venthyr zone?", a = "Revendreth", alt = {"revendreth"} },
	{ q = "Which raid features the Eye of the Jailer?", a = "Sanctum of Domination", alt = {"sanctum of domination"} },
	{ q = "What is the name of the zone added in 9.1?", a = "Korthia", alt = {"korthia"} },
	{ q = "Which covenant has the signature ability Summon Steward?", a = "Kyrian", alt = {"kyrian"} },
	{ q = "What is the name of the broker race?", a = "Brokers", alt = {"brokers", "the brokers"} },
	{ q = "Which dungeon is set in a spire?", a = "Spires of Ascension", alt = {"spires of ascension"} },
	{ q = "What is the name of the final boss in Sepulcher?", a = "The Jailer", alt = {"the jailer", "zovaal"} },
	{ q = "Which zone was added in patch 9.2?", a = "Zereth Mortis", alt = {"zereth mortis"} },
	{ q = "What is the name of the tier set system reintroduced?", a = "Tier Sets", alt = {"tier sets", "tier gear"} },
	{ q = "Which covenant can summon a fairy for help?", a = "Night Fae", alt = {"night fae"} },
	{ q = "What is the name of the legendary axe from Castle Nathria?", a = "Jaithys", alt = {"jaithys"} },
	{ q = "Which dungeon is themed around plaguefall?", a = "Plaguefall", alt = {"plaguefall"} },
}

TriviaQuestions["Dragonflight"] = {
	{ q = "What new race/class combo was introduced?", a = "Dracthyr Evoker", alt = {"dracthyr", "evoker", "dracthyr evoker"} },
	{ q = "What is the max level in Dragonflight?", a = "70", alt = {"70", "level 70"} },
	{ q = "What new traversal system lets you ride a dragon?", a = "Dragonriding", alt = {"dragonriding", "dragon riding"} },
	{ q = "What is the first zone in the Dragon Isles?", a = "The Waking Shores", alt = {"the waking shores", "waking shores"} },
	{ q = "Who is the Primal Incarnate of fire?", a = "Fyrakk", alt = {"fyrakk"} },
	{ q = "What is the centaur zone called?", a = "Ohn'ahran Plains", alt = {"ohn'ahran plains", "ohnahran plains"} },
	{ q = "What is the dragon prison called?", a = "The Forbidden Reach", alt = {"the forbidden reach", "forbidden reach"} },
	{ q = "Which dragon aspect is associated with time?", a = "Nozdormu", alt = {"nozdormu"} },
	{ q = "What underground zone was added later?", a = "Zaralek Cavern", alt = {"zaralek cavern", "zaralek"} },
	{ q = "Who is the leader of the Primalists?", a = "Raszageth", alt = {"raszageth"} },
	{ q = "What is the first raid in Dragonflight?", a = "Vault of the Incarnates", alt = {"vault of the incarnates", "voti"} },
	{ q = "What new crafting feature lets players place work orders?", a = "Work Orders", alt = {"work orders", "crafting orders"} },
	{ q = "What is the final raid in Dragonflight?", a = "Amirdrassil", alt = {"amirdrassil"} },
	{ q = "What is the Emerald Dream zone added in 10.2?", a = "Emerald Dream", alt = {"emerald dream"} },
	{ q = "What time-themed mega-dungeon was added?", a = "Dawn of the Infinite", alt = {"dawn of the infinite", "doti"} },
	{ q = "What talent system overhaul was introduced?", a = "Talent Trees", alt = {"talent trees", "new talent trees"} },
	{ q = "What is the name of the Dragon Isles continent?", a = "Dragon Isles", alt = {"dragon isles"} },
	{ q = "What profession specialization system was overhauled?", a = "Profession Specializations", alt = {"profession specializations", "specializations"} },
	{ q = "Who helps players as a Black Dragonflight member?", a = "Wrathion", alt = {"wrathion", "sabellian", "ebyssian"} },
	{ q = "What major system was added for profession quality?", a = "Crafting Quality", alt = {"crafting quality", "quality"} },
	{ q = "Which dragon aspect is associated with earth?", a = "Neltharion", alt = {"neltharion", "deathwing"} },
	{ q = "What is the name of the second raid?", a = "Aberrus", alt = {"aberrus", "aberrus the shadowed crucible"} },
	{ q = "Which zone features the Tuskarr?", a = "The Azure Span", alt = {"the azure span", "azure span"} },
	{ q = "What is the name of the black dragonflight sanctum?", a = "Obsidian Citadel", alt = {"obsidian citadel"} },
	{ q = "Which Primal Incarnate controls ice?", a = "Raszageth", alt = {"raszageth"} },
	{ q = "What is the name of the final boss in Vault of the Incarnates?", a = "Raszageth", alt = {"raszageth"} },
	{ q = "Which zone is themed around magic and arcane energy?", a = "Thaldraszus", alt = {"thaldraszus"} },
	{ q = "What is the name of the bronze dragonflight leader?", a = "Nozdormu", alt = {"nozdormu"} },
	{ q = "Which dungeon is set in Neltharus?", a = "Neltharus", alt = {"neltharus"} },
	{ q = "What is the name of the Evoker healing spec?", a = "Preservation", alt = {"preservation"} },
	{ q = "Which raid features Scalecommander Sarkareth?", a = "Aberrus", alt = {"aberrus"} },
	{ q = "What is the name of the green dragonflight sanctum?", a = "Emerald Gardens", alt = {"emerald gardens", "dreamsurge"} },
	{ q = "Which zone contains Valdrakken?", a = "Thaldraszus", alt = {"thaldraszus"} },
	{ q = "What is the name of the Evoker DPS spec?", a = "Devastation", alt = {"devastation"} },
	{ q = "Which dungeon features Primal enemies?", a = "Halls of Infusion", alt = {"halls of infusion"} },
	{ q = "What is the name of the renewed proto-drake?", a = "Renewed Proto-Drake", alt = {"renewed proto-drake", "proto drake"} },
	{ q = "Which Primal Incarnate controls earth?", a = "Iridikron", alt = {"iridikron"} },
	{ q = "What is the name of the reputation system?", a = "Renown", alt = {"renown"} },
	{ q = "Which dungeon is themed around the blue dragonflight?", a = "The Azure Vault", alt = {"the azure vault", "azure vault"} },
	{ q = "What is the name of Alexstrasza's stronghold?", a = "Valdrakken", alt = {"valdrakken", "life-binder's vault"} },
	{ q = "Which raid features Fyrakk?", a = "Amirdrassil", alt = {"amirdrassil"} },
	{ q = "What is the name of the Dracthyr starting zone?", a = "The Forbidden Reach", alt = {"the forbidden reach", "forbidden reach"} },
	{ q = "Which profession creates dragon riding glyphs?", a = "Any gathering profession", alt = {"herbalism", "mining", "skinning"} },
	{ q = "What is the name of the snail mount?", a = "Magmashell", alt = {"magmashell", "big slick"} },
	{ q = "Which zone features the Dragonscale Expedition?", a = "The Waking Shores", alt = {"the waking shores", "all zones"} },
}

local TriviaExpansions = { "All", "Vanilla", "The Burning Crusade", "Wrath of the Lich King", "Cataclysm", "Mists of Pandaria", "Warlords of Draenor", "Legion", "Battle for Azeroth", "Shadowlands", "Dragonflight" }

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function ChatMsg(msg, chatType, language, channel)
	if not msg or msg == "" then return end
	chatType = chatType or chatmethod
	if chatType == "RAID" then
		if not UnitInRaid("player") then
			if UnitInParty("player") then chatType = "PARTY"
			elseif IsInGuild() then chatType = "GUILD"
			else chatType = "SAY" end
		end
	elseif chatType == "PARTY" then
		if not UnitInParty("player") then
			if IsInGuild() then chatType = "GUILD"
			else chatType = "SAY" end
		end
	elseif chatType == "GUILD" then
		if not IsInGuild() then
			if UnitInParty("player") then chatType = "PARTY"
			else chatType = "SAY" end
		end
	end
	if chatType == "CHANNEL" and channel then
		SendChatMessage(msg, chatType, nil, channel)
	else
		SendChatMessage(msg, chatType)
	end
end

local function Print(pre, red, text)
	if red == "" then red = "/PG" end
	DEFAULT_CHAT_FRAME:AddMessage(pre .. "|cff00ff00" .. red .. "|r: " .. text)
end

-- ============================================
-- STATS FUNCTIONS
-- ============================================

local function UpdateSortedStats()
	sortedStats = {}
	if not PhantomGamble or not PhantomGamble["stats"] then return end
	for name, amount in pairs(PhantomGamble["stats"]) do
		table.insert(sortedStats, { name = name, amount = amount })
	end
	table.sort(sortedStats, function(a, b) return a.amount > b.amount end)
	statsNeedUpdate = false
end

local function ReportStats(count, fromBottom)
	if not PhantomGamble or not PhantomGamble["stats"] or not next(PhantomGamble["stats"]) then
		Print("", "", "No stats to report!"); return
	end
	if statsNeedUpdate then UpdateSortedStats() end
	local total = table.getn(sortedStats)
	if total == 0 then Print("", "", "No stats to report!"); return end
	local startIdx, endIdx, header
	if fromBottom then
		header = count == 1 and "Biggest Loser" or ("Bottom " .. count .. " Losers")
		startIdx = math.max(1, total - count + 1); endIdx = total
	else
		header = "Top " .. count .. " Winners"; startIdx = 1; endIdx = math.min(count, total)
	end
	ChatMsg("--- PhantomGamble " .. header .. " ---")
	if fromBottom then
		for i = endIdx, startIdx, -1 do
			local e = sortedStats[i]
			if e then ChatMsg(string.format("%d. %s: %s%d gold", (total-i+1), e.name, e.amount>=0 and "+" or "", e.amount)) end
		end
	else
		for i = startIdx, endIdx do
			local e = sortedStats[i]
			if e then ChatMsg(string.format("%d. %s: %s%d gold", i, e.name, e.amount>=0 and "+" or "", e.amount)) end
		end
	end
end

local function RefreshStatsDisplay()
	if not PhantomGamble_StatsFrame or not PhantomGamble_StatsFrame:IsVisible() then return end
	if not PhantomGamble_StatsScrollChild then return end
	if statsNeedUpdate then UpdateSortedStats() end
	for i = 1, MAX_STATS_LINES do if statsLines[i] then statsLines[i]:Hide() end end
	local childWidth = PhantomGamble_StatsScrollChild:GetWidth()
	if not childWidth or childWidth <= 0 then childWidth = 240 end
	local yOffset = 0
	for i, entry in ipairs(sortedStats) do
		if i > MAX_STATS_LINES then break end
		local line = statsLines[i]
		if not line then
			line = PhantomGamble_StatsScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			line:SetJustifyH("LEFT"); line:SetWidth(childWidth - 10); statsLines[i] = line
		end
		line:ClearAllPoints()
		line:SetPoint("TOPLEFT", PhantomGamble_StatsScrollChild, "TOPLEFT", 5, -yOffset)
		line:SetWidth(childWidth - 10)
		local color = entry.amount > 0 and "|cff00ff00" or (entry.amount < 0 and "|cffff0000" or "|cffffff00")
		line:SetText(string.format("%d. %s%s: %s%d gold|r", i, color, entry.name, entry.amount>=0 and "+" or "", entry.amount))
		line:Show(); yOffset = yOffset + STATS_LINE_HEIGHT
	end
	if table.getn(sortedStats) == 0 then
		local line = statsLines[1]
		if not line then line = PhantomGamble_StatsScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); line:SetJustifyH("LEFT"); statsLines[1] = line end
		line:ClearAllPoints(); line:SetPoint("TOPLEFT", PhantomGamble_StatsScrollChild, "TOPLEFT", 5, 0)
		line:SetText("|cffffff00No gambling stats yet.|r"); line:Show(); yOffset = STATS_LINE_HEIGHT
	end
	local totalHeight = math.max(yOffset + 10, 50)
	PhantomGamble_StatsScrollChild:SetHeight(totalHeight)
	if PhantomGamble_StatsScrollBar then
		local maxScroll = math.max(0, totalHeight - PhantomGamble_StatsScrollFrame:GetHeight())
		PhantomGamble_StatsScrollBar:SetMinMaxValues(0, maxScroll)
	end
end

local function UpdateStatsWindowLayout()
	if not PhantomGamble_StatsFrame then return end
	local w = PhantomGamble_StatsFrame:GetWidth()
	local bw = math.max(40, (w - 30) / 5)
	if PhantomGamble_StatsTop5Btn then PhantomGamble_StatsTop5Btn:SetWidth(bw) end
	if PhantomGamble_StatsTop10Btn then PhantomGamble_StatsTop10Btn:SetWidth(bw) end
	if PhantomGamble_StatsTop15Btn then PhantomGamble_StatsTop15Btn:SetWidth(bw) end
	if PhantomGamble_StatsBot5Btn then PhantomGamble_StatsBot5Btn:SetWidth(bw) end
	if PhantomGamble_StatsLastBtn then PhantomGamble_StatsLastBtn:SetWidth(bw) end
end

-- ============================================
-- DEBT TRACKING FUNCTIONS
-- ============================================

local function GetDebtKey(debtor, creditor)
	if string.lower(debtor) < string.lower(creditor) then return debtor..":"..creditor
	else return creditor..":"..debtor end
end

local function AddDebt(debtor, creditor, amount)
	if not PhantomGamble["debts"] then PhantomGamble["debts"] = {} end
	debtor = string.upper(string.sub(debtor,1,1))..string.sub(debtor,2)
	creditor = string.upper(string.sub(creditor,1,1))..string.sub(creditor,2)
	local key = GetDebtKey(debtor, creditor)
	if not PhantomGamble["debts"][key] then PhantomGamble["debts"][key] = { player1=debtor, player2=creditor, amount=0 } end
	local debt = PhantomGamble["debts"][key]
	if string.lower(debt.player1) == string.lower(debtor) then debt.amount = debt.amount + amount
	else debt.amount = debt.amount - amount end
	if debt.amount == 0 then PhantomGamble["debts"][key] = nil end
	debtsNeedUpdate = true
end

local function PayDebt(payer, receiver, amount)
	if not PhantomGamble["debts"] then return false end
	payer = string.upper(string.sub(payer,1,1))..string.sub(payer,2)
	receiver = string.upper(string.sub(receiver,1,1))..string.sub(receiver,2)
	local key = GetDebtKey(payer, receiver)
	local debt = PhantomGamble["debts"][key]
	if not debt then return false, "No debt found between "..payer.." and "..receiver end
	local owedAmount = string.lower(debt.player1)==string.lower(payer) and debt.amount or -debt.amount
	if owedAmount <= 0 then return false, payer.." doesn't owe "..receiver.." anything" end
	if string.lower(debt.player1)==string.lower(payer) then debt.amount = debt.amount - amount
	else debt.amount = debt.amount + amount end
	if debt.amount == 0 then PhantomGamble["debts"][key] = nil end
	debtsNeedUpdate = true
	return true, nil
end

local function UpdateSortedDebts()
	sortedDebts = {}
	if not PhantomGamble or not PhantomGamble["debts"] then return end
	for key, debt in pairs(PhantomGamble["debts"]) do
		if debt.amount ~= 0 then
			local debtor, creditor, amt
			if debt.amount > 0 then debtor=debt.player1; creditor=debt.player2; amt=debt.amount
			else debtor=debt.player2; creditor=debt.player1; amt=-debt.amount end
			table.insert(sortedDebts, { debtor=debtor, creditor=creditor, amount=amt })
		end
	end
	table.sort(sortedDebts, function(a,b) return a.amount > b.amount end)
	debtsNeedUpdate = false
end

local function RefreshDebtsDisplay()
	if not PhantomGamble_DebtsFrame or not PhantomGamble_DebtsFrame:IsVisible() then return end
	if not PhantomGamble_DebtsScrollChild then return end
	if debtsNeedUpdate then UpdateSortedDebts() end
	for i = 1, MAX_DEBT_LINES do if debtLines[i] then debtLines[i]:Hide() end end
	local childWidth = PhantomGamble_DebtsScrollChild:GetWidth()
	if not childWidth or childWidth <= 0 then childWidth = 240 end
	local yOffset = 0
	for i, entry in ipairs(sortedDebts) do
		if i > MAX_DEBT_LINES then break end
		local line = debtLines[i]
		if not line then line = PhantomGamble_DebtsScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); line:SetJustifyH("LEFT"); line:SetWidth(childWidth-10); debtLines[i]=line end
		line:ClearAllPoints(); line:SetPoint("TOPLEFT", PhantomGamble_DebtsScrollChild, "TOPLEFT", 5, -yOffset); line:SetWidth(childWidth-10)
		line:SetText(string.format("|cffff0000%s|r owes |cff00ff00%s|r |cffffff00%d|r gold", entry.debtor, entry.creditor, entry.amount))
		line:Show(); yOffset = yOffset + STATS_LINE_HEIGHT
	end
	if table.getn(sortedDebts) == 0 then
		local line = debtLines[1]
		if not line then line = PhantomGamble_DebtsScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); line:SetJustifyH("LEFT"); debtLines[1]=line end
		line:ClearAllPoints(); line:SetPoint("TOPLEFT", PhantomGamble_DebtsScrollChild, "TOPLEFT", 5, 0)
		line:SetText("|cff00ff00No outstanding debts!|r"); line:Show(); yOffset = STATS_LINE_HEIGHT
	end
	local totalHeight = math.max(yOffset + 10, 50)
	PhantomGamble_DebtsScrollChild:SetHeight(totalHeight)
	if PhantomGamble_DebtsScrollBar then
		PhantomGamble_DebtsScrollBar:SetMinMaxValues(0, math.max(0, totalHeight - PhantomGamble_DebtsScrollFrame:GetHeight()))
	end
end

local function ReportDebts()
	if not PhantomGamble or not PhantomGamble["debts"] or not next(PhantomGamble["debts"]) then Print("","","No outstanding debts!"); return end
	if debtsNeedUpdate then UpdateSortedDebts() end
	if table.getn(sortedDebts) == 0 then Print("","","No outstanding debts!"); return end
	ChatMsg("--- PhantomGamble Outstanding Debts ---")
	for i, entry in ipairs(sortedDebts) do
		if i > 10 then break end
		ChatMsg(string.format("%s owes %s %d gold", entry.debtor, entry.creditor, entry.amount))
	end
end

-- ============================================
-- TRIVIA FUNCTIONS (GOLD REMOVED - CHANGE #2 and #3)
-- ============================================

local function TR_GetQuestionPool()
	if TR_SelectedExpansion == "All" then
		local pool = {}
		for expName, questions in pairs(TriviaQuestions) do
			for _, q in ipairs(questions) do table.insert(pool, { expansion=expName, question=q }) end
		end
		return pool
	else
		local pool = {}
		local questions = TriviaQuestions[TR_SelectedExpansion]
		if questions then for _, q in ipairs(questions) do table.insert(pool, { expansion=TR_SelectedExpansion, question=q }) end end
		return pool
	end
end

local function TR_PickQuestion()
	local pool = TR_GetQuestionPool()
	if table.getn(pool) == 0 then return nil end
	local available = {}
	for _, entry in ipairs(pool) do
		local key = entry.expansion..":"..entry.question.q
		if not TR_UsedQuestions[key] then table.insert(available, entry) end
	end
	if table.getn(available) == 0 then TR_UsedQuestions = {}; available = pool end
	local idx = math.random(1, table.getn(available))
	local picked = available[idx]
	TR_UsedQuestions[picked.expansion..":"..picked.question.q] = true
	return picked
end

local function TR_CheckAnswer(msg)
	if not TR_CurrentAnswer then return false end
	local lowerMsg = string.lower(msg)
	if lowerMsg == string.lower(TR_CurrentAnswer) then return true end
	if TR_CurrentAltAnswers then
		for _, alt in ipairs(TR_CurrentAltAnswers) do
			if lowerMsg == string.lower(alt) then return true end
		end
	end
	return false
end

local function TR_UpdateStatus()
	if not PhantomGamble_TR_Status then return end
	if not TR_Active then PhantomGamble_TR_Status:SetText("|cffffff00Waiting...|r"); return end
	local t = "|cffffff00Round "..tostring(TR_CurrentRound).."/"..tostring(TR_TotalRounds).."|r"
	if TR_WaitingForAnswers then t = t .. "\n|cff00ff00Waiting for answers...|r" end
	PhantomGamble_TR_Status:SetText(t)
end

local function TR_AwardPoints()
	local num = table.getn(TR_AnswerOrder)
	if num == 0 then 
		ChatMsg("Nobody answered correctly!") 
		return 
	end
	-- Only award points to first person
	local winner = TR_AnswerOrder[1]
	TR_Scores[winner] = (TR_Scores[winner] or 0) + TR_PointsPerQuestion
	local msg = winner.." answered first! (+"..tostring(TR_PointsPerQuestion).." pts)"
	ChatMsg(msg)
end

local function TR_ReportScores()
	if not TR_Scores or not next(TR_Scores) then ChatMsg("No scores to report!"); return end
	local sorted = {}
	for name, score in pairs(TR_Scores) do table.insert(sorted, { name=name, score=score }) end
	table.sort(sorted, function(a,b) return a.score > b.score end)
	ChatMsg("--- Trivia Scores ---")
	for i, entry in ipairs(sorted) do 
		local msg = tostring(i)..". "..entry.name..": "..tostring(entry.score).." pts"
		ChatMsg(msg)
	end
end

function TR_EndGame()
	TR_Active = false; TR_WaitingForAnswers = false; TR_TimerActive = false
	ChatMsg("TRIVIA GAME OVER!")
	TR_ReportScores()
	-- CHANGE #3: Gold payout block removed
	TR_Scores = {}; TR_CurrentRound = 0; TR_UsedQuestions = {}
	if PhantomGamble_TR_StartBtn then PhantomGamble_TR_StartBtn:SetText("Start Trivia"); PhantomGamble_TR_StartBtn:Enable() end
	if PhantomGamble_TR_AskBtn then PhantomGamble_TR_AskBtn:Disable() end
	if PhantomGamble_TR_CancelBtn then PhantomGamble_TR_CancelBtn:Disable() end
	TR_UpdateStatus()
end

local function TR_EndRound()
	TR_WaitingForAnswers = false; TR_TimerActive = false
	local msg = "Time's up! The answer was: "..TR_CurrentAnswer
	ChatMsg(msg)
	TR_AwardPoints()
	TR_CurrentQuestion = nil; TR_CurrentAnswer = nil; TR_CurrentAltAnswers = nil; TR_AnswerOrder = {}
	TR_UpdateStatus()
	if TR_CurrentRound >= TR_TotalRounds then TR_EndGame()
	else if PhantomGamble_TR_AskBtn then PhantomGamble_TR_AskBtn:Enable() end end
end

function PhantomGamble_TR_Start()
	-- CHANGE #2: Gold wager reading removed
	TR_Active = true; TR_CurrentRound = 0; TR_Scores = {}; TR_UsedQuestions = {}; TR_AnswerOrder = {}; TR_WaitingForAnswers = false
	PhantomGamble["lastTRRounds"] = TR_TotalRounds; PhantomGamble["lastTRExpansion"] = TR_SelectedExpansion
	local msg = "PhantomGamble TRIVIA! "..tostring(TR_TotalRounds).." rounds - "..TR_SelectedExpansion.." - Answer in chat!"
	ChatMsg(msg)
	PhantomGamble_TR_StartBtn:SetText("In Progress..."); PhantomGamble_TR_StartBtn:Disable()
	PhantomGamble_TR_AskBtn:Enable(); PhantomGamble_TR_CancelBtn:Enable()
	TR_UpdateStatus()
end

function PhantomGamble_TR_AskQuestion()
	if not TR_Active then return end
	if TR_WaitingForAnswers then Print("","","A question is still active!"); return end
	TR_CurrentRound = TR_CurrentRound + 1
	local picked = TR_PickQuestion()
	if not picked then Print("","","No questions available!"); TR_EndGame(); return end
	TR_CurrentQuestion = picked.question.q; TR_CurrentAnswer = picked.question.a; TR_CurrentAltAnswers = picked.question.alt
	TR_AnswerOrder = {}; TR_WaitingForAnswers = true; TR_QuestionTimer = TR_AnswerTimeout; TR_TimerActive = true
	local msg = "[Round "..tostring(TR_CurrentRound).."/"..tostring(TR_TotalRounds).."] ("..picked.expansion..") "..TR_CurrentQuestion
	ChatMsg(msg)
	PhantomGamble_TR_AskBtn:Disable(); TR_UpdateStatus()
end

function PhantomGamble_TR_Cancel()
	TR_Active = false; TR_WaitingForAnswers = false; TR_TimerActive = false; TR_Scores = {}; TR_CurrentRound = 0; TR_UsedQuestions = {}
	ChatMsg("Trivia has been cancelled.")
	PhantomGamble_TR_StartBtn:SetText("Start Trivia"); PhantomGamble_TR_StartBtn:Enable()
	PhantomGamble_TR_AskBtn:Disable(); PhantomGamble_TR_CancelBtn:Disable()
	TR_UpdateStatus()
end

function PhantomGamble_TR_ParseChat(msg, sender)
	if not TR_Active or not TR_WaitingForAnswers then return end
	-- Check if this person already answered
	for _, name in ipairs(TR_AnswerOrder) do
		if string.lower(name) == string.lower(sender) then return end
	end
	-- Check if answer is correct
	if TR_CheckAnswer(msg) then
		table.insert(TR_AnswerOrder, sender)
		if whispermethod then 
			local wmsg = "Correct! You win "..tostring(TR_PointsPerQuestion).." pts!"
			SendChatMessage(wmsg, "WHISPER", nil, sender) 
		end
		Print("", "", sender .. " answered correctly first!")
		-- End the round immediately
		TR_EndRound()
	end
end

-- ============================================
-- STATS WINDOW (compact)
-- ============================================
local function CreateStatsWindow()
	local f = CreateFrame("Frame", "PhantomGamble_StatsFrame", UIParent)
	f:SetWidth(280); f:SetHeight(350); f:SetPoint("LEFT", PhantomGamble_Frame, "RIGHT", 10, 0)
	f:SetMovable(true); f:SetResizable(true); f:EnableMouse(true); f:SetFrameStrata("DIALOG")
	f:SetMinResize(250, 200); f:SetMaxResize(450, 500)
	local bg = f:CreateTexture(nil,"BACKGROUND"); bg:SetTexture(0,0,0,0.85); bg:SetAllPoints(f)
	for _,side in ipairs({"TOP","BOTTOM","LEFT","RIGHT"}) do
		local b = f:CreateTexture(nil,"BORDER"); b:SetTexture(0.6,0.6,0.6,1)
		if side=="TOP" or side=="BOTTOM" then b:SetHeight(2) else b:SetWidth(2) end
		if side=="TOP" then b:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); b:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0)
		elseif side=="BOTTOM" then b:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",0,0); b:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",0,0)
		elseif side=="LEFT" then b:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); b:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",0,0)
		else b:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0); b:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",0,0) end
	end
	local tb = f:CreateTexture(nil,"ARTWORK"); tb:SetTexture(0.2,0.2,0.4,1); tb:SetHeight(24); tb:SetPoint("TOPLEFT",f,"TOPLEFT",2,-2); tb:SetPoint("TOPRIGHT",f,"TOPRIGHT",-2,-2)
	local t = f:CreateFontString(nil,"OVERLAY","GameFontNormal"); t:SetPoint("TOP",f,"TOP",0,-8); t:SetText("|cffFFD700Gambling Stats|r")
	f:SetScript("OnMouseDown", function() if arg1=="LeftButton" then this:StartMoving() end end)
	f:SetScript("OnMouseUp", function() this:StopMovingOrSizing() end)
	local cb = CreateFrame("Button","PhantomGamble_StatsCloseButton",f,"UIPanelCloseButton"); cb:SetPoint("TOPRIGHT",f,"TOPRIGHT",-2,-2); cb:SetScript("OnClick", function() PhantomGamble_StatsFrame:Hide() end)
	local sf = CreateFrame("ScrollFrame","PhantomGamble_StatsScrollFrame",f); sf:SetPoint("TOPLEFT",f,"TOPLEFT",10,-30); sf:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-30,60); sf:EnableMouseWheel(true)
	local sc = CreateFrame("Frame","PhantomGamble_StatsScrollChild",sf); sc:SetWidth(240); sc:SetHeight(1); sf:SetScrollChild(sc)
	local sb = CreateFrame("Slider","PhantomGamble_StatsScrollBar",sf); sb:SetPoint("TOPLEFT",sf,"TOPRIGHT",2,-16); sb:SetPoint("BOTTOMLEFT",sf,"BOTTOMRIGHT",2,16); sb:SetWidth(16); sb:SetOrientation("VERTICAL"); sb:SetMinMaxValues(0,1); sb:SetValueStep(1); sb:SetValue(0)
	local sbbg = sb:CreateTexture(nil,"BACKGROUND"); sbbg:SetAllPoints(sb); sbbg:SetTexture(0,0,0,0.5)
	local th = sb:CreateTexture(nil,"OVERLAY"); th:SetTexture(0.5,0.5,0.5,1); th:SetWidth(14); th:SetHeight(30); sb:SetThumbTexture(th)
	sb:SetScript("OnValueChanged", function() sf:SetVerticalScroll(this:GetValue()) end)
	sf:SetScript("OnMouseWheel", function() local c=sb:GetValue(); local mn,mx=sb:GetMinMaxValues(); local s=STATS_LINE_HEIGHT*3; if arg1>0 then sb:SetValue(math.max(mn,c-s)) else sb:SetValue(math.min(mx,c+s)) end end)
	local bh = 20; local bs = 2
	local b1 = CreateFrame("Button","PhantomGamble_StatsTop5Btn",f,"GameMenuButtonTemplate"); b1:SetWidth(45); b1:SetHeight(bh); b1:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",5,35); b1:SetText("Top 5"); b1:SetScript("OnClick", function() ReportStats(5,false) end)
	local b2 = CreateFrame("Button","PhantomGamble_StatsTop10Btn",f,"GameMenuButtonTemplate"); b2:SetWidth(45); b2:SetHeight(bh); b2:SetPoint("LEFT",b1,"RIGHT",bs,0); b2:SetText("Top 10"); b2:SetScript("OnClick", function() ReportStats(10,false) end)
	local b3 = CreateFrame("Button","PhantomGamble_StatsTop15Btn",f,"GameMenuButtonTemplate"); b3:SetWidth(45); b3:SetHeight(bh); b3:SetPoint("LEFT",b2,"RIGHT",bs,0); b3:SetText("Top 15"); b3:SetScript("OnClick", function() ReportStats(15,false) end)
	local b4 = CreateFrame("Button","PhantomGamble_StatsBot5Btn",f,"GameMenuButtonTemplate"); b4:SetWidth(45); b4:SetHeight(bh); b4:SetPoint("LEFT",b3,"RIGHT",bs,0); b4:SetText("Bot 5"); b4:SetScript("OnClick", function() ReportStats(5,true) end)
	local b5 = CreateFrame("Button","PhantomGamble_StatsLastBtn",f,"GameMenuButtonTemplate"); b5:SetWidth(45); b5:SetHeight(bh); b5:SetPoint("LEFT",b4,"RIGHT",bs,0); b5:SetText("Last"); b5:SetScript("OnClick", function() ReportStats(1,true) end)
	local rb = CreateFrame("Button","PhantomGamble_StatsResetBtn",f,"GameMenuButtonTemplate"); rb:SetWidth(80); rb:SetHeight(bh); rb:SetPoint("BOTTOM",f,"BOTTOM",0,10); rb:SetText("Reset Stats"); rb:SetScript("OnClick", function() PhantomGamble["stats"]={}; statsNeedUpdate=true; RefreshStatsDisplay(); Print("","","Stats have been reset.") end)
	local rz = CreateFrame("Button",nil,f); rz:SetWidth(16); rz:SetHeight(16); rz:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-2,2); rz:EnableMouse(true)
	local rzt = rz:CreateTexture(nil,"OVERLAY"); rzt:SetTexture("Interface/ChatFrame/UI-ChatIM-SizeGrabber-Up"); rzt:SetAllPoints(rz)
	rz:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
	rz:SetScript("OnMouseUp", function() f:StopMovingOrSizing(); UpdateStatsWindowLayout(); PhantomGamble_StatsScrollChild:SetWidth(PhantomGamble_StatsScrollFrame:GetWidth()); RefreshStatsDisplay() end)
	rz:SetScript("OnEnter", function() GameTooltip:SetOwner(this,"ANCHOR_TOPLEFT"); GameTooltip:SetText("Drag to resize"); GameTooltip:Show() end)
	rz:SetScript("OnLeave", function() GameTooltip:Hide() end)
	f:SetScript("OnSizeChanged", function() UpdateStatsWindowLayout(); local w=PhantomGamble_StatsScrollFrame:GetWidth(); if w and w>0 then PhantomGamble_StatsScrollChild:SetWidth(w) end end)
	f:SetScript("OnShow", function() statsNeedUpdate=true; this:SetScript("OnUpdate", function() this:SetScript("OnUpdate",nil); local w=PhantomGamble_StatsScrollFrame:GetWidth(); if w and w>0 then PhantomGamble_StatsScrollChild:SetWidth(w) end; RefreshStatsDisplay() end) end)
	f:Hide(); return f
end

-- ============================================
-- DEBTS WINDOW (compact)
-- ============================================
local function CreateDebtsWindow()
	local f = CreateFrame("Frame","PhantomGamble_DebtsFrame",UIParent)
	f:SetWidth(300); f:SetHeight(300); f:SetPoint("LEFT",PhantomGamble_Frame,"RIGHT",10,0)
	f:SetMovable(true); f:SetResizable(true); f:EnableMouse(true); f:SetFrameStrata("DIALOG"); f:SetMinResize(250,200); f:SetMaxResize(450,500)
	local bg = f:CreateTexture(nil,"BACKGROUND"); bg:SetTexture(0,0,0,0.85); bg:SetAllPoints(f)
	for _,side in ipairs({"TOP","BOTTOM","LEFT","RIGHT"}) do
		local b = f:CreateTexture(nil,"BORDER"); b:SetTexture(0.6,0.6,0.6,1)
		if side=="TOP" or side=="BOTTOM" then b:SetHeight(2) else b:SetWidth(2) end
		if side=="TOP" then b:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); b:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0)
		elseif side=="BOTTOM" then b:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",0,0); b:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",0,0)
		elseif side=="LEFT" then b:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); b:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",0,0)
		else b:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0); b:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",0,0) end
	end
	local tb = f:CreateTexture(nil,"ARTWORK"); tb:SetTexture(0.4,0.2,0.2,1); tb:SetHeight(24); tb:SetPoint("TOPLEFT",f,"TOPLEFT",2,-2); tb:SetPoint("TOPRIGHT",f,"TOPRIGHT",-2,-2)
	local t = f:CreateFontString(nil,"OVERLAY","GameFontNormal"); t:SetPoint("TOP",f,"TOP",0,-8); t:SetText("|cffFF6600Outstanding Debts|r")
	f:SetScript("OnMouseDown", function() if arg1=="LeftButton" then this:StartMoving() end end)
	f:SetScript("OnMouseUp", function() this:StopMovingOrSizing() end)
	local cb = CreateFrame("Button",nil,f,"UIPanelCloseButton"); cb:SetPoint("TOPRIGHT",f,"TOPRIGHT",-2,-2); cb:SetScript("OnClick", function() PhantomGamble_DebtsFrame:Hide() end)
	local inst = f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); inst:SetPoint("TOP",f,"TOP",0,-28); inst:SetWidth(280); inst:SetText("|cffffff00Type '!paid Name Amount' in chat to confirm payment|r")
	local sf = CreateFrame("ScrollFrame","PhantomGamble_DebtsScrollFrame",f); sf:SetPoint("TOPLEFT",f,"TOPLEFT",10,-45); sf:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-30,40); sf:EnableMouseWheel(true)
	local sc = CreateFrame("Frame","PhantomGamble_DebtsScrollChild",sf); sc:SetWidth(260); sc:SetHeight(1); sf:SetScrollChild(sc)
	local sb = CreateFrame("Slider","PhantomGamble_DebtsScrollBar",sf); sb:SetPoint("TOPLEFT",sf,"TOPRIGHT",2,-16); sb:SetPoint("BOTTOMLEFT",sf,"BOTTOMRIGHT",2,16); sb:SetWidth(16); sb:SetOrientation("VERTICAL"); sb:SetMinMaxValues(0,1); sb:SetValueStep(1); sb:SetValue(0)
	local sbbg = sb:CreateTexture(nil,"BACKGROUND"); sbbg:SetAllPoints(sb); sbbg:SetTexture(0,0,0,0.5)
	local th = sb:CreateTexture(nil,"OVERLAY"); th:SetTexture(0.5,0.5,0.5,1); th:SetWidth(14); th:SetHeight(30); sb:SetThumbTexture(th)
	sb:SetScript("OnValueChanged", function() sf:SetVerticalScroll(this:GetValue()) end)
	sf:SetScript("OnMouseWheel", function() local c=sb:GetValue(); local mn,mx=sb:GetMinMaxValues(); local s=STATS_LINE_HEIGHT*3; if arg1>0 then sb:SetValue(math.max(mn,c-s)) else sb:SetValue(math.min(mx,c+s)) end end)
	local rpb = CreateFrame("Button",nil,f,"GameMenuButtonTemplate"); rpb:SetWidth(100); rpb:SetHeight(20); rpb:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",10,10); rpb:SetText("Report Debts"); rpb:SetScript("OnClick", function() ReportDebts() end)
	local clb = CreateFrame("Button",nil,f,"GameMenuButtonTemplate"); clb:SetWidth(100); clb:SetHeight(20); clb:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-25,10); clb:SetText("Clear All Debts"); clb:SetScript("OnClick", function() PhantomGamble["debts"]={}; debtsNeedUpdate=true; RefreshDebtsDisplay(); Print("","","All debts cleared.") end)
	local rz = CreateFrame("Button",nil,f); rz:SetWidth(16); rz:SetHeight(16); rz:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-2,2); rz:EnableMouse(true)
	local rzt = rz:CreateTexture(nil,"OVERLAY"); rzt:SetTexture("Interface/ChatFrame/UI-ChatIM-SizeGrabber-Up"); rzt:SetAllPoints(rz)
	rz:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
	rz:SetScript("OnMouseUp", function() f:StopMovingOrSizing(); PhantomGamble_DebtsScrollChild:SetWidth(PhantomGamble_DebtsScrollFrame:GetWidth()); RefreshDebtsDisplay() end)
	rz:SetScript("OnEnter", function() GameTooltip:SetOwner(this,"ANCHOR_TOPLEFT"); GameTooltip:SetText("Drag to resize"); GameTooltip:Show() end)
	rz:SetScript("OnLeave", function() GameTooltip:Hide() end)
	f:SetScript("OnSizeChanged", function() local w=PhantomGamble_DebtsScrollFrame:GetWidth(); if w and w>0 then PhantomGamble_DebtsScrollChild:SetWidth(w) end end)
	f:SetScript("OnShow", function() debtsNeedUpdate=true; this:SetScript("OnUpdate", function() this:SetScript("OnUpdate",nil); local w=PhantomGamble_DebtsScrollFrame:GetWidth(); if w and w>0 then PhantomGamble_DebtsScrollChild:SetWidth(w) end; RefreshDebtsDisplay() end) end)
	f:Hide(); return f
end

-- ============================================
-- MODE SWITCHING
-- ============================================
local function ShowMode(mode)
	currentMode = mode
	local regEls = {"PhantomGamble_RegularTitle","PhantomGamble_EditBox","PhantomGamble_AcceptOnes_Button","PhantomGamble_LASTCALL_Button","PhantomGamble_ROLL_Button","PhantomGamble_Cancel_Button"}
	local drEls = {"PhantomGamble_DRTitle","PhantomGamble_DR_StartLabel","PhantomGamble_DR_StartSelect","PhantomGamble_DR_StartDropdown","PhantomGamble_DR_GoldLabel","PhantomGamble_DR_GoldEditBox","PhantomGamble_DR_StartBtn","PhantomGamble_DR_CancelBtn","PhantomGamble_DR_Status"}
	-- CHANGE #5: Gold elements removed from trEls array
	local trEls = {"PhantomGamble_TRTitle","PhantomGamble_TR_RoundsLabel","PhantomGamble_TR_RoundsSelect","PhantomGamble_TR_RoundsDropdown","PhantomGamble_TR_ExpLabel","PhantomGamble_TR_ExpSelect","PhantomGamble_TR_ExpDropdown","PhantomGamble_TR_StartBtn","PhantomGamble_TR_AskBtn","PhantomGamble_TR_CancelBtn","PhantomGamble_TR_Status"}
	for _,n in ipairs(regEls) do local fr=getglobal(n); if fr then fr:Hide() end end
	for _,n in ipairs(drEls) do local fr=getglobal(n); if fr then fr:Hide() end end
	for _,n in ipairs(trEls) do local fr=getglobal(n); if fr then fr:Hide() end end
	if PhantomGamble_ModeDropdown then PhantomGamble_ModeDropdown:Hide() end
	if mode == 1 then
		for _,n in ipairs(regEls) do local fr=getglobal(n); if fr then fr:Show() end end
		if PhantomGamble_ModeBtnText then PhantomGamble_ModeBtnText:SetText("|cff00ff00Regular Gamble|r") end
	elseif mode == 2 then
		for _,n in ipairs(drEls) do local fr=getglobal(n); if fr then fr:Show() end end
		if PhantomGamble_DR_StartDropdown then PhantomGamble_DR_StartDropdown:Hide() end
		if PhantomGamble_ModeBtnText then PhantomGamble_ModeBtnText:SetText("|cffff0000Death Roll|r") end
	elseif mode == 3 then
		for _,n in ipairs(trEls) do local fr=getglobal(n); if fr then fr:Show() end end
		if PhantomGamble_TR_ExpDropdown then PhantomGamble_TR_ExpDropdown:Hide() end
		if PhantomGamble_TR_RoundsDropdown then PhantomGamble_TR_RoundsDropdown:Hide() end
		if PhantomGamble_ModeBtnText then PhantomGamble_ModeBtnText:SetText("|cffffff00Trivia|r") end
	end
end

-- ============================================
-- MAIN FRAME CREATION (TRIVIA GOLD UI REMOVED)
-- ============================================
local function CreateMainFrame()
	local f = CreateFrame("Frame","PhantomGamble_Frame",UIParent)
	f:SetWidth(290); f:SetHeight(280); f:SetPoint("CENTER",UIParent,"CENTER",0,0)
	f:SetMovable(true); f:SetResizable(true); f:EnableMouse(true); f:SetFrameStrata("DIALOG")
	f:SetMinResize(270,260); f:SetMaxResize(450,400)
	local bg = f:CreateTexture(nil,"BACKGROUND"); bg:SetTexture(0,0,0,0.85); bg:SetAllPoints(f)
	for _,side in ipairs({"TOP","BOTTOM","LEFT","RIGHT"}) do
		local b = f:CreateTexture(nil,"BORDER"); b:SetTexture(0.6,0.6,0.6,1)
		if side=="TOP" or side=="BOTTOM" then b:SetHeight(2) else b:SetWidth(2) end
		if side=="TOP" then b:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); b:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0)
		elseif side=="BOTTOM" then b:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",0,0); b:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",0,0)
		elseif side=="LEFT" then b:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); b:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",0,0)
		else b:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0); b:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",0,0) end
	end
	-- Title bar
	local tb = f:CreateTexture(nil,"ARTWORK"); tb:SetTexture(0.2,0.2,0.4,1); tb:SetHeight(24); tb:SetPoint("TOPLEFT",f,"TOPLEFT",2,-2); tb:SetPoint("TOPRIGHT",f,"TOPRIGHT",-2,-2)
	local title = f:CreateFontString(nil,"OVERLAY","GameFontNormal"); title:SetPoint("TOPLEFT",f,"TOPLEFT",52,-8); title:SetText("|cffFFD700PhantomGamble|r")

	-- Warning button
	local wb = CreateFrame("Button","PhantomGamble_WarningButton",f); wb:SetWidth(60); wb:SetHeight(16); wb:SetPoint("LEFT",title,"RIGHT",8,0)
	local wbt = wb:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); wbt:SetPoint("LEFT",wb,"LEFT",0,0); wbt:SetText("|cffff0000[Warning]|r")
	wb:SetHighlightTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	wb:SetScript("OnEnter", function() GameTooltip:SetOwner(this,"ANCHOR_BOTTOM"); GameTooltip:SetText("|cffff0000Gambling Restriction|r"); GameTooltip:AddLine("Bilgewater Cartel cities only:",1,0.82,0); GameTooltip:AddLine("Ratchet, Booty Bay, Everlook, Gadgetzan",0.5,1,0.5); GameTooltip:Show() end)
	wb:SetScript("OnLeave", function() GameTooltip:Hide() end)
	wb:SetScript("OnClick", function() DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[PhantomGamble Warning]|r Bilgewater Cartel cities only: |cff00ff00Ratchet, Booty Bay, Everlook, Gadgetzan|r") end)

	f:SetScript("OnMouseDown", function() if arg1=="LeftButton" then this:StartMoving() end end)
	f:SetScript("OnMouseUp", function() this:StopMovingOrSizing() end)

	-- Stats button
	local sb = CreateFrame("Button","PhantomGamble_StatsButton",f); sb:SetWidth(20); sb:SetHeight(20); sb:SetPoint("TOPLEFT",f,"TOPLEFT",5,-5)
	local sbbg = sb:CreateTexture(nil,"BACKGROUND"); sbbg:SetTexture(0.3,0.3,0.5,1); sbbg:SetAllPoints(sb)
	local sbt = sb:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); sbt:SetPoint("CENTER",sb,"CENTER",0,0); sbt:SetText("|cffFFD700S|r")
	sb:SetHighlightTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	sb:SetScript("OnClick", function() if not PhantomGamble_StatsFrame then CreateStatsWindow() end; if PhantomGamble_StatsFrame:IsVisible() then PhantomGamble_StatsFrame:Hide() else PhantomGamble_StatsFrame:Show() end end)
	sb:SetScript("OnEnter", function() GameTooltip:SetOwner(this,"ANCHOR_RIGHT"); GameTooltip:SetText("Gambling Stats"); GameTooltip:Show() end)
	sb:SetScript("OnLeave", function() GameTooltip:Hide() end)

	-- Debts button
	local db = CreateFrame("Button","PhantomGamble_DebtsButton",f); db:SetWidth(20); db:SetHeight(20); db:SetPoint("LEFT",sb,"RIGHT",3,0)
	local dbbg = db:CreateTexture(nil,"BACKGROUND"); dbbg:SetTexture(0.5,0.3,0.3,1); dbbg:SetAllPoints(db)
	local dbt = db:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); dbt:SetPoint("CENTER",db,"CENTER",0,0); dbt:SetText("|cffFF6600D|r")
	db:SetHighlightTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	db:SetScript("OnClick", function() if not PhantomGamble_DebtsFrame then CreateDebtsWindow() end; if PhantomGamble_DebtsFrame:IsVisible() then PhantomGamble_DebtsFrame:Hide() else PhantomGamble_DebtsFrame:Show() end end)
	db:SetScript("OnEnter", function() GameTooltip:SetOwner(this,"ANCHOR_RIGHT"); GameTooltip:SetText("Outstanding Debts"); GameTooltip:Show() end)
	db:SetScript("OnLeave", function() GameTooltip:Hide() end)

	-- Close button (created first so we can anchor mode selector relative to it)
	local xb = CreateFrame("Button","PhantomGamble_CloseButton",f,"UIPanelCloseButton"); xb:SetPoint("TOPRIGHT",f,"TOPRIGHT",-2,-2); xb:SetScript("OnClick", function() PhantomGamble_SlashCmd("hide") end)

	-- Mode selector dropdown button (to the left of close button)
	local mb = CreateFrame("Button","PhantomGamble_ModeBtn",f); mb:SetWidth(90); mb:SetHeight(18); mb:SetPoint("RIGHT",xb,"LEFT",-4,0)
	local mbbg = mb:CreateTexture(nil,"BACKGROUND"); mbbg:SetTexture(0.15,0.15,0.15,0.9); mbbg:SetAllPoints(mb)
	-- Border for mode button
	local mbBorderT = mb:CreateTexture(nil,"BORDER"); mbBorderT:SetTexture(0.5,0.5,0.5,1); mbBorderT:SetHeight(1); mbBorderT:SetPoint("TOPLEFT",mb,"TOPLEFT",0,0); mbBorderT:SetPoint("TOPRIGHT",mb,"TOPRIGHT",0,0)
	local mbBorderB = mb:CreateTexture(nil,"BORDER"); mbBorderB:SetTexture(0.5,0.5,0.5,1); mbBorderB:SetHeight(1); mbBorderB:SetPoint("BOTTOMLEFT",mb,"BOTTOMLEFT",0,0); mbBorderB:SetPoint("BOTTOMRIGHT",mb,"BOTTOMRIGHT",0,0)
	local mbBorderL = mb:CreateTexture(nil,"BORDER"); mbBorderL:SetTexture(0.5,0.5,0.5,1); mbBorderL:SetWidth(1); mbBorderL:SetPoint("TOPLEFT",mb,"TOPLEFT",0,0); mbBorderL:SetPoint("BOTTOMLEFT",mb,"BOTTOMLEFT",0,0)
	local mbBorderR = mb:CreateTexture(nil,"BORDER"); mbBorderR:SetTexture(0.5,0.5,0.5,1); mbBorderR:SetWidth(1); mbBorderR:SetPoint("TOPRIGHT",mb,"TOPRIGHT",0,0); mbBorderR:SetPoint("BOTTOMRIGHT",mb,"BOTTOMRIGHT",0,0)
	local mbt = mb:CreateFontString("PhantomGamble_ModeBtnText","OVERLAY","GameFontHighlightSmall"); mbt:SetPoint("CENTER",mb,"CENTER",-6,0); mbt:SetText("|cff00ff00Regular Gamble|r")
	local mba = mb:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); mba:SetPoint("RIGHT",mb,"RIGHT",-3,0); mba:SetText("v")
	mb:SetHighlightTexture("Interface/Buttons/UI-Panel-Button-Highlight")

	-- Mode dropdown
	local modeDD = CreateFrame("Frame","PhantomGamble_ModeDropdown",f); modeDD:SetWidth(90); modeDD:SetHeight(56); modeDD:SetPoint("TOP",mb,"BOTTOM",0,0); modeDD:SetFrameStrata("TOOLTIP"); modeDD:Hide()
	local modeDDBg = modeDD:CreateTexture(nil,"BACKGROUND"); modeDDBg:SetTexture(0,0,0,0.95); modeDDBg:SetAllPoints(modeDD)
	local modeDDBorderT = modeDD:CreateTexture(nil,"BORDER"); modeDDBorderT:SetTexture(0.5,0.5,0.5,1); modeDDBorderT:SetHeight(1); modeDDBorderT:SetPoint("TOPLEFT",modeDD,"TOPLEFT",-1,0); modeDDBorderT:SetPoint("TOPRIGHT",modeDD,"TOPRIGHT",1,0)
	local modeDDBorderB = modeDD:CreateTexture(nil,"BORDER"); modeDDBorderB:SetTexture(0.5,0.5,0.5,1); modeDDBorderB:SetHeight(1); modeDDBorderB:SetPoint("BOTTOMLEFT",modeDD,"BOTTOMLEFT",-1,0); modeDDBorderB:SetPoint("BOTTOMRIGHT",modeDD,"BOTTOMRIGHT",1,0)
	local modeDDBorderL = modeDD:CreateTexture(nil,"BORDER"); modeDDBorderL:SetTexture(0.5,0.5,0.5,1); modeDDBorderL:SetWidth(1); modeDDBorderL:SetPoint("TOPLEFT",modeDD,"TOPLEFT",-1,0); modeDDBorderL:SetPoint("BOTTOMLEFT",modeDD,"BOTTOMLEFT",-1,0)
	local modeDDBorderR = modeDD:CreateTexture(nil,"BORDER"); modeDDBorderR:SetTexture(0.5,0.5,0.5,1); modeDDBorderR:SetWidth(1); modeDDBorderR:SetPoint("TOPRIGHT",modeDD,"TOPRIGHT",1,0); modeDDBorderR:SetPoint("BOTTOMRIGHT",modeDD,"BOTTOMRIGHT",1,0)

	local modeColors = { "|cff00ff00", "|cffff0000", "|cffffff00" }
	for i, modeName in ipairs(modeNames) do
		local optBtn = CreateFrame("Button","PhantomGamble_ModeOpt"..i,modeDD); optBtn:SetWidth(88); optBtn:SetHeight(17); optBtn:SetPoint("TOP",modeDD,"TOP",0,-1-((i-1)*18))
		local optText = optBtn:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); optText:SetPoint("CENTER",optBtn,"CENTER",0,0); optText:SetText(modeColors[i]..modeName.."|r")
		optBtn:SetHighlightTexture("Interface/Buttons/UI-Panel-Button-Highlight"); optBtn.modeIndex = i
		optBtn:SetScript("OnClick", function() currentMode = this.modeIndex; ShowMode(currentMode); modeDD:Hide() end)
	end
	mb:SetScript("OnClick", function() if modeDD:IsVisible() then modeDD:Hide() else modeDD:Show() end end)
	mb:SetScript("OnEnter", function() GameTooltip:SetOwner(this,"ANCHOR_LEFT"); GameTooltip:SetText("|cffFFD700Game Mode|r"); GameTooltip:AddLine("Select which game to play",0.7,0.7,0.7); GameTooltip:Show() end)
	mb:SetScript("OnLeave", function() GameTooltip:Hide() end)

	local cTop = -30

	-- ==========================================
	-- PANEL 1: Regular Gambling
	-- ==========================================
	local rt = f:CreateFontString("PhantomGamble_RegularTitle","OVERLAY","GameFontNormalSmall"); rt:SetPoint("TOP",f,"TOP",0,cTop); rt:SetText("|cff00ff00Regular Gamble|r")
	local eb = CreateFrame("EditBox","PhantomGamble_EditBox",f); eb:SetWidth(100); eb:SetHeight(24); eb:SetPoint("TOP",rt,"BOTTOM",0,-8)
	eb:SetFontObject(ChatFontNormal); eb:SetAutoFocus(false); eb:SetNumeric(true); eb:SetMaxLetters(6); eb:SetJustifyH("CENTER")
	eb:SetScript("OnEscapePressed", function() this:ClearFocus() end); eb:SetScript("OnEnterPressed", function() this:ClearFocus() end)
	local ebbg = eb:CreateTexture(nil,"BACKGROUND"); ebbg:SetTexture(0.1,0.1,0.1,0.8); ebbg:SetAllPoints(eb)
	local ab = CreateFrame("Button","PhantomGamble_AcceptOnes_Button",f,"GameMenuButtonTemplate"); ab:SetWidth(140); ab:SetHeight(22); ab:SetPoint("TOP",eb,"BOTTOM",0,-8); ab:SetText("Open Entry"); ab:SetScript("OnClick", function() PhantomGamble_OnClickACCEPTONES() end)
	local lb = CreateFrame("Button","PhantomGamble_LASTCALL_Button",f,"GameMenuButtonTemplate"); lb:SetWidth(140); lb:SetHeight(22); lb:SetPoint("TOP",ab,"BOTTOM",0,-4); lb:SetText("Last Call"); lb:SetScript("OnClick", function() PhantomGamble_OnClickLASTCALL() end)
	local rlb = CreateFrame("Button","PhantomGamble_ROLL_Button",f,"GameMenuButtonTemplate"); rlb:SetWidth(140); rlb:SetHeight(22); rlb:SetPoint("TOP",lb,"BOTTOM",0,-4); rlb:SetText("Roll"); rlb:SetScript("OnClick", function() PhantomGamble_OnClickROLL() end)
	local cnb = CreateFrame("Button","PhantomGamble_Cancel_Button",f,"GameMenuButtonTemplate"); cnb:SetWidth(140); cnb:SetHeight(22); cnb:SetPoint("TOP",rlb,"BOTTOM",0,-4); cnb:SetText("Cancel"); cnb:SetScript("OnClick", function() PhantomGamble_OnClickCANCEL() end); cnb:Disable()

	-- ==========================================
	-- PANEL 2: Death Roll
	-- ==========================================
	local drt = f:CreateFontString("PhantomGamble_DRTitle","OVERLAY","GameFontNormalSmall"); drt:SetPoint("TOP",f,"TOP",0,cTop); drt:SetText("|cffff0000Death Roll|r")
	local dsl = f:CreateFontString("PhantomGamble_DR_StartLabel","OVERLAY","GameFontNormalSmall"); dsl:SetPoint("TOPLEFT",drt,"BOTTOM",-55,-10); dsl:SetWidth(35); dsl:SetJustifyH("RIGHT"); dsl:SetText("|cffffffffStart:|r")
	local dss = CreateFrame("Button","PhantomGamble_DR_StartSelect",f); dss:SetWidth(70); dss:SetHeight(20); dss:SetPoint("LEFT",dsl,"RIGHT",5,0)
	local dssbg = dss:CreateTexture(nil,"BACKGROUND"); dssbg:SetTexture(0.1,0.1,0.1,0.8); dssbg:SetAllPoints(dss)
	local dsst = dss:CreateFontString("PhantomGamble_DR_StartSelectText","OVERLAY","GameFontHighlightSmall"); dsst:SetPoint("CENTER",dss,"CENTER",-5,0); dsst:SetText("100")
	local dssa = dss:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); dssa:SetPoint("RIGHT",dss,"RIGHT",-3,0); dssa:SetText("v")
	dss:SetHighlightTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	local dsdd = CreateFrame("Frame","PhantomGamble_DR_StartDropdown",f); dsdd:SetWidth(70); dsdd:SetHeight(110); dsdd:SetPoint("TOP",dss,"BOTTOM",0,0); dsdd:SetFrameStrata("TOOLTIP"); dsdd:Hide()
	local dsddbg = dsdd:CreateTexture(nil,"BACKGROUND"); dsddbg:SetTexture(0,0,0,0.9); dsddbg:SetAllPoints(dsdd)
	local startOpts = {10,50,100,1000,10000}
	for i,val in ipairs(startOpts) do
		local ob = CreateFrame("Button","PhantomGamble_DR_StartOpt"..i,dsdd); ob:SetWidth(68); ob:SetHeight(20); ob:SetPoint("TOP",dsdd,"TOP",0,-2-((i-1)*21))
		local ot = ob:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); ot:SetPoint("CENTER",ob,"CENTER",0,0)
		if val>=10000 then ot:SetText("10,000") elseif val>=1000 then ot:SetText("1,000") else ot:SetText(tostring(val)) end
		ob:SetHighlightTexture("Interface/Buttons/UI-Panel-Button-Highlight"); ob.value=val
		ob:SetScript("OnClick", function() DR_StartNumber=this.value; local dt; if this.value>=10000 then dt="10,000" elseif this.value>=1000 then dt="1,000" else dt=tostring(this.value) end; PhantomGamble_DR_StartSelectText:SetText(dt); PhantomGamble["lastDRStart"]=this.value; dsdd:Hide() end)
	end
	dss:SetScript("OnClick", function() if dsdd:IsVisible() then dsdd:Hide() else dsdd:Show() end end)
	local dgl = f:CreateFontString("PhantomGamble_DR_GoldLabel","OVERLAY","GameFontNormalSmall"); dgl:SetPoint("TOPLEFT",dsl,"BOTTOMLEFT",0,-10); dgl:SetWidth(35); dgl:SetJustifyH("RIGHT"); dgl:SetText("|cffffd700Gold:|r")
	local dge = CreateFrame("EditBox","PhantomGamble_DR_GoldEditBox",f); dge:SetWidth(70); dge:SetHeight(20); dge:SetPoint("LEFT",dgl,"RIGHT",5,0)
	dge:SetFontObject(ChatFontNormal); dge:SetAutoFocus(false); dge:SetNumeric(true); dge:SetMaxLetters(6); dge:SetJustifyH("CENTER")
	dge:SetScript("OnEscapePressed", function() this:ClearFocus() end); dge:SetScript("OnEnterPressed", function() this:ClearFocus() end)
	local dgebg = dge:CreateTexture(nil,"BACKGROUND"); dgebg:SetTexture(0.1,0.1,0.1,0.8); dgebg:SetAllPoints(dge)
	local dsb = CreateFrame("Button","PhantomGamble_DR_StartBtn",f,"GameMenuButtonTemplate"); dsb:SetWidth(140); dsb:SetHeight(22); dsb:SetPoint("TOP",drt,"BOTTOM",0,-80); dsb:SetText("Start Death Roll"); dsb:SetScript("OnClick", function() PhantomGamble_DR_Start() end)
	local dcb = CreateFrame("Button","PhantomGamble_DR_CancelBtn",f,"GameMenuButtonTemplate"); dcb:SetWidth(140); dcb:SetHeight(22); dcb:SetPoint("TOP",dsb,"BOTTOM",0,-4); dcb:SetText("Cancel"); dcb:SetScript("OnClick", function() PhantomGamble_DR_Cancel() end); dcb:Disable()
	local dst = f:CreateFontString("PhantomGamble_DR_Status","OVERLAY","GameFontNormalSmall"); dst:SetPoint("TOP",dcb,"BOTTOM",0,-8); dst:SetWidth(180); dst:SetText("|cffffff00Waiting...|r")

	-- ==========================================
	-- PANEL 3: Trivia (GOLD UI REMOVED)
	-- ==========================================
	local trt = f:CreateFontString("PhantomGamble_TRTitle","OVERLAY","GameFontNormalSmall"); trt:SetPoint("TOP",f,"TOP",0,cTop); trt:SetText("|cffffff00WoW Trivia|r")

	-- Expansion dropdown
	local tel = f:CreateFontString("PhantomGamble_TR_ExpLabel","OVERLAY","GameFontNormalSmall"); tel:SetPoint("TOPLEFT",trt,"BOTTOM",-80,-8); tel:SetWidth(50); tel:SetJustifyH("RIGHT"); tel:SetText("|cffffffffExpac:|r")
	local tes = CreateFrame("Button","PhantomGamble_TR_ExpSelect",f); tes:SetWidth(110); tes:SetHeight(18); tes:SetPoint("LEFT",tel,"RIGHT",5,0)
	local tesbg = tes:CreateTexture(nil,"BACKGROUND"); tesbg:SetTexture(0.1,0.1,0.1,0.8); tesbg:SetAllPoints(tes)
	local test = tes:CreateFontString("PhantomGamble_TR_ExpSelectText","OVERLAY","GameFontHighlightSmall"); test:SetPoint("CENTER",tes,"CENTER",-5,0); test:SetText("All")
	local tesa = tes:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); tesa:SetPoint("RIGHT",tes,"RIGHT",-3,0); tesa:SetText("v")
	tes:SetHighlightTexture("Interface/Buttons/UI-Panel-Button-Highlight")

	local tedd = CreateFrame("Frame","PhantomGamble_TR_ExpDropdown",f); tedd:SetWidth(140); tedd:SetHeight(table.getn(TriviaExpansions)*18+4); tedd:SetPoint("TOP",tes,"BOTTOM",0,0); tedd:SetFrameStrata("TOOLTIP"); tedd:Hide()
	local teddbg = tedd:CreateTexture(nil,"BACKGROUND"); teddbg:SetTexture(0,0,0,0.95); teddbg:SetAllPoints(tedd)
	for i,expName in ipairs(TriviaExpansions) do
		local ob = CreateFrame("Button","PhantomGamble_TR_ExpOpt"..i,tedd); ob:SetWidth(138); ob:SetHeight(17); ob:SetPoint("TOP",tedd,"TOP",0,-2-((i-1)*18))
		local ot = ob:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); ot:SetPoint("LEFT",ob,"LEFT",5,0); ot:SetText(expName)
		ob:SetHighlightTexture("Interface/Buttons/UI-Panel-Button-Highlight"); ob.value=expName
		ob:SetScript("OnClick", function() TR_SelectedExpansion=this.value; PhantomGamble_TR_ExpSelectText:SetText(this.value); tedd:Hide() end)
	end
	tes:SetScript("OnClick", function() if tedd:IsVisible() then tedd:Hide() else tedd:Show(); if PhantomGamble_TR_RoundsDropdown then PhantomGamble_TR_RoundsDropdown:Hide() end end end)

	-- Rounds dropdown
	local trl = f:CreateFontString("PhantomGamble_TR_RoundsLabel","OVERLAY","GameFontNormalSmall"); trl:SetPoint("TOPLEFT",tel,"BOTTOMLEFT",0,-8); trl:SetWidth(50); trl:SetJustifyH("RIGHT"); trl:SetText("|cffffffffRounds:|r")
	local trs = CreateFrame("Button","PhantomGamble_TR_RoundsSelect",f); trs:SetWidth(50); trs:SetHeight(18); trs:SetPoint("LEFT",trl,"RIGHT",5,0)
	local trsbg = trs:CreateTexture(nil,"BACKGROUND"); trsbg:SetTexture(0.1,0.1,0.1,0.8); trsbg:SetAllPoints(trs)
	local trst = trs:CreateFontString("PhantomGamble_TR_RoundsSelectText","OVERLAY","GameFontHighlightSmall"); trst:SetPoint("CENTER",trs,"CENTER",-5,0); trst:SetText("5")
	local trsa = trs:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); trsa:SetPoint("RIGHT",trs,"RIGHT",-3,0); trsa:SetText("v")
	trs:SetHighlightTexture("Interface/Buttons/UI-Panel-Button-Highlight")

	local roundOpts = {3,5,10,15,20}
	local trdd = CreateFrame("Frame","PhantomGamble_TR_RoundsDropdown",f); trdd:SetWidth(50); trdd:SetHeight(table.getn(roundOpts)*20+4); trdd:SetPoint("TOP",trs,"BOTTOM",0,0); trdd:SetFrameStrata("TOOLTIP"); trdd:Hide()
	local trddbg = trdd:CreateTexture(nil,"BACKGROUND"); trddbg:SetTexture(0,0,0,0.95); trddbg:SetAllPoints(trdd)
	for i,val in ipairs(roundOpts) do
		local ob = CreateFrame("Button","PhantomGamble_TR_RoundsOpt"..i,trdd); ob:SetWidth(48); ob:SetHeight(18); ob:SetPoint("TOP",trdd,"TOP",0,-2-((i-1)*20))
		local ot = ob:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); ot:SetPoint("CENTER",ob,"CENTER",0,0); ot:SetText(tostring(val))
		ob:SetHighlightTexture("Interface/Buttons/UI-Panel-Button-Highlight"); ob.value=val
		ob:SetScript("OnClick", function() TR_TotalRounds=this.value; PhantomGamble_TR_RoundsSelectText:SetText(tostring(this.value)); trdd:Hide() end)
	end
	trs:SetScript("OnClick", function() if trdd:IsVisible() then trdd:Hide() else trdd:Show(); tedd:Hide() end end)

	-- GOLD WAGER UI REMOVED - Buttons positioned closer
	-- Trivia buttons
	local tsb = CreateFrame("Button","PhantomGamble_TR_StartBtn",f,"GameMenuButtonTemplate"); tsb:SetWidth(140); tsb:SetHeight(22); tsb:SetPoint("TOP",trt,"BOTTOM",0,-80); tsb:SetText("Start Trivia"); tsb:SetScript("OnClick", function() PhantomGamble_TR_Start() end)
	local tab = CreateFrame("Button","PhantomGamble_TR_AskBtn",f,"GameMenuButtonTemplate"); tab:SetWidth(140); tab:SetHeight(22); tab:SetPoint("TOP",tsb,"BOTTOM",0,-4); tab:SetText("Ask Question"); tab:SetScript("OnClick", function() PhantomGamble_TR_AskQuestion() end); tab:Disable()
	local tcb = CreateFrame("Button","PhantomGamble_TR_CancelBtn",f,"GameMenuButtonTemplate"); tcb:SetWidth(140); tcb:SetHeight(22); tcb:SetPoint("TOP",tab,"BOTTOM",0,-4); tcb:SetText("Cancel"); tcb:SetScript("OnClick", function() PhantomGamble_TR_Cancel() end); tcb:Disable()
	local tst = f:CreateFontString("PhantomGamble_TR_Status","OVERLAY","GameFontNormalSmall"); tst:SetPoint("TOP",tcb,"BOTTOM",0,-8); tst:SetWidth(180); tst:SetText("|cffffff00Waiting...|r")

	-- ==========================================
	-- BOTTOM - Shared Controls
	-- ==========================================
	local chatBtn = CreateFrame("Button","PhantomGamble_CHAT_Button",f,"GameMenuButtonTemplate"); chatBtn:SetWidth(70); chatBtn:SetHeight(20); chatBtn:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",15,30); chatBtn:SetText("RAID"); chatBtn:SetScript("OnClick", function() PhantomGamble_OnClickCHAT() end)
	local whisperBtn = CreateFrame("Button","PhantomGamble_WHISPER_Button",f,"GameMenuButtonTemplate"); whisperBtn:SetWidth(90); whisperBtn:SetHeight(20); whisperBtn:SetPoint("LEFT",chatBtn,"RIGHT",5,0); whisperBtn:SetText("(No Whispers)"); whisperBtn:SetScript("OnClick", function() PhantomGamble_OnClickWHISPERS() end)

	-- Resize grip
	local rz = CreateFrame("Button","PhantomGamble_ResizeButton",f); rz:SetWidth(16); rz:SetHeight(16); rz:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-2,2); rz:EnableMouse(true)
	local rzt = rz:CreateTexture(nil,"OVERLAY"); rzt:SetTexture("Interface/ChatFrame/UI-ChatIM-SizeGrabber-Up"); rzt:SetAllPoints(rz)
	rz:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
	rz:SetScript("OnMouseUp", function() f:StopMovingOrSizing() end)
	rz:SetScript("OnEnter", function() GameTooltip:SetOwner(this,"ANCHOR_TOPLEFT"); GameTooltip:SetText("Drag to resize"); GameTooltip:Show() end)
	rz:SetScript("OnLeave", function() GameTooltip:Hide() end)

	-- Default: show Regular Gamble, hide others
	ShowMode(1)
	return f
end

-- ============================================
-- MINIMAP BUTTON
-- ============================================
local function CreateMinimapButton()
	local btn = CreateFrame("Button","PG_MinimapButton",Minimap); btn:SetWidth(32); btn:SetHeight(32); btn:SetFrameStrata("MEDIUM"); btn:SetFrameLevel(8); btn:EnableMouse(true)
	btn:RegisterForClicks("LeftButtonUp","RightButtonUp"); btn:RegisterForDrag("LeftButton")
	btn:SetHighlightTexture("Interface/Minimap/UI-Minimap-ZoomButton-Highlight")
	local icon = btn:CreateTexture(nil,"BACKGROUND"); icon:SetWidth(20); icon:SetHeight(20); icon:SetTexture("Interface/Icons/INV_Misc_Coin_01"); icon:SetPoint("CENTER",btn,"CENTER",0,0)
	local border = btn:CreateTexture(nil,"OVERLAY"); border:SetWidth(52); border:SetHeight(52); border:SetTexture("Interface/Minimap/MiniMap-TrackingBorder"); border:SetPoint("TOPLEFT",btn,"TOPLEFT",0,0)
	btn:SetScript("OnClick", function() PG_MinimapButton_OnClick() end)
	btn:SetScript("OnDragStart", function() this:LockHighlight(); this:SetScript("OnUpdate", PG_MinimapButton_DraggingFrame_OnUpdate) end)
	btn:SetScript("OnDragStop", function() this:SetScript("OnUpdate",nil); this:UnlockHighlight() end)
	btn:SetScript("OnEnter", function() GameTooltip:SetOwner(this,"ANCHOR_LEFT"); GameTooltip:SetText("|cffFFD700PhantomGamble|r"); GameTooltip:AddLine("Click to toggle",1,1,1); GameTooltip:Show() end)
	btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
	PG_MinimapButton_Reposition(); return btn
end

function PG_MinimapButton_Reposition()
	if not PG_MinimapButton then return end
	if not PG_Settings then PG_Settings = { MinimapPos = 75 } end
	local angle = math.rad(PG_Settings.MinimapPos)
	PG_MinimapButton:ClearAllPoints()
	PG_MinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 52-(80*math.cos(angle)), (80*math.sin(angle))-52)
end

function PG_MinimapButton_DraggingFrame_OnUpdate()
	if not PG_Settings then PG_Settings = { MinimapPos = 75 } end
	local x,y = GetCursorPosition(); local s = UIParent:GetEffectiveScale(); x,y = x/s, y/s
	local cx,cy = Minimap:GetCenter()
	PG_Settings.MinimapPos = math.deg(math.atan2(y-cy, x-cx))
	PG_MinimapButton_Reposition()
end

function PG_MinimapButton_OnClick()
	if PhantomGamble and PhantomGamble["active"]==1 then PhantomGamble_Frame:Hide(); PhantomGamble["active"]=0
	else PhantomGamble_Frame:Show(); if PhantomGamble then PhantomGamble["active"]=1 end end
end

-- ============================================
-- DEATH ROLL FUNCTIONS
-- ============================================
function PhantomGamble_DR_Start()
	local gt = PhantomGamble_DR_GoldEditBox:GetText()
	if not DR_StartNumber or DR_StartNumber < 2 then DR_StartNumber = 100 end
	if gt=="" or not tonumber(gt) or tonumber(gt)<1 then DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Please enter a valid gold wager.|r"); return end
	DR_GoldWager = tonumber(gt); DR_CurrentMax = DR_StartNumber; DR_Active = false; DR_AcceptingPlayers = true; DR_Player1 = nil; DR_Player2 = nil; DR_WaitingForRoll = false
	PhantomGamble["lastDRStart"] = DR_StartNumber; PhantomGamble["lastDRGold"] = DR_GoldWager
	ChatMsg("Death Roll! Starting at "..DR_StartNumber.." for "..DR_GoldWager.." gold! Type 1 to join (need 2 players).")
	PhantomGamble_DR_StartBtn:SetText("Waiting..."); PhantomGamble_DR_StartBtn:Disable(); PhantomGamble_DR_CancelBtn:Enable()
	PhantomGamble_DR_Status:SetText("|cffffff00Waiting for players...|r")
end

function PhantomGamble_DR_Cancel()
	DR_Active=false; DR_AcceptingPlayers=false; DR_Player1=nil; DR_Player2=nil; DR_WaitingForRoll=false; DR_CurrentMax=0
	PhantomGamble_DR_StartBtn:SetText("Start Death Roll"); PhantomGamble_DR_StartBtn:Enable(); PhantomGamble_DR_CancelBtn:Disable()
	PhantomGamble_DR_Status:SetText("|cffffff00Cancelled|r"); ChatMsg("Death Roll has been cancelled.")
end

function PhantomGamble_DR_AddPlayer(name)
	if not DR_AcceptingPlayers then return end
	if DR_Player1 and string.lower(DR_Player1)==string.lower(name) then return end
	if DR_Player2 and string.lower(DR_Player2)==string.lower(name) then return end
	if not DR_Player1 then
		DR_Player1 = name; Print("","",name.." joined Death Roll as Player 1")
		PhantomGamble_DR_Status:SetText("|cff00ff00P1: "..name.."|r\n|cffffff00Waiting for P2...|r")
		if whispermethod then SendChatMessage("You joined as Player 1!","WHISPER",nil,name) end
	elseif not DR_Player2 then
		DR_Player2 = name; Print("","",name.." joined Death Roll as Player 2"); DR_AcceptingPlayers = false
		DR_Active = true; DR_CurrentRoller = DR_Player1; DR_WaitingForRoll = true
		PhantomGamble_DR_Status:SetText("|cff00ff00P1: "..DR_Player1.."|r\n|cff00ff00P2: "..DR_Player2.."|r")
		ChatMsg("Death Roll started! "..DR_Player1.." vs "..DR_Player2.." - Start: "..DR_StartNumber..", Wager: "..DR_GoldWager.." gold!")
		ChatMsg(DR_Player1.." rolls first! /random 1-"..DR_CurrentMax)
		if whispermethod then SendChatMessage("You joined as Player 2!","WHISPER",nil,name) end
	end
end

function PhantomGamble_DR_ParseRoll(msg)
	if not DR_Active or not DR_WaitingForRoll then return end
	local _,_,name,roll,minroll,maxroll = string.find(msg, "(.+) rolls (%d+) %((%d+)%-(%d+)%)")
	if not name then return end
	roll=tonumber(roll); minroll=tonumber(minroll); maxroll=tonumber(maxroll)
	if string.lower(name)~=string.lower(DR_CurrentRoller) then return end
	if minroll~=1 or maxroll~=DR_CurrentMax then ChatMsg(name.." rolled wrong range! Should be 1-"..DR_CurrentMax); return end
	if roll == 1 then
		local winner,loser
		if string.lower(DR_CurrentRoller)==string.lower(DR_Player1) then loser=DR_Player1; winner=DR_Player2
		else loser=DR_Player2; winner=DR_Player1 end
		winner=string.upper(string.sub(winner,1,1))..string.sub(winner,2)
		loser=string.upper(string.sub(loser,1,1))..string.sub(loser,2)
		ChatMsg("DEATH! "..loser.." rolled a 1!")
		ChatMsg(loser.." owes "..winner.." "..DR_GoldWager.." gold!")
		PhantomGamble["stats"][winner]=(PhantomGamble["stats"][winner] or 0)+DR_GoldWager
		PhantomGamble["stats"][loser]=(PhantomGamble["stats"][loser] or 0)-DR_GoldWager
		statsNeedUpdate=true; AddDebt(loser, winner, DR_GoldWager)
		if PhantomGamble_StatsFrame and PhantomGamble_StatsFrame:IsVisible() then RefreshStatsDisplay() end
		if PhantomGamble_DebtsFrame and PhantomGamble_DebtsFrame:IsVisible() then RefreshDebtsDisplay() end
		DR_Active=false; DR_WaitingForRoll=false; DR_Player1=nil; DR_Player2=nil
		PhantomGamble_DR_StartBtn:SetText("Start Death Roll"); PhantomGamble_DR_StartBtn:Enable(); PhantomGamble_DR_CancelBtn:Disable()
		PhantomGamble_DR_Status:SetText("|cff00ff00"..winner.." wins!|r"); return
	end
	DR_CurrentMax = roll
	if string.lower(DR_CurrentRoller)==string.lower(DR_Player1) then DR_CurrentRoller=DR_Player2 else DR_CurrentRoller=DR_Player1 end
	ChatMsg(name.." rolled "..roll..". "..DR_CurrentRoller.."'s turn! /random 1-"..DR_CurrentMax)
	PhantomGamble_DR_Status:SetText("|cffffff00"..DR_CurrentRoller.."'s turn|r\n|cffffff00Roll 1-"..DR_CurrentMax.."|r")
end

-- ============================================
-- REGULAR GAMBLING FUNCTIONS
-- ============================================
function PhantomGamble_OnClickACCEPTONES()
	if PhantomGamble_AcceptOnes_Button:GetText() == "New Game" then
		PhantomGamble_Reset(); PhantomGamble_AcceptOnes_Button:SetText("Open Entry"); PhantomGamble_AcceptOnes_Button:Enable()
		PhantomGamble_ROLL_Button:Disable(); PhantomGamble_LASTCALL_Button:Disable(); PhantomGamble_Cancel_Button:Disable(); return
	end
	local et = PhantomGamble_EditBox:GetText()
	if et~="" and et~="1" and tonumber(et) then
		PhantomGamble_Reset(); PhantomGamble_ROLL_Button:Disable(); PhantomGamble_LASTCALL_Button:Disable(); PhantomGamble_Cancel_Button:Enable()
		AcceptOnes="true"; ChatMsg("Welcome to PhantomGamble! Roll Amount: "..et.." gold. Type 1 to Join or -1 to withdraw.")
		PhantomGamble["lastroll"]=et; theMax=tonumber(et); low=theMax+1; PhantomGamble_AcceptOnes_Button:SetText("New Game")
	else DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Please enter a valid number.|r") end
end

function PhantomGamble_OnClickLASTCALL() ChatMsg("Last Call to join!"); PhantomGamble_LASTCALL_Button:Disable(); PhantomGamble_ROLL_Button:Enable() end

function PhantomGamble_OnClickROLL()
	if totalrolls > 1 then AcceptOnes="false"; AcceptRolls="true"; ChatMsg("Roll now! Type /random 1-"..theMax); PhantomGamble_List()
	elseif AcceptOnes=="true" then ChatMsg("Not enough Players!") end
end

function PhantomGamble_OnClickCANCEL()
	if AcceptOnes=="true" or AcceptRolls=="true" then ChatMsg("Gambling session has been cancelled.") end
	PhantomGamble_Reset(); PhantomGamble_AcceptOnes_Button:SetText("Open Entry"); PhantomGamble_AcceptOnes_Button:Enable()
	PhantomGamble_ROLL_Button:Disable(); PhantomGamble_LASTCALL_Button:Disable(); PhantomGamble_Cancel_Button:Disable(); PhantomGamble_CHAT_Button:Enable()
	Print("","","Gambling cancelled.")
end

function PhantomGamble_OnClickCHAT()
	PhantomGamble["chat"]=(PhantomGamble["chat"] or 1)+1
	if PhantomGamble["chat"]>4 then PhantomGamble["chat"]=1 end
	chatmethod=chatmethods[PhantomGamble["chat"]]; PhantomGamble_CHAT_Button:SetText(chatmethod)
end

function PhantomGamble_OnClickWHISPERS()
	PhantomGamble["whispers"]=not PhantomGamble["whispers"]; whispermethod=PhantomGamble["whispers"]
	PhantomGamble_WHISPER_Button:SetText(whispermethod and "(Whispers)" or "(No Whispers)")
end

function PhantomGamble_OnClickSTATS(full)
	if not PhantomGamble["stats"] or not next(PhantomGamble["stats"]) then DEFAULT_CHAT_FRAME:AddMessage("No stats yet!"); return end
	DEFAULT_CHAT_FRAME:AddMessage("--- PhantomGamble Stats ---")
	for name,amount in pairs(PhantomGamble["stats"]) do
		DEFAULT_CHAT_FRAME:AddMessage(string.format("%s %s %d gold", name, amount>=0 and "won" or "lost", math.abs(amount)))
	end
end

function PhantomGamble_Report()
	local goldowed = high - low
	if goldowed ~= 0 then
		lowname=string.upper(string.sub(lowname,1,1))..string.sub(lowname,2); highname=string.upper(string.sub(highname,1,1))..string.sub(highname,2)
		PhantomGamble["stats"][highname]=(PhantomGamble["stats"][highname] or 0)+goldowed
		PhantomGamble["stats"][lowname]=(PhantomGamble["stats"][lowname] or 0)-goldowed
		statsNeedUpdate=true; AddDebt(lowname, highname, goldowed)
		if PhantomGamble_StatsFrame and PhantomGamble_StatsFrame:IsVisible() then RefreshStatsDisplay() end
		if PhantomGamble_DebtsFrame and PhantomGamble_DebtsFrame:IsVisible() then RefreshDebtsDisplay() end
		ChatMsg(string.format("%s owes %s %d gold.", lowname, highname, goldowed))
	else ChatMsg("It was a tie! No payouts!") end
	PhantomGamble_Reset(); PhantomGamble_AcceptOnes_Button:SetText("Open Entry"); PhantomGamble_AcceptOnes_Button:Enable()
	PhantomGamble_ROLL_Button:Disable(); PhantomGamble_LASTCALL_Button:Disable(); PhantomGamble_Cancel_Button:Disable(); PhantomGamble_CHAT_Button:Enable()
end

function PhantomGamble_Reset()
	totalrolls,low,high,lowname,highname = 0,0,0,"",""
	tie,highbreak,lowbreak = 0,0,0; AcceptOnes,AcceptRolls = "false","false"
	if PhantomGamble then PhantomGamble.strings={}; PhantomGamble.lowtie={}; PhantomGamble.hightie={} end
end

function PhantomGamble_Add(name)
	if not PhantomGamble.strings then PhantomGamble.strings={} end
	for i,v in ipairs(PhantomGamble.strings) do if string.lower(v)==string.lower(name) then return end end
	table.insert(PhantomGamble.strings, name); totalrolls=table.getn(PhantomGamble.strings)
	if whispermethod then SendChatMessage("You joined!","WHISPER",nil,name) end
	Print("","",name.." joined. Players: "..totalrolls)
	if totalrolls>=1 then PhantomGamble_LASTCALL_Button:Enable() end
end

function PhantomGamble_Remove(name)
	if not PhantomGamble.strings then return end
	for i,v in ipairs(PhantomGamble.strings) do
		if string.lower(v)==string.lower(name) then table.remove(PhantomGamble.strings,i); totalrolls=table.getn(PhantomGamble.strings); Print("","",name.." left. Players: "..totalrolls); return end
	end
end

function PhantomGamble_ChkBan(name)
	if not PhantomGamble or not PhantomGamble.bans then return 0 end
	for i,v in ipairs(PhantomGamble.bans) do if string.lower(v)==string.lower(name) then return 1 end end; return 0
end

function PhantomGamble_List()
	if not PhantomGamble.strings or table.getn(PhantomGamble.strings)==0 then ChatMsg("No players."); return end
	local list=""
	for i,v in ipairs(PhantomGamble.strings) do list=list..(list~="" and ", " or "")..v end
	ChatMsg("Players: "..list)
end

function PhantomGamble_ParseRoll(msg)
	local _,_,name,roll,minroll,maxroll = string.find(msg, "(.+) rolls (%d+) %((%d+)%-(%d+)%)")
	if not name then return end; roll,minroll,maxroll = tonumber(roll),tonumber(minroll),tonumber(maxroll)
	local found,idx = false,nil
	if PhantomGamble.strings then for i,v in ipairs(PhantomGamble.strings) do if string.lower(v)==string.lower(name) then found,idx=true,i; break end end end
	if not found then return end; table.remove(PhantomGamble.strings, idx)
	if maxroll~=theMax or minroll~=1 then ChatMsg(name.." rolled wrong range!"); return end
	if roll>high then high,highname=roll,name end; if roll<low then low,lowname=roll,name end
	totalrolls=totalrolls-1; Print("","",name.." rolled "..roll..". Waiting: "..totalrolls)
	if totalrolls==0 then PhantomGamble_Report() end
end

-- ============================================
-- CHAT MESSAGE PARSING
-- ============================================
function PhantomGamble_ParseChatMsg(msg, sender)
	local _,_,paidTo,paidAmount = string.find(msg, "^!paid%s+(%S+)%s+(%d+)")
	if paidTo and paidAmount then
		paidAmount=tonumber(paidAmount)
		if paidAmount and paidAmount>0 then
			local success,errMsg = PayDebt(sender, paidTo, paidAmount)
			if success then ChatMsg(sender.." paid "..paidTo.." "..paidAmount.." gold. Debt updated!"); Print("","","Payment recorded: "..sender.." -> "..paidTo.." ("..paidAmount.."g)")
				if PhantomGamble_DebtsFrame and PhantomGamble_DebtsFrame:IsVisible() then RefreshDebtsDisplay() end
			else Print("","",errMsg or "Could not record payment") end
		end; return
	end

	-- Trivia answers
	if TR_Active and TR_WaitingForAnswers then PhantomGamble_TR_ParseChat(msg, sender) end

	-- Death Roll join
	if msg=="1" and DR_AcceptingPlayers then PhantomGamble_DR_AddPlayer(sender); return end

	-- Regular gambling
	if msg=="1" and AcceptOnes=="true" then
		if PhantomGamble_ChkBan(sender)==0 then PhantomGamble_Add(sender); if totalrolls>=2 then PhantomGamble_AcceptOnes_Button:Disable() end
		else ChatMsg("Sorry, you're banned!") end
	elseif msg=="-1" and AcceptOnes=="true" then PhantomGamble_Remove(sender) end
end

-- ============================================
-- SLASH COMMANDS
-- ============================================
function PhantomGamble_SlashCmd(msg)
	msg = string.lower(msg or "")
	if msg=="" then Print("","","Commands: show, hide, stats, debts, reset, fullstats, resetstats, resetdebts, minimap, ban, unban, listban"); return end
	if msg=="hide" then PhantomGamble_Frame:Hide(); PhantomGamble["active"]=0
	elseif msg=="show" then PhantomGamble_Frame:Show(); PhantomGamble["active"]=1
	elseif msg=="stats" then if not PhantomGamble_StatsFrame then CreateStatsWindow() end; PhantomGamble_StatsFrame:Show()
	elseif msg=="debts" then if not PhantomGamble_DebtsFrame then CreateDebtsWindow() end; PhantomGamble_DebtsFrame:Show()
	elseif msg=="reset" then PhantomGamble_Reset(); PhantomGamble_DR_Cancel(); Print("","","PhantomGamble has been reset.")
	elseif msg=="fullstats" then PhantomGamble_OnClickSTATS(true)
	elseif msg=="resetstats" then PhantomGamble["stats"]={}; statsNeedUpdate=true; Print("","","Stats have been reset.")
	elseif msg=="resetdebts" then PhantomGamble["debts"]={}; debtsNeedUpdate=true; Print("","","Debts have been reset.")
	elseif msg=="minimap" then PhantomGamble["minimap"]=not PhantomGamble["minimap"]; if PhantomGamble["minimap"] then PG_MinimapButton:Show() else PG_MinimapButton:Hide() end
	elseif string.sub(msg,1,4)=="ban " then
		local name=string.sub(msg,5); if not PhantomGamble.bans then PhantomGamble.bans={} end; table.insert(PhantomGamble.bans,name); Print("","",name.." banned.")
	elseif string.sub(msg,1,6)=="unban " then
		local name=string.sub(msg,7)
		if PhantomGamble.bans then for i,v in ipairs(PhantomGamble.bans) do if string.lower(v)==string.lower(name) then table.remove(PhantomGamble.bans,i); Print("","",name.." unbanned."); return end end end
	elseif msg=="listban" then
		if not PhantomGamble.bans or table.getn(PhantomGamble.bans)==0 then Print("","","No bans.")
		else for i,v in ipairs(PhantomGamble.bans) do DEFAULT_CHAT_FRAME:AddMessage("  "..v) end end
	else Print("","","Unknown command: "..msg) end
end

SLASH_PHANTOMGAMBLE1 = "/phantomgamble"
SLASH_PHANTOMGAMBLE2 = "/pg"
SlashCmdList["PHANTOMGAMBLE"] = PhantomGamble_SlashCmd

-- ============================================
-- EVENT HANDLING
-- ============================================
function PhantomGamble_OnEvent()
	if event == "PLAYER_ENTERING_WORLD" then
		if not PhantomGamble_Frame then CreateMainFrame() end
		if not PG_MinimapButton then CreateMinimapButton() end
		if not PhantomGamble then
			PhantomGamble = { active=1, chat=1, channel="gambling", whispers=false, strings={}, lowtie={}, hightie={}, bans={}, minimap=true, lastroll=100, stats={}, joinstats={}, debts={} }
		end
		if not PhantomGamble["debts"] then PhantomGamble["debts"] = {} end
		PhantomGamble_EditBox:SetText(tostring(PhantomGamble["lastroll"] or 100))
		DR_StartNumber = PhantomGamble["lastDRStart"] or 100
		if PhantomGamble_DR_StartSelectText then
			local dt; if DR_StartNumber>=10000 then dt="10,000" elseif DR_StartNumber>=1000 then dt="1,000" else dt=tostring(DR_StartNumber) end
			PhantomGamble_DR_StartSelectText:SetText(dt)
		end
		PhantomGamble_DR_GoldEditBox:SetText(tostring(PhantomGamble["lastDRGold"] or 100))
		-- Restore trivia settings (GOLD REMOVED)
		TR_TotalRounds = PhantomGamble["lastTRRounds"] or 5
		TR_SelectedExpansion = PhantomGamble["lastTRExpansion"] or "All"
		if PhantomGamble_TR_RoundsSelectText then PhantomGamble_TR_RoundsSelectText:SetText(tostring(TR_TotalRounds)) end
		if PhantomGamble_TR_ExpSelectText then PhantomGamble_TR_ExpSelectText:SetText(TR_SelectedExpansion) end
		chatmethod = chatmethods[PhantomGamble["chat"] or 1] or "RAID"
		PhantomGamble_CHAT_Button:SetText(chatmethod)
		if PhantomGamble["minimap"] then PG_MinimapButton:Show() else PG_MinimapButton:Hide() end
		whispermethod = PhantomGamble["whispers"] or false
		PhantomGamble_WHISPER_Button:SetText(whispermethod and "(Whispers)" or "(No Whispers)")
		if PhantomGamble["active"]==1 then PhantomGamble_Frame:Show() else PhantomGamble_Frame:Hide() end
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00PhantomGamble loaded!|r Type |cffFFD700/pg|r for commands.")
	end

	local chatEvent = false
	if (event=="CHAT_MSG_RAID_LEADER" or event=="CHAT_MSG_RAID") and PhantomGamble["chat"]==1 then chatEvent=true
	elseif event=="CHAT_MSG_GUILD" and PhantomGamble["chat"]==2 then chatEvent=true
	elseif event=="CHAT_MSG_PARTY" and PhantomGamble["chat"]==3 then chatEvent=true
	elseif event=="CHAT_MSG_SAY" and PhantomGamble["chat"]==4 then chatEvent=true end

	if chatEvent then PhantomGamble_ParseChatMsg(arg1, arg2) end

	if event == "CHAT_MSG_SYSTEM" then
		if DR_Active then PhantomGamble_DR_ParseRoll(tostring(arg1)) end
		if AcceptRolls == "true" then PhantomGamble_ParseRoll(tostring(arg1)) end
	end
end

-- ============================================
-- TRIVIA TIMER (OnUpdate handler)
-- ============================================
local PG_TimerFrame = CreateFrame("Frame", "PhantomGamble_TimerFrame", UIParent)
local PG_TimerElapsed = 0
PG_TimerFrame:SetScript("OnUpdate", function()
	if not TR_TimerActive then return end
	PG_TimerElapsed = PG_TimerElapsed + arg1
	if PG_TimerElapsed >= 1 then
		PG_TimerElapsed = 0
		TR_QuestionTimer = TR_QuestionTimer - 1
		if TR_QuestionTimer <= 0 then
			TR_EndRound()
		elseif TR_QuestionTimer == 15 then
			ChatMsg("15 seconds remaining!")
		elseif TR_QuestionTimer == 5 then
			ChatMsg("5 seconds remaining!")
		end
	end
end)

-- ============================================
-- EVENT FRAME REGISTRATION
-- ============================================
local PhantomGamble_EventFrame = CreateFrame("Frame", "PhantomGamble_EventFrame", UIParent)
PhantomGamble_EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
PhantomGamble_EventFrame:RegisterEvent("CHAT_MSG_RAID")
PhantomGamble_EventFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
PhantomGamble_EventFrame:RegisterEvent("CHAT_MSG_GUILD")
PhantomGamble_EventFrame:RegisterEvent("CHAT_MSG_PARTY")
PhantomGamble_EventFrame:RegisterEvent("CHAT_MSG_SAY")
PhantomGamble_EventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
PhantomGamble_EventFrame:SetScript("OnEvent", PhantomGamble_OnEvent)
