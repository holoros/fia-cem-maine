# Cardinal Disk Cleanup, 2026-05-21

Freed about 51 GB by removing superseded run directories from `~/fia_cem_projections/output`. The output tree went from 78 GB to 31 GB and the per_plot checkpoint count went from 31 to 12. All current runs were preserved and all six in flight jobs were undisturbed. A modification time guard (skip anything touched in the last 60 minutes) protected active outputs.

## Deleted (21 directories)

Superseded p1, p2, r21, and diagnostic runs:

- ME_20260505_rcp45_hadgem2_wear_r21 (1.9G)
- ME_20260508_rcp85_hadgem2_wear_r21 (1.9G)
- ME_20260516_rcp85_hadgem2_wear_econ_r21 (1.6G)
- ME_20260516_rcp45_hadgem2_wear_econ_r21 (1.7G)
- WA_20260510_rcp45_wear_p1 (2.4G)
- WA_20260510_rcp85_wear_p1 (2.3G)
- MN_20260510_rcp45_wear_p1 (5.6G)
- MN_20260510_rcp85_wear_p1 (5.6G)
- GA_20260510_rcp45_wear_p1 (6.2G)
- GA_20260510_rcp85_wear_p1 (6.2G)
- WA_20260518_rcp45_wear_p2 (4.5G)
- WA_20260518_rcp85_wear_p2 (4.5G)
- MN_20260516_rcp45_wear_p1_2004base (4.0G)

Superseded smoke and test directories:

- MN_20260510_mn_smoke, GA_20260510_ga_smoke, WA_20260510_wa_smoke
- ME_20260515_layer2_smoke_20260513, ME_20260518_us_l3_smoke2
- WA_20260516_wa_fire_halfamp
- WA_20260520_conus_donor_smoke_20260520, WA_20260520_conus_donor_smoke2_20260520

## Skipped by the safety guard (touched within 60 minutes)

- WA_20260520_rcp45_wear_conus_l7b and WA_20260520_rcp85_wear_conus_l7b. These are the md5 identical duplicates of the non CONUS l7b runs (the null result). They are harmless to keep and can be removed in a later pass once outside the activity window, reclaiming about 4.8 GB.
- WA_20260521_conusCA_smoke. The two simulation verification smoke from this session, tiny.

## Preserved (current, in use)

ME, WA, MN, GA l7b and p3hindcast runs, the ME econ_l7b runs, and the WA conusCA production directories being written by the running jobs.
