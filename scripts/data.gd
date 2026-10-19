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
## Árvore de talentos de cada classe (estilo Grand Chase): três ramos especializados no jeito de lutar
## da classe, 2 talentos em cada ramo, e o talento de Mestre (precisa de 4 talentos comprados).
## Pontos: cada lendário vencido com a classe dá TALENT_PER_LEG pontos para ela (permanentes).
## Efeitos (fx): atk_dmg, atk_cd, atk_range, sk0/1/2_pow, sk0/1/2_cd, sk0/1/2_dur, ult_pow, ult_gain, pass (força da passiva),
## rage_cap, shot_n, pierce, jumps, poison_cap, skel, leech, def, spd.
const TALENT_PER_LEG := 2
const TALENT_TREES := {
	"minotauro_0": {"cols": ["Machado", "Chifres", "Fúria"], "nodes": [
		{"id": "a1", "col": 0, "cost": 1, "req": "", "nome": "Machado pesado", "desc": "+15% de dano no ataque básico.", "fx": {"atk_dmg": 0.15}},
		{"id": "a2", "col": 0, "cost": 2, "req": "a1", "nome": "Golpe largo", "desc": "O machado alcança 30% mais longe.", "fx": {"atk_range": 0.3}},
		{"id": "b1", "col": 1, "cost": 1, "req": "", "nome": "Chifres de ferro", "desc": "Habilidade 1 com +35% de poder.", "fx": {"sk0_pow": 0.35}},
		{"id": "b2", "col": 1, "cost": 2, "req": "b1", "nome": "Fôlego de touro", "desc": "Habilidade 1 recarrega 25% e habilidade 2, 15% mais rápido.", "fx": {"sk0_cd": 0.25, "sk1_cd": 0.15}},
		{"id": "c1", "col": 2, "cost": 1, "req": "", "nome": "Fúria longa", "desc": "Habilidade 3 dura 40% mais.", "fx": {"sk2_dur": 0.4}},
		{"id": "c2", "col": 2, "cost": 2, "req": "c1", "nome": "Sangue quente", "desc": "A suprema carrega 30% mais rápido.", "fx": {"ult_gain": 0.3}},
		{"id": "m", "col": -1, "cost": 4, "req": "*4", "nome": "Rei do Labirinto", "desc": "+20% de poder nas 3 habilidades e suprema 40% mais forte.", "fx": {"sk0_pow": 0.2, "sk1_pow": 0.2, "sk2_pow": 0.2, "ult_pow": 0.4}}]},
	"minotauro_1": {"cols": ["Lâminas", "Sede", "Frenesi"], "nodes": [
		{"id": "a1", "col": 0, "cost": 1, "req": "", "nome": "Lâminas leves", "desc": "Ataque básico 12% mais rápido.", "fx": {"atk_cd": 0.12}},
		{"id": "a2", "col": 0, "cost": 2, "req": "a1", "nome": "Corte fundo", "desc": "+20% de dano no ataque básico.", "fx": {"atk_dmg": 0.2}},
		{"id": "b1", "col": 1, "cost": 1, "req": "", "nome": "Sangue nas lâminas", "desc": "Cada acerto básico devolve 0,08s.", "fx": {"leech": 0.08}},
		{"id": "b2", "col": 1, "cost": 2, "req": "b1", "nome": "Sede infinita", "desc": "Habilidade 3 dura 50% mais.", "fx": {"sk2_dur": 0.5}},
		{"id": "c1", "col": 2, "cost": 1, "req": "", "nome": "Ódio sem fim", "desc": "A fúria acumula até 15 cargas.", "fx": {"rage_cap": 5}},
		{"id": "c2", "col": 2, "cost": 2, "req": "c1", "nome": "Fúria crescente", "desc": "Cada carga de fúria vale 50% mais.", "fx": {"pass": 0.5}},
		{"id": "m", "col": -1, "cost": 4, "req": "*4", "nome": "Encarnação da fúria", "desc": "Fúria acumula até 20 cargas, cada uma vale mais, e a suprema fica 30% mais forte.", "fx": {"rage_cap": 5, "pass": 0.5, "ult_pow": 0.3}}]},
	"minotauro_2": {"cols": ["Escudo", "Maça", "Terra"], "nodes": [
		{"id": "a1", "col": 0, "cost": 1, "req": "", "nome": "Escudo pesado", "desc": "Perde 10% menos tempo por golpe.", "fx": {"def": 0.1}},
		{"id": "a2", "col": 0, "cost": 2, "req": "a1", "nome": "Rocha viva", "desc": "Perde mais 10% menos tempo e a habilidade 1 dura 30% mais.", "fx": {"def": 0.1, "sk0_dur": 0.3}},
		{"id": "b1", "col": 1, "cost": 1, "req": "", "nome": "Maça de granito", "desc": "+20% de dano no ataque básico.", "fx": {"atk_dmg": 0.2}},
		{"id": "b2", "col": 1, "cost": 2, "req": "b1", "nome": "Empurrão brutal", "desc": "Os golpes empurram o lendário 60% mais longe.", "fx": {"pass": 0.6}},
		{"id": "c1", "col": 2, "cost": 1, "req": "", "nome": "Terra viva", "desc": "Habilidade 3 com +35% de poder.", "fx": {"sk2_pow": 0.35}},
		{"id": "c2", "col": 2, "cost": 2, "req": "c1", "nome": "Abalo", "desc": "Habilidade 2 com +30% de poder e 20% menos recarga.", "fx": {"sk1_pow": 0.3, "sk1_cd": 0.2}},
		{"id": "m", "col": -1, "cost": 4, "req": "*4", "nome": "Montanha", "desc": "Perde mais 10% menos tempo, habilidade 3 +20% e suprema 40% mais forte.", "fx": {"def": 0.1, "sk2_pow": 0.2, "ult_pow": 0.4}}]},
	"minotauro_3": {"cols": ["Lança", "Galope", "Rebanho"], "nodes": [
		{"id": "a1", "col": 0, "cost": 1, "req": "", "nome": "Ponta longa", "desc": "A lança alcança 30% mais longe.", "fx": {"atk_range": 0.3}},
		{"id": "a2", "col": 0, "cost": 2, "req": "a1", "nome": "Estocada precisa", "desc": "+15% de dano e ataque 8% mais rápido.", "fx": {"atk_dmg": 0.15, "atk_cd": 0.08}},
		{"id": "b1", "col": 1, "cost": 1, "req": "", "nome": "Lança afiada", "desc": "Habilidade 1 com +35% de poder.", "fx": {"sk0_pow": 0.35}},
		{"id": "b2", "col": 1, "cost": 2, "req": "b1", "nome": "Galope veloz", "desc": "+12% de velocidade e habilidade 2 recarrega 20% mais rápido.", "fx": {"spd": 0.12, "sk1_cd": 0.2}},
		{"id": "c1", "col": 2, "cost": 1, "req": "", "nome": "Rebanho maior", "desc": "Habilidade 3 com +40% de poder.", "fx": {"sk2_pow": 0.4}},
		{"id": "c2", "col": 2, "cost": 2, "req": "c1", "nome": "Chifres de prata", "desc": "A suprema carrega 30% mais rápido.", "fx": {"ult_gain": 0.3}},
		{"id": "m", "col": -1, "cost": 4, "req": "*4", "nome": "Senhor da manada", "desc": "Habilidade 3 recarrega 25% mais rápido, +8% de velocidade e suprema 40% mais forte.", "fx": {"sk2_cd": 0.25, "spd": 0.08, "ult_pow": 0.4}}]},
	"lich_0": {"cols": ["Virotes", "Ossos", "Dreno"], "nodes": [
		{"id": "a1", "col": 0, "cost": 1, "req": "", "nome": "Virotes perfurantes", "desc": "Os virotes atravessam o lendário.", "fx": {"pierce": 1}},
		{"id": "a2", "col": 0, "cost": 2, "req": "a1", "nome": "Rajada dupla", "desc": "Cada ataque solta um virote a mais.", "fx": {"shot_n": 1}},
		{"id": "b1", "col": 1, "cost": 1, "req": "", "nome": "Ossos afiados", "desc": "Habilidade 1 com +35% de poder.", "fx": {"sk0_pow": 0.35}},
		{"id": "b2", "col": 1, "cost": 2, "req": "b1", "nome": "Ossos densos", "desc": "Habilidade 2 dura 40% mais e tem +30% de poder.", "fx": {"sk1_dur": 0.4, "sk1_pow": 0.3}},
		{"id": "c1", "col": 2, "cost": 1, "req": "", "nome": "Dreno profundo", "desc": "Habilidade 3 dura 40% mais.", "fx": {"sk2_dur": 0.4}},
		{"id": "c2", "col": 2, "cost": 2, "req": "c1", "nome": "Alma faminta", "desc": "Suprema carrega 30% mais rápido e cada acerto básico devolve 0,05s.", "fx": {"ult_gain": 0.3, "leech": 0.05}},
		{"id": "m", "col": -1, "cost": 4, "req": "*4", "nome": "Senhor dos ossos", "desc": "Mais um virote por ataque e suprema 40% mais forte.", "fx": {"shot_n": 1, "ult_pow": 0.4}}]},
	"lich_1": {"cols": ["Caveiras", "Servos", "Almas"], "nodes": [
		{"id": "a1", "col": 0, "cost": 1, "req": "", "nome": "Caveiras pesadas", "desc": "+20% de dano no ataque básico.", "fx": {"atk_dmg": 0.2}},
		{"id": "a2", "col": 0, "cost": 2, "req": "a1", "nome": "Caveira dupla", "desc": "Cada ataque solta uma caveira a mais.", "fx": {"shot_n": 1}},
		{"id": "b1", "col": 1, "cost": 1, "req": "", "nome": "Servos fortes", "desc": "Esqueletos aliados com +40% de dano e vida.", "fx": {"skel": 0.4}},
		{"id": "b2", "col": 1, "cost": 2, "req": "b1", "nome": "Servos eternos", "desc": "Esqueletos aliados com mais 40% de dano e vida.", "fx": {"skel": 0.4}},
		{"id": "c1", "col": 2, "cost": 1, "req": "", "nome": "Colheita rápida", "desc": "Um esqueleto se ergue com metade dos acertos.", "fx": {"pass": 0.5}},
		{"id": "c2", "col": 2, "cost": 2, "req": "c1", "nome": "Ritual", "desc": "Habilidades 1 e 3 recarregam 20% mais rápido.", "fx": {"sk0_cd": 0.2, "sk2_cd": 0.2}},
		{"id": "m", "col": -1, "cost": 4, "req": "*4", "nome": "Rei necromante", "desc": "Esqueletos ainda mais fortes, colheita mais rápida e suprema 30% mais forte.", "fx": {"skel": 0.5, "pass": 0.5, "ult_pow": 0.3}}]},
	"lich_2": {"cols": ["Lascas", "Nevasca", "Cristal"], "nodes": [
		{"id": "a1", "col": 0, "cost": 1, "req": "", "nome": "Lascas afiadas", "desc": "+15% de dano no ataque básico.", "fx": {"atk_dmg": 0.15}},
		{"id": "a2", "col": 0, "cost": 2, "req": "a1", "nome": "Frio penetrante", "desc": "As lascas atravessam o lendário.", "fx": {"pierce": 1}},
		{"id": "b1", "col": 1, "cost": 1, "req": "", "nome": "Inverno longo", "desc": "Habilidade 2 dura 50% mais.", "fx": {"sk1_dur": 0.5}},
		{"id": "b2", "col": 1, "cost": 2, "req": "b1", "nome": "Gelo cortante", "desc": "Habilidade 1 com +35% de poder.", "fx": {"sk0_pow": 0.35}},
		{"id": "c1", "col": 2, "cost": 1, "req": "", "nome": "Congelamento", "desc": "Os acertos deixam o lendário lento 60% mais tempo.", "fx": {"pass": 0.6}},
		{"id": "c2", "col": 2, "cost": 2, "req": "c1", "nome": "Corpo de cristal", "desc": "Perde 12% menos tempo por golpe.", "fx": {"def": 0.12}},
		{"id": "m", "col": -1, "cost": 4, "req": "*4", "nome": "Coração de gelo", "desc": "Lentidão ainda maior, habilidade 3 recarrega 20% mais rápido e suprema 40% mais forte.", "fx": {"pass": 0.4, "sk2_cd": 0.2, "ult_pow": 0.4}}]},
	"lich_3": {"cols": ["Ponteiros", "Tempo", "Eco"], "nodes": [
		{"id": "a1", "col": 0, "cost": 1, "req": "", "nome": "Ponteiros rápidos", "desc": "Ataque básico 15% mais rápido.", "fx": {"atk_cd": 0.15}},
		{"id": "a2", "col": 0, "cost": 2, "req": "a1", "nome": "Ponteiros afiados", "desc": "+15% de dano no ataque básico.", "fx": {"atk_dmg": 0.15}},
		{"id": "b1", "col": 1, "cost": 1, "req": "", "nome": "Tempo devolvido", "desc": "Cada acerto devolve 60% mais tempo.", "fx": {"pass": 0.6}},
		{"id": "b2", "col": 1, "cost": 2, "req": "b1", "nome": "Relógio paciente", "desc": "Habilidade 1 dura 40% mais e recarrega 15% mais rápido.", "fx": {"sk0_dur": 0.4, "sk0_cd": 0.15}},
		{"id": "c1", "col": 2, "cost": 1, "req": "", "nome": "Eco profundo", "desc": "Habilidade 3 com +40% de poder.", "fx": {"sk2_pow": 0.4}},
		{"id": "c2", "col": 2, "cost": 2, "req": "c1", "nome": "Rebobinar mais", "desc": "Habilidade 2 com +40% de poder e 15% menos recarga.", "fx": {"sk1_pow": 0.4, "sk1_cd": 0.15}},
		{"id": "m", "col": -1, "cost": 4, "req": "*4", "nome": "Senhor do tempo", "desc": "Ainda mais tempo devolvido, suprema carrega 30% mais rápido e fica 30% mais forte.", "fx": {"pass": 0.6, "ult_gain": 0.3, "ult_pow": 0.3}}]},
	"dragao_0": {"cols": ["Garras", "Fogo", "Asas"], "nodes": [
		{"id": "a1", "col": 0, "cost": 1, "req": "", "nome": "Garras afiadas", "desc": "+15% de dano no ataque básico.", "fx": {"atk_dmg": 0.15}},
		{"id": "a2", "col": 0, "cost": 2, "req": "a1", "nome": "Garras rápidas", "desc": "Ataque básico 12% mais rápido.", "fx": {"atk_cd": 0.12}},
		{"id": "b1", "col": 1, "cost": 1, "req": "", "nome": "Fogo intenso", "desc": "Habilidade 1 com +35% de poder.", "fx": {"sk0_pow": 0.35}},
		{"id": "b2", "col": 1, "cost": 2, "req": "b1", "nome": "Mergulho em chamas", "desc": "Habilidade 2 com +40% de poder.", "fx": {"sk1_pow": 0.4}},
		{"id": "c1", "col": 2, "cost": 1, "req": "", "nome": "Escamas grossas", "desc": "Habilidade 3 dura 40% mais.", "fx": {"sk2_dur": 0.4}},
		{"id": "c2", "col": 2, "cost": 2, "req": "c1", "nome": "Asas fortes", "desc": "Um pulo no ar a mais.", "fx": {"jumps": 1}},
		{"id": "m", "col": -1, "cost": 4, "req": "*4", "nome": "Dragão adulto", "desc": "Suprema 40% mais forte, habilidade 1 +20% e ataque +10%.", "fx": {"ult_pow": 0.4, "sk0_pow": 0.2, "atk_dmg": 0.1}}]},
	"dragao_1": {"cols": ["Raio", "Céu", "Vento"], "nodes": [
		{"id": "a1", "col": 0, "cost": 1, "req": "", "nome": "Garras elétricas", "desc": "Faíscas extras saem 50% mais vezes.", "fx": {"pass": 0.5}},
		{"id": "a2", "col": 0, "cost": 2, "req": "a1", "nome": "Choque rápido", "desc": "Ataque básico 12% mais rápido.", "fx": {"atk_cd": 0.12}},
		{"id": "b1", "col": 1, "cost": 1, "req": "", "nome": "Raio potente", "desc": "Habilidade 1 com +35% de poder.", "fx": {"sk0_pow": 0.35}},
		{"id": "b2", "col": 1, "cost": 2, "req": "b1", "nome": "Céu carregado", "desc": "Habilidade 3 com +35% de poder e 15% menos recarga.", "fx": {"sk2_pow": 0.35, "sk2_cd": 0.15}},
		{"id": "c1", "col": 2, "cost": 1, "req": "", "nome": "Vento a favor", "desc": "+12% de velocidade.", "fx": {"spd": 0.12}},
		{"id": "c2", "col": 2, "cost": 2, "req": "c1", "nome": "Voo longo", "desc": "Habilidade 2 dura 50% mais.", "fx": {"sk1_dur": 0.5}},
		{"id": "m", "col": -1, "cost": 4, "req": "*4", "nome": "Senhor das tempestades", "desc": "Ainda mais faíscas, um pulo no ar a mais e suprema 40% mais forte.", "fx": {"pass": 0.5, "jumps": 1, "ult_pow": 0.4}}]},
	"dragao_2": {"cols": ["Ferrão", "Veneno", "Muda"], "nodes": [
		{"id": "a1", "col": 0, "cost": 1, "req": "", "nome": "Ferrão longo", "desc": "O ferrão alcança 30% mais longe.", "fx": {"atk_range": 0.3}},
		{"id": "a2", "col": 0, "cost": 2, "req": "a1", "nome": "Ferrão afiado", "desc": "+15% de dano no ataque básico.", "fx": {"atk_dmg": 0.15}},
		{"id": "b1", "col": 1, "cost": 1, "req": "", "nome": "Veneno acumulado", "desc": "O veneno acumula até 12.", "fx": {"poison_cap": 4}},
		{"id": "b2", "col": 1, "cost": 2, "req": "b1", "nome": "Veneno potente", "desc": "Cada acerto aplica mais veneno.", "fx": {"pass": 0.5}},
		{"id": "c1", "col": 2, "cost": 1, "req": "", "nome": "Muda rápida", "desc": "Habilidade 3 recarrega 25% mais rápido.", "fx": {"sk2_cd": 0.25}},
		{"id": "c2", "col": 2, "cost": 2, "req": "c1", "nome": "Nuvem densa", "desc": "Habilidade 1 dura 40% mais e tem +30% de poder.", "fx": {"sk0_dur": 0.4, "sk0_pow": 0.3}},
		{"id": "m", "col": -1, "cost": 4, "req": "*4", "nome": "Rainha das serpes", "desc": "Veneno acumula até 16, ainda mais veneno por acerto e suprema 30% mais forte.", "fx": {"poison_cap": 4, "pass": 0.5, "ult_pow": 0.3}}]},
	"dragao_3": {"cols": ["Cauda", "Meteoro", "Rugido"], "nodes": [
		{"id": "a1", "col": 0, "cost": 1, "req": "", "nome": "Cauda maciça", "desc": "+20% de dano no ataque básico.", "fx": {"atk_dmg": 0.2}},
		{"id": "a2", "col": 0, "cost": 2, "req": "a1", "nome": "Cauda longa", "desc": "A cauda alcança 25% mais longe.", "fx": {"atk_range": 0.25}},
		{"id": "b1", "col": 1, "cost": 1, "req": "", "nome": "Meteoro maior", "desc": "Habilidade 1 com +40% de poder.", "fx": {"sk0_pow": 0.4}},
		{"id": "b2", "col": 1, "cost": 2, "req": "b1", "nome": "Céu em chamas", "desc": "Habilidade 1 recarrega 20% mais rápido e habilidade 3 tem +30% de poder.", "fx": {"sk0_cd": 0.2, "sk2_pow": 0.3}},
		{"id": "c1", "col": 2, "cost": 1, "req": "", "nome": "Rugido ensurdecedor", "desc": "Habilidade 2 dura 50% mais.", "fx": {"sk1_dur": 0.5}},
		{"id": "c2", "col": 2, "cost": 2, "req": "c1", "nome": "Couro ancestral", "desc": "Perde 12% menos tempo por golpe.", "fx": {"def": 0.12}},
		{"id": "m", "col": -1, "cost": 4, "req": "*4", "nome": "Ancião eterno", "desc": "Suprema 50% mais forte, habilidade 2 +30% e perde 8% menos tempo.", "fx": {"ult_pow": 0.5, "sk1_pow": 0.3, "def": 0.08}}]}
}

## ===== Upgrades básicos do guardião: valem para todas as 4 classes dele, inclusive a base =====
## Pontos de guardião: cada lendário vencido com qualquer classe do guardião dá GUARD_PTS_PER_LEG.
## Custo de cada nível = 1 + nível atual / 3.
const GUARD_PTS_PER_LEG := 2
const BASIC_UPS := [
	{"id": "forca", "nome": "Força", "desc": "+5% de dano em tudo por nível.", "max": 10},
	{"id": "resist", "nome": "Resistência", "desc": "Perde 4% menos tempo por golpe, por nível.", "max": 10},
	{"id": "poder", "nome": "Poder das habilidades", "desc": "+6% de poder nas habilidades e na suprema por nível.", "max": 10},
	{"id": "agil", "nome": "Agilidade", "desc": "+3% de velocidade e dash 5% mais rápido por nível.", "max": 5},
	{"id": "impeto", "nome": "Ímpeto", "desc": "A suprema começa a luta com +6% de carga por nível.", "max": 5},
]
## ===== Habilidades supremas da própria classe (a suprema base de cada classe) =====
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
## ===== Alternativas de cada classe (só da própria classe) =====
## Para cada classe: [opções extras da hab. 1, da hab. 2, da hab. 3, da suprema] (2 extras por posição).
## As alternativas usam "mechs": peças de efeito montadas em arena.gd → run_mechs.
const CLASS_ALTS := {
	"minotauro_0": [["m0_machado", "m0_tufao"], ["m0_grito", "m0_quebra"], ["m0_couro", "m0_estandarte"], ["u_m0_colosso", "u_m0_tita"]],
	"minotauro_1": [["m1_corte", "m1_laminas"], ["m1_salto", "m1_chute"], ["m1_frenesi", "m1_ira"], ["u_m1_carnificina", "u_m1_matanca"]],
	"minotauro_2": [["m2_pedra", "m2_paredao"], ["m2_tremor", "m2_punho"], ["m2_granito", "m2_regenerar"], ["u_m2_fortaleza", "u_m2_avatar"]],
	"minotauro_3": [["m3_lancas", "m3_dardo"], ["m3_trote", "m3_salto"], ["m3_marca", "m3_rebanho"], ["u_m3_manada", "u_m3_ceu_lancas"]],
	"lich_0": [["l0_virote", "l0_orbe"], ["l0_vazio", "l0_espelho"], ["l0_maldicao", "l0_ceifa"], ["u_l0_ceifador", "u_l0_eclipse"]],
	"lich_1": [["l1_caveiras", "l1_lascas_osso"], ["l1_ossada", "l1_cadaver"], ["l1_pacto", "l1_horda"], ["u_l1_rei_morto", "u_l1_tumulo"]],
	"lich_2": [["l2_estilhacos", "l2_cometa"], ["l2_prisao", "l2_deslize"], ["l2_armadura", "l2_espelho_gelo"], ["u_l2_inverno", "u_l2_zero"]],
	"lich_3": [["l3_ponteiros", "l3_badalo"], ["l3_acelerar", "l3_atraso"], ["l3_hora", "l3_ampulheta"], ["u_l3_paradoxo", "u_l3_relogio"]],
	"dragao_0": [["d0_bola", "d0_garras"], ["d0_rasante", "d0_salto"], ["d0_chamas", "d0_furia"], ["u_d0_sol", "u_d0_fenix"]],
	"dragao_1": [["d1_faiscas", "d1_rajada"], ["d1_relampago", "d1_trovao"], ["d1_nuvem", "d1_campo"], ["u_d1_furacao", "u_d1_ciclone"]],
	"dragao_2": [["d2_cuspe", "d2_espinhos"], ["d2_bote", "d2_enrosco"], ["d2_toxina", "d2_pele"], ["u_d2_ninho", "u_d2_hidra"]],
	"dragao_3": [["d3_cauda", "d3_sopro"], ["d3_brasas", "d3_pisada"], ["d3_escamas", "d3_tesouro"], ["u_d3_cataclismo", "u_d3_dominio"]],
}
const ALT_SKILLS := {
	"m1_investida_sangue": {"nome": "Investida sangrenta", "cd": 5.0, "icon": "ui/sk_investida", "desc": "avança com os machados e cada acerto devolve tempo por 2s", "mechs": [{"m": "charge", "t": 0.3, "spd": 760.0, "dmg": 28.0}, {"m": "buff", "leech": 2.0}]},
	"l1_colheita": {"nome": "Colheita de almas", "cd": 7.0, "icon": "ui/sk_erguer", "desc": "ergue 2 esqueletos e deixa o lendário frágil por 3s", "mechs": [{"m": "summon", "n": 2, "life": 6.0, "dmg": 5.0}, {"m": "boss", "vuln": 3.0}]},
	"m0_tufao": {"nome": "Tufão de machado", "cd": 6.0, "icon": "ui/sk_redemoinho", "desc": "gira o machado em volta do corpo por 1s", "mechs": [{"m": "spin", "t": 1.0, "dmg": 7.0}]},
	"m0_quebra": {"nome": "Quebra-chão", "cd": 6.0, "icon": "ui/sk_pisao", "desc": "onda de choque forte que atordoa", "mechs": [{"m": "stomp", "n": 1, "dmg": 26.0}, {"m": "boss", "stun": 0.5}]},
	"m0_estandarte": {"nome": "Estandarte", "cd": 11.0, "icon": "ui/sk_furia", "desc": "4s de fúria e muito mais velocidade", "mechs": [{"m": "buff", "fury": 4.0, "haste": 4.0}]},
	"m1_laminas": {"nome": "Lâminas giratórias", "cd": 4.0, "icon": "ui/sk_redemoinho", "desc": "lança dois machados que atravessam o lendário", "mechs": [{"m": "proj", "spr": "fx/axe_spin", "n": 2, "spread": 0.3, "spd": 600.0, "dmg": 14.0, "pierce": true}]},
	"m1_chute": {"nome": "Chute", "cd": 5.0, "icon": "ui/sk_chifrada", "desc": "chute curto que atordoa por quase 1s", "mechs": [{"m": "charge", "t": 0.12, "spd": 600.0, "dmg": 16.0, "stun": 0.8}]},
	"m1_ira": {"nome": "Ira", "cd": 10.0, "icon": "ui/sk_sede", "desc": "3s de fúria e o lendário leva +30% de dano", "mechs": [{"m": "buff", "fury": 3.0}, {"m": "boss", "vuln": 3.0}]},
	"m2_paredao": {"nome": "Paredão de pedra", "cd": 7.0, "icon": "ui/sk_muralha", "desc": "ergue uma parede de pedra que barra projéteis e investidas", "mechs": [{"m": "wall", "dmg": 24.0}]},
	"m2_punho": {"nome": "Punho de pedra", "cd": 6.0, "icon": "ui/sk_chifrada", "desc": "soco pesado que atordoa", "mechs": [{"m": "charge", "t": 0.15, "spd": 600.0, "dmg": 34.0, "stun": 0.5}]},
	"m2_regenerar": {"nome": "Regenerar", "cd": 12.0, "icon": "ui/sk_postura", "desc": "devolve 4s ao relógio", "mechs": [{"m": "clock", "s": 4.0}]},
	"m3_dardo": {"nome": "Dardo triplo", "cd": 4.5, "icon": "ui/sk_arremesso", "desc": "três dardos que atravessam o lendário", "mechs": [{"m": "proj", "spr": "fx/spear", "n": 3, "spread": 0.12, "spd": 760.0, "dmg": 12.0, "pierce": true}]},
	"m3_salto": {"nome": "Salto de lança", "cd": 6.0, "icon": "ui/sk_mergulho", "desc": "salta e cai com a lança sobre o lendário", "mechs": [{"m": "leap", "dmg": 30.0}]},
	"m3_rebanho": {"nome": "Rebanho veloz", "cd": 8.0, "icon": "ui/sk_estouro", "desc": "dois touros espectrais atravessam a arena", "mechs": [{"m": "bulls", "n": 2, "dmg": 16.0}]},
	"l0_orbe": {"nome": "Orbe de alma", "cd": 4.0, "icon": "ui/sk_drenar", "desc": "orbe lento e pesado que atravessa o lendário", "mechs": [{"m": "proj", "spr": "fx/orb", "spd": 360.0, "dmg": 30.0, "r": 14.0, "pierce": true}]},
	"l0_espelho": {"nome": "Véu sombrio", "cd": 7.0, "icon": "ui/sk_muralha", "desc": "fica intocável por 1s e recua", "mechs": [{"m": "blink", "dist": -140.0}, {"m": "buff", "inv": 1.0}]},
	"l0_ceifa": {"nome": "Ceifa de tempo", "cd": 8.0, "icon": "ui/sk_drenar", "desc": "fere o lendário e devolve 1s ao relógio", "mechs": [{"m": "boss", "dmg": 18.0}, {"m": "clock", "s": 1.0}]},
	"l1_lascas_osso": {"nome": "Lascas de osso", "cd": 4.0, "icon": "ui/sk_explosao", "desc": "cinco lascas de osso em linha reta", "mechs": [{"m": "proj", "spr": "fx/bone", "n": 5, "spread": 0.06, "spd": 700.0, "dmg": 7.0}]},
	"l1_cadaver": {"nome": "Cadáver venenoso", "cd": 6.0, "icon": "ui/sk_explosao", "desc": "explode um cadáver no lendário e envenena", "mechs": [{"m": "boss", "dmg": 22.0, "poison": 2}]},
	"l1_horda": {"nome": "Horda", "cd": 9.0, "icon": "ui/sk_erguer", "desc": "ergue 3 esqueletos fracos por 5s", "mechs": [{"m": "summon", "n": 3, "life": 5.0, "dmg": 4.0}]},
	"l2_cometa": {"nome": "Cometa de gelo", "cd": 6.0, "icon": "ui/sk_lanca_gelo", "desc": "um cometa de gelo cai e deixa lento", "mechs": [{"m": "meteors", "n": 1, "dmg": 34.0, "spread": 0.0, "spr": "fx/orb_ice", "r": 70.0}, {"m": "boss", "slow": 2.0}]},
	"l2_deslize": {"nome": "Deslizar", "cd": 5.0, "icon": "ui/sk_bloco", "desc": "desliza no gelo atravessando o lendário e deixa lento", "mechs": [{"m": "charge", "t": 0.3, "spd": 700.0, "dmg": 12.0}, {"m": "boss", "slow": 2.0}]},
	"l2_espelho_gelo": {"nome": "Espelho de gelo", "cd": 10.0, "icon": "ui/sk_bloco", "desc": "2s bloqueando tudo e devolvendo o dano", "mechs": [{"m": "buff", "block": 2.0}]},
	"l3_badalo": {"nome": "Badalo", "cd": 5.0, "icon": "ui/sk_eco", "desc": "uma badalada solta ponteiros para todos os lados", "mechs": [{"m": "nova", "waves": 1, "n": 10, "spr": "fx/clockhand", "spd": 420.0, "dmg": 7.0}]},
	"l3_atraso": {"nome": "Atraso", "cd": 8.0, "icon": "ui/sk_parar", "desc": "o lendário fica lento e frágil", "mechs": [{"m": "boss", "slow": 4.0, "vuln": 2.0}]},
	"l3_ampulheta": {"nome": "Ampulheta", "cd": 10.0, "icon": "ui/sk_rebobinar", "desc": "devolve 2s e dá 3s de velocidade", "mechs": [{"m": "clock", "s": 2.0}, {"m": "buff", "haste": 3.0}]},
	"d0_garras": {"nome": "Garras ardentes", "cd": 3.5, "icon": "ui/sk_mergulho", "desc": "avanço curto com as garras em chamas", "mechs": [{"m": "charge", "t": 0.14, "spd": 650.0, "dmg": 20.0}]},
	"d0_salto": {"nome": "Salto alado", "cd": 6.0, "icon": "ui/sk_mergulho", "desc": "salta e cai sobre o lendário", "mechs": [{"m": "leap", "dmg": 28.0}]},
	"d0_furia": {"nome": "Fúria dracônica", "cd": 11.0, "icon": "ui/sk_escamas", "desc": "4s de fúria: +50% de dano", "mechs": [{"m": "buff", "fury": 4.0}]},
	"d1_rajada": {"nome": "Rajada de vento", "cd": 4.0, "icon": "ui/sk_voo", "desc": "rajada rápida que atravessa o lendário", "mechs": [{"m": "proj", "spr": "fx/orb_storm", "spd": 800.0, "dmg": 20.0, "pierce": true}]},
	"d1_trovao": {"nome": "Trovão", "cd": 8.0, "icon": "ui/sk_raio", "desc": "atordoa o lendário por mais de 1s", "mechs": [{"m": "boss", "stun": 1.2, "dmg": 10.0}]},
	"d1_campo": {"nome": "Campo elétrico", "cd": 9.0, "icon": "ui/sk_tempestade", "desc": "área elétrica sob o lendário por 4s", "mechs": [{"m": "zone", "kind": "storm", "at": "boss", "w": 140.0, "h": 120.0, "life": 4.0, "tick": 0.3, "dmg": 3.5}]},
	"d2_espinhos": {"nome": "Espinhos venenosos", "cd": 4.0, "icon": "ui/sk_ferrao", "desc": "quatro espinhos que envenenam", "mechs": [{"m": "proj", "spr": "fx/stinger", "n": 4, "spread": 0.15, "spd": 600.0, "dmg": 6.0, "poison": 1}]},
	"d2_enrosco": {"nome": "Enroscar", "cd": 8.0, "icon": "ui/sk_muda", "desc": "prende o lendário por 1s e envenena", "mechs": [{"m": "boss", "stop": 1.0, "poison": 2}]},
	"d2_pele": {"nome": "Pele tóxica", "cd": 11.0, "icon": "ui/sk_muda", "desc": "5s com aura que machuca e envenena", "mechs": [{"m": "buff", "scale": 5.0}, {"m": "boss", "poison": 1}]},
	"d3_sopro": {"nome": "Sopro antigo", "cd": 6.0, "icon": "ui/sk_baforada", "desc": "baforada larga e pesada", "mechs": [{"m": "breath", "t": 1.2, "dmg": 1.6}]},
	"d3_pisada": {"nome": "Pisada colossal", "cd": 6.0, "icon": "ui/sk_terremoto", "desc": "onda de choque que atordoa", "mechs": [{"m": "stomp", "n": 1, "dmg": 30.0}, {"m": "boss", "stun": 0.7}]},
	"d3_tesouro": {"nome": "Tesouro", "cd": 12.0, "icon": "ui/sk_escamas", "desc": "devolve 4s ao relógio", "mechs": [{"m": "clock", "s": 4.0}]},
	"m0_machado": {"nome": "Machado arremessado", "cd": 4.5, "icon": "ui/sk_arremesso", "desc": "arremessa o machado, que atravessa o lendário", "mechs": [{"m": "proj", "spr": "fx/axe_spin", "spd": 620.0, "dmg": 24.0, "r": 12.0, "pierce": true}]},
	"m0_grito": {"nome": "Grito de guerra", "cd": 7.0, "icon": "ui/sk_rugido", "desc": "atordoa o lendário por 1s e dá 3s de fúria", "mechs": [{"m": "boss", "stun": 1.0}, {"m": "buff", "fury": 3.0}]},
	"m0_couro": {"nome": "Couro de touro", "cd": 11.0, "icon": "ui/sk_postura", "desc": "5s perdendo menos tempo e queimando quem chega perto", "mechs": [{"m": "buff", "scale": 5.0}]},
	"m1_corte": {"nome": "Corte cruzado", "cd": 3.5, "icon": "ui/sk_furia", "desc": "avanço curto com dois cortes", "mechs": [{"m": "charge", "t": 0.22, "spd": 720.0, "dmg": 30.0}]},
	"m1_salto": {"nome": "Salto brutal", "cd": 6.0, "icon": "ui/sk_terremoto", "desc": "salta e despenca sobre o lendário", "mechs": [{"m": "leap", "dmg": 34.0}]},
	"m1_frenesi": {"nome": "Frenesi", "cd": 12.0, "icon": "ui/sk_sede", "desc": "6s de fúria: +50% de dano e golpes mais rápidos", "mechs": [{"m": "buff", "fury": 6.0}]},
	"m2_pedra": {"nome": "Pedra arremessada", "cd": 4.0, "icon": "ui/sk_pisao", "desc": "arremessa uma rocha que atordoa um instante", "mechs": [{"m": "proj", "spr": "fx/rock", "spd": 480.0, "dmg": 28.0, "r": 14.0, "stun": 0.4}]},
	"m2_tremor": {"nome": "Tremor", "cd": 6.0, "icon": "ui/sk_terremoto", "desc": "duas ondas de choque seguidas", "mechs": [{"m": "stomp", "n": 2, "dmg": 18.0}]},
	"m2_granito": {"nome": "Pele de granito", "cd": 12.0, "icon": "ui/sk_postura", "desc": "6s perdendo menos tempo, com aura que machuca", "mechs": [{"m": "buff", "scale": 6.0}]},
	"m3_lancas": {"nome": "Chuva de lanças", "cd": 6.0, "icon": "ui/sk_arremesso", "desc": "três lanças caem do alto sobre o lendário", "mechs": [{"m": "meteors", "n": 3, "dmg": 16.0, "spread": 80.0, "spr": "fx/spear", "r": 40.0}]},
	"m3_trote": {"nome": "Trote", "cd": 5.0, "icon": "ui/sk_investida_longa", "desc": "4s muito mais rápido, intocável no começo", "mechs": [{"m": "buff", "haste": 4.0, "inv": 0.5}]},
	"m3_marca": {"nome": "Marca do caçador", "cd": 9.0, "icon": "ui/sk_drenar", "desc": "o lendário leva +30% de dano por 5s", "mechs": [{"m": "boss", "vuln": 5.0}]},
	"l0_virote": {"nome": "Virote sombrio", "cd": 3.0, "icon": "ui/sk_coroa", "desc": "um virote pesado de caveira", "mechs": [{"m": "proj", "spr": "fx/skull", "spd": 560.0, "dmg": 26.0, "r": 10.0}]},
	"l0_vazio": {"nome": "Passo do vazio", "cd": 5.0, "icon": "ui/sk_drenar", "desc": "teleporta longe para a frente, intocável", "mechs": [{"m": "blink", "dist": 210.0}, {"m": "buff", "inv": 0.5}]},
	"l0_maldicao": {"nome": "Maldição", "cd": 9.0, "icon": "ui/sk_drenar", "desc": "o lendário fica lento e leva +30% de dano por 5s", "mechs": [{"m": "boss", "vuln": 5.0, "slow": 3.0}]},
	"l1_caveiras": {"nome": "Caveiras uivantes", "cd": 4.0, "icon": "ui/sk_coroa", "desc": "três caveiras em leque", "mechs": [{"m": "proj", "spr": "fx/skull", "n": 3, "spread": 0.2, "spd": 520.0, "dmg": 12.0}]},
	"l1_ossada": {"nome": "Ossada", "cd": 6.0, "icon": "ui/sk_erguer", "desc": "ergue um esqueleto forte por 10s", "mechs": [{"m": "summon", "n": 1, "life": 10.0, "dmg": 8.0}]},
	"l1_pacto": {"nome": "Pacto sombrio", "cd": 10.0, "icon": "ui/sk_drenar", "desc": "5s em que cada acerto devolve tempo", "mechs": [{"m": "buff", "leech": 5.0}]},
	"l2_estilhacos": {"nome": "Estilhaços", "cd": 4.0, "icon": "ui/sk_lanca_gelo", "desc": "leque de 5 lascas que deixam lento", "mechs": [{"m": "proj", "spr": "fx/shard", "n": 5, "spread": 0.18, "spd": 600.0, "dmg": 8.0, "slow": 1.5}]},
	"l2_prisao": {"nome": "Prisão de gelo", "cd": 8.0, "icon": "ui/sk_bloco", "desc": "congela o lendário por 1,2s", "mechs": [{"m": "boss", "stop": 1.2, "dmg": 12.0}]},
	"l2_armadura": {"nome": "Armadura glacial", "cd": 11.0, "icon": "ui/sk_bloco", "desc": "5s perdendo menos tempo, com aura gelada", "mechs": [{"m": "buff", "scale": 5.0}]},
	"l3_ponteiros": {"nome": "Ponteiros", "cd": 4.0, "icon": "ui/sk_parar", "desc": "três ponteiros que atravessam o lendário", "mechs": [{"m": "proj", "spr": "fx/clockhand", "n": 3, "spread": 0.12, "spd": 700.0, "dmg": 10.0, "pierce": true}]},
	"l3_acelerar": {"nome": "Acelerar", "cd": 7.0, "icon": "ui/sk_rebobinar", "desc": "4s muito mais rápido", "mechs": [{"m": "buff", "haste": 4.0}]},
	"l3_hora": {"nome": "Hora certa", "cd": 10.0, "icon": "ui/sk_parar", "desc": "devolve 3s ao relógio e atordoa o lendário", "mechs": [{"m": "clock", "s": 3.0}, {"m": "boss", "stun": 0.8}]},
	"d0_bola": {"nome": "Bola de fogo", "cd": 4.0, "icon": "ui/sk_meteoro", "desc": "uma bola de fogo grande", "mechs": [{"m": "proj", "spr": "fx/orb_fire", "spd": 480.0, "dmg": 28.0, "r": 12.0}]},
	"d0_rasante": {"nome": "Rasante", "cd": 5.0, "icon": "ui/sk_asas_fogo", "desc": "voa rente ao chão atravessando o lendário", "mechs": [{"m": "charge", "t": 0.35, "spd": 760.0, "dmg": 26.0}]},
	"d0_chamas": {"nome": "Chão em chamas", "cd": 9.0, "icon": "ui/sk_baforada", "desc": "o chão sob o lendário queima por 4s", "mechs": [{"m": "zone", "kind": "fire", "at": "boss", "w": 130.0, "h": 60.0, "life": 4.0, "tick": 0.3, "dmg": 3.0}]},
	"d1_faiscas": {"nome": "Faíscas", "cd": 3.5, "icon": "ui/sk_raio", "desc": "três faíscas que dão choque", "mechs": [{"m": "proj", "spr": "fx/orb_storm", "n": 3, "spread": 0.25, "spd": 600.0, "dmg": 10.0, "stun": 0.15}]},
	"d1_relampago": {"nome": "Relâmpago", "cd": 5.0, "icon": "ui/sk_raio", "desc": "avança como um raio e atordoa", "mechs": [{"m": "charge", "t": 0.2, "spd": 900.0, "dmg": 22.0, "stun": 0.5}]},
	"d1_nuvem": {"nome": "Nuvem carregada", "cd": 9.0, "icon": "ui/sk_tempestade", "desc": "quatro raios caem aos poucos sobre o lendário", "mechs": [{"m": "bolts", "n": 4, "gap": 0.6, "dmg": 11.0, "stun": 0.2}]},
	"d2_cuspe": {"nome": "Cuspe ácido", "cd": 3.5, "icon": "ui/sk_nuvem", "desc": "três gotas que envenenam", "mechs": [{"m": "proj", "spr": "fx/drop_acid", "n": 3, "spread": 0.15, "spd": 520.0, "dmg": 8.0, "poison": 2}]},
	"d2_bote": {"nome": "Bote duplo", "cd": 5.0, "icon": "ui/sk_ferrao", "desc": "bote rápido que envenena bastante", "mechs": [{"m": "charge", "t": 0.25, "spd": 800.0, "dmg": 18.0, "poison": 3}]},
	"d2_toxina": {"nome": "Toxina", "cd": 9.0, "icon": "ui/sk_nuvem", "desc": "envenena e deixa o lendário frágil por 4s", "mechs": [{"m": "boss", "poison": 4, "vuln": 4.0}]},
	"d3_cauda": {"nome": "Golpe de cauda", "cd": 4.5, "icon": "ui/sk_rugido", "desc": "avanço curto e pesado que atordoa", "mechs": [{"m": "charge", "t": 0.18, "spd": 650.0, "dmg": 40.0, "stun": 0.6}]},
	"d3_brasas": {"nome": "Chuva de brasas", "cd": 6.0, "icon": "ui/sk_meteoro", "desc": "três brasas caem em volta do lendário", "mechs": [{"m": "meteors", "n": 3, "dmg": 14.0, "spread": 120.0, "spr": "fx/orb_fire", "r": 50.0}]},
	"d3_escamas": {"nome": "Escamas antigas", "cd": 12.0, "icon": "ui/sk_escamas", "desc": "6s perdendo menos tempo e devolve 2s", "mechs": [{"m": "buff", "scale": 6.0}, {"m": "clock", "s": 2.0}]},
}
const ALT_ULTS := {
	"u_m0_tita": {"nome": "Titã", "icon": "ui/sk_furia", "desc": "5s gigante: dano dobrado, golpes rápidos e metade do tempo perdido.", "mechs": [{"m": "king", "t": 5.0}, {"m": "buff", "inv": 0.6}]},
	"u_m1_matanca": {"nome": "Matança", "icon": "ui/sk_redemoinho", "desc": "2s girando com dano altíssimo e 4s de fúria.", "mechs": [{"m": "spin", "t": 2.0, "dmg": 18.0}, {"m": "buff", "fury": 4.0}]},
	"u_m2_avatar": {"nome": "Avatar de pedra", "icon": "ui/sk_postura", "desc": "5s de dano dobrado e 8s de aura que protege.", "mechs": [{"m": "king", "t": 5.0}, {"m": "buff", "scale": 8.0}]},
	"u_m3_ceu_lancas": {"nome": "Céu de lanças", "icon": "ui/sk_arremesso", "desc": "Dez lanças caem do alto sobre o lendário.", "mechs": [{"m": "meteors", "n": 10, "dmg": 14.0, "spread": 200.0, "spr": "fx/spear", "r": 40.0}]},
	"u_l0_eclipse": {"nome": "Eclipse", "icon": "ui/sk_drenar", "desc": "Para o lendário por 1,5s e solta três rajadas de caveiras.", "mechs": [{"m": "boss", "stop": 1.5}, {"m": "nova", "waves": 3, "n": 10, "spr": "fx/skull", "spd": 460.0, "dmg": 8.0}]},
	"u_l1_tumulo": {"nome": "Túmulo aberto", "icon": "ui/sk_erguer", "desc": "Quatro esqueletos saem da terra e o lendário fica lento.", "mechs": [{"m": "summon", "n": 4, "life": 10.0, "dmg": 8.0}, {"m": "boss", "slow": 4.0}]},
	"u_l2_zero": {"nome": "Zero absoluto", "icon": "ui/sk_bloco", "desc": "Congela o lendário por 2s com dano muito alto.", "mechs": [{"m": "boss", "stop": 2.0, "dmg": 50.0}]},
	"u_l3_relogio": {"nome": "Relógio quebrado", "icon": "ui/sk_rebobinar", "desc": "Seis ponteiros gigantes caem e o relógio ganha 5s.", "mechs": [{"m": "meteors", "n": 6, "dmg": 16.0, "spread": 150.0, "spr": "fx/clockhand", "r": 50.0}, {"m": "clock", "s": 5.0}]},
	"u_d0_fenix": {"nome": "Fênix", "icon": "ui/sk_asas_fogo", "desc": "Renasce: +6s no relógio, 2s intocável e fogo ao redor.", "mechs": [{"m": "clock", "s": 6.0}, {"m": "buff", "inv": 2.0}, {"m": "zone", "kind": "fire", "at": "self", "w": 200.0, "h": 70.0, "life": 5.0, "tick": 0.3, "dmg": 4.0}]},
	"u_d1_ciclone": {"nome": "Ciclone", "icon": "ui/sk_voo", "desc": "Um ciclone elétrico segue o lendário por 6s e solta raios.", "mechs": [{"m": "zone", "kind": "storm", "at": "boss", "follow": true, "w": 220.0, "h": 200.0, "life": 6.0, "tick": 0.3, "dmg": 5.0}, {"m": "bolts", "n": 3, "gap": 1.5, "dmg": 12.0, "stun": 0.2}]},
	"u_d2_hidra": {"nome": "Hidra", "icon": "ui/sk_ferrao", "desc": "Nove ferrões venenosos e veneno alto no lendário.", "mechs": [{"m": "proj", "spr": "fx/stinger", "n": 9, "spread": 0.1, "spd": 620.0, "dmg": 8.0, "poison": 1}, {"m": "boss", "poison": 6}]},
	"u_d3_dominio": {"nome": "Domínio do céu", "icon": "ui/sk_escamas", "desc": "6s de dano dobrado e aura de fogo.", "mechs": [{"m": "king", "t": 6.0}, {"m": "buff", "scale": 6.0}]},
	"u_m0_colosso": {"nome": "Machado colossal", "icon": "ui/sk_arremesso", "desc": "Um machado gigante cai sobre o lendário e o deixa atordoado.", "mechs": [{"m": "meteors", "n": 1, "dmg": 70.0, "spread": 0.0, "spr": "fx/axe_spin", "r": 90.0}, {"m": "boss", "stun": 1.5}]},
	"u_m1_carnificina": {"nome": "Carnificina", "icon": "ui/sk_sede", "desc": "6s de fúria em que cada acerto devolve tempo.", "mechs": [{"m": "buff", "fury": 6.0, "leech": 6.0}]},
	"u_m2_fortaleza": {"nome": "Fortaleza", "icon": "ui/sk_postura", "desc": "5s bloqueando tudo e devolvendo o dano; recupera 4s.", "mechs": [{"m": "buff", "block": 5.0}, {"m": "clock", "s": 4.0}]},
	"u_m3_manada": {"nome": "Manada sem fim", "icon": "ui/sk_estouro", "desc": "Seis touros espectrais atropelam a arena.", "mechs": [{"m": "bulls", "n": 6, "dmg": 24.0}]},
	"u_l0_ceifador": {"nome": "Ceifador", "icon": "ui/sk_coroa", "desc": "Duas rajadas de 16 caveiras e o lendário atordoado.", "mechs": [{"m": "nova", "waves": 2, "n": 16, "spr": "fx/skull", "spd": 480.0, "dmg": 10.0}, {"m": "boss", "stun": 1.0}]},
	"u_l1_rei_morto": {"nome": "Rei dos mortos", "icon": "ui/sk_erguer", "desc": "Três esqueletos fortes e 6s de aura que protege.", "mechs": [{"m": "summon", "n": 3, "life": 12.0, "dmg": 10.0}, {"m": "buff", "scale": 6.0}]},
	"u_l2_inverno": {"nome": "Inverno eterno", "icon": "ui/sk_nevasca", "desc": "8s de nevasca enorme sobre o lendário, que fica lento.", "mechs": [{"m": "zone", "kind": "snow", "at": "boss", "follow": true, "w": 260.0, "h": 240.0, "life": 8.0, "tick": 0.25, "dmg": 5.0, "slow": 0.6}, {"m": "boss", "slow": 8.0}]},
	"u_l3_paradoxo": {"nome": "Paradoxo", "icon": "ui/sk_eco", "desc": "Para o tempo por 2,5s e dispara duas rajadas de ponteiros.", "mechs": [{"m": "boss", "stop": 2.5}, {"m": "nova", "waves": 2, "n": 12, "spr": "fx/clockhand", "spd": 560.0, "dmg": 9.0}]},
	"u_d0_sol": {"nome": "Sol negro", "icon": "ui/sk_meteoro", "desc": "Uma esfera de fogo imensa cai sobre o lendário.", "mechs": [{"m": "meteors", "n": 1, "dmg": 80.0, "spread": 0.0, "spr": "fx/orb_fire", "r": 120.0}, {"m": "boss", "stun": 1.0}]},
	"u_d1_furacao": {"nome": "Olho do furacão", "icon": "ui/sk_tempestade", "desc": "Dez raios rápidos sobre o lendário.", "mechs": [{"m": "bolts", "n": 10, "gap": 0.2, "dmg": 12.0, "stun": 0.1}]},
	"u_d2_ninho": {"nome": "Ninho de serpes", "icon": "ui/sk_nuvem", "desc": "Veneno no máximo e uma área venenosa enorme por 8s.", "mechs": [{"m": "boss", "poison": 8}, {"m": "zone", "kind": "poison", "at": "boss", "w": 240.0, "h": 140.0, "life": 8.0, "tick": 0.4, "dmg": 4.0, "poison": 1}]},
	"u_d3_cataclismo": {"nome": "Cataclismo", "icon": "ui/sk_meteoro", "desc": "Doze meteoros e três ondas de choque.", "mechs": [{"m": "meteors", "n": 12, "dmg": 20.0, "spread": 200.0, "spr": "fx/meteor", "r": 60.0}, {"m": "stomp", "n": 3, "dmg": 18.0}]},
}
const ULT_CHARGE_START := 35.0   # barra de poder ao começar a luta (cheia = 100)
## Custos em pontos de talento da classe em uso.
const SKILL_UNLOCK_COST := 3     # liberar a habilidade alternativa da classe
const ULT_UNLOCK_COST := 4       # liberar a suprema alternativa da classe
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
			"atk": {"kind": "melee", "dmg": 12, "cd": 0.24, "range": 60, "hh": 48, "t": 0.09, "anti": 0.03, "rec": 0.05, "fx": "axe", "shake": 0.003}, "skills": ["redemoinho", "m1_investida_sangue", "sede"], "passive": "furia_acumula", "bonus": {"desc": "Monstros causam +35% de dano, mas têm 10% menos vida.", "mul": {"monDmg": 1.35, "monHp": 0.9}}},
		{"nome": "Guardião de Pedra", "estilo": "Tanque com escudo e maça: lento, aguenta muito e empurra o inimigo.", "spd": 0.85, "jump": 0.95, "jumps": 1, "armor": 0.6,
			"atk": {"kind": "melee", "dmg": 26, "cd": 0.6, "range": 62, "hh": 56, "t": 0.16, "anti": 0.1, "rec": 0.14, "fx": "axe", "shake": 0.008}, "skills": ["postura", "chifrada", "terremoto"], "passive": "empurrao", "bonus": {"desc": "Monstros têm +40% de vida.", "mul": {"monHp": 1.4}}},
		{"nome": "Senhor dos Touros", "estilo": "Lança longa: ataca de mais longe e atropela com o rebanho.", "spd": 1.05, "jump": 1.05, "jumps": 1, "armor": 0.9,
			"atk": {"kind": "melee", "dmg": 18, "cd": 0.38, "range": 110, "hh": 30, "t": 0.12, "anti": 0.07, "rec": 0.08, "fx": "spear", "shake": 0.004}, "skills": ["arremesso", "investida_longa", "estouro"], "passive": "", "bonus": {"desc": "Um ogro sai de graça a cada 25s de onda.", "free": ["ogro", 25.0]}},
	],
	"lich": [
		{"nome": "Lich", "estilo": "Magia à distância e controle.", "spd": 1.0, "jump": 1.0, "jumps": 2, "armor": 0.98,
			"atk": {"kind": "shot", "dmg": 8, "cd": 0.26, "spd": 640, "anti": 0.04, "rec": 0.05, "spr": "fx/bone", "fx": "necro"}, "skills": ["coroa", "muralha", "drenar"], "passive": "", "bonus": {"desc": "Espinhos causam +30% de dano.", "mul": {"esp": 1.3}}},
		{"nome": "Necromante", "estilo": "Ergue esqueletos que lutam por ele; acertos colhem almas.", "spd": 0.95, "jump": 1.0, "jumps": 2, "armor": 0.93,
			"atk": {"kind": "shot", "dmg": 10, "cd": 0.4, "spd": 520, "anti": 0.06, "rec": 0.06, "spr": "fx/skull", "fx": "necro"}, "skills": ["erguer", "explosao", "l1_colheita"], "passive": "colheita", "bonus": {"desc": "Esqueletos custam metade do tempo e um sai de graça a cada 12s de onda.", "cheap": "esqueleto", "free": ["esqueleto", 12.0]}},
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
