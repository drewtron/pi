SELECT QR.RESPONDENT_ID as PERSON_ID
        ,Q.QUESTION_ID
        ,COALESCE(Q.QUESTION_TEXT, ' ') AS QUESTION_TEXT
        ,QR.RESPONSE_DATE
        ,COALESCE(QR.COMMENT,' ') AS COMMENT
FROM GLGLIVE.dbo.QUESTION Q
JOIN GLGLIVE.dbo.QUESTION_RESPONSE QR
  ON Q.QUESTION_ID = QR.QUESTION_ID
WHERE QR.RESPONSE_VALUE = 'Yes'
AND COMMENT <> ' '