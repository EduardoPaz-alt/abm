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
