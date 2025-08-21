# Loading and cleaning the data

# Dataset
data <- read_excel("data/data_ce.xlsx") |> 
  dplyr::filter(periodo < "2025-05-01") |> 
  dplyr::select(periodo, 
                commodities_pi = ipcom, 
                imae, 
                ipc, 
                exp_interanual = exp_interanual_mean, 
                embi, 
                tasa_interb, 
                m1) %>% 
  mutate(periodo = as.Date(periodo))

# Adjusting the data to use
# Here we select the variables wi 
adjusted_long <- adjusted_data %>% 
  select(periodo,     
         exp_interanual, 
         ipc,
         imae, 
         tasa_interb, 
         embi,
         m1) %>% 
  pivot_longer(cols = -periodo,
               names_to = "Variable",
               values_to = "Value")

# Creating the COVID-19 dummy
# Shock = 1 in March-June 2020, exponential decay thereafter.
shock_start <- as.Date("2020-03-01")
shock_months <- 4
decay_months <- 30
decay_curve <- exp(seq(0, -3, length.out = decay_months))

# build the dummy ----------------------------------------------------------
final_data <- adjusted_data %>% 
  arrange(periodo) %>%                            
  mutate(months_since_shock = lubridate::interval(shock_start, periodo) %/% months(1),
         dummy_covid       = 0)                       

# 1. acute phase (1 for first four shock months)
acute_rows  <- which(between(final_data$months_since_shock, 0, shock_months - 1))
final_data$dummy_covid[acute_rows] <- 1

# 2. exponential decay phase
decay_rows  <- which(between(final_data$months_since_shock,
                             shock_months,
                             shock_months + decay_months - 1))
final_data$dummy_covid[decay_rows] <-
  decay_curve[ final_data$months_since_shock[decay_rows] - shock_months + 1 ]

# 3. drop helper column
final_data <- final_data %>% dplyr::select(-months_since_shock)

ggplot(final_data, aes(periodo, dummy_covid)) +
  geom_line(size = 1, colour = "steelblue") +
  labs(title = "COVID-19 Dummy", x = NULL, y = NULL) +
  theme_minimal(base_size = 11) +  
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"), 
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 10)
  )

# Endogenous variables 
endog_var_simple <- c("imae","ipc","exp_interanual","tasa_interb")

v_endog_simple <- final_data %>%                                
  select(periodo, all_of(endog_var_simple))

# Testing stationarity
# Unit-root/stationary (A VAR assumes all endogenous series are (weakly) stationary)
unitroot_tests <- function(x, max_lag = 6, alpha = 0.05) {
  x <- na.omit(x)
  
  adf_p <- tryCatch(tseries::adf.test(x, k = max_lag)$p.value, error = function(e) NA_real_)
  
  # KPSS stat + critical value from urca (no hard-coding)
  kpss_obj  <- tryCatch(urca::ur.kpss(x, type = "mu", lags = "short"), error = function(e) NULL)
  kpss_stat <- if (is.null(kpss_obj)) NA_real_ else unname(kpss_obj@teststat)
  kpss_crit <- if (is.null(kpss_obj)) NA_real_ else unname(kpss_obj@cval[1, "5pct"])  # 5%
  
  tibble(
    adf_p = adf_p,                          # H0: unit root (want p < .05)
    kpss_stat = kpss_stat,                  # H0: stationarity (want stat < crit)
    kpss_crit = kpss_crit
  )
}

unitroot_tbl <- v_endog_simple %>% 
  select(-periodo) %>% 
  map_dfr(
    .f   = unitroot_tests,
    .id  = "variable"
  ) %>%
  mutate(
    kpss_crit_10 = 0.347,          # from Kwiatkowski et al. (1992) for monthly
    kpss_stationary = kpss_stat < kpss_crit_10,
    adf_stationary  = adf_p < 0.05,
    decision = case_when(
      adf_stationary & kpss_stationary        ~ "OK (stationary)",
      !adf_stationary & !kpss_stationary      ~ "I(1) → difference",
      TRUE                                    ~ "Mixed → inspect"
    )
  )

print(unitroot_tbl)

# The IMAE is stationary, so only difference the rest of the variables
data_station_1 <- final_data %>%  
  mutate(
    d_ipc_yoy  = ipc              - lag(ipc, 1),
    d_exp      = exp_interanual   - lag(exp_interanual, 1),
    d_rate     = tasa_interb      - lag(tasa_interb, 1)
  ) %>%
  select(
    periodo,
    imae, 
    d_ipc_yoy, 
    d_exp, 
    d_rate,
    dummy_covid
  ) %>%
  drop_na()    

# Testing again to see if 1 diff was enough
unitroot_tbl_2 <- data_station_1 %>% 
  select(-c(periodo, dummy_covid)) %>% 
  map_dfr(unitroot_tests, .id = "variable") %>%
  mutate(
    adf_stationary  = adf_p < 0.05,
    kpss_stationary = kpss_stat < kpss_crit,
    decision = case_when(
      adf_stationary &  kpss_stationary ~ "OK (stationary)",
      !adf_stationary & !kpss_stationary ~ "Non-stationary",
      TRUE                               ~ "Mixed → inspect"
    )
  )

print(unitroot_tbl_2)

# Seeing if they have a seasonal component after differencing once
spec_test <- function(x, date_vec) {
  y <- ts(x,
          start     = c(year(date_vec[1]), month(date_vec[1])),
          frequency = 12)
  
  sp <- spec.pgram(y, log = "no", detrend = TRUE, plot = FALSE)
  # location of the 1-cycle-per-year frequency bin
  k  <- which.min( abs(sp$freq - 1/12) )
  tibble(
    peak      = sp$spec[k],
    spec_mean = mean(sp$spec),
    ratio     = peak / mean(sp$spec),
    seasonal  = ratio > 6          # empirical rule-of-thumb
  )
}

sa_vars <- c("imae","d_ipc_yoy","d_exp","d_rate")

spec_tbl <- map_dfr(sa_vars, \(v)
                    spec_test(data_station_1[[v]], data_station_1$periodo) |> mutate(series = v, .before = 1))

print(spec_tbl)  # After one difference they appear not seasonal.

# Endogenous and exogenous variables 1 difference
endog_vars <- c("imae","d_ipc_yoy","d_exp","d_rate")
exo_vars <- c("dummy_covid")

v_endog <- data_station_1 %>% 
  select(periodo, all_of(endog_vars))

v_exo <- data_station_1 %>% 
  select(periodo, all_of(exo_vars))

#Standardizing endogenous variables, so they are all in the same terms and its easier to read the IRFs. (mean = 0, sd = 1 for each column)
v_endog_z <- v_endog %>%
  mutate(across(all_of(endog_vars),
                ~ (.x - mean(.x, na.rm = TRUE)) / sd(.x, na.rm = TRUE),
                .names = "{.col}")) %>%
  select(periodo, all_of(endog_vars))

