README
| Traductores e Interpretadores
| Lenguaje para operaciones en conjuntos de bits

Autores:
David Ernesto Cabeza Luque 1310191 <13-10191@usb.ve>
Fabiola Mercedes Martinez Perez 1310838 <13-10838@usb.ve>

EJECUCION
----------------------------------------------------------------------------------------------------

```
$ ./bitiondo filename.bto
```

Nota: Para ejecutar el archivo, el dueño (quien lo descarga) debe tener permisos de ejecución. Esto se logra fácilmente ejecutando el siguiente comando en el terminal (estando en la ruta del proyecto):

```
chmod u+x bitiondo
```

Añadir sudo al inicio del comando si hay problemas de permisos.

Nota 2: Para correr el archivo bitiondo sin tener que usar el comando ruby, se requiere tener instalado ruby en la ruta /usr/bin/ruby, de otra manera, el proyecto se debe correr de la siguiente manera:

```
$ ruby bitiondo filename.bto
```

Donde "filename" hace referencia al nombre del archivo en formato .bto que se quiere ejecutar.
Si el archivo es un formato distinto a .bto, el programa mostrará un mensaje y terminara su ejecución.

DECISIONES DE IMPLEMENTACION 
----------------------------------------------------------------------------------------------------

El proyecto se implementó utilizando el lenguaje de programación Ruby en su versión 2.3.

Etapa 1

Para reconocer los tokens, se usaron expresiones regulares. 

En el archivo lexer.rb, se crearon dos clases:

La primera clase token que tiene como metodos:

- initialize: se creo para inicializar todos los atributos que posee un token. Type que se refiere 
a la clave del diccionario, es decir el nombre del token, value los valores que toman ciertos ele-
mentos (string, integer, identifier, bitsexpression) del lenguaje bitiondo, que deben ser mostrados 
en la salida. Tambien contiene la información sobre la columna y fila a la que pertence el token.

- to_s: se usa para que cada token genere su string de salida.

La segunda clase lexer, que tiene como metodos:

- intialize: inicializa las estructuras de datos y elementos que se usaran a lo largo del programa. 
Contiene un diccionario donde la clave es el nombre del token del lenguaje bitiondo y valor es la 
expresion regular que le corresponde, este es usado para hacer las comparaciones correspondientes 
con el archivo y tambien para imprimir la salida. Por otro lado, se tienen dos arreglos uno que almacena
los tokens correctos y otro que almacena los tokens incorrectos del lenguaje bitiondo. 
Finalmente, dos contadores para las columnas y filas, y una expresion regular ignore para hacer las 
comparaciones con los tokens que se deben ignorar.

- readFile: este método se creo para hacer la lectura de archivo .bto, se encarga de abrir archivo,
 leerlo y luego cerrarlo.

- tokenizer: es la funcion principal del analizador lexicografico, esta se encarga de recorrer el ar-
chivo y hacer las comparaciones correspondientes de los tokens del archivo con las expresiones con-
tenidas en el diccionario, luego los tokens correctos se anaden a una lista y los incorrectos a otra 
lista. Al mismo tiempo, se van contando las lineas y columnas correspondientes.

- printk: se encarga de recorrer las listas de tokens correctos e incorrectos y mostrarlos en la 
salida.

Etapa 2 

En el archivo parser.y contiene el diseño de la gramática libre de contexto del lenguaje bitiondo y 
un reconocedor para la misma. Dicho archivo recibe los tokens reconocidos por el analizador lexicográfico
y va aplicando las reglas de gramática correspondientes. Es importante mencionar que el tercer caso para
while se colocó ';' . 

Por otro lado, el archivo parser.rb es generado a partir de la gramática y es el reconocerdor encargado 
de hacer interpretación de la parte sintáctica del lenguaje.

Para imprimir el árbol sintáctico abstracto durante el reconocimiento, se crearon clases para las decla-
raciones, cada tipo de instrucción y expresión. Además, la variable ident que se encarga de llevar el 
control de la identación.

Para finalizar, el main del programa se encuentra en el archivo bitiondo.

Etapa 3

Después de haber implementado el analizador lexicográfico y sintáctico, en el cual se encuentra el archi-
vo ast.rb que ejecuta el árbol sintáctico, dicho archivo sirvió se modificó en etapa agregando la función
check() para cada nodo del árbol. Esta, se encarga de verificar el uso correcto de los tipos.

A su vez, se implementó una tabla de hash para la tabla de símbolos en que contiene la declaración de cada 
identificador a través de objetos que tienen como atributos name, type, size y value.

Finalmente, para la impresión de errores se creó una lista en la cual se fueron almacenando durante el chequeo.

Etapa 4

Durante el desarrollo de esta etapa se añadieron los interpretadores de cada nodo del AST, la cual se encarga
de ejecutar y evaluar expresiones.

Ademas se intentó colocar los flags que permiten la ejecución al interpretador con los distintos comportamientos
de las etapas anteriores. Sin embargo, esta parte se intentó implementar pero no pudo lograrse.

Por otro lado, de haber errores que corresponden a las entregas anteriores serán mostrados por salida estándar
y se abortará la ejecución del interpretador. 
 
ESTADO ACTUAL DEL PROYECTO
----------------------------------------------------------------------------------------------------
El programa que se comporta como un analizador lexicografico y sintáctico para el lenguaje Bitiondo, 
cumple con todas las funcionalidades requeridas para la etapa 1 y la etapa 2.

Se hicieron cambios en la tercera entrega que permitieron continuar correctamente en la cuarta.

Sin embargo, para el caso de transformaciones de bits a entero no verifica que el identificador tipo 
bits sea de 32 bits, es el unico error asociado a expresiones que trabajen con expresiones de tipo
bits. A su vez, no se pudo completar el interpretador para el forbits.


PROBLEMAS PRESENTES
----------------------------------------------------------------------------------------------------
Forbits no funciona correctamente.
