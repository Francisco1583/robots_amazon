# 🤖 robots_amazon

Este proyecto implementa una heurística para distribuir robots dentro de una bodega con el objetivo de optimizar el flujo de cajas hacia un camión.  
Se modelaron robots autónomos que cooperan en cadena utilizando **Julia + Agents.jl**, con visualización en **2D (React)** y **3D (Python + OpenGL)**.

---

## 📌 Objetivo

Diseñar y simular una estrategia eficiente de movimientos para que múltiples robots:
1. Recojan cajas desde distintos carriles.
2. Las trasladen hacia un punto intermedio ("estación de descarga").
3. Finalmente las organicen en una ruta óptima hacia el camión.

---

## 🧠 Heurística Propuesta

La bodega está dividida en **tres carriles verticales** y un **carril horizontal superior**.  
En cada carril vertical trabajan *dos robots* en coordinación, mientras que en el carril horizontal trabaja un robot central encargado del orden final.

