# Proyecto Account Reconciliation en Node.js

Este es un proyecto básico en Node.js que sirve para cargar el listado de usuarios en la máquinas de producción a Share Point.

## Cómo ejecutar

1. Ejecutar el script pasando los parámetros necesarios.
2. La ejecución del Job desencadena lo siguiente:
   - Ingresa al NFS de Rundeck.
   - Genera un archivo CSV con el listado de usuarios.
   - Carga el listado a share point.
