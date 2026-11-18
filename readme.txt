===============================================================================
TALLER 2 - PROGRAMACION POR RESTRICCIONES (COP: PLANTAS DE ENERGIA)
Universidad del Valle - Escuela de Ingenieria de Sistemas y Computacion
===============================================================================

Integrantes:
  - Cristian David Cabrera Pantoja
  - Junior Orlando Cantor Arevalo
  - Juan Diego Cardenas Mejia

-------------------------------------------------------------------------------
1. ENUMERACION Y DESCRIPCION DEL CONTENIDO DE LA CARPETA
-------------------------------------------------------------------------------

  problemas/
    PlantaEnergia.mzn         Modelo generico COP en MiniZinc para planificar
                              la produccion diaria de energia de np centrales
                              y el suministro a m clientes en n dias, con
                              restriccion de regimen alto para todas las
                              centrales, restricciones redundantes (R1-R5),
                              rompimiento de simetrias (S1-S2) y busqueda
                              Branch-and-Bound por biseccion descendente.

  datos/
    Datos.dzn                 Archivo base de configuracion con todos los
                              parametros de entrada del modelo.
    Instancia01.dzn           Instancia 1 (np=3, m=3, n=4, G=50%, H=80%).
    Instancia02.dzn           Instancia 2 (np=3, m=4, n=5, G=50%, H=80%).
    Instancia03.dzn           Instancia 3 (np=3, m=4, n=5, G=60%, H=75%).
    Instancia04.dzn           Instancia 4 (np=2, m=3, n=5, G=50%, H=80%).
    Instancia05.dzn           Instancia 5 (np=4, m=4, n=6, G=50%, H=80%).
    Instancia06.dzn           Instancia 6 (np=4, m=4, n=6, G=50%, H=80%).
    Instancia07.dzn           Instancia 7 (np=5, m=5, n=7, G=70%, H=80%).
    Instancia08.dzn           Instancia 8 (np=5, m=6, n=8, G=60%, H=75%).
    Instancia09.dzn           Instancia 9 (np=6, m=6, n=10, G=75%, H=80%).
    Instancia10.dzn           Instancia 10 (np=6, m=8, n=12, G=80%, H=80%).

  pruebas/
    test_planta_energia.py    Suite automatizada en Python (unittest) que
                              verifica las 10 instancias + Datos.dzn en
                              Gecode y Chuffed, aserciones y ablacion.

  Informe/
    main.pdf                  Informe tecnico compilado en formato PDF.
    main.tex                  Documento raiz LaTeX.
    secciones/                Archivos modulares .tex (01_modelo.tex a
                              05_conclusiones.tex).
    Imagenes/                 Logo institucional y subcarpeta 1/ con las
                              cuatro figuras experimentales.

  readme.txt                  Este archivo descriptivo y guia de ejecucion.
  README.md                   Documentacion general del repositorio en Markdown.
  GUIA_LATEX.md               Guia de configuracion y compilacion de LaTeX.

-------------------------------------------------------------------------------
2. INSTRUCCIONES PARA CORRER EL MODELO Y LAS PRUEBAS
-------------------------------------------------------------------------------

A) Ejecucion desde linea de comandos (MiniZinc 2.9+):

   Ubicarse en la raiz del proyecto y ejecutar con Gecode o Chuffed:

     minizinc --solver gecode --statistics problemas/PlantaEnergia.mzn datos/Datos.dzn
     minizinc --solver gecode --statistics problemas/PlantaEnergia.mzn datos/Instancia01.dzn
     minizinc --solver chuffed --statistics problemas/PlantaEnergia.mzn datos/Instancia06.dzn
     minizinc --solver chuffed --statistics problemas/PlantaEnergia.mzn datos/Instancia10.dzn

B) Ejecucion desde MiniZinc IDE:

   1. Abrir el archivo problemas/PlantaEnergia.mzn.
   2. Abrir cualquiera de los archivos de datos en datos/ (por ejemplo,
      datos/Datos.dzn o datos/Instancia01.dzn .. datos/Instancia10.dzn).
   3. Seleccionar el solver "Gecode" o "Chuffed" en el menu desplegable.
   4. Presionar el boton "Run" (Ctrl+R).

C) Ejecucion de la suite de pruebas automatizadas (Python 3):

     python pruebas/test_planta_energia.py
