SELECT
  cm.PERSON_ID,
  'hourly',
  COALESCE(cmr.RATE_AMOUNT, 0)
FROM
  GLGLIVE.dbo.COUNCIL_MEMBER_RATE cmr
  INNER JOIN GLGLIVE.dbo.COUNCIL_MEMBER cm ON cm.COUNCIL_MEMBER_ID = cmr.COUNCIL_MEMBER_ID
WHERE
  cmr.ACTIVE_IND = 1
  AND cmr.CURRENT_IND = 1
  AND cmr.PRODUCT_TYPE_ID = 3
  AND cmr.COUNCIL_MEMBER_ID > 0
UNION
SELECT
  cm.PERSON_ID,
  'expert',
  cmr.RATE_AMOUNT
FROM
  GLGLIVE.expert.COUNCIL_MEMBER_RATE cmr
  INNER JOIN GLGLIVE.dbo.COUNCIL_MEMBER cm ON cm.COUNCIL_MEMBER_ID = cmr.COUNCIL_MEMBER_ID
WHERE
  cmr.RATE_TYPE_ID = 5
