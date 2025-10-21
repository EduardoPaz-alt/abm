# 1) Preparación
   
**Paquete y semilla.**
`library(ABM)` carga la mini-infraestructura de simulación (agentes, eventos, contadores).

`set.seed(1)` fija aleatoriedad reproducible (para que tu experimento sea replicable).

# 2) Parámetros del modelo

`N = 5000:` número de hogares (1 agente = 1 hogar).

`Tmax = 36:` meses a simular.

`transfer_amount = 600:` monto nominal esperado.

`delay_prob_base = 0.30:` probabilidad de retraso (o sea, de no pago a tiempo).

`lambda_cred = 0.30:` qué tan rápido se ajusta la credibilidad con un promedio móvil (0=lento, 1=rapidísimo).

# 3) Construir el "mundo" y el estado inicial

`sim <- Simulation$new(N)` crea la simulación con IDs 1..N.

Estado principal del agente: "A" o "N".

Atributos por agente:

`theta:` umbral individual de decisión (heterogéneo, ~ Normal(300, 80)).

`cred:` credibilidad inicial = 1 − delay_prob_base (= 0.70).

**Seeding:** `seedA <- 10.` Los primeros 10 agentes arrancan asistiendo ("A") para no empezar con cero asistencia.

Bucle `for (i in 1:N):` para cada agente, se define theta, cred0 y el estado inicial; luego sim$setState(i, list(state0, theta=..., cred=...)).
Nota: en setState(...) el primer elemento de la lista siempre es el **estado**; lo demás son atributos.

# 4) Loggers (contadores automáticos)

`sim$addLogger(newCounter("A", "A")) y ("N","N")` crean dos columnas de salida que, en cada tick, cuentan cuántos están en A y cuántos en N.
Esto facilita luego calcular la proporción que asiste.

# 5) Dinámica mensual (el "handler" del tick)

- Qué es el handle que regresa `getAgent(sim, i):` Es una referencia al agente `i` que está dentro de `sim.` Con esa referencia puedes leer su estado `(getState(...))` y escribir cambios `(setState(...)).`

La función `tick_handler(time, sim, agent)` define qué pasa cada mes. Dentro:

**1. Recorres los N agentes** `(bucle for (i in 1:N)):`

- `ai <- getAgent(sim, i)` y st <- getState(ai) para leer estado y atributos actuales.

Beneficio esperado este mes: benefit = transfer_amount * st$cred.
(Si la credibilidad es alta, el monto “esperado” es más alto.)

Regla de decisión mínima:
new_state <- if (benefit >= st$theta) "A" else "N".
El hogar asiste si el beneficio esperado supera su umbral.

Realización del pago a tiempo (solo si decidió asistir):
paid_on_time <- (new_state == "A") && (runif(1) > delay_prob_base).
Es decir, tiras una moneda: con prob. 0.70 llega a tiempo; con 0.30 se retrasa.

Actualización de credibilidad (EMA/promedio móvil exponencial):
cred_new <- (1 - lambda_cred) * st$cred + lambda_cred*as.numeric(paid_on_time)

Si pagaron a tiempo (1), cred sube hacia 1.

Si se retrasó (0), cred baja hacia 0.

Importante: theta no cambia; es un rasgo fijo del hogar en este modelo.

Guardar nuevo estado y atributos:
setState(ai, list(new_state, theta = st$theta, cred = cred_new)).

Re-agendar el evento para el próximo mes (si time < Tmax):
schedule(agent, newEvent(time + 1, tick_handler)).
Así, el mismo handler se ejecuta en t=1,2,…,Tmax.
