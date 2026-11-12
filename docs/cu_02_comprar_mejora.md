# CASOS DE USO
# COMPRAR MEJORA
# Proyecto: Age Of Defense

## CU-02: Comprar  Mejora.
Actor principal: Usuario.
otros actores: Sistema.
Nivel/Alcance: Usuario.
Caja: Negra.
Precondiciones: El jugador existe y esta activo y las  mejoras existen en la persistencia de datos.

1. USUARIO Navega hasta menu mejoras.
2. SISTEMA genera y despliega un catalogo con las mejoras disponibles para el usuario  ( evaluando sus prerequisitos, ejemplo que haya desbloqueado la tropa a la que le aplicara la mejora) junto a su saldo asi evitar complicaciones.
3. USUARIO seleciona una mejora que le  guste y le da a comprar.
4. SISTEMA valida tenga cantidad de donas suficiente para comprar ( precio mejora <= cantidad donas doradas que el Usuario posee).
5. SISTEMA descuenta el costo, registra el mismo y lo guarda, actualiza las Donas Doradas del usuario, y  muestra  un mensaje de exito. (Comentario adicional ***) 

## ALTERNATIVOS
1-4* Ocurre un error.
1-4*. 1 : Sistema informa a usuario con nombre y numero de error, ofreciendole volver al menu y reintentar.
1-4*.1.2 dirijase al paso 1.

1-4* .2 El usuario se arrepiente y prefiere ir a otro menu.
1-4*.2.1 El SISTEMA le permite desplazarse al menu que quiera.
1-4*.2 FIN CU.

3.1 El USUARIO no posee suficientes donas.
3.1.1 El SISTEMA le informa su sitacion, y le permite volver a comprar otra mejora que quiera, (Comentario adicional ^^^) 

3.1.2 Dirijase al paso 2. 

3.2. USUARIO vuelve al menu de mejoras. 
3.2.1. dirijase al paso 2.

Comentario adicional
***: En nuestras primeras fases, trataremos que sea cartel NO INVASIVO y que desaparecera a los 4 segundos si el USUARIO no hace click en la cruz (x) que tendra este arriba a su derecha para dejar de mostrarlo. ( Aunque el mismo por supuesto, esta sujeto a cambios y no sera obligatorio seguir el patron).

^^^: para evitar esto ocurra muy seguido, si el usuario no puede comprar la mejora el boton de comprar debera aparecer en gris, si puede comprar en verde, debera ademas realizar validaciones basicas, como que la tropa a la que quiera aumenar sus estadisticas el usuario la haya comprado entre otras.