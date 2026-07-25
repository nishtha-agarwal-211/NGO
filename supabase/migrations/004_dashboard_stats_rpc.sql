-- Migration: Consolidated dashboard statistics RPC
-- Returns all scalar dashboard stats in a single round-trip instead of 5+
-- separate queries.

CREATE OR REPLACE FUNCTION get_dashboard_stats()
RETURNS json
LANGUAGE sql STABLE
AS $$
  SELECT json_build_object(
    'member_count',       (SELECT count(*) FROM members WHERE is_active = true),
    'donor_count',        (SELECT count(*) FROM donors),
    'active_project_count', (SELECT count(*) FROM projects WHERE status = 'active'),
    'this_month_events',  (SELECT count(*) FROM events
                           WHERE event_date >= date_trunc('month', CURRENT_DATE)),
    'total_donations',    (SELECT coalesce(sum(amount), 0)
                           FROM donations
                           WHERE donation_type = 'cash')
  );
$$;
