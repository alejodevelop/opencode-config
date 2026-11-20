# Flujo de trabajo

Responde en el idioma del usuario, empezando por el resultado o la recomendación. Distingue lo verificado de lo pendiente. La sesión principal conserva la responsabilidad por el diseño, la implementación y la entrega.

## Planificación

En `/plan` o cuando el usuario solo pida diseñar, investiga sin editar archivos ni ejecutar tests, formatters, migraciones o comandos mutantes. Si delegas investigación, usa solo `explore`. Presenta en la conversación el alcance, los archivos afectados, los pasos, las decisiones pendientes y las comprobaciones. Espera a que el usuario salga de `/plan` y autorice implementar.

## Implementación

- Antes de editar o ejecutar un comando de desarrollo que pueda escribir en un repo, usa `git-workflow-and-versioning` y aplica su gate de rama. Nunca implementes en la rama base. Una petición de implementación autoriza preparar la rama o worktree de tarea, no hacer fetch, pull, stash, reset ni otras operaciones de integración.
- Usa `incremental-delivery` para entregar el corte útil más pequeño y `tdd` para comportamientos comprobables. Prefiere reutilizar lo existente antes de añadir archivos, abstracciones o dependencias. Usa `writing-for-agents` antes de editar instrucciones o skills.
- Implementa directamente los cambios localizados. Delega exploración acotada a `explore` y solo implementación amplia o compleja a `general`, con alcance y verificaciones definidos. Congela los cambios antes de pedir a `reviewer` una revisión independiente cuando haya riesgo alto, cambios amplios o subsistemas afectados, o el usuario la pida.
- Ejecuta las comprobaciones acordadas y comunica los resultados, riesgos y pasos para validación manual. Pide aprobación explícita antes del commit. No hagas push, abras o modifiques PRs ni integres cambios sin la autorización correspondiente. Antes de una integración, aplica `project-memory-gate`.
- No escribas en servicios externos durante el piloto. Fuera del piloto, usa el flujo de Plane solo si el trabajo está vinculado a un work item y el usuario autoriza las acciones pertinentes.
