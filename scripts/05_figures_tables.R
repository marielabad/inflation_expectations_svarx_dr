# Tables and Figures

# Table of Descriptive statistics ----------------
desc_table <- data %>% 
  filter(periodo < "2025-05-01") |> 
  select(
    `Commodities Price Index` = commodities_pi,
    `Monthly Index of Economic Activity` = imae,
    `Consumer Price Index` = ipc,
    `12-month Average Inflation Expectations` = exp_interanual,
    `EMBI` = embi,
    `Interbank Interest Rate` = tasa_interb,
    `M1` = m1
  ) %>% 
  summarise(across(everything(), list(
    N = ~sum(!is.na(.)),
    Mean = ~mean(., na.rm = TRUE),
    `St. Dev.` = ~sd(., na.rm = TRUE),
    Min = ~min(., na.rm = TRUE),
    Max = ~max(., na.rm = TRUE)
  ), .names = "{.col}_{.fn}")) %>% 
  pivot_longer(everything(),
               names_to = c("Variable", ".value"),
               names_sep = "_")

desc_table %>%
  kable(digits = 2, caption = "Descriptive Statistics") %>%
  kable_styling(full_width = FALSE, position = "center")
# Adjusted data
adjusted_data <- data %>% 
  mutate(
    across(c(commodities_pi, imae, m1, ipc),
           ~ (.x/lag(.x, 12) - 1),
           .names = "{.col}")
  ) %>% 
  tidyr::drop_na()


# Plotting the actual inflation and inflation expectations
data %>% 
  mutate(ipc_interanual = ipc - lag(ipc, 12)) %>% 
  drop_na() %>% 
  ggplot(mapping = aes(x = periodo)) +
  geom_line(aes(y = ipc_interanual, color = "Inflation")) +
  geom_line(aes(y = exp_interanual, color = "Inflation Expectations")) +
  annotate("rect",
           xmin = as.Date("2020-03-01"),
           xmax = as.Date("2021-12-01"),
           ymin = -Inf, ymax = Inf,
           fill = "gray80", alpha = 0.5) +
  geom_vline(xintercept = as.Date("2012-01-01"), 
             linetype = "dashed", color = "black", size = 0.8) +
  annotate("text", x = as.Date("2012-01-01"), y = 10.5, 
           label = "ITR", angle = 90, vjust = -0.5, hjust = 1.1, size = 3.5) +
  scale_color_manual(values = c("Inflation" = "blue", "Inflation Expectations" = "red")) + 
  labs(title = "ITR",
       x = "Date",
       y = "Percent (%)",
       color = "Series") +
  theme_minimal() 
