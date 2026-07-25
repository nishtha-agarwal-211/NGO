-- Migration: Server-side birthday and anniversary filtering
-- Replaces client-side Dart filtering with efficient Postgres queries
-- using day-of-year arithmetic with year-boundary wraparound.

-- Get active members whose birthday falls within the next N days.
CREATE OR REPLACE FUNCTION get_upcoming_birthdays(within_days int DEFAULT 7)
RETURNS SETOF members
LANGUAGE sql STABLE
AS $$
  SELECT *
  FROM members
  WHERE is_active = true
    AND date_of_birth IS NOT NULL
    AND (
      -- Normal case: current doy + within_days doesn't cross year boundary
      (
        EXTRACT(DOY FROM date_of_birth)
          BETWEEN EXTRACT(DOY FROM CURRENT_DATE)
              AND EXTRACT(DOY FROM CURRENT_DATE) + within_days
      )
      OR
      -- Wraparound case: e.g. Dec 28 looking 7 days ahead into Jan
      (
        EXTRACT(DOY FROM CURRENT_DATE) + within_days > 365
        AND EXTRACT(DOY FROM date_of_birth)
              <= (EXTRACT(DOY FROM CURRENT_DATE) + within_days) - 365
      )
    )
  ORDER BY
    CASE
      WHEN EXTRACT(DOY FROM date_of_birth) >= EXTRACT(DOY FROM CURRENT_DATE)
      THEN EXTRACT(DOY FROM date_of_birth) - EXTRACT(DOY FROM CURRENT_DATE)
      ELSE 365 - EXTRACT(DOY FROM CURRENT_DATE) + EXTRACT(DOY FROM date_of_birth)
    END;
$$;

-- Get active members whose wedding anniversary falls within the next N days.
CREATE OR REPLACE FUNCTION get_upcoming_anniversaries(within_days int DEFAULT 7)
RETURNS SETOF members
LANGUAGE sql STABLE
AS $$
  SELECT *
  FROM members
  WHERE is_active = true
    AND wedding_anniversary IS NOT NULL
    AND (
      (
        EXTRACT(DOY FROM wedding_anniversary)
          BETWEEN EXTRACT(DOY FROM CURRENT_DATE)
              AND EXTRACT(DOY FROM CURRENT_DATE) + within_days
      )
      OR
      (
        EXTRACT(DOY FROM CURRENT_DATE) + within_days > 365
        AND EXTRACT(DOY FROM wedding_anniversary)
              <= (EXTRACT(DOY FROM CURRENT_DATE) + within_days) - 365
      )
    )
  ORDER BY
    CASE
      WHEN EXTRACT(DOY FROM wedding_anniversary) >= EXTRACT(DOY FROM CURRENT_DATE)
      THEN EXTRACT(DOY FROM wedding_anniversary) - EXTRACT(DOY FROM CURRENT_DATE)
      ELSE 365 - EXTRACT(DOY FROM CURRENT_DATE) + EXTRACT(DOY FROM wedding_anniversary)
    END;
$$;
