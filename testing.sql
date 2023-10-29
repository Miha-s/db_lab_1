CALL update_employee_position(1, 3);

CALL update_employee_skills(1, 1, 2);

DO $$
DECLARE
    total_rewards_count integer;
BEGIN
    CALL calculate_total_rewards(1, total_rewards_count);
    RAISE NOTICE 'Total Rewards Count: %', total_rewards_count;
END;
$$;
