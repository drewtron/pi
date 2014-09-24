SELECT
  PERSON_ID, COUNT(*)
FROM
  GLGLIVE.dbo.PAYMENT p
  INNER JOIN GLGLIVE.dbo.COUNCIL_MEMBER cm on p.COUNCIL_MEMBER_ID = cm.COUNCIL_MEMBER_ID
WHERE
  PAID = 'Y'
  AND ACCEPTED = 'Y'
  AND cm.ACTIVE_IND = 1
  AND p.ACTIVE_IND = 1
  AND PAID_DATE IS NOT NULL
GROUP BY PERSON_ID
