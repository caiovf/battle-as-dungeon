class_name Data
## Tabelas do jogo. Mexa nos números à vontade para balancear.

# ===== Ajustes gerais =====
const CFG := {
	"START": 60.0,
	"SELL": 0.5, "RESET_REFUND": 0.5,
	"FIRST_DELAY": 0.6,
	"BELL_COST": 5, "BELL_FREEZE": 2.0, "BELL_CD": 8.0,
	"COMBO_WINDOW": 1.2, "COMBO_STEP": 0.25, "COMBO_MAX": 2.5,
	"GREED_MUL": 1.5,
	"BENDS": [3, 5],
	"SPECIAL_FROM": 4, "SPECIAL_CHANCE": 0.08,
	# Fama em %: cada ponto deixa os heróis mais perigosos (vida +1% e dano +0,5% por ponto)
	"FAME_WAVE": 3.0, "FAME_KILL": 0.15, "FAME_COMBO": 0.15, "FAME_LEG": 10.0,
	"FAME_HP": 1.0, "FAME_DMG": 0.5,
	"LEG_FAME_FIRST": 15.0, "LEG_FAME_STEP": 25.0, "LEG_FAME_GROW": 1.2,
	# Evolução do guardião em %: cada herói derrotado o fortalece
	"EVO_KILL": 0.4, "EVO_LEG": 15.0,
	"SOUL_BASE": 1.0,   # energia absorvida por herói derrotado: 1s × (1 + fama%)
	"SOUL_LEG": 10.0,   # lendário vale 10× isso
	"LEG_RES": 0.45,    # lendário no corredor só sofre 45% do dano
	"LEG_HP_GROWTH": 0.22,      # vida do lendário na arena a cada lendário que já caiu
	"LEG_MAP_HP_GROWTH": 0.35,  # vida do lendário no corredor a cada lendário que já caiu
	"ARENA_BONUS": 10.0,
	# dano dos lendários na arena acompanha o relógio: cada golpe tira uma fatia do tempo que você tinha
	# ao entrar na sala (relógio/LEG_DMG_REF, com expoente para guardar tempo ainda ajudar um pouco)
	"LEG_DMG_REF": 185.0, "LEG_DMG_EXP": 0.9, "LEG_DMG_MIN": 0.5, "LEG_DMG_GROWTH": 0.11, "LEG_FAME_DMG": 0.4, "LEG_FAME_HP": 0.5,
	"LEG_ARENA_HP": 2.0,   # vida dos lendários na arena (multiplica LEG_ARENA.hp)
	"AURA": 2.5,
	"HERO_HP_GROWTH": 0.10, "HERO_DMG_GROWTH": 0.05, "HERO_SPD_GROWTH": 0.015, "HERO_STEAL_GROWTH": 0.15,
	"HERO_COUNT": [4, 2],
	"DRAIN_BASE": 0.6, "DRAIN_GROWTH": 0.08, "DRAIN_MAX": 2.5,
	"EVENT_FROM": 2, "EVENT_CHANCE": 0.45,
	"MON_LVL_GAIN": 0.35, "MON_UP_COST": 1.5,
	"LEGENDARY_WEIGHT": 2.5,
	"FAME_PER_RUN": 0.03, "FAME_MAX": 0.6,   # vida extra dos heróis por run já jogada
	"FORGET_WAVES": 2,
	# Níveis: 0 nada · 1 repararam · 2 desconfiados · 3 estudando · 4 conhecem bem
	"ABUSE_MIN": 3,
	"ABUSE_HEAVY": {"share": 0.6, "cover": 0.25, "uses": 6},
	"ABUSE_EXTREME": {"share": 0.8, "cover": 0.45, "uses": 10},
	"LEARN_WAVES": 2,
	"KNOW_RESIST": [1.0, 0.9, 0.78, 0.62, 0.45],
	"KNOW_POWER": [1.0, 1.1, 1.25, 1.5, 2.0],
	"KNOW_DODGE": [0.0, 0.1, 0.2, 0.35, 0.6],
	"COUNTER_CHANCE": [0.0, 1.0, 1.0, 1.0, 1.0],
	"COUNTER_COUNT": [0, 1, 1, 2, 3],
	"DISARM_MUL": [1.0, 0.85, 0.7, 0.5, 0.0],
}

const T := 40
const COLS := 18
const ROWS := 12
const W := T * COLS   # 720
const H := T * ROWS   # 480
const PATH_LEN := [28, 52]

# ===== Ferramentas da masmorra =====
const TOOLS := {
	"espinhos": {"kind": "trap", "nome": "Espinhos", "custo": 5, "on_path": true, "cor": 0xb9c2c9, "desc": "Fere quem pisa"},
	"besta": {"kind": "trap", "nome": "Besta", "custo": 8, "on_path": false, "cor": 0xd0a245, "alcance": 2.6, "desc": "Atira no mais adiantado"},
	"ampulheta": {"kind": "trap", "nome": "Ampulheta", "custo": 6, "on_path": false, "cor": 0x7fb8c9, "alcance": 2.1, "desc": "Deixa heróis lentos"},
	"fogo": {"kind": "trap", "nome": "Fogueira", "custo": 10, "on_path": true, "cor": 0xe0613a, "alcance": 1.25, "desc": "Explode em área"},
	"ganancia": {"kind": "trap", "nome": "Ganância", "custo": 7, "on_path": false, "cor": 0x9fd36b, "alcance": 2.1, "desc": "Abates perto dão 1,5×"},
	"alcapao": {"kind": "trap", "nome": "Alçapão", "custo": 12, "on_path": true, "cor": 0x8a6a44, "desc": "Engole 1 herói a cada 6s"},
	"runa": {"kind": "trap", "nome": "Runa de gelo", "custo": 9, "on_path": false, "cor": 0x9fd3ff, "alcance": 2.4, "desc": "Congela o mais adiantado"},
	"esqueleto": {"kind": "monster", "nome": "Esqueleto", "custo": 6, "cor": 0xe6dcc3, "hp": 45, "dps": 9, "cap": 1, "vel": 55, "desc": "Luta com todos ao alcance; golpeia 1 por vez"},
	"ogro": {"kind": "monster", "nome": "Ogro", "custo": 14, "cor": 0x7a8c4a, "hp": 160, "dps": 22, "cap": 2, "vel": 34, "desc": "Golpe pesado que atinge 2 heróis"},
	"morcego": {"kind": "monster", "nome": "Morcego", "custo": 5, "cor": 0x6a4c8c, "hp": 22, "dps": 13, "cap": 1, "vel": 100, "desc": "Rápido e frágil"},
	"gosma": {"kind": "monster", "nome": "Gosma", "custo": 8, "cor": 0x7fcf6a, "hp": 70, "dps": 6, "cap": 2, "vel": 40, "desc": "Se divide em duas ao morrer"},
	"espectro": {"kind": "monster", "nome": "Espectro", "custo": 11, "cor": 0xbfe6ef, "hp": 1, "dps": 18, "cap": 0, "vel": 45, "desc": "Atravessa heróis e fere todos; some em 25s"},
	"golem": {"kind": "monster", "nome": "Golem", "custo": 20, "cor": 0x8c8a86, "hp": 420, "dps": 14, "cap": 3, "vel": 22, "desc": "Muralha; golpe atinge 3 heróis"},
	"aranha": {"kind": "monster", "nome": "Aranha", "custo": 9, "cor": 0x3a3340, "hp": 50, "dps": 8, "cap": 1, "vel": 50, "desc": "Prende em teia quem estiver perto"},
	"mimico": {"kind": "monster", "nome": "Mímico", "custo": 10, "cor": 0x8a5a2b, "hp": 90, "dps": 12, "cap": 1, "vel": 30, "desc": "Disfarçado de baú; o primeiro bote é brutal"},
	"vampiro": {"kind": "monster", "nome": "Vampiro", "custo": 13, "cor": 0x8c1f2b, "hp": 80, "dps": 16, "cap": 1, "vel": 45, "desc": "Se cura com o sangue que tira"},
}
const TRAP_ORDER := ["espinhos", "besta", "ampulheta", "fogo", "ganancia", "alcapao", "runa"]
const MON_ORDER := ["esqueleto", "ogro", "morcego", "gosma", "aranha", "espectro", "mimico", "vampiro", "golem"]
const MON_UNLOCK := {
	"ogro": {"onda": 2, "tempo": 20}, "morcego": {"onda": 2, "tempo": 12}, "gosma": {"onda": 3, "tempo": 18},
	"aranha": {"onda": 4, "tempo": 22}, "espectro": {"onda": 5, "tempo": 26}, "mimico": {"onda": 6, "tempo": 24},
	"vampiro": {"onda": 7, "tempo": 30}, "golem": {"onda": 8, "tempo": 40},
}
const BASE_TOOLS := ["espinhos", "besta", "esqueleto"]
const FREE_POOL := ["ampulheta", "fogo", "ganancia", "ogro"]
const UNLOCK_COST := {"alcapao": 2, "runa": 2, "morcego": 1, "gosma": 2, "aranha": 2, "espectro": 3, "mimico": 3, "vampiro": 3, "golem": 4}
const COUNTER := {
	"espinhos": "acrobata", "besta": "escudeiro", "ampulheta": "andarilho", "fogo": "desarmador", "ganancia": "inquisidor",
	"alcapao": "batedor", "runa": "piromante", "esqueleto": "sacerdote", "ogro": "cacador", "morcego": "arqueiro", "gosma": "alquimista",
	"espectro": "exorcista", "golem": "mineiro", "aranha": "tocheiro", "mimico": "cacatesouro", "vampiro": "cacavampiro",
}

# ===== Heróis =====
const HEROES := {
	"mercador": {"nome": "Mercador", "hp": 90, "vel": 30, "da": 20, "rouba": 3, "dps": 2, "r": 10, "cor": 0xf2c94c},
	"guerreiro": {"nome": "Guerreiro", "hp": 28, "vel": 48, "da": 4, "rouba": 6, "dps": 10, "r": 8, "cor": 0xc9c9d6},
	"ladino": {"nome": "Ladino", "hp": 14, "vel": 86, "da": 3, "rouba": 5, "dps": 7, "r": 6, "cor": 0x8f78d6},
	"paladino": {"nome": "Paladino", "hp": 75, "vel": 33, "da": 7, "rouba": 10, "dps": 9, "r": 10, "cor": 0xeed98f},
	"acrobata": {"nome": "Acrobata", "hp": 22, "vel": 70, "da": 5, "rouba": 6, "dps": 6, "r": 7, "cor": 0xe08fb8, "special": true, "poder": "desarma espinhos"},
	"escudeiro": {"nome": "Escudeiro", "hp": 44, "vel": 40, "da": 5, "rouba": 7, "dps": 8, "r": 9, "cor": 0x8aa0b8, "special": true, "aura": true, "poder": "protege contra virotes"},
	"andarilho": {"nome": "Andarilho", "hp": 26, "vel": 56, "da": 5, "rouba": 7, "dps": 7, "r": 7, "cor": 0x7fd1c0, "special": true, "aura": true, "poder": "quebra ampulhetas"},
	"desarmador": {"nome": "Desarmador", "hp": 26, "vel": 52, "da": 5, "rouba": 7, "dps": 7, "r": 7, "cor": 0xc98a4a, "special": true, "poder": "apaga fogueiras"},
	"inquisidor": {"nome": "Inquisidor", "hp": 52, "vel": 38, "da": 6, "rouba": 8, "dps": 9, "r": 9, "cor": 0xf4f4f4, "special": true, "poder": "destrói Ganância"},
	"batedor": {"nome": "Batedor", "hp": 24, "vel": 62, "da": 5, "rouba": 6, "dps": 7, "r": 7, "cor": 0x9c8b5e, "special": true, "poder": "fecha alçapões"},
	"piromante": {"nome": "Piromante", "hp": 30, "vel": 48, "da": 5, "rouba": 7, "dps": 8, "r": 8, "cor": 0xff8a3d, "special": true, "poder": "derrete runas"},
	"sacerdote": {"nome": "Sacerdote", "hp": 36, "vel": 42, "da": 5, "rouba": 7, "dps": 8, "r": 8, "cor": 0xfff3c4, "special": true, "aura": true, "poder": "purifica esqueletos"},
	"cacador": {"nome": "Caçador", "hp": 34, "vel": 50, "da": 5, "rouba": 7, "dps": 9, "r": 8, "cor": 0xb0503e, "special": true, "aura": true, "poder": "caça ogros"},
	"arqueiro": {"nome": "Arqueiro", "hp": 26, "vel": 52, "da": 5, "rouba": 7, "dps": 7, "r": 7, "cor": 0x6fae5a, "special": true, "aura": true, "poder": "derruba morcegos"},
	"alquimista": {"nome": "Alquimista", "hp": 28, "vel": 46, "da": 5, "rouba": 7, "dps": 7, "r": 7, "cor": 0xb06fd8, "special": true, "aura": true, "poder": "dissolve gosmas"},
	"exorcista": {"nome": "Exorcista", "hp": 32, "vel": 44, "da": 5, "rouba": 7, "dps": 7, "r": 8, "cor": 0xa8e6ff, "special": true, "aura": true, "poder": "bane espectros"},
	"mineiro": {"nome": "Mineiro", "hp": 48, "vel": 36, "da": 6, "rouba": 8, "dps": 10, "r": 9, "cor": 0x8d7b6a, "special": true, "aura": true, "poder": "quebra golens"},
	"tocheiro": {"nome": "Tocheiro", "hp": 30, "vel": 48, "da": 5, "rouba": 7, "dps": 8, "r": 8, "cor": 0xffc65a, "special": true, "aura": true, "poder": "queima teias de aranha"},
	"cacatesouro": {"nome": "Caça-tesouros", "hp": 30, "vel": 52, "da": 5, "rouba": 7, "dps": 8, "r": 8, "cor": 0xd8b45a, "special": true, "aura": true, "poder": "desmascara mímicos"},
	"cacavampiro": {"nome": "Caçavampiros", "hp": 36, "vel": 46, "da": 5, "rouba": 7, "dps": 9, "r": 8, "cor": 0xd9d9e8, "special": true, "aura": true, "poder": "impede vampiros de se curar"},
	"campeao": {"nome": "Campeão", "hp": 320, "vel": 27, "da": 25, "rouba": 20, "dps": 30, "r": 13, "cor": 0xd6453a, "boss": true, "poder": "ignora lentidão, gelo, alçapão e badalada"},
	"arquimago": {"nome": "Arquimago", "hp": 240, "vel": 30, "da": 25, "rouba": 20, "dps": 14, "r": 12, "cor": 0x6b5be0, "boss": true, "poder": "apaga armadilhas"},
	"rei": {"nome": "Rei Paladino", "hp": 380, "vel": 24, "da": 30, "rouba": 25, "dps": 24, "r": 14, "cor": 0xf2c94c, "boss": true, "poder": "cura os heróis"},
	# ===== Lendários (enfrentam o guardião). "power" = poder no corredor:
	# cc ignora lentidão/gelo/badalada · mage apaga armadilhas · king cura a escolta · burn queima monstros perto
	# shield sofre bem menos dano · fast corre muito · summon chama reforços
	"lyra": {"nome": "Lyra, a Lâmina Rubra", "hp": 520, "vel": 34, "da": 30, "rouba": 30, "dps": 34, "r": 13, "cor": 0xe0413a, "boss": true, "legend": true, "fem": true, "power": "cc", "poder": "ignora lentidão, gelo e badalada"},
	"borin": {"nome": "Borin, o Quebra-Muralhas", "hp": 700, "vel": 24, "da": 30, "rouba": 30, "dps": 30, "r": 15, "cor": 0x9a8a78, "boss": true, "legend": true, "power": "mage", "poder": "quebra armadilhas pelo caminho"},
	"seraphine": {"nome": "Seraphine, a Luz Eterna", "hp": 560, "vel": 28, "da": 30, "rouba": 30, "dps": 20, "r": 13, "cor": 0xf2e6a0, "boss": true, "legend": true, "fem": true, "power": "king", "poder": "cura a escolta"},
	"kael": {"nome": "Kael, o Olho do Falcão", "hp": 440, "vel": 46, "da": 30, "rouba": 30, "dps": 26, "r": 13, "cor": 0x52b048, "boss": true, "legend": true, "power": "fast", "poder": "atravessa o corredor correndo"},
	"yuki": {"nome": "Yuki, a Lâmina da Neve", "hp": 460, "vel": 40, "da": 30, "rouba": 30, "dps": 32, "r": 12, "cor": 0xc8f0ff, "boss": true, "legend": true, "fem": true, "power": "cc", "poder": "ignora lentidão, gelo e badalada"},
	"garrick": {"nome": "Garrick, o Escudo Eterno", "hp": 760, "vel": 22, "da": 30, "rouba": 30, "dps": 24, "r": 15, "cor": 0x3c68c8, "boss": true, "legend": true, "power": "shield", "poder": "o escudo bloqueia boa parte do dano"},
	"morgana": {"nome": "Morgana, a Bruxa do Pântano", "hp": 500, "vel": 28, "da": 30, "rouba": 30, "dps": 22, "r": 13, "cor": 0x8c48d6, "boss": true, "legend": true, "fem": true, "power": "mage", "poder": "amaldiçoa e apaga armadilhas"},
	"thorne": {"nome": "Thorne, o Domador de Feras", "hp": 560, "vel": 30, "da": 30, "rouba": 30, "dps": 28, "r": 14, "cor": 0x6e442e, "boss": true, "legend": true, "power": "summon", "poder": "chama lobos que lutam por ele"},
	"ignis": {"nome": "Ignis, o Piromante Real", "hp": 520, "vel": 28, "da": 30, "rouba": 30, "dps": 24, "r": 13, "cor": 0xff7020, "boss": true, "legend": true, "power": "burn", "poder": "queima os monstros por perto"},
	"bram": {"nome": "Bram, o Alquimista Louco", "hp": 520, "vel": 30, "da": 30, "rouba": 30, "dps": 22, "r": 13, "cor": 0xa06a42, "boss": true, "legend": true, "power": "king", "poder": "joga poções que curam a escolta"},
	"astra": {"nome": "Astra, a Cavaleira Estelar", "hp": 600, "vel": 30, "da": 30, "rouba": 30, "dps": 30, "r": 14, "cor": 0xffc430, "boss": true, "legend": true, "fem": true, "power": "cc", "poder": "ignora lentidão, gelo e badalada"},
	"ragnar": {"nome": "Ragnar, o Viking Furioso", "hp": 680, "vel": 28, "da": 30, "rouba": 30, "dps": 36, "r": 15, "cor": 0xce3a36, "boss": true, "legend": true, "power": "cc", "poder": "ignora lentidão, gelo e badalada"},
	"nyx": {"nome": "Nyx, a Sacerdotisa da Lua", "hp": 500, "vel": 28, "da": 30, "rouba": 30, "dps": 20, "r": 13, "cor": 0x5c58c8, "boss": true, "legend": true, "fem": true, "power": "king", "poder": "a luz da lua cura a escolta"},
}
const BOSSES := ["campeao", "arquimago", "rei"]
const LEGENDS := ["lyra", "borin", "seraphine", "kael", "yuki", "garrick", "morgana", "thorne", "ignis", "bram", "astra", "ragnar", "nyx"]
const DISARMERS := {"acrobata": "espinhos", "desarmador": "fogo", "andarilho": "ampulheta", "batedor": "alcapao", "piromante": "runa", "inquisidor": "ganancia"}
const DISARM := {
	"espinhos": {"tempo": 3.0, "raio": 1.6, "txt": "desarmado", "cor": Color("#e08fb8")},
	"fogo": {"tempo": 4.0, "raio": 1.6, "txt": "apagada", "cor": Color("#c98a4a")},
	"ampulheta": {"tempo": 3.0, "raio": 2.1, "txt": "quebrada", "cor": Color("#7fd1c0")},
	"alcapao": {"tempo": 4.0, "raio": 1.6, "txt": "fechado", "cor": Color("#9c8b5e")},
	"runa": {"tempo": 4.0, "raio": 2.4, "txt": "derretida", "cor": Color("#ff8a3d")},
	"ganancia": {"tempo": 3.0, "raio": 2.1, "txt": "destruída", "cor": Color("#f4f4f4")},
}
const KNOW_NAMES := ["nada", "repararam", "desconfiados", "estudando", "conhecem bem"]

# ===== Eventos =====
const NO_EVENT := {"id": "", "nome": "", "desc": "", "ruim": false, "spawnMul": 1.0, "killMul": 1.0, "monMul": 1.0, "costMul": 1.0,
	"drainMul": 1.0, "heroSpd": 1.0, "regen": 0.0, "stealMul": 1.0, "rangeMul": 1.0, "essBonus": 0}
const EVENTS := [
	{"id": "incursao", "nome": "Incursão", "ruim": true, "peso": 3, "desc": "Um grupo enorme de heróis, com vários especialistas, invade de uma vez.", "efeito": {"spawnMul": 0.4}},
	{"id": "enxame", "nome": "Enxame de ladinos", "ruim": true, "peso": 2, "desc": "Ladinos rápidos entram em fila e tentam passar correndo.", "efeito": {"spawnMul": 0.55}},
	{"id": "lua", "nome": "Lua de sangue", "ruim": false, "peso": 1, "desc": "Seus monstros causam +60% de dano nesta onda.", "efeito": {"monMul": 1.6}},
	{"id": "mare", "nome": "Maré do tempo", "ruim": false, "peso": 1, "desc": "Abates valem +50% de tempo nesta onda.", "efeito": {"killMul": 1.5}},
	{"id": "neblina", "nome": "Neblina", "ruim": true, "peso": 2, "desc": "Bestas, ampulhetas, runas e ganância alcançam 40% menos.", "efeito": {"rangeMul": 0.6}},
	{"id": "pressa", "nome": "Marcha forçada", "ruim": true, "peso": 2, "desc": "Os heróis andam 35% mais rápido nesta onda.", "efeito": {"heroSpd": 1.35}},
	{"id": "bencao", "nome": "Bênção do templo", "ruim": true, "peso": 2, "desc": "Os heróis regeneram vida enquanto andam.", "efeito": {"regen": 0.04}},
	{"id": "saque", "nome": "Saqueadores", "ruim": true, "peso": 2, "desc": "Quem chegar ao coração rouba o dobro de tempo.", "efeito": {"stealMul": 2.0}},
	{"id": "relogio", "nome": "Relógio disparado", "ruim": true, "peso": 1, "desc": "O relógio corre 50% mais rápido nesta onda.", "efeito": {"drainMul": 1.5}},
	{"id": "pechincha", "nome": "Pechincha", "ruim": false, "peso": 1, "desc": "Armadilhas e monstros custam 40% menos nesta onda.", "efeito": {"costMul": 0.6}},
	{"id": "calmaria", "nome": "Calmaria", "ruim": false, "peso": 1, "desc": "O relógio corre na metade da velocidade nesta onda.", "efeito": {"drainMul": 0.5}},
	{"id": "mercador", "nome": "Caravana de ouro", "ruim": false, "peso": 1, "desc": "Mercadores ricos atravessam a masmorra. Cada um vale +20s.", "efeito": {}},
	{"id": "essencia", "nome": "Chuva de essência", "ruim": false, "peso": 1, "desc": "Vencer esta onda dá +2 de essência extra.", "efeito": {"essBonus": 2}},
]

# ===== Grimório (vale só para a run) =====
const PERKS := [
	{"id": "inicio", "nome": "Coração robusto", "desc": "+12s no relógio agora", "max": 5, "base": 1, "revela": 1},
	{"id": "custo", "nome": "Mão de obra barata", "desc": "Armadilhas e monstros custam 6% menos", "max": 4, "base": 2, "revela": 2},
	{"id": "refund", "nome": "Pedreiros cuidadosos", "desc": "+10% de devolução quando a masmorra muda", "max": 3, "base": 1, "revela": 3},
	{"id": "cripta", "nome": "Criptas antigas", "desc": "Todos os monstros sobem 1 nível agora", "max": 3, "base": 3, "revela": 4},
	{"id": "sino", "nome": "Sino de bronze", "desc": "A badalada custa 1s a menos", "max": 2, "base": 2, "revela": 6},
	{"id": "cartas", "nome": "Biblioteca proibida", "desc": "Escolha entre 4 relíquias em vez de 3", "max": 1, "base": 4, "revela": 8, "fixo": true},
]

# ===== Guardiões e lendários (luta de ação) =====
const GUARDS := {
	"minotauro": {"nome": "Minotauro", "cor": 0x9b5a34, "desc": "Corpo a corpo pesado. Machado largo e golpes fortes, mas pula só uma vez.",
		"spd": 175, "jump": 620, "jumps": 1, "w": 40, "h": 50, "armor": 0.85,
		"atk": {"kind": "melee", "dmg": 22, "cd": 0.46, "range": 68, "hh": 52, "t": 0.16}, "dash": {"spd": 560, "t": 0.16, "cd": 0.75},
		"skills": [
			{"nome": "Investida", "cd": 5.0, "desc": "atravessa o inimigo com os chifres, invulnerável"},
			{"nome": "Pisão sísmico", "cd": 6.0, "desc": "ondas de choque pelo chão; atordoa quem estiver perto (no ar, despenca antes)"},
			{"nome": "Fúria do labirinto", "cd": 12.0, "desc": "5s com +50% de dano, golpes mais rápidos e 30% menos tempo perdido"}]},
	"lich": {"nome": "Lich", "cor": 0x7fd1c0, "desc": "Magia à distância. Virotes de osso rápidos, pulo duplo e dash de teleporte. Corpo frágil.",
		"spd": 165, "jump": 580, "jumps": 2, "w": 28, "h": 46, "armor": 1.1,
		"atk": {"kind": "shot", "dmg": 8, "cd": 0.26, "spd": 640}, "dash": {"blink": 150, "cd": 1.0},
		"skills": [
			{"nome": "Coroa de ossos", "cd": 4.5, "desc": "leque de 7 lâminas na direção do lendário"},
			{"nome": "Muralha de ossos", "cd": 7.0, "desc": "parede que segura orbes, pedras e ondas; quem a atravessa se machuca"},
			{"nome": "Drenar tempo", "cd": 10.0, "desc": "marca o lendário: ele leva +25% de dano e cada acerto devolve tempo"}]},
	"dragao": {"nome": "Dragão jovem", "cor": 0xd6453a, "desc": "Ágil. Pulo duplo, dash até no ar e garras muito rápidas.",
		"spd": 225, "jump": 610, "jumps": 2, "w": 36, "h": 36, "armor": 1.0,
		"atk": {"kind": "melee", "dmg": 10, "cd": 0.2, "range": 52, "hh": 40, "t": 0.11}, "dash": {"spd": 660, "t": 0.14, "cd": 0.55},
		"skills": [
			{"nome": "Baforada", "cd": 5.0, "desc": "cone de fogo contínuo"},
			{"nome": "Mergulho", "cd": 6.0, "desc": "mergulha em diagonal, invulnerável, e explode ao tocar o chão"},
			{"nome": "Escamas de brasa", "cd": 11.0, "desc": "4s com 40% menos tempo perdido e aura de fogo que queima de perto"}]},
}
const GUARD_ORDER := ["minotauro", "lich", "dragao"]
const GUP := [
	{"id": "couraca", "t": "Couraça", "d": "Golpes tiram 15% menos segundos.", "max": 4},
	{"id": "agil", "t": "Passos leves", "d": "+12% de velocidade e dash mais longo.", "max": 3},
	{"id": "sangue", "t": "Sede de tempo", "d": "Cada golpe que acerta devolve 0,3s ao relógio.", "max": 3},
]
## Lendários na arena. moves/moves2 = golpes e pesos (moves2 = depois da fúria, abaixo de 50% de vida).
## fx = sprites dos projéteis/efeitos desse lendário.
const LEG_ARENA := {
	"lyra": {"w": 28, "h": 54, "spd": 200, "hp": 340, "hit": 7.0, "moves": {"dash": 3, "leap": 3, "combo": 4}, "moves2": {"dash": 3, "leap": 2, "combo": 3, "waves": 4}, "fx": {"wave": "fx/wave_red"}, "heavy": false},
	"borin": {"w": 46, "h": 62, "spd": 120, "hp": 430, "hit": 9.0, "moves": {"slam": 4, "charge": 3, "rock": 3}, "moves2": {"slam": 3, "charge": 3, "rock": 2, "quake": 4}, "fx": {"wave": "fx/wave_dust", "rain": "fx/rock"}, "heavy": true},
	"seraphine": {"w": 28, "h": 56, "spd": 150, "hp": 320, "hit": 6.0, "moves": {"volley": 4, "pillar": 3, "blink": 2}, "moves2": {"volley": 3, "pillar": 3, "blink": 2, "nova": 4}, "fx": {"orb": "fx/orb"}},
	"kael": {"w": 26, "h": 54, "spd": 190, "hp": 300, "hit": 7.0, "moves": {"arrows": 4, "rain": 3, "trap": 2, "evade_back": 2}, "moves2": {"arrows": 3, "rain": 4, "trap": 3, "evade_back": 2}, "fx": {"arrow": "fx/arrow", "rain": "fx/arrow_down"}},
	"yuki": {"w": 26, "h": 52, "spd": 230, "hp": 310, "hit": 6.0, "moves": {"lunge2": 3, "clones": 3, "shuriken": 3}, "moves2": {"lunge2": 2, "clones": 4, "shuriken": 3, "combo": 2}, "fx": {"shuriken": "fx/shuriken"}},
	"garrick": {"w": 40, "h": 58, "spd": 130, "hp": 460, "hit": 8.0, "moves": {"guard": 3, "bash": 3, "boomerang": 3}, "moves2": {"guard": 2, "bash": 3, "boomerang": 3, "slam": 3}, "fx": {"boomer": "fx/shield", "wave": "fx/wave_dust"}, "heavy": true},
	"morgana": {"w": 28, "h": 58, "spd": 140, "hp": 330, "hit": 6.0, "moves": {"pools": 4, "volley": 3, "blink": 2}, "moves2": {"pools": 3, "volley": 3, "blink": 2, "rain": 3}, "fx": {"orb": "fx/orb_green", "rain": "fx/drop_acid", "pool": 0x8ce65a}},
	"thorne": {"w": 30, "h": 54, "spd": 170, "hp": 360, "hit": 7.0, "moves": {"whip": 4, "beast": 3, "leap": 2}, "moves2": {"whip": 3, "beast": 4, "leap": 2}, "fx": {"beast": "fx/wolf"}},
	"ignis": {"w": 28, "h": 56, "spd": 140, "hp": 330, "hit": 7.0, "moves": {"pillar": 3, "waves": 3, "volley": 2}, "moves2": {"pillar": 3, "waves": 2, "rain": 4, "nova": 2}, "fx": {"orb": "fx/orb_fire", "wave": "fx/wave_fire", "rain": "fx/meteor", "pillar": 0xff7020}},
	"bram": {"w": 30, "h": 52, "spd": 160, "hp": 340, "hit": 6.0, "moves": {"pools": 3, "rock": 3, "blink": 2}, "moves2": {"pools": 3, "rock": 2, "blink": 2, "rain": 4}, "fx": {"rain": "fx/bottle", "rock": "fx/bottle", "pool": 0xffa040}},
	"astra": {"w": 30, "h": 56, "spd": 180, "hp": 380, "hit": 8.0, "moves": {"charge": 3, "starfall": 3, "leap": 3}, "moves2": {"charge": 3, "starfall": 3, "leap": 2, "sweep": 3}, "fx": {"rain": "fx/star", "pillar": 0xfff0a0}},
	"ragnar": {"w": 40, "h": 58, "spd": 150, "hp": 440, "hit": 9.0, "moves": {"spin": 4, "leap": 3, "slam": 2}, "moves2": {"spin": 4, "leap": 3, "slam": 2, "charge": 2}, "fx": {"wave": "fx/wave_dust"}, "heavy": true},
	"nyx": {"w": 28, "h": 58, "spd": 150, "hp": 320, "hit": 6.0, "moves": {"sweep": 3, "boomerang": 3, "blink": 2}, "moves2": {"sweep": 3, "boomerang": 3, "blink": 2, "starfall": 3}, "fx": {"boomer": "fx/crescent", "rain": "fx/moonshard", "pillar": 0xc08ae0}},
}

# ===== Classes do guardião (estilo Grand Chase): cada classe muda arma, ataque, movimento e habilidades =====
## Classes 2, 3 e 4 liberam com missões permanentes (ficam salvas entre runs).
## stat = o que conta para a missão; goal = quanto precisa.
## Poder de cada classe: a 1ª é a base e a 4ª a mais forte.
## dmg multiplica todo o dano do guardião; def multiplica o tempo perdido ao levar golpes.
const CLASS_POWER := [{"dmg": 1.0, "def": 1.0}, {"dmg": 1.15, "def": 0.92}, {"dmg": 1.3, "def": 0.85}, {"dmg": 1.5, "def": 0.76}]
## Árvore de talentos (estilo Grand Chase): igual para todas as classes, com os nomes das habilidades de cada uma.
## Pontos: cada lendário vencido com a classe dá TALENT_PER_LEG pontos para ela (permanentes, salvos entre runs).
## col 0 = Ataque, 1 = Habilidades, 2 = Defesa. req = talento anterior; "*6" = precisa de 6 talentos comprados.
## {s0} {s1} {s2} viram os nomes das habilidades da classe.
const TALENT_PER_LEG := 2
const TALENT_COLS := ["Ataque", "Habilidades", "Defesa"]
const TALENTS := [
	{"id": "a1", "col": 0, "cost": 1, "req": "", "nome": "Golpe certeiro", "desc": "+10% de dano no ataque básico.", "fx": {"atk": 0.10}},
	{"id": "a2", "col": 0, "cost": 2, "req": "a1", "nome": "Ritmo de batalha", "desc": "Ataque básico 12% mais rápido.", "fx": {"atk_cd": 0.12}},
	{"id": "a3", "col": 0, "cost": 3, "req": "a2", "nome": "Golpe devastador", "desc": "+20% de dano no ataque básico.", "fx": {"atk": 0.20}},
	{"id": "b1", "col": 1, "cost": 1, "req": "", "nome": "Foco", "desc": "Habilidades recarregam 10% mais rápido.", "fx": {"sk_cd": 0.10}},
	{"id": "b2", "col": 1, "cost": 2, "req": "b1", "nome": "Domínio: {s0}", "desc": "{s0} e {s1} com +30% de poder.", "fx": {"sk0": 0.30, "sk1": 0.30}},
	{"id": "b3", "col": 1, "cost": 3, "req": "b2", "nome": "Domínio: {s2}", "desc": "{s2} com +40% de poder e 20% menos recarga.", "fx": {"sk2": 0.40, "sk2_cd": 0.20}},
	{"id": "c1", "col": 2, "cost": 1, "req": "", "nome": "Couro grosso", "desc": "Perde 8% menos tempo por golpe.", "fx": {"def": 0.08}},
	{"id": "c2", "col": 2, "cost": 2, "req": "c1", "nome": "Passos de caça", "desc": "+10% de velocidade e dash recarrega 20% mais rápido.", "fx": {"spd": 0.10, "dash": 0.20}},
	{"id": "c3", "col": 2, "cost": 3, "req": "c2", "nome": "Sangue do relógio", "desc": "Perde 12% menos tempo e cada acerto básico devolve 0,1s.", "fx": {"def": 0.12, "leech": 0.1}},
	{"id": "m", "col": -1, "cost": 4, "req": "*6", "nome": "Mestre", "desc": "", "fx": {"master": 1.0}},
]
## ===== Habilidades supremas (uma por classe; trocáveis entre as do mesmo guardião) =====
## Carregam com a barra de poder: acertar o lendário e levar golpes enchem a barra.
const ULTS := {
	"ult_rei": {"nome": "Rei do Labirinto", "dono": "minotauro_0", "icon": "ui/sk_furia", "desc": "6s com dano dobrado, golpes mais rápidos e metade do tempo perdido."},
	"ult_massacre": {"nome": "Massacre", "dono": "minotauro_1", "icon": "ui/sk_redemoinho", "desc": "3s girando os machados com dano triplo; cada acerto devolve tempo."},
	"ult_avalanche": {"nome": "Avalanche", "dono": "minotauro_2", "icon": "ui/sk_terremoto", "desc": "Seis rochas caem sobre o lendário e o deixam atordoado."},
	"ult_chifres": {"nome": "Chifres do Rei", "dono": "minotauro_3", "icon": "ui/sk_investida_longa", "desc": "Três investidas seguidas de parede a parede, invulnerável."},
	"ult_apocalipse": {"nome": "Apocalipse de ossos", "dono": "lich_0", "icon": "ui/sk_coroa", "desc": "Três explosões de lâminas de osso em todas as direções."},
	"ult_exercito": {"nome": "Exército dos mortos", "dono": "lich_1", "icon": "ui/sk_erguer", "desc": "Ergue seis esqueletos que lutam por 10s."},
	"ult_era_gelo": {"nome": "Era do gelo", "dono": "lich_2", "icon": "ui/sk_bloco", "desc": "Congela o lendário por 3s, causa dano alto e o deixa lento por 6s."},
	"ult_fim_tempos": {"nome": "Fim dos tempos", "dono": "lich_3", "icon": "ui/sk_parar", "desc": "Para o tempo por 4s e devolve 10s ao relógio."},
	"ult_inferno": {"nome": "Inferno", "dono": "dragao_0", "icon": "ui/sk_baforada", "desc": "3s de fogo enorme e contínuo, invulnerável enquanto cospe fogo."},
	"ult_furia_ceus": {"nome": "Fúria dos céus", "dono": "dragao_1", "icon": "ui/sk_tempestade", "desc": "Seis raios seguidos sobre o lendário."},
	"ult_praga": {"nome": "Praga", "dono": "dragao_2", "icon": "ui/sk_nuvem", "desc": "Veneno no máximo e uma nuvem tóxica que segue o lendário por 6s."},
	"ult_meteoros": {"nome": "Chuva de meteoros", "dono": "dragao_3", "icon": "ui/sk_meteoro", "desc": "Oito meteoros caem em volta do lendário."},
}
const ULT_CHARGE_START := 35.0   # barra de poder ao começar a luta (cheia = 100)
## Custos em pontos de talento da classe em uso.
const SKILL_UNLOCK_COST := 3     # liberar uma habilidade de outra classe antes de liberar a classe
const ULT_UNLOCK_COST := 4
const SKILL_UP_COST := [2, 3]    # aprimorar uma habilidade de forma permanente (nível +1, depois +2)
const WAVE_COUNTDOWN := 5.0   # segundos para se arrumar antes de cada onda (o relógio não corre)
const MISSIONS := {
	"minotauro_1": {"desc": "Acerte 250 golpes básicos com o Minotauro na sala do guardião.", "goal": 250},
	"minotauro_2": {"desc": "Vença um lendário com o Minotauro perdendo menos de 30% do relógio na luta.", "goal": 1},
	"minotauro_3": {"desc": "Derrote 4 lendários com o Minotauro (somando todas as runs).", "goal": 4},
	"lich_1": {"desc": "Solte 40 esqueletos na masmorra jogando com o Lich.", "goal": 40},
	"lich_2": {"desc": "Toque a badalada 15 vezes jogando com o Lich.", "goal": 15},
	"lich_3": {"desc": "Termine uma onda com 300s ou mais no relógio jogando com o Lich.", "goal": 1},
	"dragao_1": {"desc": "Dê 120 pulos no ar com o Dragão na sala do guardião.", "goal": 120},
	"dragao_2": {"desc": "Vença um lendário com o Dragão sem usar o dash na luta.", "goal": 1},
	"dragao_3": {"desc": "Chegue à onda 12 jogando com o Dragão.", "goal": 1},
}
## Bônus que o guardião dá à masmorra enquanto ele é o seu guardião.
## mul = multiplica (monHp, monDmg, esp, besta, fogo, bellCd, drain); add = soma (slow, kill);
## cheap = monstro pela metade do tempo; free = [monstro, segundos] sai de graça.
const GUARD_BONUS := {
	"minotauro": {"nome": "Labirinto", "desc": "Monstros têm +25% de vida.", "mul": {"monHp": 1.25}},
	"lich": {"nome": "Coração gelado", "desc": "A badalada recarrega 30% mais rápido.", "mul": {"bellCd": 0.7}},
	"dragao": {"nome": "Tesouro do dragão", "desc": "Cada herói derrotado dá +0,5s.", "add": {"kill": 0.5}},
}
const CLASSES := {
	"minotauro": [
		{"nome": "Guerreiro do Labirinto", "estilo": "Equilibrado: machado pesado e investidas.", "spd": 1.0, "jump": 1.0, "jumps": 1, "armor": 0.85,
			"atk": {"kind": "melee", "dmg": 22, "cd": 0.46, "range": 70, "hh": 54, "t": 0.14, "anti": 0.07, "rec": 0.1, "fx": "axe", "shake": 0.006}, "skills": ["investida", "pisao", "furia"], "passive": "", "bonus": {"desc": "Monstros causam +20% de dano.", "mul": {"monDmg": 1.2}}},
		{"nome": "Berserker", "estilo": "Dois machados, golpes rápidos; cada acerto aumenta o dano até ser atingido.", "spd": 1.12, "jump": 1.0, "jumps": 1, "armor": 0.88,
			"atk": {"kind": "melee", "dmg": 12, "cd": 0.24, "range": 60, "hh": 48, "t": 0.09, "anti": 0.03, "rec": 0.05, "fx": "axe", "shake": 0.003}, "skills": ["redemoinho", "investida", "sede"], "passive": "furia_acumula", "bonus": {"desc": "Monstros causam +35% de dano, mas têm 10% menos vida.", "mul": {"monDmg": 1.35, "monHp": 0.9}}},
		{"nome": "Guardião de Pedra", "estilo": "Tanque com escudo e maça: lento, aguenta muito e empurra o inimigo.", "spd": 0.85, "jump": 0.95, "jumps": 1, "armor": 0.6,
			"atk": {"kind": "melee", "dmg": 26, "cd": 0.6, "range": 62, "hh": 56, "t": 0.16, "anti": 0.1, "rec": 0.14, "fx": "axe", "shake": 0.008}, "skills": ["postura", "chifrada", "terremoto"], "passive": "empurrao", "bonus": {"desc": "Monstros têm +40% de vida.", "mul": {"monHp": 1.4}}},
		{"nome": "Senhor dos Touros", "estilo": "Lança longa: ataca de mais longe e atropela com o rebanho.", "spd": 1.05, "jump": 1.05, "jumps": 1, "armor": 0.9,
			"atk": {"kind": "melee", "dmg": 18, "cd": 0.38, "range": 110, "hh": 30, "t": 0.12, "anti": 0.07, "rec": 0.08, "fx": "spear", "shake": 0.004}, "skills": ["arremesso", "investida_longa", "estouro"], "passive": "", "bonus": {"desc": "Um ogro sai de graça a cada 25s de onda.", "free": ["ogro", 25.0]}},
	],
	"lich": [
		{"nome": "Lich", "estilo": "Magia à distância e controle.", "spd": 1.0, "jump": 1.0, "jumps": 2, "armor": 0.98,
			"atk": {"kind": "shot", "dmg": 8, "cd": 0.26, "spd": 640, "anti": 0.04, "rec": 0.05, "spr": "fx/bone", "fx": "necro"}, "skills": ["coroa", "muralha", "drenar"], "passive": "", "bonus": {"desc": "Espinhos causam +30% de dano.", "mul": {"esp": 1.3}}},
		{"nome": "Necromante", "estilo": "Ergue esqueletos que lutam por ele; acertos colhem almas.", "spd": 0.95, "jump": 1.0, "jumps": 2, "armor": 0.93,
			"atk": {"kind": "shot", "dmg": 10, "cd": 0.4, "spd": 520, "anti": 0.06, "rec": 0.06, "spr": "fx/skull", "fx": "necro"}, "skills": ["erguer", "explosao", "coroa"], "passive": "colheita", "bonus": {"desc": "Esqueletos custam metade do tempo e um sai de graça a cada 12s de onda.", "cheap": "esqueleto", "free": ["esqueleto", 12.0]}},
		{"nome": "Feiticeiro do Gelo", "estilo": "Cada acerto deixa o lendário lento; congela e se protege.", "spd": 1.0, "jump": 1.0, "jumps": 2, "armor": 0.88,
			"atk": {"kind": "shot", "dmg": 7, "cd": 0.3, "spd": 600, "anti": 0.04, "rec": 0.05, "spr": "fx/shard", "fx": "necro"}, "skills": ["lanca_gelo", "nevasca", "bloco"], "passive": "congelar", "bonus": {"desc": "Ampulhetas deixam 15% mais lento.", "add": {"slow": 0.15}}},
		{"nome": "Arauto do Tempo", "estilo": "Manipula o relógio: para o inimigo, rebobina dano e devolve tempo a cada acerto.", "spd": 1.05, "jump": 1.0, "jumps": 2, "armor": 1.03,
			"atk": {"kind": "shot", "dmg": 8, "cd": 0.28, "spd": 680, "anti": 0.04, "rec": 0.05, "spr": "fx/clockhand", "fx": "necro"}, "skills": ["parar", "rebobinar", "eco"], "passive": "tempo_devolvido", "bonus": {"desc": "O relógio corre 15% mais devagar durante as ondas.", "mul": {"drain": 0.85}}},
	],
	"dragao": [
		{"nome": "Dragão Jovem", "estilo": "Ágil, garras rápidas e fogo.", "spd": 1.0, "jump": 1.0, "jumps": 2, "armor": 0.88,
			"atk": {"kind": "melee", "dmg": 11, "cd": 0.2, "range": 54, "hh": 42, "t": 0.09, "anti": 0.03, "rec": 0.04, "fx": "claw", "shake": 0.002}, "skills": ["baforada", "mergulho", "escamas"], "passive": "", "bonus": {"desc": "Fogueiras causam +40% de dano.", "mul": {"fogo": 1.4}}},
		{"nome": "Dragão da Tempestade", "estilo": "Pulo triplo e raios; acertos às vezes soltam faíscas.", "spd": 1.1, "jump": 1.05, "jumps": 3, "armor": 0.93,
			"atk": {"kind": "melee", "dmg": 10, "cd": 0.2, "range": 54, "hh": 42, "t": 0.09, "anti": 0.03, "rec": 0.04, "fx": "claw", "shake": 0.002}, "skills": ["raio", "voo", "tempestade"], "passive": "faisca", "bonus": {"desc": "Bestas causam +40% de dano.", "mul": {"besta": 1.4}}},
		{"nome": "Serpe Venenosa", "estilo": "Ferrão na cauda: envenena e desgasta aos poucos.", "spd": 1.05, "jump": 1.0, "jumps": 2, "armor": 0.88,
			"atk": {"kind": "melee", "dmg": 10, "cd": 0.26, "range": 64, "hh": 40, "t": 0.1, "anti": 0.05, "rec": 0.05, "fx": "claw", "shake": 0.002}, "skills": ["nuvem", "ferrao", "muda"], "passive": "veneno", "bonus": {"desc": "Espinhos causam +50% de dano.", "mul": {"esp": 1.5}}},
		{"nome": "Dragão Ancião", "estilo": "Grande e pesado: cauda larga, meteoros e rugido.", "spd": 0.85, "jump": 0.92, "jumps": 1, "armor": 0.63,
			"atk": {"kind": "melee", "dmg": 20, "cd": 0.45, "range": 84, "hh": 62, "t": 0.14, "anti": 0.08, "rec": 0.1, "fx": "axe", "shake": 0.006}, "skills": ["meteoro", "rugido", "asas_fogo"], "passive": "", "bonus": {"desc": "Cada herói derrotado dá +1s extra.", "add": {"kill": 1.0}}},
	],
}
const PASSIVES := {
	"furia_acumula": "Cada acerto dá +4% de dano (até +40%). Zera ao levar dano.",
	"empurrao": "Golpes empurram o lendário para trás.",
	"colheita": "A cada 8 acertos, um esqueleto se ergue para lutar.",
	"congelar": "Acertos deixam o lendário lento.",
	"tempo_devolvido": "Cada acerto devolve 0,15s ao relógio.",
	"faisca": "Acertos têm 25% de chance de soltar uma faísca extra.",
	"veneno": "Acertos envenenam (acumula até 8).",
}
const SKILLS := {
	"investida": {"nome": "Investida", "cd": 5.0, "icon": "ui/sk_investida", "desc": "atravessa o inimigo com os chifres, invulnerável"},
	"pisao": {"nome": "Pisão sísmico", "cd": 6.0, "icon": "ui/sk_pisao", "desc": "ondas de choque pelo chão; atordoa quem estiver perto"},
	"furia": {"nome": "Fúria do labirinto", "cd": 12.0, "icon": "ui/sk_furia", "desc": "5s com +50% de dano, golpes mais rápidos e menos tempo perdido"},
	"redemoinho": {"nome": "Redemoinho", "cd": 6.0, "icon": "ui/sk_furia", "desc": "gira os machados em volta do corpo por 1,3s"},
	"sede": {"nome": "Sede de sangue", "cd": 11.0, "icon": "ui/sk_drenar", "desc": "5s em que cada acerto devolve 0,5s"},
	"postura": {"nome": "Postura de pedra", "cd": 7.0, "icon": "ui/sk_muralha", "desc": "2s bloqueando tudo; quem bate no escudo se machuca"},
	"chifrada": {"nome": "Chifrada", "cd": 6.0, "icon": "ui/sk_investida", "desc": "golpe curto que atordoa por 1,2s"},
	"terremoto": {"nome": "Terremoto", "cd": 10.0, "icon": "ui/sk_pisao", "desc": "três ondas de choque seguidas pelo chão"},
	"arremesso": {"nome": "Arremesso de lança", "cd": 4.5, "icon": "ui/sk_mergulho", "desc": "lança que atravessa a arena"},
	"investida_longa": {"nome": "Galope", "cd": 6.0, "icon": "ui/sk_investida", "desc": "investida longa e mais forte"},
	"estouro": {"nome": "Estouro do rebanho", "cd": 12.0, "icon": "ui/sk_investida", "desc": "touros espectrais atropelam a arena inteira"},
	"coroa": {"nome": "Coroa de ossos", "cd": 4.5, "icon": "ui/sk_coroa", "desc": "leque de 7 lâminas"},
	"muralha": {"nome": "Muralha de ossos", "cd": 7.0, "icon": "ui/sk_muralha", "desc": "parede que segura projéteis e barra investidas"},
	"drenar": {"nome": "Drenar tempo", "cd": 10.0, "icon": "ui/sk_drenar", "desc": "o lendário leva +25% de dano e cada acerto devolve tempo"},
	"erguer": {"nome": "Erguer mortos", "cd": 8.0, "icon": "ui/sk_coroa", "desc": "ergue 2 esqueletos que lutam por 8s"},
	"explosao": {"nome": "Explosão de ossos", "cd": 6.0, "icon": "ui/sk_furia", "desc": "detona os esqueletos em explosões"},
	"lanca_gelo": {"nome": "Lança de gelo", "cd": 5.0, "icon": "ui/sk_coroa", "desc": "raio de gelo que atravessa e deixa lento"},
	"nevasca": {"nome": "Nevasca", "cd": 9.0, "icon": "ui/sk_drenar", "desc": "tempestade de neve sobre o lendário por 3s"},
	"bloco": {"nome": "Bloco de gelo", "cd": 12.0, "icon": "ui/sk_muralha", "desc": "fica invulnerável e recupera um pouco de tempo"},
	"parar": {"nome": "Parar o tempo", "cd": 12.0, "icon": "ui/sk_drenar", "desc": "o lendário e os golpes dele congelam por 1,8s"},
	"rebobinar": {"nome": "Rebobinar", "cd": 14.0, "icon": "ui/sk_drenar", "desc": "recupera parte do tempo perdido nos últimos 4s"},
	"eco": {"nome": "Eco", "cd": 8.0, "icon": "ui/sk_coroa", "desc": "os próximos ataques saem em dobro"},
	"baforada": {"nome": "Baforada", "cd": 5.0, "icon": "ui/sk_baforada", "desc": "cone de fogo contínuo"},
	"mergulho": {"nome": "Mergulho", "cd": 6.0, "icon": "ui/sk_mergulho", "desc": "mergulha em diagonal e explode no chão"},
	"escamas": {"nome": "Escamas de brasa", "cd": 11.0, "icon": "ui/sk_escamas", "desc": "4s de couraça e aura de fogo"},
	"raio": {"nome": "Raio", "cd": 4.5, "icon": "ui/sk_mergulho", "desc": "raio cai sobre o lendário e atordoa"},
	"voo": {"nome": "Voo", "cd": 9.0, "icon": "ui/jump", "desc": "3s voando, rápido e com pulos à vontade"},
	"tempestade": {"nome": "Tempestade", "cd": 12.0, "icon": "ui/sk_mergulho", "desc": "três raios seguidos"},
	"nuvem": {"nome": "Nuvem tóxica", "cd": 7.0, "icon": "ui/sk_baforada", "desc": "nuvem que envenena por 4s"},
	"ferrao": {"nome": "Ferrão", "cd": 5.0, "icon": "ui/sk_mergulho", "desc": "bote rápido que envenena muito"},
	"muda": {"nome": "Muda de pele", "cd": 9.0, "icon": "ui/sk_escamas", "desc": "fica invulnerável e mais rápido por um tempo"},
	"meteoro": {"nome": "Meteoro", "cd": 7.0, "icon": "ui/sk_baforada", "desc": "meteoro cai sobre o lendário"},
	"rugido": {"nome": "Rugido", "cd": 10.0, "icon": "ui/sk_furia", "desc": "atordoa e faz o lendário levar +30% de dano"},
	"asas_fogo": {"nome": "Asas de fogo", "cd": 8.0, "icon": "ui/sk_escamas", "desc": "voo rasante deixando fogo"},
}

const DUEL_KEYS := ["dash", "pulo", "perto", "longe", "especial"]
const DUEL_NAMES := {"dash": "Dash do guardião", "pulo": "Pulos", "perto": "Luta de perto", "longe": "Luta de longe", "especial": "Habilidades"}


static func col(c: int, a: float = 1.0) -> Color:
	return Color(((c >> 16) & 0xff) / 255.0, ((c >> 8) & 0xff) / 255.0, (c & 0xff) / 255.0, a)


static func r1(v: float) -> float:
	return round(v * 10.0) / 10.0


static func fmt(v: float) -> String:
	return str(r1(v)).replace(".", ",")


static func pct(v: float) -> String:
	return fmt(v) + "%"
