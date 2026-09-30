# HU-AL-02: Escanear el código QR de una computadora

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Alumno |
| **Plataforma** | Móvil |
| **Prioridad** | Alta |
| **Origen** | Documento |
| **Iteración sugerida** | Iteración 2 |
| **Dependencias** | `HU-AL-01` |

---

### Narrativa (Card)
**Como** alumno,  
**quiero** escanear con la cámara de mi teléfono el código QR de una computadora,  
**para** identificar el equipo que voy a utilizar sin capturar datos manualmente.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] La aplicación solicita permiso de cámara; si se niega, explica cómo habilitarlo.
- [ ] Al leer un QR válido se muestra el equipo identificado (identificador y laboratorio).
- [ ] Un QR que no pertenece al sistema muestra un mensaje claro y permite reintentar.
- [ ] Si el equipo está dado de baja, se informa y no se permite continuar.
- [ ] El escaneo responde en pocos segundos con iluminación normal.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Integrar paquete de lectura QR en la app móvil.
- [ ] Implementar manejo de permisos de cámara en tiempo de ejecución.
- [ ] Conectar el escaneo con el endpoint de validación de equipo.
- [ ] Escribir pruebas unitarias y de widgets/UI.
