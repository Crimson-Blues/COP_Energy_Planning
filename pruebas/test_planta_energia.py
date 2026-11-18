# =============================================================================
# Suite automatizada de pruebas para el Taller 2 (COP - Plantas de Energia)
# Verifica sintaxis, aserciones de dominio, optimalidad cruzada Gecode/Chuffed,
# cumplimiento independiente de restricciones en las 10 instancias + Datos.dzn,
# y estudio de ablacion de restricciones redundantes y simetrias.
# =============================================================================

import re
import subprocess
import unittest
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
MODEL_PATH = ROOT_DIR / "problemas" / "PlantaEnergia.mzn"
DATA_DIR = ROOT_DIR / "datos"

EXPECTED_OPTIMA = {
    "Datos.dzn": 21400,
    "Instancia01.dzn": 129200,
    "Instancia02.dzn": 157220,
    "Instancia03.dzn": 92280,
    "Instancia04.dzn": 87720,
    "Instancia05.dzn": 210360,
    "Instancia06.dzn": 207600,
    "Instancia07.dzn": 329760,
    "Instancia08.dzn": 399008,
    "Instancia09.dzn": 523080,
    "Instancia10.dzn": 745034,
}

REQUIRED_PARAMS = [
    "TYPES",
    "np",
    "plantas",
    "n",
    "m",
    "demandas",
    "pagos",
    "min_prod",
    "percent_high",
    "max_days_high",
]


def parse_dzn(dzn_path: Path) -> dict:
    text = dzn_path.read_text(encoding="utf-8")
    text_no_comments = re.sub(r"%.*", "", text)

    def get_int(name: str) -> int:
        m = re.search(rf"\b{name}\s*=\s*(-?\d+)\s*;", text_no_comments)
        if not m:
            raise ValueError(f"Parametro {name} no encontrado en {dzn_path.name}")
        return int(m.group(1))

    def get_int_list(name: str) -> list[int]:
        m = re.search(rf"\b{name}\s*=\s*\[([^\]]+)\]\s*;", text_no_comments)
        if not m:
            raise ValueError(f"Arreglo {name} no encontrado en {dzn_path.name}")
        return [int(x.strip()) for x in m.group(1).split(",") if x.strip()]

    def get_int_matrix(name: str) -> list[list[int]]:
        m = re.search(rf"\b{name}\s*=\s*\[\|(.*?)\|\s*\]\s*;", text_no_comments, re.S)
        if not m:
            raise ValueError(f"Matriz {name} no encontrada en {dzn_path.name}")
        rows = []
        for raw_row in m.group(1).split("|"):
            vals = [int(x.strip()) for x in raw_row.split(",") if x.strip()]
            if vals:
                rows.append(vals)
        return rows

    return {
        "np": get_int("np"),
        "n": get_int("n"),
        "m": get_int("m"),
        "min_prod": get_int("min_prod"),
        "percent_high": get_int("percent_high"),
        "pagos": get_int_list("pagos"),
        "max_days_high": get_int_list("max_days_high"),
        "plantas": get_int_matrix("plantas"),
        "demandas": get_int_matrix("demandas"),
    }


def parse_solution_output(stdout: str, np_val: int, m_val: int, n_val: int) -> dict:
    gan_match = re.search(r"Ganancia neta:\s*(-?\d+)", stdout)
    ing_match = re.search(r"Ingresos:\s*(-?\d+)", stdout)
    cos_match = re.search(r"Costos:\s*(-?\d+)", stdout)
    if not (gan_match and ing_match and cos_match):
        raise AssertionError(f"No se encontro resumen financiero en salida:\n{stdout}")

    prod = []
    for i in range(1, np_val + 1):
        m = re.search(rf"Planta\s+{i}\s+\([^)]+\)\s*\|\s*([0-9\s]+)\|", stdout)
        if not m:
            raise AssertionError(f"No se encontro fila de Planta {i} en salida:\n{stdout}")
        row = [int(x) for x in m.group(1).split()]
        assert len(row) == n_val, f"Longitud invalida en Planta {i}: {row}"
        prod.append(row)

    vendido = []
    for s in range(1, m_val + 1):
        m = re.search(rf"Cliente\s+{s}\s*\|\s*([0-9\s]+)\|", stdout)
        if not m:
            raise AssertionError(f"No se encontro fila de Cliente {s} en salida:\n{stdout}")
        row = [int(x) for x in m.group(1).split()]
        assert len(row) == n_val, f"Longitud invalida en Cliente {s}: {row}"
        vendido.append(row)

    nodes_m = re.search(r"%%%mzn-stat:\s*nodes=(\d+)", stdout)
    fails_m = re.search(r"%%%mzn-stat:\s*failures=(\d+)", stdout)
    props_m = re.search(r"%%%mzn-stat:\s*propagations=(\d+)", stdout)

    return {
        "ganancia": int(gan_match.group(1)),
        "ingresos": int(ing_match.group(1)),
        "costos": int(cos_match.group(1)),
        "prod": prod,
        "vendido": vendido,
        "nodes": int(nodes_m.group(1)) if nodes_m else -1,
        "failures": int(fails_m.group(1)) if fails_m else -1,
        "propagations": int(props_m.group(1)) if props_m else -1,
    }


class TestPlantaEnergiaCOP(unittest.TestCase):
    def test_01_existencia_modelo_datos_y_10_instancias(self):
        self.assertTrue(MODEL_PATH.is_file(), f"No existe {MODEL_PATH}")
        for fname in EXPECTED_OPTIMA:
            fpath = DATA_DIR / fname
            self.assertTrue(fpath.is_file(), f"No existe archivo de datos {fpath}")
            content = fpath.read_text(encoding="utf-8")
            for param in REQUIRED_PARAMS:
                self.assertRegex(
                    content,
                    rf"\b{param}\s*=",
                    f"Falta el parametro '{param}' en {fname}",
                )

    def test_02_aserciones_parametros_invalidos(self):
        base_dzn = (DATA_DIR / "Datos.dzn").read_text(encoding="utf-8")
        casos_invalidos = [
            base_dzn.replace("min_prod = 50;", "min_prod = 120;"),
            base_dzn.replace("percent_high = 80;", "percent_high = 0;"),
            base_dzn.replace("pagos = [50, 40, 60];", "pagos = [-10, 40, 60];"),
        ]
        for dzn_invalido in casos_invalidos:
            proc = subprocess.run(
                ["minizinc", "--solver", "gecode", str(MODEL_PATH), "-D", dzn_invalido],
                text=True,
                capture_output=True,
                timeout=10,
            )
            combined = (proc.stdout + "\n" + proc.stderr).lower()
            self.assertTrue(
                proc.returncode != 0 or "error de entrada" in combined or "assertion failed" in combined,
                f"Se esperaba fallo de asercion para entrada invalida:\n{dzn_invalido}",
            )

    def test_03_optimalidad_factibilidad_y_equivalencia_gecode_chuffed(self):
        for fname, expected_z in EXPECTED_OPTIMA.items():
            dzn_path = DATA_DIR / fname
            data = parse_dzn(dzn_path)
            np_val, n_val, m_val = data["np"], data["n"], data["m"]

            solvers_out = {}
            for solver in ["gecode", "chuffed"]:
                proc = subprocess.run(
                    ["minizinc", "--solver", solver, "--statistics", str(MODEL_PATH), str(dzn_path)],
                    text=True,
                    capture_output=True,
                    timeout=15,
                )
                self.assertEqual(
                    proc.returncode,
                    0,
                    f"Fallo ejecucion en {fname} con {solver}:\n{proc.stderr}",
                )
                sol = parse_solution_output(proc.stdout, np_val, m_val, n_val)
                solvers_out[solver] = sol

                # 1. Optimalidad exacta
                self.assertEqual(
                    sol["ganancia"],
                    expected_z,
                    f"Optimo incorrecto en {fname} ({solver}): {sol['ganancia']} != {expected_z}",
                )

                # 2. Consistencia contable del resumen financiero
                ingresos_calc = sum(
                    sol["vendido"][s][j] * data["pagos"][s]
                    for s in range(m_val)
                    for j in range(n_val)
                )
                costos_calc = sum(
                    sol["prod"][i][j] * data["plantas"][i][1]
                    for i in range(np_val)
                    for j in range(n_val)
                )
                self.assertEqual(sol["ingresos"], ingresos_calc)
                self.assertEqual(sol["costos"], costos_calc)
                self.assertEqual(sol["ganancia"], ingresos_calc - costos_calc)

                # 3. Capacidades diarias y regimen alto para TODAS las centrales
                for i in range(np_val):
                    cap_i = data["plantas"][i][2]
                    umbral_i = (data["percent_high"] * cap_i) // 100
                    r_i = data["max_days_high"][i]
                    for j in range(n_val):
                        self.assertGreaterEqual(sol["prod"][i][j], 0)
                        self.assertLessEqual(sol["prod"][i][j], cap_i)
                    if 1 <= r_i <= n_val:
                        for k in range(n_val - r_i + 1):
                            dias_altos = sum(
                                1 for d in range(r_i) if sol["prod"][i][k + d] > umbral_i
                            )
                            self.assertLess(
                                dias_altos,
                                r_i,
                                f"Planta {i+1} viola regimen alto en {fname} ventana dia {k+1}",
                            )

                # 4. Rango de demanda por cliente [min_dem, demanda]
                for s in range(m_val):
                    for j in range(n_val):
                        dem_sj = data["demandas"][s][j]
                        min_sj = (data["min_prod"] * dem_sj) // 100
                        self.assertGreaterEqual(sol["vendido"][s][j], min_sj)
                        self.assertLessEqual(sol["vendido"][s][j], dem_sj)

                # 5. Cobertura energetica diaria
                for j in range(n_val):
                    tot_vend = sum(sol["vendido"][s][j] for s in range(m_val))
                    tot_prod = sum(sol["prod"][i][j] for i in range(np_val))
                    self.assertLessEqual(tot_vend, tot_prod)
                    self.assertEqual(tot_vend, tot_prod)

            # Equivalencia entre Gecode y Chuffed
            self.assertEqual(
                solvers_out["gecode"]["ganancia"],
                solvers_out["chuffed"]["ganancia"],
            )

    def test_04_ablacion_restricciones_redundantes_y_poda(self):
        full_code = MODEL_PATH.read_text(encoding="utf-8")
        # Modelo sin secciones 6 y 7 (sin redundantes ni simetrias)
        base_code = re.sub(
            r"% -------------------- 6\. Restricciones Redundantes ---------------------------.*?"
            r"% ---------------- 8\. Funcion Objetivo y Estrategia de Busqueda ---------------",
            "% ---------------- 8. Funcion Objetivo y Estrategia de Busqueda ---------------",
            full_code,
            flags=re.S,
        )

        dzn_path = DATA_DIR / "Instancia03.dzn"
        p_full = subprocess.run(
            ["minizinc", "--solver", "chuffed", "--statistics", str(MODEL_PATH), str(dzn_path)],
            text=True,
            capture_output=True,
            timeout=15,
        )
        p_base = subprocess.run(
            ["minizinc", "--solver", "coin-bc", "--statistics", "-", str(dzn_path)],
            input=base_code,
            text=True,
            capture_output=True,
            timeout=15,
        )
        self.assertEqual(p_full.returncode, 0)
        self.assertEqual(p_base.returncode, 0)

        z_full = int(re.search(r"Ganancia neta:\s*(-?\d+)", p_full.stdout).group(1))
        z_base = int(re.search(r"Ganancia neta:\s*(-?\d+)", p_base.stdout).group(1))
        self.assertEqual(z_full, z_base, "Las restricciones redundantes alteraron el optimo")


if __name__ == "__main__":
    unittest.main(verbosity=2)
