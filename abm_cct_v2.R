# =========================
# 0) Paquetes y semilla
# =========================
library(ABM)        # Carga el paquete ABM: define Simulation, Event, counters, etc.
library(ggplot2)
library(dplyr)
set.seed(1)         # Fija la semilla para que los resultados sean reproducibles

# =========================
# 1) Definir combinaciones de parámetros
# =========================
N      <- 5000     # Número de hogares (cada uno es un "agente")
Tmax   <- 36       # Número de meses (ticks) a simular
lambda_cred <- 0.30 # Qué tan rápido "aprende" la credibilidad

# Definir las combinaciones de parámetros a probar
param_combinations <- expand.grid(
  transfer_amount = c(400, 600, 800),           # Tres montos diferentes
  delay_prob_base = c(0.20, 0.30, 0.40)         # Tres probabilidades de retraso diferentes
)

# =========================
# 2) Función para ejecutar una simulación con parámetros dados
# =========================
run_simulation <- function(transfer_amount, delay_prob_base) {
  # =====================================
  # Crear simulación y estado inicial
  # =====================================
  sim <- Simulation$new(N)
  
  seedA <- 10  # Cantidad de hogares que ya comienzan asistiendo en t=0
  for (i in 1:N) {
    theta <- rnorm(1, mean = 300, sd = 80)     # Umbral heterogéneo ~ Normal(300, 80)
    cred0 <- 1 - delay_prob_base               # Credibilidad inicial
    state0 <- if (i <= seedA) "A" else "N"
    sim$setState(i, list(state0, theta = theta, cred = cred0))
  }
  
  # ======================================
  # Loggers (contadores automáticos)
  # ======================================
  sim$addLogger(newCounter("A", "A"))
  sim$addLogger(newCounter("N", "N"))
  
  # =========================================================
  # Handler mensual (la "dinámica" que corre cada mes)
  # =========================================================
  tick_handler <- function(time, sim, agent) {
    for (i in 1:N) {
      ai <- getAgent(sim, i)
      st <- getState(ai)
      
      # Beneficio esperado este mes: monto * credibilidad percibida
      benefit <- transfer_amount * st$cred
      
      # Regla de decisión mínima:
      new_state <- if (benefit >= st$theta) "A" else "N"
      
      # Si asiste, "experimento" de pago a tiempo
      paid_on_time <- (new_state == "A") && (runif(1) > delay_prob_base)
      
      # Actualizar credibilidad (promedio móvil)
      cred_new <- (1 - lambda_cred) * st$cred + lambda_cred * as.numeric(paid_on_time)
      
      # Guardamos nuevo estado + atributos
      setState(ai, list(new_state, theta = st$theta, cred = cred_new))
    }
    
    # Re-agendar el mismo handler para el mes siguiente
    if (time < Tmax) schedule(agent, newEvent(time + 1, tick_handler))
  }
  
  # ==============================
  # Ejecutar la simulación
  # ==============================
  schedule(sim$get, newEvent(0, tick_handler))
  res <- sim$run(0:Tmax)
  
  # Agregar columnas útiles
  res$attend <- res$A / N
  res$transfer_amount <- transfer_amount
  res$delay_prob_base <- delay_prob_base
  res$scenario <- paste0("Transfer: $", transfer_amount, ", Delay: ", delay_prob_base*100, "%")
  
  return(res)
}

# =========================
# 3) Ejecutar todas las simulaciones
# =========================
all_results <- list()

for (i in 1:nrow(param_combinations)) {
  cat("Ejecutando simulación", i, "de", nrow(param_combinations), "\n")
  
  transfer <- param_combinations$transfer_amount[i]
  delay <- param_combinations$delay_prob_base[i]
  
  result <- run_simulation(transfer, delay)
  all_results[[i]] <- result
}

# Combinar todos los resultados en un solo data frame
combined_results <- bind_rows(all_results)

# =========================
# 4) Crear gráfico con todas las líneas
# =========================
p <- ggplot(combined_results, aes(x = times, y = attend, color = scenario, linetype = scenario)) +
  geom_line(size = 1.2) +
  coord_cartesian(ylim = c(0, 1)) +
  labs(
    title = "Comparación de Escenarios CCT",
    subtitle = "Diferentes montos de transferencia y probabilidades de retraso",
    x = "Mes",
    y = "Proporción que asiste",
    color = "Escenario",
    linetype = "Escenario"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "bottom",
    legend.box = "vertical",
    legend.key.width = unit(2, "cm")
  ) +
  scale_color_manual(values = c("#E41A1C", "#377EB8", "#4DAF4A", 
                                "#984EA3", "#FF7F00", "#A65628",
                                "#F781BF", "#999999", "#66C2A5")) +
  scale_linetype_manual(values = c("solid", "dashed", "dotted", 
                                   "longdash", "dotdash", "twodash",
                                   "solid", "dashed", "dotted"))

# Mostrar el gráfico
print(p)

# Guardar en PNG
ggsave("comparacion_escenarios_cct.png", plot = p, width = 10, height = 7, dpi = 300)
