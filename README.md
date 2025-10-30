# robots_amazon

Este proyecto implementa una heurística para distribuir robots dentro de una bodega con el objetivo de optimizar el flujo de cajas hacia un camión.  
Se modelaron robots autónomos que cooperan en cadena utilizando **Julia + Agents.jl**, con visualización en **2D (React)** y **3D (Python + OpenGL)**.

---

##  Objetivo

Diseñar y simular una estrategia eficiente de movimientos para que múltiples robots:
1. Recojan cajas desde distintos carriles.
2. Las trasladen hacia un punto intermedio ("estación de descarga").
3. Finalmente las organicen en una ruta óptima hacia el camión.

---

##  Heurística Propuesta

La bodega está dividida en **tres carriles verticales** y un **carril horizontal superior**.  
En cada carril vertical trabajan *dos robots* en coordinación, mientras que en el carril horizontal trabaja un robot central encargado del orden final.


- **Robot A (por carril):** recoge cajas dentro del carril
- **Robot B (por carril):** traslada a la estación intermedia
- **Robot H (horizontal):** recoge y organiza para carga final

---

##  Tecnologías

| Tecnología | Uso |
|------------|-----|
| **Julia** | Motor principal de simulación |
| **Agents.jl** | Modelado multiagente |
| **React** | Visualización 2D del grid y los robots |
| **Python + OpenGL** | Visualización 3D |

---

## Visualizaciones

- **2D (React):** enfoque minimalista para observar posiciones y trayectorias en tiempo real.
- **3D (Python + OpenGL):** mayor inmersión y validación espacial del flujo.

---

## Beneficios de la heurística

- Coordinación secuencial (pipeline continuo).
- Menor congestión en pasillos.
- Entrega ordenada para cargar el camión de manera más eficiente.
- Facilidad para escalar el número de robots.





