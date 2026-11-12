# CASOS DE USO
# COMPRAR MEJORA
# Proyecto: Age Of Defense

## CU-03: Terminar Nivel

Actor principal: Sistema
Otros actores: Usuario
Nivel/Alcance: Objetivo de Sistema
Enfoque: Caja Negra
Precondiciones: Existe una instancia de nivel en curso y las entidades de base (Aliada y Enemiga) tienen su registro de HP (Puntos de Salud) inicializado.

## Flujo Principal (Camino Feliz - Victoria)
1. El Sistema detecta que los Puntos de Salud (HP) de la base enemiga han llegado a 0.
2. El Sistema congela las físicas y lógicas de la instancia, y ejecuta una secuencia visual de victoria (parametrizada para evitar patrones dañinos para personas con fotosensibilidad o epilepsia).
3. El Sistema procesa el cálculo de la variable "Donas Doradas" aplicando la fórmula de victoria, actualiza el saldo global del Usuario sumando la cantidad obtenida, y despliega el desglose del resultado en pantalla.
4. El Usuario acciona el botón de confirmación ("Hurra" o "De acuerdo").
5. El Sistema libera la memoria de la instancia y retorna al Usuario al Menú Principal o al Menú de Selección de Niveles.

## Flujos Alternativos y Excepciones

A. La base aliada llega a 0HP
A1. En el paso 1, el Sistema detecta que la base aliada alcanzó 0 HP.
A2. El Sistema congela la instancia y ejecuta una secuencia visual y sonora de derrota, incluyendo indicadores visuales redundantes para garantizar la accesibilidad de usuarios con capacidades auditivas reducidas.
A3. El Sistema procesa el cálculo de "Donas Doradas" aplicando el bonificador de derrota y muestra el resultado en pantalla.
A4. El Sistema habilita las opciones "Reiniciar Nivel" o "Volver al Menú".
A5. El Usuario selecciona una opción y el Sistema ejecuta la redirección correspondiente.

B. Excepción de Cálculo Matemático (Fallo de Lógica)
B1. Durante el paso 3 o A3, el Sistema detecta un error de procesamiento aritmético al calcular las Donas Doradas (ej. resultado negativo, variables nulas o valores ilógicos).
B2. El Sistema aborta el cálculo dinámico y asigna automáticamente una compensación fija de 50 Donas Doradas al saldo global del Usuario por las molestias ocasionadas.
B3. El flujo retoma en el paso 4 o A4, informando al Usuario sobre la compensación otorgada en lugar del desglose normal.