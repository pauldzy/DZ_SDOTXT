CREATE OR REPLACE TYPE dz_sdotxt_labeled FORCE
AUTHID CURRENT_USER
AS OBJECT (
    shape_label         VARCHAR2(4000 Char)
   ,shape               MDSYS.SDO_GEOMETRY
    
   ,CONSTRUCTOR FUNCTION dz_sdotxt_labeled
    RETURN SELF AS RESULT

);
/

GRANT EXECUTE ON dz_sdotxt_labeled TO public;

