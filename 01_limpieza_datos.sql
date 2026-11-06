-- Fase 3: Limpieza y Transformación de Datos Clínicos (Pacientes)
-- Objetivo: Estandarizar nombres, calcular edad y eliminar registros con nulos.

SELECT 
    patient AS patient_id,
    UPPER(last) AS apellido_paciente,
    INITCAP(first) AS nombre_paciente,
    gender AS genero,
    birthdate AS fecha_nacimiento,
    -- Calculamos la edad directamente con la fecha de nacimiento:
    DATE_DIFF(CURRENT_DATE(), birthdate, YEAR) AS edad
FROM 
    `portfolio-clinica-513922.datos_clinicos.pacientes`
WHERE 
    first IS NOT NULL 
    AND last IS NOT NULL;