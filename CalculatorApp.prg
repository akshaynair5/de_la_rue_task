
//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// This is a standard console mode exe.
/// </summary>
///
/// <remarks>
/// </remarks>
///
/// <copyright>
/// Your-Company. All Rights Reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////

#include "Common.ch"

PROCEDURE InitHistoryDB()
   IF ! FILE("history.dbf")
      DbCreate("history", { ;
         { "ID",     "N", 8, 0 }, ;
         { "EXPR",   "C", 50, 0 }, ;
         { "RESULT", "N", 16, 5 } ;
      })
   ENDIF
   USE history EXCLUSIVE
   INDEX ON ID TO historyID
   USE
RETURN

FUNCTION ParseAndEval(cExpr)
   LOCAL nResult := 0
   LOCAL nOpPos := 0
   LOCAL cOp := ""
   LOCAL nLeft := 0
   LOCAL nRight := 0
   LOCAL cTmpExpr := ""
   LOCAL i := 0

   // Remove all spaces
   FOR i := 1 TO LEN(cExpr)
      IF SUBSTR(cExpr,i,1) # " "
         cTmpExpr += SUBSTR(cExpr,i,1)
      ENDIF
   NEXT
   cExpr := cTmpExpr

   // Find operator and operands
   FOR i := 2 TO LEN(cExpr)-1
      cOp := SUBSTR(cExpr,i,1)
      IF cOp $ "+-*/"
         nOpPos := i
         EXIT
      ENDIF
   NEXT

   IF nOpPos == 0
      BREAK  // Triggers error handler in calling sequence
   ENDIF

   nLeft := VAL(LEFT(cExpr, nOpPos-1))
   nRight := VAL(SUBSTR(cExpr, nOpPos+1))

   DO CASE
      CASE cOp == "+"
         nResult := nLeft + nRight
      CASE cOp == "-"
         nResult := nLeft - nRight
      CASE cOp == "*"
         nResult := nLeft * nRight
      CASE cOp == "/"
         IF nRight != 0
            nResult := nLeft / nRight
         ELSE
            BREAK  // Zero division, triggers error handler
         ENDIF
      OTHERWISE
         BREAK  // Should never happen, just in case
   ENDCASE

RETURN nResult

PROCEDURE Main()
   LOCAL cExpr := ""
   LOCAL nResult := 0
   LOCAL oError
   LOCAL nID

   SET CONFIRM ON
   SET ESCAPE OFF
   SET TALK OFF
   SET SCOREBOARD OFF

   InitHistoryDB()
   USE history EXCLUSIVE

   DO WHILE .T.
      CLS
      @ 1,1 SAY "Simple XBase++ Calculator"
      @ 3,1 SAY "Enter expression (e.g., 5+3, 10 / 2, -5 * 3) or 'exit' to quit:"
      cExpr := SPACE(50)
      @ 4,1 GET cExpr PICTURE "@S50"
      READ

      cExpr := RTRIM(LTRIM(cExpr))
      IF LOWER(cExpr) == "exit"
         EXIT
      ENDIF

      @ 5,1 SAY "You entered: " + cExpr

      BEGIN SEQUENCE
         nResult := ParseAndEval(cExpr)
         @ 6,1 SAY "Result: " + LTRIM(STR(nResult, 16, 5))
         // Get next ID (auto-increment)
         IF RECCOUNT() > 0
            GOTO BOTTOM
            nID := ID + 1
         ELSE
            nID := 1
         ENDIF
         SaveHistory(nID, cExpr, nResult)
      RECOVER USING oError
         @ 6,1 SAY "Invalid expression. Press any key..."
         INKEY(0)
         LOOP
      END SEQUENCE

      @ 8,1 SAY "Calculation History:"
      ShowHistory()

      @ 23,1 SAY "Press any key for next calculation..."
      INKEY(0)
   ENDDO

   USE
   CLOSE DATABASES
RETURN

PROCEDURE SaveHistory(nID, cExpr, nResult)
   APPEND BLANK
   REPLACE ID     WITH nID
   REPLACE EXPR   WITH cExpr
   REPLACE RESULT WITH nResult
RETURN

PROCEDURE ShowHistory()
   LOCAL nRow := 10
   LOCAL nCur := RECNO()

   GOTO TOP
   DO WHILE !EOF() .AND. nRow <= 20
      @ nRow,1 SAY STR(ID,5) + ". " + PADR(EXPR,30) + " = " + STR(RESULT,14,5)
      SKIP
      nRow++
   ENDDO
   IF nCur > 0 .AND. nCur <= RECCOUNT()
      GOTO nCur
   ENDIF
RETURN
