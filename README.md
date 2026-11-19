# Taller 2 — Programación por Restricciones (COP: Plantas de Energía)

Proyecto del Taller 2 para la asignatura **Programación por Restricciones**, Escuela de Ingeniería de Sistemas y Computación, Universidad del Valle.

## Integrantes

- Cristian David Cabrera Pantoja
- Junior Orlando Cantor Arevalo
- Juan Diego Cárdenas Mejía

## Estructura del Repositorio

- `problemas/`: Implementación en MiniZinc del Problema de Optimización con Restricciones (COP).
  - `PlantaEnergia.mzn`: Modelo genérico parametrizado para $np$ centrales eléctricas, $m$ clientes y $n$ días, con restricción de régimen alto aplicada a todas las centrales, restricciones redundantes ($R_1$–$R_5$), rompimiento de simetrías ($S_1$–$S_2$) y estrategia de búsqueda `input_order` + `indomain_reverse_split`.
- `datos/`: Archivos de configuración de datos de entrada (`.dzn`).
  - `Datos.dzn`: Formato base con todos los parámetros del modelo.
  - `Instancia01.dzn` a `Instancia10.dzn`: Batería de 10 instancias graduadas ($np \in \{2,\dots,6\}$, $m \in \{3,\dots,8\}$, $n \in \{4,\dots,12\}$, $G \in [50\%, 80\%]$, $H \in [75\%, 80\%]$).
- `pruebas/`: Suite automatizada de validación, equivalencia entre solvers y pruebas de ablación.
  - `test_planta_energia.py`: Pruebas automatizadas en Python (`unittest`) para `Gecode`, `Chuffed` y `COIN-BC`.
- `Informe/`: Documento LaTeX del informe técnico modularizado por secciones.
  - `main.tex` y `main.pdf`: Documento raíz e informe PDF compilado (20 páginas).
  - `secciones/`: Archivos `.tex` independientes (`01_modelo.tex` a `05_conclusiones.tex`).
  - `Imagenes/`: Carpeta para recursos gráficos (`logoUV.jpg` en la raíz y figuras experimentales en `1/`).
- `readme.txt`: Descripción del contenido de la entrega e instrucciones detalladas de ejecución.
- `GUIA_LATEX.md`: Guía de instalación, configuración y compilación de LaTeX en Visual Studio Code.

## Ejecución del Modelo y Pruebas

Desde la raíz del repositorio (`COP_Energy_Planning/`):

```bash
# Ejecutar el modelo sobre el caso base Datos.dzn
minizinc --solver gecode --statistics problemas/PlantaEnergia.mzn datos/Datos.dzn

# Ejecutar el modelo sobre cualquiera de las 10 instancias (ej. Instancia06 o Instancia10)
minizinc --solver gecode --statistics problemas/PlantaEnergia.mzn datos/Instancia06.dzn
minizinc --solver chuffed --statistics problemas/PlantaEnergia.mzn datos/Instancia10.dzn

# Ejecutar la suite completa de pruebas automatizadas
python pruebas/test_planta_energia.py
```
