-- Fase 3: Imputación de Costos Financieros (Procedimientos)
-- Objetivo: Simular costos de tratamientos usando lógica de negocio para análisis de rentabilidad.

SELECT 
    DATE AS fecha_procedimiento,
    PATIENT AS patient_id,
    ENCOUNTER AS encounter_id,
    DESCRIPTION AS descripcion_tratamiento,
    CASE 
        -- Nuevos términos adaptados a lo que realmente hay en tus datos:
        WHEN UPPER(DESCRIPTION) LIKE '%MAGNETIC RESONANCE%' THEN 300.00
        WHEN UPPER(DESCRIPTION) LIKE '%CT SCAN%' THEN 200.00
        WHEN UPPER(DESCRIPTION) LIKE '%ULTRASOUND%' THEN 120.00
        WHEN UPPER(DESCRIPTION) LIKE '%THERAPY%' THEN 80.00
        WHEN UPPER(DESCRIPTION) LIKE '%INJECTION%' THEN 45.00
        WHEN UPPER(DESCRIPTION) LIKE '%CONSULTATION%' THEN 60.00
        ELSE 100.00 
    END AS ingreso_estimado_usd
FROM 
    `portfolio-clinica-513922.datos_clinicos.procedimientos`
WHERE 
    DESCRIPTION IS NOT NULL
ORDER BY 
    ingreso_estimado_usd DESC;