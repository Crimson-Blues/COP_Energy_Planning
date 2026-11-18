% =============================================================================
% Taller 2: Programacion por Restricciones (COP)
% Problema 1: Planificacion de Produccion en Plantas de Energia
%
% Integrantes:
%   - Cristian David Cabrera Pantoja
%   - Junior Orlando Cantor Arevalo
%   - Juan Diego Cardenas Mejia
% =============================================================================

include "globals.mzn";

% ----------------------------- 1. Parametros ---------------------------------

% Catalogo de tipos de centrales electricas
array[int] of string: TYPES;

% Numero total de plantas electricas en el parque generador
int: np;

% Matriz de caracteristicas por planta p in 1..np:
%   Columna 1: Identificador del tipo de planta en TYPES
%   Columna 2: Costo unitario de produccion c_p ($/MW)
%   Columna 3: Capacidad maxima de produccion diaria Cap_p (MW)
array[1..np, 1..3] of int: plantas;

% Horizonte de planificacion (dias) y numero de clientes
int: n;
int: m;

% Demanda diaria estimada d_{s,j} (MW) del cliente s in 1..m en el dia j in 1..n
array[1..m, 1..n] of int: demandas;

% Pago unitario P_s ($/MW) acordado con cada cliente s in 1..m
array[1..m] of int: pagos;

% Porcentaje minimo obligatorio G (%) de satisfaccion de demanda por cliente y dia
int: min_prod;

% Porcentaje H (%) de la capacidad maxima por encima del cual una planta entra en regimen alto
int: percent_high;

% Numero de dias consecutivos prohibidos en regimen alto R_p para cada central p in 1..np
array[1..np] of int: max_days_high;

% ------------------- 2. Validacion de Parametros de Entrada ------------------

constraint assert(np >= 1,
  "Error de entrada: el numero de plantas (np) debe ser al menos 1.");
constraint assert(n >= 1,
  "Error de entrada: el numero de dias (n) debe ser al menos 1.");
constraint assert(m >= 1,
  "Error de entrada: el numero de clientes (m) debe ser al menos 1.");
constraint assert(min_prod >= 0 /\ min_prod <= 100,
  "Error de entrada: min_prod debe pertenecer al rango 0..100.");
constraint assert(percent_high > 0 /\ percent_high <= 100,
  "Error de entrada: percent_high debe pertenecer al rango 1..100.");

constraint forall(i in 1..np)(
  assert(plantas[i, 1] in index_set(TYPES),
    "Error de entrada: identificador de tipo de planta fuera de TYPES.") /\
  assert(plantas[i, 2] >= 0,
    "Error de entrada: el costo de produccion por MW no puede ser negativo.") /\
  assert(plantas[i, 3] > 0,
    "Error de entrada: la capacidad maxima diaria debe ser estrictamente positiva.") /\
  assert(max_days_high[i] == -1 \/ max_days_high[i] >= 1,
    "Error de entrada: max_days_high debe ser un entero positivo (o -1 si no aplica).")
);

constraint forall(s in 1..m)(
  assert(pagos[s] >= 0,
    "Error de entrada: el pago por MW del cliente no puede ser negativo.") /\
  forall(j in 1..n)(
    assert(demandas[s, j] >= 0,
      "Error de entrada: la demanda diaria no puede ser negativa.")
  )
);

% ------------------------ 3. Constantes Derivadas ----------------------------

int: MAX_CAP = max(i in 1..np)(plantas[i, 3]);
int: MAX_DEM = max(i in 1..m, j in 1..n)(demandas[i, j]);
int: C_MIN   = min(i in 1..np)(plantas[i, 2]);

% Demanda minima obligatoria d^{min}_{s,j} = floor(G * d_{s,j} / 100)
array[1..m, 1..n] of int: min_dem = array2d(1..m, 1..n, [
  (min_prod * demandas[s, j]) div 100 | s in 1..m, j in 1..n
]);

% Umbral maximo de produccion en regimen normal U_p = floor(H * Cap_p / 100)
array[1..np] of int: umbral_alto = [
  (percent_high * plantas[i, 3]) div 100 | i in 1..np
];

% Cotas teoricas a priori del dominio de la funcion objetivo
int: MIN_GAN = sum(s in 1..m, j in 1..n)(min_dem[s, j] * pagos[s])
             - sum(i in 1..np, j in 1..n)(plantas[i, 3] * plantas[i, 2]);
int: MAX_GAN = sum(s in 1..m, j in 1..n)(demandas[s, j] * max(0, pagos[s] - C_MIN));

% ----------------------- 4. Variables de Decision ----------------------------

% Energia producida (MW) por la planta i in 1..np en el dia j in 1..n
array[1..np, 1..n] of var 0..MAX_CAP: prod;

% Energia entregada/vendida (MW) al cliente s in 1..m en el dia j in 1..n
array[1..m, 1..n] of var 0..MAX_DEM: vendido;

% Variable objetivo: ganancia neta acumulada en el horizonte de n dias
var MIN_GAN..MAX_GAN: ganancia;

% ---------------------- 5. Restricciones Primarias ---------------------------

% C1: Limite de capacidad maxima diaria de cada planta (consistencia de nodo)
constraint forall(i in 1..np, j in 1..n)(
  prod[i, j] <= plantas[i, 3]
);

% C2: Rango de satisfaccion de demanda por cliente y dia (minimo G% y maximo d_{s,j})
constraint forall(s in 1..m, j in 1..n)(
  vendido[s, j] >= min_dem[s, j] /\
  vendido[s, j] <= demandas[s, j]
);

% C3: Cobertura energetica diaria (lo vendido no supera lo producido en el dia)
constraint forall(j in 1..n)(
  sum(s in 1..m)(vendido[s, j]) <= sum(i in 1..np)(prod[i, j])
);

% C4: Prohibicion de operar max_days_high[i] dias consecutivos en regimen alto
%     (> umbral_alto[i]) aplicada a todas las centrales del parque generador
constraint forall(i in 1..np where max_days_high[i] >= 1 /\ max_days_high[i] <= n)(
  forall(k in 1..(n - max_days_high[i] + 1))(
    exists(d in 0..(max_days_high[i] - 1))(
      prod[i, k + d] <= umbral_alto[i]
    )
  )
);

% -------------------- 6. Restricciones Redundantes ---------------------------

% R1: Cota inferior de produccion diaria agregada
constraint forall(j in 1..n)(
  sum(i in 1..np)(prod[i, j]) >= sum(s in 1..m)(min_dem[s, j])
);

% R2: Equilibrio exacto de flujo diario sin sobreproduccion esteril en el optimo
%     y cota superior de demanda agregada diaria
constraint forall(j in 1..n)(
  sum(i in 1..np)(prod[i, j]) == sum(s in 1..m)(vendido[s, j]) /\
  sum(i in 1..np)(prod[i, j]) <= sum(s in 1..m)(demandas[s, j])
);

% R3: Cota lineal acumulada en toda ventana deslizante de regimen alto
constraint forall(i in 1..np where max_days_high[i] >= 1 /\ max_days_high[i] <= n)(
  forall(k in 1..(n - max_days_high[i] + 1))(
    sum(d in 0..(max_days_high[i] - 1))(prod[i, k + d]) <=
      (max_days_high[i] - 1) * plantas[i, 3] + umbral_alto[i]
  )
);

% R4: Dominancia por orden de merito y saturacion del umbral de regimen normal
constraint forall(j in 1..n, p1, p2 in 1..np where
  (plantas[p1, 2] < plantas[p2, 2]) \/ (plantas[p1, 2] == plantas[p2, 2] /\ p1 < p2)
)(
  ((prod[p2, j] > 0) -> (prod[p1, j] >= umbral_alto[p1])) /\
  ((prod[p1, j] > umbral_alto[p1] /\ prod[p2, j] > umbral_alto[p2]) -> (prod[p1, j] == plantas[p1, 3]))
);

constraint forall(j in 1..n, p1, p2 in 1..np where
  p1 != p2 /\ plantas[p2, 2] <= plantas[p1, 2]
)(
  (prod[p1, j] > umbral_alto[p1]) -> (prod[p2, j] >= umbral_alto[p2])
);

constraint forall(j in 1..n, s in 1..m, p in 1..np where pagos[s] > plantas[p, 2])(
  (vendido[s, j] < demandas[s, j]) -> (prod[p, j] >= umbral_alto[p])
);

constraint forall(j in 1..n, s1, s2 in 1..m where
  (pagos[s1] > pagos[s2]) \/ (pagos[s1] == pagos[s2] /\ s1 < s2)
)(
  (vendido[s2, j] > min_dem[s2, j]) -> (vendido[s1, j] == demandas[s1, j])
);

% R5: Proyeccion lineal de Fourier-Motzkin sobre la ganancia neta por nivel de costo c_q
constraint forall(q in 1..np)(
  ganancia <= sum(s in 1..m, j in 1..n)((pagos[s] - plantas[q, 2]) * vendido[s, j])
            - sum(i in 1..np, j in 1..n)((plantas[i, 2] - plantas[q, 2]) * prod[i, j])
);

% -------------------- 7. Rompimiento de Simetrias ----------------------------

% S1: Ordenamiento lexicografico descendente entre plantas gemelas
constraint forall(p1, p2 in 1..np where p1 < p2 /\
  plantas[p1, 2] == plantas[p2, 2] /\
  plantas[p1, 3] == plantas[p2, 3] /\
  max_days_high[p1] == max_days_high[p2]
)(
  lex_greatereq([prod[p1, j] | j in 1..n], [prod[p2, j] | j in 1..n])
);

% S2: Ordenamiento lexicografico descendente entre clientes gemelos
constraint forall(s1, s2 in 1..m where s1 < s2 /\
  pagos[s1] == pagos[s2] /\
  forall(j in 1..n)(demandas[s1, j] == demandas[s2, j])
)(
  lex_greatereq([vendido[s1, j] | j in 1..n], [vendido[s2, j] | j in 1..n])
);

% ---------------- 8. Funcion Objetivo y Estrategia de Busqueda ---------------

constraint ganancia = sum(s in 1..m, j in 1..n)(vendido[s, j] * pagos[s])
                    - sum(i in 1..np, j in 1..n)(prod[i, j] * plantas[i, 2]);

solve :: int_search(
        array1d(prod) ++ array1d(vendido),
        input_order,
        indomain_reverse_split)
        maximize ganancia;

% -------------------------- 9. Formato de Salida -----------------------------

output [
  "=== RESUMEN FINANCIERO ===\n",
  "Ganancia neta: ", show(ganancia), "\n",
  "Ingresos:      ", show(sum(s in 1..m, j in 1..n)(vendido[s, j] * pagos[s])), "\n",
  "Costos:        ", show(sum(i in 1..np, j in 1..n)(prod[i, j] * plantas[i, 2])), "\n\n",

  "=== PRODUCCION POR PLANTA (MW) ===\n",
  "Planta \\ Dia | "
] ++
[ show_int(5, j) | j in 1..n ] ++ [" |  Total | Umbral Alto\n"] ++
[
  if j == 1 then
    "Planta " ++ show_int(2, i) ++ " (" ++ TYPES[plantas[i, 1]] ++ ") | "
  else "" endif ++
  show_int(5, prod[i, j]) ++
  if j == n then
    " | " ++ show_int(6, sum(d in 1..n)(prod[i, d])) ++
    " | " ++ show_int(4, umbral_alto[i]) ++ " MW (max " ++ show(max_days_high[i]) ++ "d)\n"
  else "" endif
  | i in 1..np, j in 1..n
] ++
[
  "\n=== ENERGIA VENDIDA POR CLIENTE (MW) ===\n",
  "Cliente \\ Dia | "
] ++
[ show_int(5, j) | j in 1..n ] ++ [" | Vendido / Demanda\n"] ++
[
  if j == 1 then
    "Cliente " ++ show_int(2, s) ++ "    | "
  else "" endif ++
  show_int(5, vendido[s, j]) ++
  if j == n then
    " | " ++ show_int(6, sum(d in 1..n)(vendido[s, d])) ++
    " / " ++ show_int(6, sum(d in 1..n)(demandas[s, d])) ++ "\n"
  else "" endif
  | s in 1..m, j in 1..n
];
