-- ==============================================================================
-- PROYECTO: Viabilidad Financiera y Expansión de Servicios - Clínica Dr. Omar Panche
-- ARCHIVO: 02_transformacion_financiera.sql
-- FASE 3: Transformación con CTEs (WITH), LEFT JOIN y Tabla de Hechos P&L
-- ==============================================================================

CREATE OR REPLACE TABLE `portfolio-clinica-513922.datos_clinicos.fact_finanzas_clinica` AS

WITH procedimientos_limpios AS (
    -- 1. Auditoría, limpieza de nulos (COALESCE) y estandarización de fechas
    SELECT DISTINCT
        SAFE_CAST(DATE AS DATE) AS fecha_procedimiento,
        PATIENT AS patient_id,
        ENCOUNTER AS encounter_id,
        CODE AS codigo_procedimiento,
        COALESCE(DESCRIPTION, 'Procedimiento no especificado') AS descripcion_tratamiento,
        COALESCE(REASONDESCRIPTION, 'Diagnóstico general / Preventivo') AS motivo_consulta
    FROM 
        `portfolio-clinica-513922.datos_clinicos.procedimientos`
    WHERE 
        PATIENT IS NOT NULL 
        AND DESCRIPTION IS NOT NULL
),

resumen_encuentros AS (
    -- 2. Agrupación por encuentro clínico para validar el volumen por cita médica
    SELECT 
        ENCOUNTER AS encounter_id,
        COUNT(*) AS total_procedimientos_en_cita
    FROM 
        `portfolio-clinica-513922.datos_clinicos.procedimientos`
    WHERE 
        ENCOUNTER IS NOT NULL
    GROUP BY 
        ENCOUNTER
),

modelo_financiero AS (
    -- 3. Cruce relacional (LEFT JOIN) e imputación de P&L (Ingresos, Costos y Categoría)
    SELECT 
        p.fecha_procedimiento,
        EXTRACT(YEAR FROM p.fecha_procedimiento) AS anio,
        EXTRACT(MONTH FROM p.fecha_procedimiento) AS mes,
        FORMAT_DATE('%Y-%m', p.fecha_procedimiento) AS periodo_anio_mes,
        p.patient_id,
        p.encounter_id,
        COALESCE(e.total_procedimientos_en_cita, 1) AS procedimientos_por_cita,
        p.descripcion_tratamiento,
        p.motivo_consulta,

        -- Clasificación en las dos líneas estratégicas del negocio
        CASE 
            WHEN UPPER(p.descripcion_tratamiento) LIKE '%THERAPY%' 
              OR UPPER(p.descripcion_tratamiento) LIKE '%INJECTION%'
              OR UPPER(p.descripcion_tratamiento) LIKE '%MAGNETIC RESONANCE%'
              OR UPPER(p.descripcion_tratamiento) LIKE '%ULTRASOUND%'
              OR UPPER(p.descripcion_tratamiento) LIKE '%CT SCAN%'
              OR UPPER(p.motivo_consulta) LIKE '%PAIN%'
            THEN 'Manejo del Dolor Crónico'
            ELSE 'Consulta y Plan Nutricional'
        END AS linea_servicio,

        -- Ingresos Estimados (USD)
        CASE 
            WHEN UPPER(p.descripcion_tratamiento) LIKE '%MAGNETIC RESONANCE%' THEN 300.00
            WHEN UPPER(p.descripcion_tratamiento) LIKE '%CT SCAN%' THEN 200.00
            WHEN UPPER(p.descripcion_tratamiento) LIKE '%ULTRASOUND%' THEN 120.00
            WHEN UPPER(p.descripcion_tratamiento) LIKE '%THERAPY%' THEN 85.00
            WHEN UPPER(p.descripcion_tratamiento) LIKE '%INJECTION%' THEN 65.00
            WHEN UPPER(p.descripcion_tratamiento) LIKE '%CONSULTATION%' THEN 60.00
            ELSE 75.00
        END AS ingreso_estimado_usd,

        -- Costos Operativos y de Tratamiento (USD)
        CASE 
            WHEN UPPER(p.descripcion_tratamiento) LIKE '%MAGNETIC RESONANCE%' THEN 135.00
            WHEN UPPER(p.descripcion_tratamiento) LIKE '%CT SCAN%' THEN 90.00
            WHEN UPPER(p.descripcion_tratamiento) LIKE '%ULTRASOUND%' THEN 40.00
            WHEN UPPER(p.descripcion_tratamiento) LIKE '%THERAPY%' THEN 25.00
            WHEN UPPER(p.descripcion_tratamiento) LIKE '%INJECTION%' THEN 18.00
            WHEN UPPER(p.descripcion_tratamiento) LIKE '%CONSULTATION%' THEN 15.00
            ELSE 22.00
        END AS costo_operativo_usd

    FROM 
        procedimientos_limpios p
    LEFT JOIN 
        resumen_encuentros e 
        ON p.encounter_id = e.encounter_id
)

-- 4. Consolidación de la Tabla de Hechos (Fact Table) con Márgenes y CAC
SELECT 
    *,
    ROUND(ingreso_estimado_usd - costo_operativo_usd, 2) AS margen_beneficio_usd,
    ROUND(SAFE_DIVIDE(ingreso_estimado_usd - costo_operativo_usd, ingreso_estimado_usd) * 100, 2) AS margen_porcentual,
    -- Costo de Adquisición de Paciente (CAC) estimado según línea de servicio
    CASE 
        WHEN linea_servicio = 'Manejo del Dolor Crónico' THEN 35.00
        ELSE 20.00
    END AS cac_estimado_usd
FROM 
    modelo_financiero
ORDER BY 
    fecha_procedimiento DESC;