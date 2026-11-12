Age of Defense
Documentacion FORMAL
Analisis
Lucas Mascheroni

¿Que se encontrara en este documento? / Indice
Introduccion y mision
Requisitos Funcionales ( Aca deberia clickear e ir alli)
Requisitos no funcionales


Introduccion y mision

Este proyecto inicio a partir de un recuerdo nostalgico mio sobre un juego de mi infancia, lalmado “Garfield defense” tambien encontrado a dia de hoy como “Garfield War”, es un juego sencillo y muy entretenido, aunque avanzado para su epoca debo admitir, es un juego 2d donde uno debia defenser su base y atacar la del rival.
Si bien esta inspirado en el, se distinguira mucho del juego orginal para evitar un Copy-Paste del mismo o incluso peor, una demanda por Copyrigth, ademas de que perderia en efecto, lo mas maravilloso de construir un software o projecto por si mismo, añadirle eso brillo magico que cada uno de nosotros posee.
A continuacion se estructura todo



REQUISITOS FUNCIONALES


RF-001: El jugador podra atacar, presionando un unico input de accion , el cual infligira daño al enemigo mas cercano (Restandole HP).
RF-002: El jugador podra almacenar y obtener dinero que debera persistir de manera global ( es decir, garantizar su, almacenamiento, acumulacion y disponibilidad a lo largo de varias sesiones y menues fuera de la insancias de nivel)  el cual podra ser utilizado en cualquier momento, llamada “Donas Doradas”(Vea RF-003).
RF-003: El jugador podra comprar mejoras en cualquier momento, tanto para el como para sus unidades o su propia base, incrementando las estadisticas base de forma positiva ( ej daño del espadachin LVL 2: 10HP , daño del espadachin LVL 3: 15HP.).
RF-004: El Sistema gestionara el dinero de instancia local del jugador, una moneda que se utilizara y solo sera util  y almacenada en el nivel que se este jugando, con esta se podra comprar unidades, mejorar su base o repararla y construir torres, el usuario podra si lo desea incrementar la produccion de esta moneda a cambio de un importe (pagado con la misma moneda) el nombre de la misma por ahora sera “patas de pollo”.
RF-005 El jugador podra comandar sus tropas, por el momento solo podra  desplegarlas (spawnearlas ) a cambia de un costo, no podra interferir en su comportamiento ni tampoco decirle que hacer, el Sistema debera descontar el costo de la misma de su dinero actual (vea RF-004)  asi como tambien validar que tiene el dinero necesario para poder costear lo solicitado.
RF-006:El jugador podra pausar el juego en cualquier momento y cuando el lo desee, congelando tanto a los enemigos como sus propias unidades  y a todo el juego en si.
RF-007: Cada partida terminara con un solo resultado, Victoria o Derrota, la Victoria se obtiene cuando la base enemiga llega a 0HP, la Derrota cuando la base aliada llega a 0 HP.
RF-008: El sistema debera comandar su propia base, podra desplegar sus propias tropas mejorar y reparar su base, asi como construir torres, todo esto comandado de manera autonoma mediaante una IA, la cual incrementara su inteligencia y ventajas acorde al numero de nivel y temporizador




REQUISITOS NO FUNCIONALES

2

RNF 001: La aplicacion no debera tardar mas de 10 segundos en cargar, ni tampoco debera tomar mucho tiempo en cargar los niveles ni cambiar de menu en menu o pantalla en pantalla ( lo  ideal seria menor a 3 segundos ), asi evitar que el usuario tenga una mala experiencia y se frustre.

RNF 002: la resolucion debera ser lo mas basica y generica posible (estimamos que luego el usuario podra modificarla en su menu de configuracion, por el momentolo ideal seria 1920x1080)

RNF 003: La aplicacion debera poder ejecutarse en su fase inicial en  LINUX, luego una vez terminada su fase inicial, debera ser compatible tambien, con los sistemas operativos WINDOWS Y MAC.
La base de código deberá ser agnóstica al sistema operativo, asegurando la viabilidad técnica para exportar binarios hacia arquitecturas Windows y macOS en iteraciones posteriores sin refactorización estructural.

RNF 004: Los controles iniciales seran los mas genericos y populares( el usuario luego podra cambiarlos en un menu destinado para ello, y tambien si llegase a escalar el juego El módulo de entradas deberá ser modular para permitir la futura reasignación dinámica de teclas y el soporte de controladores externos (gamepads) ) en un principio sera AWSD para moverse (en ejes X ^ Y ), las flechas para mover la camara y el mouse si lo ubica al extremo derecho o izquierdo de la pantalla, la barra espaciadora para golpear, por el momento seran sencillos asi no sobre cargar ni abrumar al usuario con controles complejos desde un principio, y tampoco sobre cargar al equipo de programacion

RNF 005:La aplicacion primero  sera diseñada para ser ejecutada de mAnera offline y local ( stand-alone ), sin funciones en linea, luego mas adelante estimamos hacer un sistema de rankings y de tiempos






