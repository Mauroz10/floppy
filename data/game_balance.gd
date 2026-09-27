extends Resource
class_name GameBalance


# ============================================================
# MOVIMIENTO HORIZONTAL
# ============================================================

@export_category("Horizontal Movement")

# Velocidad máxima lateral de Milo.
@export var horizontal_speed: float = 320.0

# Qué tan rápido acelera Milo al tocar izquierda o derecha.
@export var horizontal_acceleration: float = 1350.0

# Qué tan rápido se detiene cuando soltamos el control.
@export var horizontal_deceleration: float = 1100.0

# Margen para impedir que salga de la pantalla.
@export var horizontal_margin: float = 58.0


# ============================================================
# ASCENSO CON GLOBO
# ============================================================

@export_category("Inflated Movement")

# Velocidad de ascenso.
#
# 125 era demasiado lento.
# 270 era demasiado rápido.
#
# 150 es nuestro nuevo punto de equilibrio.
@export var rise_speed: float = 150.0


# Aire máximo.
#
# Con un consumo de 1 unidad por segundo,
# tendremos aproximadamente 18 segundos
# de vuelo antes de quedarnos sin aire.
@export var max_air: float = 18.0


# Cantidad de aire consumida cada segundo.
@export var air_drain_per_second: float = 1.0


# Cuando queda 20% de aire aparece
# la advertencia de aire bajo.
@export_range(0.0, 1.0, 0.01)
var low_air_threshold: float = 0.20


# ============================================================
# CAÍDA
# ============================================================

@export_category("Falling")

# Fuerza de gravedad durante la caída.
@export var gravity: float = 1050.0


# Velocidad máxima de caída.
@export var max_fall_speed: float = 700.0


# Tiempo disponible para encontrar
# un globo de rescate.
@export var fall_rescue_window: float = 3.5


# Distancia mínima a la que aparecerá
# el globo de rescate.
@export var rescue_balloon_min_drop: float = 520.0


# Distancia máxima a la que aparecerá
# el globo de rescate.
@export var rescue_balloon_max_drop: float = 760.0


# ============================================================
# REVIVE
# ============================================================

@export_category("Revive")

# El jugador revive con 100% de aire.
@export var revive_air_ratio: float = 1.0


# Tiempo de invulnerabilidad después de revivir.
@export var revive_invulnerability_seconds: float = 2.0


# ============================================================
# CONFIGURACIÓN DEL MUNDO
# ============================================================

@export_category("World")

# Conversión de distancia visual a metros.
#
# 80 píxeles recorridos verticalmente
# equivalen aproximadamente a 1 metro
# mostrado en el HUD.
@export var pixels_per_meter: float = 80.0


# Ancho lógico del mundo.
@export var world_width: float = 1080.0


# Altura de cada bloque procedural.
@export var chunk_height: float = 540.0


# Cantidad de chunks generados
# por encima del jugador.
@export var chunks_above_player: int = 7


# Cantidad de chunks conservados
# debajo del jugador.
#
# Esto es importante para las caídas
# y para el sistema de rescate.
@export var chunks_below_player: int = 4


# Número de carriles horizontales.
@export var lane_count: int = 5


# Margen lateral utilizado por los carriles.
@export var lane_side_margin: float = 120.0


# Cantidad de filas de obstáculos
# dentro de cada chunk.
@export var rows_per_chunk: int = 3


# ============================================================
# JARDINES DE NIMBO - DIFICULTAD
# ============================================================

@export_category("Zone 1 Difficulty")


# Los drones empiezan a aparecer
# después de los 90 metros.
#
# Esto permite que el jugador aprenda primero
# cómo controlar a Milo.
@export var drone_start_height_meters: float = 90.0


# Máximo de peligros que puede tener
# una misma fila.
@export var max_hazards_per_row: int = 2


# Una burbuja devuelve aproximadamente
# 4 segundos adicionales de aire.
@export var bubble_restore_seconds: float = 4.0
