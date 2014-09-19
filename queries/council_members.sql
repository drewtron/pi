SELECT
  PERSON_ID,
  COUNCIL_MEMBER_ID,
  COALESCE(HIGH_VALUE_IND, 0),
  COALESCE(LEARNING_DEVELOPMENT_IND, 0),
  BIOGRAPHY,
  PHONE,
  MOBILE
FROM
  GLGLIVE.dbo.COUNCIL_MEMBER
WHERE
  BIOGRAPHY IS NOT NULL
