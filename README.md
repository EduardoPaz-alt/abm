# 1) Preparación
   
## Paquete y semilla.
`library(ABM)` carga la mini-infraestructura de simulación (agentes, eventos, contadores).

`set.seed(1)` fija aleatoriedad reproducible (para que tu experimento sea replicable).

# 2) Parámetros del modelo

`N = 5000:` número de hogares (1 agente = 1 hogar).

`Tmax = 36:` meses a simular.

`transfer_amount = 600:` monto nominal esperado.

`delay_prob_base = 0.30:` probabilidad de retraso (o sea, de no pago a tiempo).

`lambda_cred = 0.30:` qué tan rápido se ajusta la credibilidad con un promedio móvil (0=lento, 1=rapidísimo).
