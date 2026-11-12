AGE OF DEFENSE
DOCUMENTACION FORMAL
ANALISIS
LUCAS MASCHERONI

Indice / ¿Que encontrara en este documento?

Reglas Del juego : 3 (Haga click Aqui para Dirijirse  alli )
Glosario/Mision: 3 .2
Historial De Versiones 

REGLAS DEL JUEGO (REGLAS DE NEGOCIO EN NUESTRO CONTEXTO)

3
3.1.1
¿Como se obtiene la victoria/derrota? 
detallado tambien en REQUISITOS FUNCIONALES JUEGO ( RF-001 ).
Cada torre contara con un nivel de vida inicial, el cual ira aumentando acorde el usuario compre mejoras y tambien  progrese en niveles aumentando la del enemigo asi sube la dificultad, el usuario NO podra dañar la base enemiga con su ataque , solo lo podran hacer sus tropas una vez esten a una distancia considerable de la misma, y atacaran a lo mas cerca, es decir si hay una tropa enemiga o la base enemiga, atacara a quien este mas cerca, lo mismo hara el rival enemigo con el usuario,
el usuario perdera si su base llega a 0 HP, y ganara si la base enemiga llega a 0 HP

3.1.1.A
SIMPLIFICADO
¿Como se obtiene la victoria/derrota? 
el usuario perdera si su base llega a 0 HP, y ganara si la base enemiga llega a 0 HP.

3.1.2
DINERO DEL JUEGO
SE DIVIDIRA EN 2, EL DINERO EN CADA NIVEL(.1) Y DineroGlobal

3.1.2.1
DINERO DEL JUEGO EN CADA NIVEL
el jugador comenzara con una dinero inicial el cual podra comprar mejoras para aumentarlo (su cantidad inicial, es decir en nvl 0 de esta mejora arranca con 100 patas de pollo, si lo mejora a nivel 2, iniciara con 150 patas de pollo)
con este dinero el cual llamaremos " PATAS DE POLLO " podra comprar unidades, mejorar su produccion de dinero(dirijase a  granjas de pollo para mas informacion) y  reparar su base,
 el dinero lo obtendra de 2 formas distintas, primero, tendra una base de produccion, la cual seran Granjas de pollo, estas estaran dentro de la base y no pueden ser dañadas por el enemigo ni por el o  sus tropas, generaran cada ciertos segundos una cantidad de patas de pollo, el usuario podra mejorarlas mientras juegue en ese mismo nivel, y tambien comprando mejoras para esta torre en la seccion mejoras en el menu global del jeugo, tendra un maximo de hasta 5 granjas, su costo ira aumentando a medida compre mas, y cada granja generara lo mismo que la otra, (ej 10 patas de pollo por segundo, si compra una 3era por 500 patas de pollo, su produccion sera de 30 patas de pollo por segundo, y la 4ta pata de pollo la comprara por 750 y generara 40 patas de pollo x segundo ).
 
 


3.1.2.2 
DINERO EN MENU GLOBAL
 ESTE DINERO LO LLAMAREMOS "DONAS DORADAS" EL JUGADOR CONSEGUIRA ESTA LUEGO DE CADA NIVEL, PIERDA O GANE, SERA CALCULADO MATEMATICAMENTE INFLUENCIADO POR DIVERSOS FACTORES DE MAYOR A MENOR
 
A) NUMERO DE NIVEL (ACORDE INCREMENTE LA DIFICULTAD MAS DINERO GANARA, YA QUE SUS MEJORAS SERAN MAS CARAS Y LO MISMO EL PRECIO PARA DESBLOQUEAR NUEVAS UNIDADES, EL NIVEL 15 SERA MAS DIFICIL QUE EL 1, Y LAS ESTADISTICAS TANTO DE LA BASE ENEMIGA COMO DE SUS UNIDADES SERAN MAS FUERTES obviamente de 15 al 1)
B) RESULTADO DE LA PARTIDA: Si el usuario gana se le dara una bonificacion en forma de porcentaje, ej ganaria 75 donas por todo lo demas, se le hara una bonificacion del x1,5 por ganar elevandola a  113 donas, se manejaran unicamente con numeros enteros a nivel usuario, a nivel calculos si podremos usar flotantes/reales, pero se redondeara si es 0,5 a 9,9 para arriba, 0.1 a 4,99 para abajo.
Si pierde se le dara una bonificacion del 0,25.
Ej si perdio y se le pagaria 10 donas con las demas variables, se reduciria a 2,5 donas por haber perdido, que redondeado le quedan 3 donas de oro.

C) TIEMPO QUE GANO EL NIVEL, mientras mas rapido lo complete mas donas obtendra

D) Vida restante de la base, sera calculado cuantos HP le restaron, y mas importante aun el rango de vida, sera excelente si queda 100 por ciento, 75 a 99 muy bueno, 50 a 75 bueno, 25 a 50 deficiente, y de 1 a 25 malo, CADA porcentaje lo afectara distinto, y sera calculado solo con un historial de danio recibido, por que si el usuario al final de nivel compra o restaura la vida de su base el sistema tomara ese valor, queremos evitar esto por tanto se hara un contador global de daño recibido, si llega a ser menos de 1 (recibio 500 de daño pero su base tenia solo 125 de hp, significa compro mucha salud de base) se le dara 0 en esta estadistica total, tanto sus hp restante como el rango le daran 0.


Todo esto sera utilizado con una formula matematica, la idea es que vaya incrementando nivel por nivle, y los precios de mejoras sean acordes a lo que gane por nivel, la formula inicial sera algo como esto :
DD(N) = (Numero_nivel*bonificadorresultadonivel*donasxtiempofinal)
* ModificadorPorRangoVidaRestanteBase +BonificacionxvidaRestanteBase


Formula simplificada
DD(N)= PN * B * (D*MRVB)+BHP
REFERENCIAS


DD= DONAS DORADAS
N=Nivel (DD en funcion de nivel)
PN= PAGO POR NIVEL (mientras mas dificil/Mayor numero de nivel, mas donas obtendra el usuario)
B= Bonificador por resultado del nivel (Derrota o Victoria)
D= Donas por el tiempo que le tomo al usuario finalizar el nivel
MRVB= ModificadorPorRangoVidaRestanteBase ( Dirijase a 3.1.2.2.D Para mas informacion)
BHP =  Bonificacion por vida restante de la base (Dirijase a 3.1.2.2.D para mas informacion )




3.1.3
COSTO DE MEJORAS Y COMO COMPRARLAS
el usuario tendra un menu especifico de mejoras el cual se dividiran en 4:

Mejoras de personaje, donde podra aumentar su vida y daño ( a futuro pondremos armas nuevas y habilidades pero por el momento tendra una sola ).
mejoras de unidades, donde podra mejorar la vida y daño de su ejercito, asi como tambien desbloquear nuevas unidades
mejoras de base, donde podra incrementar, las HP de su base y estadisticas (podra dañar a los enemigos su base con el uso de torretas (Dirijase A para mas informacion), esto lo hacemos por si llega aquedarse sin unidades o dinero, asi puede seguir jugando, y de paso añadirle dificultad a atacar la base enemiga, El impacto del daño de las torretas sobre la base enemiga requerirá ajustes de balanceo para evitar un estancamiento prolongado de la partida (stalemate) ).
mejoras de edificios, tales como la granja de pollo, donde aumentara su ratio de produccion y cuantas podra tener por nivel asi como tambien la cantidad maxima de torretas que podra insertar el usuario.

3.1.3.* todo estas mejoras seran compradas con donas doradas
 

3.1.4
ENTIDADES Y RELACIONES
Habra un unico Jugador(Click Aqui para informacion) por partida, el cual dañara a enemigos, podra spawnear sus unidades, reparar su base , y comprar granjas de pollo, el enemigo podra hacer lo mismo el cual sera comandado por una IA, pero sin tener un personaje esta para facilitar la programacion
las tropas enemigas y aliadas seran del mismo tipo, ej cono de helado son la misma unidad, pero una tendra su barra de vida verde, la otra en rojo para diferenciarlos ( a futuro tambien podriamos ponerle un contorno e inclusive permitir el usuario elija estos colores a su gusto, ej azul y amarillo en vez de verde y rojo)





3.2
Glosario/Mision:
Jugador: Sera el personaje el cual el usuario utilizara como si fuera el, utilizando las teclas AWSD para moverse y la barra espaciadora para atacar


Historial de Versiones

Versiones:				Descripcion/Modificacion  		Fecha de la modificacion y
										autor
1.0	Creacion Del Documento	 22 OCT 2026Lucas Mascheroni
1.0.1	Mejora Redaccion y Sintaxis Del Documento	24 OCT 2026Lucas Mascheroni



 