# Estimating the benchmark SVAR-X
# Modeling ----------------------------------------------------------------
# Converting to timeseries
ts_y <- create_ts(v_endog_z)

ts_x <- create_ts(v_exo)

VARselect(ts_y) #SC(n) = 1 BUT AIC(n) = 2!

# reduced form VAR-X 
varx_model <- VAR(
  y = ts_y,
  p = 2, 
  exogen = ts_x,
  type = "const"
)

serial.test(varx_model, lags.pt = 11, type = "PT.asymptotic") #PASSES 

# Serial correlation test (alternative to Portmanteau)
serial.test(varx_model, type = "BG", lags.bg = 1) #PASSES

# Restrictions matrix
A4 <- matrix(c(
  # imae   ipc     exp     rate
  1,     0,      0,      0,     # IMAE eqn: no contemporaneous shocks
  NA,     1,     NA,      0,     # Inflation eqn: responds to IMAE and expectations
  NA,    NA,      1,      0,     # Expectations eqn: responds to IMAE and inflation
  0,     0,     NA,      1      # Interest rate eqn: responds to expectations only
), 4, 4, byrow = TRUE,
dimnames = list(
  c("imae", "d_ipc_yoy", "d_exp", "d_rate"),
  c("imae", "d_ipc_yoy", "d_exp", "d_rate")
))

# quick checks ----------------------------------------------------------
sum(is.na(A4))                  
Matrix::rankMatrix(!is.na(A4))   

svar_model <- SVAR(varx_model, 
                   estmethod = "scoring", 
                   Amat = A4)

# Checking the current sign
K <- svar_model$B   
cat("Impact of ε_rate on d_rate  :  ", K["d_rate", "d_rate"], "\n")

# Confirming that its positive so its a tightening.

# Impulse-response analysis
irf_svar_exp_tasa <- plot(irf(svar_model, 
                              impulse = "d_rate", 
                              response = "d_exp", 
                              n.ahead = 24, 
                              boot = TRUE,
                              runs = 1000))


irf_svar_exp_ipc <- plot(irf(svar_model, 
                             impulse = "d_exp", 
                             response = "d_ipc_yoy", 
                             n.ahead = 30,  
                             boot = TRUE))


irf_svar_imae <- plot(irf(svar_model, 
                          impulse = "d_exp", 
                          response = "imae", 
                          n.ahead = 30, 
                          boot = TRUE))