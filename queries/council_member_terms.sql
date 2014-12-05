SELECT
  PERSON_ID,
  CASE
    WHEN EXPIRATION_DATE > GETDATE() THEN 1
    ELSE 0
  END TERMS_SIGNED
FROM (
  --CMs who've signed something at one point or another
	SELECT
	  P.PERSON_ID,
	  MAX(EXPIRATION_DATE) EXPIRATION_DATE
	FROM GLGLIVE.dbo.TERMS_CONDITIONS_SIGNED TCS
	JOIN GLGLIVE.dbo.COUNCIL_MEMBER CM ON CM.COUNCIL_MEMBER_ID = TCS.COUNCIL_MEMBER_ID
	JOIN GLGLIVE.dbo.PERSON P ON P.PERSON_ID = CM.PERSON_ID
  GROUP BY P.PERSON_ID

	UNION

  --CMs who've never signed a TCs to begin with
	SELECT
	  PERSON_ID,
	  NULL
	FROM GLGLIVE.dbo.COUNCIL_MEMBER
	WHERE PERSON_ID NOT IN (
      SELECT P.PERSON_ID
      FROM GLGLIVE.dbo.TERMS_CONDITIONS_SIGNED TCS
      JOIN GLGLIVE.dbo.COUNCIL_MEMBER CM ON CM.COUNCIL_MEMBER_ID = TCS.COUNCIL_MEMBER_ID
      JOIN GLGLIVE.dbo.PERSON P ON P.PERSON_ID = CM.PERSON_ID
    )
) A