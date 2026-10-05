# Computer practical catchment hydrology – answers

Numbers below come from running `Thiessen.R`, `Budyko.R` and `unit_hydrograph.R`
with the data in `data/`. Numbers refer to the answer boxes in the assignment PDF.

## 2 Precipitation

**1.** Isselburg: P = 0.25·10 + 0.35·8 + 0.25·7.5 + 0.15·7 = **8.2 mm**. Dämmerwald: only the Raesfeld polygon, so P = **7.5 mm**.

**2.** ID: abbreviated name of the rain gauge (e.g. GEMM, WARE).
**3.** X: x-coordinate (easting) of the gauge in UTM zone 31N [m].
**4.** Y: y-coordinate (northing) of the gauge in UTM zone 31N [m].
**5.** Z: elevation of the gauge [m above sea level].

**6.** First column: date and hour, format yyyymmddhh.
**7.** Other columns: hourly rainfall sum at each of the 42 gauges [mm/h].

**8.** 0: pixel (1 km × 1 km) outside the catchment (also the NODATA value).
**9.** 1: pixel inside the catchment.

**10.** The plusses are the locations of the rain gauges.
**11.** The thin lines are the Thiessen polygon boundaries (the perpendicular bisectors between neighbouring gauges); the thick line is the catchment boundary.

**12.** VIEL has the largest contribution: **0.093** (9.3 %), closely followed by TERN and BALM (0.090).

**13.** Elevation / orography (air forced upward cools and condenses).
**14.** Distance to the sea and the direction of the prevailing wind (windward vs. lee side).
**15.** Type of rainfall: convective showers are local and very variable; frontal rain is more uniform.

**16.** Mean: **1216 mm**
**17.** St. dev.: **207 mm**
**18.** Max: **1648 mm** (BOUI)
**19.** Min: **872 mm** (ROCH)

**20.** The spatial variability is large: within one catchment, the wettest gauge gets almost twice as much as the driest one (coefficient of variation ≈ 17 %). One gauge is not representative of the whole catchment.

**21.** They are large: the Netherlands gets about 800–900 mm/y. Most Ourthe gauges get more, up to almost twice as much.

**22.** Rainfall increases with elevation (correlation 0.54, about +0.8 mm/y per metre, so about 400 mm more between 54 and 599 m). Physically: orographic lifting. When air is forced up over the Ardennes, it cools, water vapour condenses and more rain falls on the higher parts (and on the windward side).

**23.** P_th: catchment average rainfall per hour, computed with the Thiessen polygon method.
**24.** P_ar: catchment average rainfall per hour, computed with the arithmetic mean of all gauges.

**25.** The arithmetic mean gives every gauge the same weight. Thiessen weights every gauge by the area of its polygon inside the catchment, so gauges that represent a large area count more and gauges outside or near the edge of the catchment count less (or not at all).

**26.** VIEL (the gauge with the largest Thiessen weight; any gauge is allowed).

**27–32.**

|                  | P_th   | P_ar   | P_one (VIEL) |
|------------------|--------|--------|--------------|
| Yearly sum [mm]  | **1312** | **1216** | **1278** |
| Max. hourly sum [mm/h] | **5.2** | **4.7** | **16.5** |

**33.** P_ar is lower than P_th because many gauges are in the lower, drier areas near the outlet or just outside the catchment, and they get the same weight as gauges that represent large (higher, wetter) areas. With Thiessen, these gauges get small or zero weights. The maximum of P_one is much higher, because one gauge catches the full intensity of a local shower. Averaging over many gauges smooths out such peaks.

**34.** The points lie close to a straight line (correlation 0.92), but the slope is about 1.08: P_th is on average about 8 % higher than P_ar. There is also scatter for individual hours, mostly during local showers.

**35.** Yes. The yearly sums differ by about 100 mm (8 %), which is substantial for water balance studies. The Ourthe gauges are unevenly spread and some are outside the catchment, and Thiessen corrects for that.

**36.** How evenly the gauges are spread over the catchment (clustered gauges or gauges outside the catchment cause large differences), and the spatial variability of the rainfall itself (for example elevation differences). With evenly spaced gauges, or uniform rainfall, both methods give the same result.

**37.** No. The yearly sum is close (1278 vs. 1312 mm), but hour by hour it's poor. The scatter is large (correlation 0.77), the peaks are far too high or are missed completely, and in 64 % of the hours with catchment rainfall VIEL measured nothing. One point can't represent the spatial variability of showers.

**38.** It depends on whether the gauge over- or underestimates. VIEL underestimates the yearly sum a bit, so the modelled discharge would be too low. The error propagates and grows: the rainfall error is passed on to the soil moisture, so evapotranspiration, groundwater recharge and storage are also wrong. Because evapotranspiration doesn't change much with rainfall, almost all of the rainfall error ends up in the discharge. A small relative error in P becomes a larger relative error in Q. Peaks are also wrong in timing and height, because local showers are missed or exaggerated.

## 3 Evapotranspiration

**39–62 (guesses, Table 1).** These are your own guesses before the practical; for example:

| Catchment | P [mm/y] | ETact [mm/y] | ET reduction |
|---|---|---|---|
| Guadiana (Spain) | 500 | 400 | large |
| Hupsel Brook (NL) | 800 | 500 | small |
| Mahakam (Indonesia) | 3000 | 1200 | small |
| Metuje (Czech rep.) | 700 | 450 | small |
| Narsjø (Norway) | 800 | 300 | small |
| Ourthe (Belgium) | 1000 | 500 | small |
| Plynlimon (Wales) | 2500 | 450 | small |
| Rietholzbach (Switzerland) | 1500 | 550 | small |

**63.** P: precipitation [mm/d].
**64.** ETpot: potential evapotranspiration [mm/d].
**65.** Q: discharge, expressed as a water depth over the catchment [mm/d]. (The last column, T, is the air temperature [°C].)

**66.** The storage change (ΔS/Δt) in soil moisture, groundwater, surface water and snow. Groundwater flow across the catchment boundary was also neglected.

**67.** The data cover many years (between 3 and 40, depending on the catchment). Over such long periods, storage at the end is about the same as at the start, so the storage change is negligible compared with P, ET and Q.

**68.** Not valid for short periods (days, months, a single season or year), in catchments with a trend in storage (e.g. groundwater extraction, melting glaciers), with large deep groundwater flows into or out of the catchment, or for short records in catchments with very large storage.

**69–100 (Table 2, from the table `WB`).**

| Catchment | P [mm/y] | ETact [mm/y] | ET reduction (ETpot − ETact) | Limiting factor |
|---|---|---|---|---|
| Guadiana | 452 | 433 | large (824 mm) | water (ETpot/P = 2.78) |
| Hupsel Brook | 805 | 477 | small (98 mm) | energy (0.72) |
| Mahakam | 3256 | 453 | large (641 mm) | energy (0.34) |
| Metuje | 750 | 385 | medium (236 mm) | energy (0.83) |
| Narsjø | 593 | −227 (!) | not reliable | energy (0.50) |
| Ourthe | 995 | 543 | small (54 mm) | energy (0.60) |
| Plynlimon | 2452 | 460 | small (68 mm) | energy (0.22) |
| Rietholzbach | 1458 | 437 | small (69 mm) | energy (0.35) |

(ETpot: 1257, 576, 1094, 621, 295, 598, 528, 506 mm/y; Q: 19, 328, 2803, 365, 820, 452, 1992, 1021 mm/y.)

**101.** Compare with your own guesses. Typical surprises are:
- Narsjø: ETact is negative, which is impossible. Q (820 mm) is larger than the measured P (593 mm), so P is strongly underestimated: the gauges are in valleys outside the catchment while the catchment reaches 1600 m, and snow undercatch adds to this.
- Mahakam: ETact (453 mm) is much lower than expected for a tropical rainforest (normally over 1000 mm). This is probably a data problem (P underestimated or Q overestimated).
- Plynlimon and Rietholzbach: P is higher and ETact lower than most people guess.

**102.** The Hupsel P (805 mm/y) is among the lowest. Only Guadiana (452 mm) and Narsjø (593 mm, underestimated) are lower. Mahakam, Plynlimon and Rietholzbach get 2–4 times as much.

**103.** Yes 😉 (it doesn't rain that much in the Netherlands, it just rains often).

**104.** Usually: Metuje (it's energy limited, not water limited) and Mahakam (energy limited but with a large ET reduction, which you wouldn't expect for a rainforest). Most people overestimate ETact in wet, cool catchments and underestimate how wet Plynlimon and Rietholzbach are.

**105.** Plynlimon (lowest ETpot/P = 0.22).

**106.** Guadiana (ETpot/P = 2.78; ETact/P = 0.96, so almost all rain evaporates).

**107.** Most catchments follow the curves well. Hupsel, Ourthe, Rietholzbach and Plynlimon lie close to the w = 2.63 curve, and Guadiana lies between the 2.63 and 5.00 curves. Metuje lies between the 1.70 and 2.63 curves. Mahakam (far below all curves) and Narsjø (negative) don't fit, because their data are wrong (see 101).

**108.** Pastures have shallower roots and less interception than forest, so ETact decreases. The Metuje point moves down: ETact/P becomes lower at the same ETpot/P (to a curve with a lower w), and Q increases.

**109.** Shallow grass roots can reach less soil water, so in dry periods the vegetation gets soil moisture stress earlier and evapotranspiration reduction becomes larger. Interception evaporation is also lower for grass than for forest. ETact goes down and more water drains to the river.

**110.** ETact can only be computed from the water balance (P − Q) for long periods, when the storage change is negligible. Per month, the storage change is large (water is stored in winter and used in summer), so P − Q isn't ETact.

**111.** Discharge is very low in winter (0.3–0.8 mm/d), even though precipitation keeps falling. In May and June there's a large peak (8.0 and 5.4 mm/d) that is much higher than P. Precipitation is stored as snow in winter and comes out as snowmelt in spring.

**112.** Close to the equator, solar radiation and day length are about the same all year, and temperature and humidity hardly vary. So the available energy for evapotranspiration is about constant. There are no seasons in temperature, only in rainfall.

**113.** In those periods, more water leaves the catchment than enters it, so storage (soil moisture and groundwater) decreases. When the soil gets drier, plants get water stress and ETact becomes lower than ETpot.

**114.** In those periods, even a catchment that is energy limited on a yearly basis can become temporarily water limited (e.g. in summer). Evapotranspiration is then limited by available water rather than energy.

## 4 Runoff

**115–120.** UHO = (0.3, 0.6, 0.1), P = (10, 2, 1, 8):
- Q1 = 0.3·10 = **3.0 mm/h**
- Q2 = 0.6·10 + 0.3·2 = **6.6 mm/h**
- Q3 = 0.1·10 + 0.6·2 + 0.3·1 = **2.5 mm/h**
- Q4 = 0.1·2 + 0.6·1 + 0.3·8 = **3.2 mm/h**
- Q5 = 0.1·1 + 0.6·8 = **4.9 mm/h**
- Q6 = 0.1·8 = **0.8 mm/h**

**121.** Yes: `conv(P_example, UHO_example)` gives 3.0, 6.6, 2.5, 3.2, 4.9, 0.8, the same as the manual computation (sum = 21 mm = rainfall sum).

**122.** if t < tp: Qt = Qp · t / tp
**123.** if t ≥ tp: Qt = Qp · (tt − t) / (tt − tp)

**124.** 4 Feb 2002 – 9 Feb 2002 (start = 2002020400, end = 2002020900).

**125.** The unit hydrograph only describes the fast response of the catchment to a rainfall event (direct runoff). Baseflow comes from groundwater that was already there before the event, so it doesn't belong to the response to this rain and has to be removed first.

**126.** P sum = **34.5 mm**
**127.** DR sum = **13.3 mm** (baseflow = 0.023 mm/h)
**128.** ΣDR/ΣP = **0.39**

**129.** Only 39 % of the rain becomes direct runoff, so 61 % is stored in the soil or groundwater (or evaporates). The catchment wasn't completely wet before the event: the soil still had room to store water. In winter it's fairly wet, though; in a dry summer the ratio would be much lower.

**130.** Overestimated. The unit hydrograph assumes that all rain becomes direct runoff (the ordinates sum to 1), but in reality only 39 % does. The modelled discharge would be about 2.6 times too large.

**131.** Precipitation is all the rain that falls. Effective precipitation is only the part that becomes direct runoff; the rest (infiltration into soil and groundwater, interception, evaporation) is a loss for the event.

**132.** The unit hydrograph only converts rainfall into a time distribution of discharge and conserves volume. You have to put in only the water that actually becomes direct runoff, otherwise the volume of the modelled discharge is wrong.

**133.** When the catchment is dry (summer, after a dry period, low groundwater) or the rain intensity is low: much of the rain can infiltrate and be stored in the soil. Also on permeable, sandy soils and with a deep groundwater table. In a wet catchment, or with very intense rainfall (saturation or infiltration-excess overland flow), the difference is small.

**134.** tt = **87 h**, tp = **11 h** (highest NS; found by trying all combinations).

**135.** Mainly the overall shape and the Nash-Sutcliffe efficiency: timing and height of the peak, the shape of the recession, and similar volumes.

**136.** No. With these parameters the peak is underestimated (modelled 0.25 mm/h vs. observed 0.29 mm/h), because NS weighs the whole event. For flood protection you'd calibrate specifically on peak height (e.g. a shorter tt or tp), and on several large events.

**137.** Not really. The modelled peak comes about 5 hours too early (hour 55 vs. 60). For timing, you'd choose tp so that the peak times match, and judge on peak timing rather than NS.

**138.** NS = **0.93**

**139.** Yes, it's high (1 is perfect, above about 0.7 is usually considered good). But it's the calibration event, so a high value is expected: the parameters were fitted to exactly this event.

**140.** 29 Dec 2002 – 2 Jan 2003 (start = 2002122900, end = 2003010200).

**141.** Only partly. The total volume is right (P_eff is scaled with this event's runoff ratio), and the rise and recession are roughly in the right period. The peak is much too low (modelled 0.30 vs. observed 0.93 mm/h) and comes about 7 hours too late.

**142.** The unit hydrograph assumes the catchment always responds the same way (linear, time-invariant). In reality, the response depends on the wetness of the catchment and the rain intensity: in this wetter period, more fast flow (overland flow, drains) occurred, giving a faster and higher peak. The constant loss fraction and constant baseflow are also simplifications. Finally, the parameters were fitted to one event and are partly case-specific.

**143.** NS = **0.29**: much lower than in calibration. The model is better than the mean, but not good. The fitted parameters don't hold for other events.

**144.** The catchment is a rectangle with the river in the middle: A = 2·L·ll, so L = A / (2·ll) = 6.5·10⁶ / (2 · 15 000) = **217 m**.

**145.**
- Smallest j: μ = 0.05, k = 5, D = 8 gives j = 0.05·217² / (π²·5·8) = 6.0 d = **143 h**
- Largest j: μ = 0.1, k = 1, D = 1 gives j = 0.1·217² / π² = 477 d = **11 451 h**

**146.** With j = 716 h (middle values μ = 0.075, k = 3, D = 4), the j-model UH has no rising limb: the highest ordinate is at t = 1 h and then it decays exponentially over hundreds of hours. The ordinates are very small (about 0.0019 max) and the tail is very long. The triangular UH has a clear peak after 11 h and is over after 87 h.

**147.** No. With j from field data (716 h), NS = **−0.96**: the modelled direct runoff is far too low and spread out over far too long a period, with no peak. Only with a much smaller (calibrated) j of about 40 h is the fit reasonable (NS = 0.73), and that value is outside the physically realistic range.

**148.** The j-model describes slow groundwater flow to the ditches. Fast flow routes aren't included: overland flow (infiltration-excess and saturation-excess), direct rain on the channels, interflow (shallow subsurface flow) and, in Hupsel in particular, flow through tile drains.

**149.** Calibrated j = **40 h** (highest NS for 4–9 Feb 2002).

**150.** NS = **0.73**, lower than the triangular UH (0.93).

**151.** The j-model UH has its maximum at t = 1 h and no rising limb (no travel time to the outlet), so the modelled discharge reacts immediately to the rain and peaks too early. To get a peak at all, j has to be small, which makes the recession too fast.
