extends Resource
class_name GameBalance


# ============================================================
# MOVIMIENTO HORIZONTAL
# ============================================================

@export_category("Horizontal Movement")

@export var horizontal_speed: float = 300.0
@export var horizontal_acceleration: float = 1200.0
@export var horizontal_deceleration: float = 1000.0
@export var horizontal_margin: float = 58.0


# ============================================================
# ASCENSO CON GLOBO
# ============================================================

@export_category("Inflated Movement")

# Velocidad vertical de Milo.
# Antes: 270 px/s
# Ahora: 125 px/s
@export var rise_speed: float = 125.0


# Aproximadamente 18 segundos de aire completo.
@export var max_air: float = 18.0


# Consume 1 unidad de aire por segundo.
@export var air_drain_per_second: float = 1.0


# Al llegar al 20% aparece la alerta de aire bajo.
@export_range(0.0, 1.0, 0.01)
var low_air_threshold: float = 0.20


# ============================================================
# CAÍDA
# ============================================================

@export_category("Falling")

@export var gravity: float = 1050.0
@export var max_fall_speed: float = 700.0


# Tiempo para encontrar un globo durante la caída.
@export var fall_rescue_window: float = 3.5


# Distancia a la que puede aparecer el globo de rescate.
@export var rescue_balloon_min_drop: float = 520.0
@export var rescue_balloon_max_drop: float = 760.0


# ============================================================
# REVIVE
# ============================================================

@export_category("Revive")

# Revive con 100% de aire.
@export var revive_air_ratio: float = 1.0


# Protección después de revivir.
@export var revive_invulnerability_seconds: float = 2.0


# ============================================================
# MUNDO Y ALTURA
# ============================================================

@export_category("World")

# 80 píxeles recorridos equivalen aproximadamente
# a 1 metro mostrado en el HUD.
#
# Antes estaba en 12, por eso los metros
# aumentaban exageradamente rápido.
@export var pixels_per_meter: float = 80.0


@export var world_width: float = 1080.0

@export var chunk_height: float = 540.0


# Escenario generado por encima del jugador.
@export var chunks_above_player: int = 7


# Escenario conservado debajo para permitir
# caídas y rescates.
@export var chunks_below_player: int = 4


@export var lane_count: int = 5
@export var lane_side_margin: float = 120.0
@export var rows_per_chunk: int = 3


# ============================================================
# JARDINES DE NIMBO
# ============================================================

@export_category("Zone 1 Difficulty")


# Los drones comienzan después de 90 metros.
@export var drone_start_height_meters: float = 90.0


# Máximo de peligros por fila.
@export var max_hazards_per_row: int = 2


# Una burbuja devuelve aproximadamente
# 4 segundos de aire.
@export var bubble_restore_seconds: float = 4.0
