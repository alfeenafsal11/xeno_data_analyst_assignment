SELECT COUNT(*) AS total_initial_rows FROM communication_log;

SELECT * FROM communication_log t2
WHERE NOT EXISTS(
SELECT 1 FROM campaign t1
WHERE t1.id=t2.communication_id
AND (t1.creation_status!='approved' OR t1.processing_status!='processed'));

SELECT COUNT(*) AS remaining_rows_count
FROM communication_log t2
WHERE NOT EXISTS(
SELECT 1
FROM campaign t1
WHERE t1.id=t2.communication_id
AND (t1.creation_status!='approved' OR t1.processing_status!='processed'));

WITH RECURSIVE Minitable AS(
SELECT
c.id AS root_campaign_id,
c.id AS current_campaign_id,
cl.customer_id,
cl.communication_id AS current_communication_id
FROM communication_log cl
JOIN campaign c ON cl.communication_id=c.id
WHERE c.parent_id IS NULL OR c.parent_id=''
UNION ALL
SELECT
mt.root_campaign_id,
c_child.id,
cl_child.customer_id,
cl_child.communication_id
FROM Minitable mt
JOIN campaign c_child ON c_child.parent_id=mt.current_campaign_id
JOIN communication_log cl_child ON cl_child.communication_id=c_child.id
WHERE cl_child.customer_id=mt.customer_id
),
LatestRetries AS(
SELECT MAX(current_communication_id) AS final_communication_id
FROM Minitable
GROUP BY root_campaign_id, customer_id
)
SELECT COUNT(*) AS target_base_count
FROM LatestRetries;

WITH RECURSIVE TargetBase AS (
SELECT
cl.rowid AS root_row_id,
c.id AS current_campaign_id,
cl.customer_id,
cl.communication_id AS current_communication_id
FROM communication_log cl
JOIN campaign c ON cl.communication_id = c.id
WHERE c.parent_id IS NULL OR c.parent_id = ''
UNION ALL
SELECT
tb.root_row_id,
c_child.id,
cl_child.customer_id,
cl_child.communication_id
FROM TargetBase tb
JOIN campaign c_child ON c_child.parent_id = tb.current_campaign_id
JOIN communication_log cl_child ON cl_child.communication_id = c_child.id
WHERE cl_child.customer_id = tb.customer_id
),
LatestRetries AS (
SELECT MAX(current_communication_id) AS final_communication_id
FROM TargetBase
GROUP BY root_row_id
)
SELECT COUNT(*) AS total_target_rows
FROM LatestRetries;
