ALTER TABLE alert_rate.reference_rate
    DROP COLUMN IF EXISTS reference_person_daily_liters;

ALTER TABLE alert_rate.reference_rate
    DROP COLUMN IF EXISTS reference_people_count;

ALTER TABLE home.home
    DROP CONSTRAINT IF EXISTS ck_home_people_count;

ALTER TABLE home.home
    DROP COLUMN IF EXISTS people_count;
