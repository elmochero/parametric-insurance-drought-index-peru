Parametric Insurance Drought Index – Peru

Parametric drought insurance model based on consecutive dry days using PISCO data (Peru, 1981–2016).

Overview
This project develops a parametric insurance index to quantify and transfer drought risk affecting agricultural systems and South American camelids in high-altitude regions of Peru.

The model is calibrated using daily precipitation data from the PISCO dataset and focuses on extreme dry spell behavior during the critical September–December period, which is highly relevant for pasture regeneration.

Objective
Design a transparent and scalable drought index
Estimate actuarial metrics (pure premium, frequency, severity)
Evaluate risk transfer feasibility
Support public policy and reinsurance structuring

Index Definition
The parametric index is based on extreme dry spell duration:
 A dry day is defined as precipitation < 1 mm
 For each year, the maximum number of consecutive dry days is calculated
 A 60-day moving window is applied
 Analysis period: September–December

Thresholds:
P90: Moderate extreme drought
P95: Severe drought
An event is triggered when observed values exceed these thresholds.
This ensures that payouts are linked to statistically extreme climatic conditions, not arbitrary thresholds.

Study Area
Region: Puno, Peru
Altitude: > 3600 m.a.s.l.
Climate: High Andean plateau (Altiplano)

Data
Source: PISCO precipitation dataset (SENAMHI)
Frequency: Daily
Period: 1981–2016

Methodology
Filter study area (altitude + region)
Compute dry days (precipitation < 1 mm)
Apply 60-day moving window
Extract annual maximum dry spell
Compute climatological percentiles (P90, P95)
Trigger events when thresholds are exceeded
Estimate payouts based on affected area proportion

Key Results
Index Performance
 Successfully captures major drought years
 High payouts observed in years associated with El Niño events
 Strong spatial coherence of drought signals

Actuarial Metrics
Metric	                      P90	     P95
Frequency of activation	      94%	     89%
Pure premium rate	          13.3%	    7.9%
Mean annual loss (S/.)	  132,862	  79,271

Results assume a sum insured of S/ 1,000,000 per department

Important Insight
The insured amount acts as a linear scaling factor:
 Increasing insured value → increases expected loss proportionally
 Does not affect risk structure or volatility

This enables flexible scaling depending on budget constraints.

Risk Analysis (Monte Carlo)
A stochastic simulation (10,000 synthetic years) was performed to evaluate extreme losses.

P90 Results
 Mean: S/ 132,885
 CV: 1.10
 VaR 95: S/ 516,509
 TVaR 95: S/ 525,687

Interpretation
 Controlled variability
 Limited tail risk
 Suitable for reinsurance structuring

Loss Distribution Insights
Right-skewed distribution (expected in drought risk)
Most years: low to moderate payouts
Few extreme years: high payouts (systemic events)

Exceedance Probability Curve (EP Curve)
Step-like behavior reflects empirical distribution
Tail stability indicates bounded extreme risk
This is a desirable property for risk transfer instruments

Key Insights
The index is:
 Objective
 Transparent
 Scalable
 Actuarially sound
Captures systemic drought risk effectively
Reduces:
 Basis risk (relative)
 Loss adjustment costs
 Information asymmetry

Limitations
Based on historical period (1981–2016)
Single hazard: drought (rainfall deficit)
Single temporal window (Sep–Dec)
Single window length (60 days)

Future Work
Evaluate additional windows (30, 45, 90 days)
Extend analysis to January–April period
Incorporate:
 Low temperature risk (frost)
 Excess rainfall
Develop multi-risk composite index
Spatial scaling to national level
Integration into Shiny application

Repository Structure
scripts/        → Core modeling code
data/           → Input data (not included)
results/        → Outputs (maps, tables, figures)
docs/           → Supporting documentation

Outputs
This repository generates:
 Climatology maps
 Frequency maps
 Loss cost maps
 Payment time series
 Monte Carlo simulations
 EP curves

Visual outputs can be used for:
Technical reports
Policy presentations
Reinsurance discussions

Author

Yonel Mendoza
Developed using open-source tools and PISCO data from SENAMHI.

Acknowledgements
Technical insights on camelid systems and drought vulnerability were informed by expert contributions (Omar Príncipe).

License
Creative Commons Attribution-NonCommercial 4.0 (CC BY-NC 4.0)

Final Statement

This project demonstrates that parametric insurance based on dry spell indices can be a viable, scalable, and technically robust solution for climate risk management in Peru.
