%Modelado de problema de Plantas de Energía
% Juan Diego Cárdenas 
% Junior Cantor Arevalo
% Cristian David Cabrera Pantoja

% Importaciones
include "globals.mzn";

% -------------- Párametros -----------------
%Tipos de plantas eléctricas
array[int] of string: TYPES; %Tipos de plantas eléctricas: Ej [Nuclear, Hidroelectrica, Termica]

%Información sobre las centrales eléctricas:
int: np; %Número de plantas eléctricas en total
% Tipo de planta | Costo de producción (pesos/MW) | Máxima producción diaria (MW)
array[1..np, 1..3] of int: plantas;

%Información de requerimientos de producción
int: n; %Número de días a planificar 
int: m; %Número de clientes de energía
array[1..m, 1..n] of int: demandas; %Demanda de MW por cliente por día

%Información de pagos
array[1..m] of int: pagos; %Pago realizado por MW por cada cliente

%Límites de producción 
int: min_prod; %Porcentaje mínimo de satisfacción de demanda de cliente por día

% Límites de centrales hidroélectricas
int: percent_high; %Porcentaje de producción que define una producción de régimen alto
array[1..np] of int: max_days_high; %Máximo días consecutivos que pueden estar las plantas en régimen alto
                                    %Para plantas no hidroélectricas este valor es igual a -1.


%Valores máximos
int: MAX_CAP = max(i in 1..np)(plantas[i, 3]);
int: MAX_DEM = max(i in 1..m, j in 1..n)(demandas[i, j]);

% -------------- Variables -----------------
array[1..np, 1..n] of var 0..MAX_CAP: prod; %Producción de MW producido por día por cada planta
array[1..m, 1..n] of var 0..MAX_DEM: vendido; %Cantidad de MW vendida por día a cada cliente

%Arreglos de variables booleanas para reificar el cumplimiento de las demandas
array[1..m, 1..n] of var bool: total;
array[1..m, 1..n] of var bool: parcial;

%Función objetivo
var int: ganancia;

% -------------- Restricciones -----------------
% No se puede vender en total más de lo producido en un día
constraint forall(j in 1..n)(
  sum(i in 1..m)(vendido[i, j]) <= sum(i in 1..np)(prod[i, j])
); 

%No sobrepasar límites máximos de producción
constraint forall(i in 1..np, j in 1..n) (
  prod[i, j] <= plantas[i, 3]
);

%No vender a un cliente más de su demanda
constraint forall(i in 1..m, j in 1..n) (
  vendido[i, j] <= demandas[i, j]
);

%Cumplir con las demandas total o el límite mínimo
constraint forall(i in 1.. m, j in 1..n)(
  (total[i, j] = (vendido[i,j] == demandas[i, j])) /\
  (parcial[i, j] = (vendido[i,j] >= ((min_prod*demandas[i, j]) div 100))) /\
  (total[i, j] \/ parcial[i, j])  
);

%Restricción de regimen alto de hidroeléctricas
constraint forall(i in 1..np, k in 1..(n - max_days_high[i])
  where TYPES[plantas[i, 1]] == "Hidro" /\ max_days_high[i] > 0
 )
 (exists(d in 0..max_days_high[i]) (
    prod[i, k + d] <= ((percent_high * plantas[i, 3]) div 100)
  ));
  

% -------------- Función objetivo -----------------

constraint ganancia = sum(i in 1..m, j in 1..n)(vendido[i,j]*pagos[i]) - sum(i in 1..np, j in 1..n)(prod[i,j]*plantas[i,2]);

solve :: int_search(
        array1d(prod) ++ array1d(vendido),       
        first_fail, 
        indomain_min)
        maximize ganancia;
        
output [
  "=== RESUMEN FINANCIERO ===\n",
  "Ganancia neta: ", show(ganancia), "\n",
  "Ingresos:      ", show(sum(k in 1..m, j in 1..n)(vendido[k, j] * pagos[k])), "\n",
  "Costos:        ", show(sum(i in 1..np, j in 1..n)(prod[i, j] * plantas[i, 1])), "\n\n",

  "=== PRODUCCIÓN POR PLANTA (MW) ===\n",
  "Planta \\ Día | "
] ++
[ show_int(5, j) | j in 1..n ] ++ [" | Total\n"] ++
[
  if j == 1 then
    "Planta " ++ show_int(2, i) ++ " (" ++ show(TYPES[i]) ++ ") | "
  else "" endif ++
  show_int(5, prod[i, j]) ++
  if j == n then
    " | " ++ show_int(6, sum(d in 1..n)(prod[i, d])) ++ "\n"
  else "" endif
  | i in 1..np, j in 1..n
] ++
[
  "\n=== ENERGÍA VENDIDA POR CLIENTE (MW) ===\n",
  "Cliente \\ Día | "
] ++
[ show_int(5, j) | j in 1..n ] ++ [" | Vendido / Demanda\n"] ++
[
  if j == 1 then
    "Cliente " ++ show_int(2, k) ++ "    | "
  else "" endif ++
  show_int(5, vendido[k, j]) ++
  if j == n then
    " | " ++ show_int(6, sum(d in 1..n)(vendido[k, d])) ++
    " / " ++ show_int(6, sum(d in 1..n)(demandas[k, d])) ++ "\n"
  else "" endif
  | k in 1..m, j in 1..n
];