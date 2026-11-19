# Guía de Configuración y Uso de LaTeX en VS Code

Esta guía explica cómo compilar y editar el informe técnico en LaTeX ubicado en la carpeta `Informe/`.

---

## 1. Estructura del Proyecto

```text
COP_Energy_Planning/
├── .vscode/
│   └── settings.json          # Configuración automática de compilación LaTeX
├── problemas/
│   └── PlantaEnergia.mzn      # Modelo COP genérico en MiniZinc
├── datos/
│   ├── Datos.dzn              # Formato base de parámetros
│   └── Instancia01..10.dzn    # 10 instancias de evaluación
├── pruebas/
│   └── test_planta_energia.py # Suite de pruebas automatizadas (Gecode/Chuffed)
├── Informe/
│   ├── main.tex               # Archivo raíz principal (portada, índice e imports)
│   ├── main.pdf               # PDF compilado resultante
│   ├── Imagenes/
│   │   ├── logoUV.jpg         # Logo institucional (raíz)
│   │   └── 1/                 # Figuras experimentales del problema de Plantas de Energía
│   └── secciones/             # Subarchivos modulares del informe
│       ├── 01_modelo.tex
│       ├── 02_implementacion.tex
│       ├── 03_busqueda.tex
│       ├── 04_pruebas_y_analisis.tex
│       └── 05_conclusiones.tex
├── readme.txt                 # Instrucciones de entrega y ejecución
├── README.md                  # Documentación general
└── .gitignore                 # Ignora archivos temporales (.aux, .log, .synctex.gz)
```

---

## 2. Compilación del Informe

### 2.1. Con Tectonic desde terminal
```powershell
cd Informe
tectonic -o . main.tex
```

### 2.2. Con LaTeX Workshop en Visual Studio Code
1. Abre `Informe/main.tex` o cualquiera de los archivos en `Informe/secciones/`.
2. Presiona <kbd>Ctrl</kbd> + <kbd>S</kbd> para compilar automáticamente o <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>B</kbd> para forzar la compilación.
3. Presiona <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>V</kbd> para abrir la vista previa lado a lado del archivo `Informe/main.pdf`.
