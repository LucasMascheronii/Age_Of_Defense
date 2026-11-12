CASOS DE USO
INICIAR PARTIDA
Proyecto: Age Of Defense

CU-01: Iniciar partida
Actor principal: Usuario
otros actores: Sistema
Nivel/Alcance: Usuario
Caja: Negra
Precondiciones: El jugador existe y esta activo y los niveles  existen en la persistencia de datos
1. El usuario navega entre el menu principal dandole  el mismo a  JUGAR => Niveles => se desplasa por un mapa tematico por comida hasta el ultimo nivel que esta  seleccionandolo y dandole al boton JUGAR.
2. El usuario juega el nivel como lo haria, controlando su personaje, generando su ejercito y tropas y manejando su economia y HP de su base, intentando ganar la partida.

1.1 : El usuario quiere jugar otro nivel que ya hizo.
1.1A. EL usuario lo selecciona y le da jugar.
1.2B. dirijase al paso 2.

1-2 * ocurre un error inesperado o se demora mucho tiempo en cargar ( 30 s):
El sistema informara al usuario de la situacion, y le ofrecera para volver a cargar el menu de seleccion de niveles, el sistema tambien hara un contador global de errores, añadiendole 1 por cada ves suceda el error, si el contador llega hasta 3, le ofrecera reducir los graficos y tambien que reinicie la aplicacion guardando su progreso, si cuentan 3 minutos sin error, el contador global se reiniciara a 0.
1-2.1.A: El usuario le da a esperar
1-2.1.B: Sistema aumenta contador de errores en  contador de errores =  contador de errores + 1. y le permite esperar 30 segundos al usuario
1-2.2:El usuario decide volver a la seleccion de niveles
1-2.2-A: EL SISTEMA  aumenta contador de errores en  contador de errores =  contador de errores + 1. y lleva al usuario al menu de seleccion de niveles
1-2-2-b: Dirijase al paso 1 ( notese podria irse a otro menu como mejoras etc)