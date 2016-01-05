CREATE OR REPLACE PACKAGE dz_sdotxt_util
AUTHID CURRENT_USER
AS
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION downsize_2d(
      p_input       IN  MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION downsize_2dM(
      p_input       IN  MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION downsize_3d(
      p_input       IN  MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION indent(
       p_level      IN  NUMBER
      ,p_amount     IN  VARCHAR2 DEFAULT '   '
   ) RETURN VARCHAR2;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION pretty(
       p_input      IN  CLOB
      ,p_level      IN  NUMBER
      ,p_amount     IN  VARCHAR2 DEFAULT '   '
      ,p_linefeed   IN  VARCHAR2 DEFAULT CHR(10)
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION blob2clob(
       p_input      IN  BLOB
      ,p_decompress IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION clob2blob(
       p_input      IN  CLOB
      ,p_compress   IN  VARCHAR2 DEFAULT 'FALSE' 
      ,p_comp_qual  IN  NUMBER   DEFAULT 6   
   ) RETURN BLOB;
   
END dz_sdotxt_util;
/

GRANT EXECUTE ON dz_sdotxt_util TO PUBLIC;

