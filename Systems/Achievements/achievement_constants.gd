extends RefCounted
class_name AchievementConstants

const SAVE_PATH := "user://achievements_save_v1.json"
const SAVE_VERSION := 1

const EVENT_RUN_STARTED := &"run_started"

const ID_BIENVENIDA_RUKA := "bienvenida_ruka"
const ID_PRIMERA_CHISPA := "primera_chispa"

const DEFINITIONS := {
	ID_BIENVENIDA_RUKA: {
		"id": ID_BIENVENIDA_RUKA,
		"title": "Bienvenida, Ruka",
		"description": "Inicia una partida por primera vez.",
		"scope": "total",
		"threshold": 1,
		"event_name": EVENT_RUN_STARTED,
		"wavedash_id": "bienvenida_ruka"
	},
	ID_PRIMERA_CHISPA: {
		"id": ID_PRIMERA_CHISPA,
		"title": "Primera Chispa",
		"description": "Elimina tu primer enemigo.",
		"scope": "total",
		"threshold": 1,
		"event_name": &"enemy_killed",
		"wavedash_id": "primera_chispa"
	},
}

const ACTIVE_FOR_TEST := [
	ID_BIENVENIDA_RUKA,
	ID_PRIMERA_CHISPA,
]

# TODO Backlog (documentado, no implementado en esta iteracion):
# - caja_de_herramientas: 10 bajas con llave inglesa.
# - limpieza_industrial: 25 bajas en una run.
# - fantasma_en_la_maquina: completar run sin dano.
# - pulso_de_acero: 3 salas seguidas sin dano.
# - hora_del_desarme: entrar por primera vez a sala de jefe.
# - no_tocas_mi_helado: derrotar jefe final.
# - exterminadora_run: 50 bajas en una run (ajuste del proyecto).
# - infestacion: 100 bajas total.
# - llave_maestra: completar run usando solo llave inglesa.
const TODO_BACKLOG := [
	"caja_de_herramientas",
	"limpieza_industrial",
	"fantasma_en_la_maquina",
	"pulso_de_acero",
	"hora_del_desarme",
	"no_tocas_mi_helado",
	"exterminadora_run",
	"infestacion",
	"llave_maestra",
]
