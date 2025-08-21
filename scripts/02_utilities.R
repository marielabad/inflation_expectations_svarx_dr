# Utilitites

# Function to create a time series
create_ts <- function(
    df,
    time_variable = "periodo",
    frequency = 12
) {
  start_date = min(df[[time_variable]])
  start_year <- lubridate::year(start_date)
  start_month <- lubridate::month(start_date)
  
  ts(
    data.matrix(dplyr::select(df, -all_of(time_variable))),
    start = c(start_year, start_month), 
    frequency = 12
  )
}