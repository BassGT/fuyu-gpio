### 3. Ejercicios Prácticos Sugeridos (con tu hardware)

  Con las piezas que tienes (74HC595, Matriz de Botones y DIP Switch) puedes aprender tres conceptos
  fundamentales de electrónica y GPIO en Haskell:

  #### 🚀 Ejercicio 1: Bit-Banging con el Registro de Desplazamiento 74HC595

  • Pines necesarios: 3 salidas GPIO — Data (DS), Clock (SH_CP) y Latch (ST_CP).
  • Concepto a practicar: Bit-Banging (control manual de temporización de reloj y envío de bits serie
  a paralelo).
  • El reto en Haskell:
      1. Escribir una función pura o IO que tome un Byte (Word8, ej: 255 o 0b10101010) y extraiga sus
      8 bits.
      2. Enviar bit por bit con Line.setValue al pin Data, dando un pulso en el pin Clock.
      3. Dar un pulso en el pin Latch para mostrar el resultado en los 8 LEDs.
  • Proyecto: Un contador binario visual de 0 a 255 o el efecto de luz del "Auto Fantástico" (Knight
  Rider).

  #### 🎛️ Ejercicio 2: Lectura en Paralelo y Conversión con DIP Switch

  • Pines necesarios: 4 u 8 entradas GPIO con BiasPullUp.
  • Concepto a practicar: Lectura multilínea simultánea con Line.getValues.
  • El reto en Haskell:
      1. Registrar un vector de offsets correspondiente a los pines del DIP Switch.
      2. Leer todos los pines en una sola llamada usando Line.getValues.
      3. Convertir el vector de valores (Vector Line.Value) en un número entero o máscara de bits.
  • Proyecto: Usar el DIP Switch como selector de modo o selector de velocidad para los ejercicios
  anteriores.

  #### 🎹 Ejercicio 3: Escaneo Matricial de Teclado (Matriz de Botones 3x3 / 4x4)

  • Pines necesarios: Filas (Outputs) y Columnas (Inputs con BiasPullUp).
  • Concepto a practicar: Multiplexación y Escaneo Matricial.
  • El reto en Haskell:
      1. Poner Fila 1 en LOW, leer el estado de todas las Columnas. Si la Columna 2 está en LOW, se
      presionó el botón (Fila 1, Columna 2).
      2. Poner Fila 1 en HIGH y repetir con la Fila 2, Fila 3, etc.
  • Proyecto: Un decodificador que imprima en consola la tecla presionada (ej: '1', '9', '#').

  #### 🏆 Proyecto Integrador Final: "El Panel de Control"

  Combinar tus 5 ejemplos + los componentes:

  • Lees los botones de la matriz o el Encoder.
  • Muestras la tecla/posición en los 8 LEDs gestionados por el 74HC595.
  • Usas el DIP Switch para cambiar el modo de animación de los LEDs.
