-- ==============================================================================
-- PROYECTO: Viabilidad Financiera y Expansión de Servicios - Clínica Dr. Omar Panche
-- ARCHIVO: 01_limpieza_datos.sql
-- FASE 3 y 4: Limpieza Demográfica y Creación de Dimensiones (Star Schema)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. DIMENSIÓN PACIENTES (dim_pacientes)
-- Auditoría de nulos (COALESCE), cálculo de edad actual y segmentación etaria
-- ------------------------------------------------------------------------------
CREATE OR REPLACE TABLE `portfolio-clinica-513922.datos_clinicos.dim_pacientes` AS
SELECT DISTINCT
    patient AS patient_id,
    COALESCE(first, 'Sin Nombre') AS nombre,
    COALESCE(last, 'Sin Apellido') AS apellido,
    CONCAT(COALESCE(first, ''), ' ', COALESCE(last, '')) AS nombre_completo,
    COALESCE(gender, 'No especificado') AS genero,
    SAFE_CAST(birthdate AS DATE) AS fecha_nacimiento,
    DATE_DIFF(CURRENT_DATE(), SAFE_CAST(birthdate AS DATE), YEAR) AS edad_actual,
    CASE 
        WHEN DATE_DIFF(CURRENT_DATE(), SAFE_CAST(birthdate AS DATE), YEAR) < 30 THEN 'Joven (<30)'
        WHEN DATE_DIFF(CURRENT_DATE(), SAFE_CAST(birthdate AS DATE), YEAR) BETWEEN 30 AND 59 THEN 'Adulto (30-59)'
        ELSE 'Adulto Mayor (60+)'
    END AS segmento_edad,
    CASE 
        WHEN deathdate IS NULL THEN 'Activo'
        ELSE 'Fallecido'
    END AS estado_paciente
FROM 
    `portfolio-clinica-513922.datos_clinicos.pacientes`
WHERE 
    patient IS NOT NULL;


-- ------------------------------------------------------------------------------
-- 2. DIMENSIÓN CALENDARIO MAESTRA (dim_calendario)
-- Inteligencia de tiempo para análisis interanual y trimestral en Power BI
-- ------------------------------------------------------------------------------
CREATE OR REPLACE TABLE `portfolio-clinica-513922.datos_clinicos.dim_calendario` AS
SELECT DISTINCT
    fecha_procedimiento AS fecha,
    anio,
    mes,
    periodo_anio_mes,
    EXTRACT(QUARTER FROM fecha_procedimiento) AS trimestre,
    CONCAT('T', CAST(EXTRACT(QUARTER FROM fecha_procedimiento) AS STRING)) AS nombre_trimestre
FROM 
    `portfolio-clinica-513922.datos_clinicos.fact_finanzas_clinica`
WHERE 
    fecha_procedimiento IS NOT NULL
ORDER BY 
    fecha DESC;