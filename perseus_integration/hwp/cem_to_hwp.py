#!/usr/bin/env python3
"""
cem_to_hwp.py  -- bridge CEM harvested carbon into Wei's WPsCS-Estimator.

Takes a CEM harvested-carbon-by-product series and runs the validated WPsCS
HWPs_CFLUX engine on it, returning the long-term HWP storage pool
(in-use products + landfill + charcoal) as an annual series. Drives the
original Python model unmodified except for the Linux path-separator fix
(see HWP_SETUP.md); does not re-implement the decay math.

Input CSV (annual): columns Year, Biomass, Pulpwood, Sawlog in carbon units
(any consistent unit; the HWP pool comes back in the same unit). Harvested_Timber
is computed as the sum if absent.

Usage:
  python3 cem_to_hwp.py \
    --harvest_csv cem_harvest_ME_BAU.csv \
    --wps_model  ~/WPsCS_run \
    --params_from ~/WPsCS_run/Scenario_1 \
    --out cem_hwp_ME_BAU.csv

The --wps_model dir must contain the (path-fixed) HWPs_CFLUX.py and the pool
modules (_Biomass.py, _Pulpwood.py, _Sawlog.py, _Landfill.py, _Charcoal.py).
--params_from supplies HWPs_CFLUX_Params1.csv (annual product allocation) and
HWPs_CFLUX_Params2.csv (decay parameters); Params1 is forward-filled to cover
the harvest series length.
"""
import argparse, os, shutil, subprocess, sys, tempfile
import pandas as pd

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--harvest_csv", required=True)
    ap.add_argument("--wps_model", required=True, help="dir with path-fixed HWPs_CFLUX.py + pool modules")
    ap.add_argument("--params_from", required=True, help="a Scenario dir with Params1/Params2 CSVs")
    ap.add_argument("--out", required=True)
    ap.add_argument("--python", default=sys.executable)
    a = ap.parse_args()

    hv = pd.read_csv(a.harvest_csv)
    need = {"Year", "Biomass", "Pulpwood", "Sawlog"}
    if not need.issubset(hv.columns):
        sys.exit(f"harvest_csv must have columns {need}; got {list(hv.columns)}")
    if "Harveted_Timber" not in hv.columns:   # note: WPsCS spells it this way
        hv["Harveted_Timber"] = hv[["Biomass", "Pulpwood", "Sawlog"]].sum(axis=1)
    hv = hv[["Year", "Harveted_Timber", "Biomass", "Pulpwood", "Sawlog"]]
    n = len(hv)

    work = tempfile.mkdtemp(prefix="cem_hwp_")
    sc = "CEM"
    scdir = os.path.join(work, sc)
    os.makedirs(scdir)

    # data
    hv.to_csv(os.path.join(scdir, "HWPs_Data.csv"), index=False)

    # decay params verbatim
    shutil.copy(os.path.join(a.params_from, "HWPs_CFLUX_Params2.csv"),
                os.path.join(scdir, "HWPs_CFLUX_Params2.csv"))

    # allocation params: forward-fill to >= n rows
    p1 = pd.read_csv(os.path.join(a.params_from, "HWPs_CFLUX_Params1.csv"))
    if len(p1) < n:
        last = p1.iloc[[-1]]
        p1 = pd.concat([p1] + [last] * (n - len(p1)), ignore_index=True)
    p1 = p1.iloc[:n].reset_index(drop=True)
    p1.to_csv(os.path.join(scdir, "HWPs_CFLUX_Params1.csv"), index=False)

    # engine + pool modules, with sc pointed at our scenario dir
    eng_src = os.path.join(a.wps_model, "HWPs_CFLUX.py")
    eng = open(eng_src).read().replace("chr(92)", "os.sep")
    # force the scenario name regardless of what is hardcoded
    import re
    eng = re.sub(r"sc=['\"]Scenario_\d+['\"]", f"sc='{sc}'", eng, count=1)
    open(os.path.join(work, "HWPs_CFLUX.py"), "w").write(eng)
    for m in ("_Biomass.py", "_Pulpwood.py", "_Sawlog.py", "_Landfill.py", "_Charcoal.py"):
        src = os.path.join(a.wps_model, m)
        if os.path.exists(src):
            shutil.copy(src, os.path.join(work, m))

    env = dict(os.environ, PYTHONNOUSERSITE="1")
    r = subprocess.run([a.python, "HWPs_CFLUX.py"], cwd=work, env=env,
                       capture_output=True, text=True)
    cflux = os.path.join(scdir, "Results_CFlux.csv")
    if not os.path.exists(cflux):
        sys.exit(f"WPsCS did not produce Results_CFlux.csv\nSTDOUT:\n{r.stdout}\nSTDERR:\n{r.stderr}")

    df = pd.read_csv(cflux)
    inuse = [c for c in df.columns if c.endswith("_A")]
    land = [c for c in df.columns if c.endswith("_L")]
    out = pd.DataFrame({"Year": df["Year"]})
    out["HWP_inuse"] = df[inuse].sum(axis=1)
    out["HWP_landfill"] = df[land].sum(axis=1)
    # charcoal long-term store if present
    char = [c for c in df.columns if c.lower().startswith("biochar") and not c.endswith("_E")]
    out["HWP_charcoal"] = df[char].sum(axis=1) if char else 0
    out["HWP_total"] = out["HWP_inuse"] + out["HWP_landfill"] + out["HWP_charcoal"]
    out.to_csv(a.out, index=False)
    shutil.rmtree(work, ignore_errors=True)
    print(f"wrote {a.out}: {n} years, HWP_total {out['HWP_total'].iloc[0]:.0f} -> {out['HWP_total'].iloc[-1]:.0f}")

if __name__ == "__main__":
    main()
