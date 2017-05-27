CREATE OR REPLACE TYPE dz_sdotxt_dumper FORCE
AUTHID CURRENT_USER
AS OBJECT (
    str_cursor  CLOB
   ,dummy       INTEGER
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_sdotxt_dumper(
      p_input      IN  CLOB
    )
    RETURN SELF AS RESULT
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,MEMBER FUNCTION sql_inserts(
      p_table_name  IN  VARCHAR2
    )
    RETURN CLOB
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,MEMBER FUNCTION plsql_inserts(
      p_table_name  IN  VARCHAR2
    )
    RETURN CLOB

);
/

GRANT EXECUTE ON dz_sdotxt_dumper TO public;

