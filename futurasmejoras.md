Si bien el estado actual de la aplicación representa un Producto Mínimo Viable (MVP) completamente funcional, el diseño de la arquitectura fue pensado para ser escalable.

A continuación se detallan las características planificadas para llevar el prototipo a una fase de producción a gran escala (versión 1.0 y posteriores):

1. Bases de Datos y Backend (Escalabilidad)

Migración de Persistencia: Reemplazar el guardado local en archivos .json por una integración con una base de datos RELACIONAL (ej. MySQL o PostgreSQL).

Autenticación Segura: Implementar un sistema real de Login con cifrado de contraseñas (hashing) y tokens de sesión.

Tablas de Clasificación (Leaderboards): Habilitar un ranking global en línea para que los jugadores compitan por quién acumula más "Donas Doradas" o sobrevive más tiempo en dificultad Imposible.

2. Expansión de Gameplay

Lista de Héroes: Añadir nuevos héroes jugables (además de Mara) que el usuario pueda desbloquear. Cada uno contará con estadísticas únicas, armas distintas y habilidades activas (ej. curación en área, ataques a distancia o una lluvia de meteoritos que dañe a todos los enemigos,o un lluvia de hielo que congele a los enemigos, etc).


Nuevas Unidades y Defensas: Desarrollar tropas con mecánicas avanzadas (unidades voladoras, tanques pesados, etc) y torres con control de masas (ralentización, daño por fuego, congelar, electrocuccion en masa, etc).

3. Arte, Sonido y Experiencia de Usuario (UX)

Migración a Sprites 2D: Sustituir los gráficos generados proceduralmente (matemáticas en tiempo real) por unos mejores.

Animaciones Completas: Integrar animaciones fluidas utilizando el motor de Godot (caminar, atacar, recibir daño, morir, pantallas de victoria).

Diseño Sonoro: Añadir música de fondo dinámica que reaccione a la dificultad seleccionada y efectos de sonido (SFX) para los ataques, construcciones y botones de la interfaz.

4. Campaña y Progresión

Modo Historia: Crear un mapa de niveles progresivos con jefes finales (bosses) que requieran mecánicas específicas para ser derrotados, asi como una historia detras del videojuego, (ejemplos, stick war 2, stick war legacy).

Árbol de Habilidades Complejo: Expandir el menú global de "Donas Doradas" hacia un árbol de habilidades ramificado donde el jugador deba elegir qué especialización mejorar (aca se incluiran mejoras de jefes, habilidades, resistencia y danio a ciertos elementos).

5. ELEMENTOS
Esta sera la idea mas compleja de llevar a cabo ya que estara estrechamente relacionada con el 4.1 "Modo Historia" la idea ser atener distintos elementos, como tierra, aire, fuego, electricidad, veneno, hielo, 
que tengan ciertas estadisticas de ventajas sobre ellos, (ej hielo es debil de fuego, entonces fuego le hace hace un x1,25 de daño a tipo hielo, y tipo hielo solo le hace un x0,8 a fuego) ademas de que el usuario vaya desbloqueando este estilo para sus tropas, ej una vez que derrota al jefe de electricidad,podra personalizar a sus tropas para que lleven este tipo, tambien podra combinarlas, ej los arqueros son tipo electricidad, y los roller de tipo veneno.
por el momento tenemos pensado que sea unicamente un tipo de tropa a la vez, ej selecciona al arquero de electricidad, y solo podra usar arquero de electricidad durante todo el nivel (no podra usar arqueros de veneno o hielo por ejemplo).
