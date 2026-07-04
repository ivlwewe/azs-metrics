WITH normalized_fuel AS (
    -- Нормализуем типы топлива, чтобы «АИ‑92», «АИ92», «92» стали единым кодом
    SELECT
        date,
        fuel_type,
        CASE
            WHEN fuel_type ILIKE '%92%' OR fuel_type ILIKE '%АИ‑92%' THEN 'AI92'
            WHEN fuel_type ILIKE '%95%' OR fuel_type ILIKE '%АИ‑95%' THEN 'AI95'
            WHEN fuel_type ILIKE '%ДТ%' OR fuel_type ILIKE '%дизель%' THEN 'DT'
            ELSE 'OTHER'
        END AS fuel_code,
        volume_liters
    FROM deliveries
),
meter_usage AS (
    -- Считаем объём реализации по счётчикам
    SELECT
        date,
        fuel_code,
        SUM(meter_end - meter_start) AS sold_liters
    FROM meters
    GROUP BY date, fuel_code
),
daily_balance AS (
    -- Сводим приход и расход по дням
    SELECT
        d.date,
        d.fuel_code,
        COALESCE(d.volume_liters, 0) AS delivered_liters,
        COALESCE(m.sold_liters, 0) AS sold_liters,
        (COALESCE(d.volume_liters, 0) - COALESCE(m.sold_liters, 0)) AS discrepancy_liters
    FROM normalized_fuel d
    LEFT JOIN meter_usage m
        ON d.date = m.date AND d.fuel_code = m.fuel_code
)
SELECT
    date,
    fuel_code,
    delivered_liters,
    sold_liters,
    discrepancy_liters,
    CASE
        WHEN delivered_liters > 0 THEN ROUND((discrepancy_liters * 100.0 / delivered_liters), 2)
        ELSE NULL
    END AS discrepancy_rate_pct
FROM daily_balance
ORDER BY date, fuel_code;
