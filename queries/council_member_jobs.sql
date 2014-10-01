SELECT
PERSON_ID,
jfr.COUNCIL_MEMBER_JOB_FUNCTION_RELATION_ID,
jfr.COMPANY,
jfr.COMPANY_ID,
COALESCE(TITLE, " "),
COALESCE(START_YEAR, "-"),
COALESCE(START_MONTH, "-"),
COALESCE(END_YEAR, "-"),
COALESCE(END_MONTH, "-"),
COALESCE(CURRENT_IND, 0),
COALESCE(s.FULL_PATH, "") as SECTOR,
COALESCE(jf.FULL_PATH, "") as JOB_FUNCTION
FROM
  GLGLIVE.dbo.COUNCIL_MEMBER_JOB_FUNCTION_RELATION jfr
  LEFT JOIN GLGLIVE.taxonomy.JOB_FUNCTION jf ON jfr.JOB_FUNCTION_ID = jf.ID
  LEFT JOIN GLGLIVE.taxonomy.SECTOR s ON jfr.SECTOR_ID = s.id
  INNER JOIN GLGLIVE.dbo.COUNCIL_MEMBER cm ON cm.COUNCIL_MEMBER_ID = jfr.COUNCIL_MEMBER_ID
WHERE
  PERSON_ID > 0
  and CM.ACTIVE_IND = 1