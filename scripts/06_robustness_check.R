# Robustness checks

# Dynamic stability (roots)
eigvals <- vars:::roots(varx_model)          # companion-matrix roots
if ( all(Mod(eigvals) < 1) ) {
  cat("✓  all eigenvalues < 1  →  VARX is dynamically stable\n\n")
} else {
  cat("⚠  some roots ≥ 1  →  model is NOT stable!\n\n")
}


# Recursive-estimates / CUSUM stability plot ────────────────
stab_obj <- stability(varx_model, type = "OLS-CUSUM")
par(mar = c(4,4,2,1))     
plot(stab_obj)

# Granger causality test
causality(varx_model, cause = "d_exp")$Granger
causality(varx_model, cause = "d_rate")$Granger
causality(varx_model, cause = "d_ipc_yoy")$Granger
