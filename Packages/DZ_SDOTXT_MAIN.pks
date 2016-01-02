CREATE OR REPLACE PACKAGE dz_sdotxt_main
AUTHID CURRENT_USER
AS
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   header: DZ_SDOTXT
     
   - Build ID: DZBUILDIDDZ
   - TFS Change Set: DZTFSCHANGESETDZ
   
   Utilities for the conversion and inspection of Oracle Spatial objects as 
   text.
   
   Generally there are few reasons for you to want to manifest Oracle Spatial 
   objects as SQL text. So you should only be using this code if you need to 
   generate an example for an OTN posting or Oracle SR, or if you are exchanging 
   a very modest amount of data with a colleague who has limited access to 
   Oracle. Overwhelmingly the proper way to exchange Oracle data is via datapump.

   See the DZ_TESTDATA project as an example of what this module can do.
   
   */
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_sdotxt_main.sdo2sql

   Utility to convert an Oracle Spatial object into text format.

   Parameters:

      p_input - object to convert to text format
      p_2d_flag - optional TRUE/FALSE flag to remove any third or fourth 
      dimensions on geometries before text conversion.
      p_output_srid - optional srid to transform geometries to before text 
      conversion.
      p_pretty_print - optional pretty print indent value
      
   Returns:

      CLOB text value representing an Oracle Spatial object.
      
   Notes:
   
   - Input objects may include MDSYS.SDO_GEOMETRY, MDSYS.SDO_GEOMETRY_ARRAY,
     MDSYS.SDO_POINT_TYPE, MDSYS.SDO_ELEM_INFO_ARRAY, MDSYS.SDO_ORDINATE_ARRAY,
     MDSYS.SDO_GEORASTER, MDSYS.SDO_RASTER and MDSYS.SDO_DIM_ARRAY.
     
   - Note that Oracle is not PostgreSQL or other database systems where large
     objects can be comfortably dumped to text.  Attempting to dump a 300,000 
     vertice geometry is going to fail, attempting to dump a 70 gig raster rdt 
     table is going to fail, attempting to feed more than a few meg
     of generated text data back through sqlplus is also going to fail.  These 
     utilities are provided for very modest purposes primarily to inspect the  
     details of small example spatial objects or package up one or two smaller 
     sized objects for transport via text to a collaborator.  In all situations 
     the use of Oracle datapump to import and export spatial data is the way to 
     go.

   */
   FUNCTION sdo2sql(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'FALSE'
      ,p_output_srid      IN  NUMBER   DEFAULT NULL
      ,p_pretty_print     IN  NUMBER   DEFAULT 0
   ) RETURN CLOB;
   
   FUNCTION sdo2sql(
       p_input            IN  MDSYS.SDO_GEOMETRY_ARRAY
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'FALSE'
      ,p_output_srid      IN  NUMBER   DEFAULT NULL
      ,p_pretty_print     IN  NUMBER   DEFAULT 0
   ) RETURN CLOB;

   FUNCTION sdo2sql(
       p_input            IN  MDSYS.SDO_POINT_TYPE
      ,p_pretty_print     IN  NUMBER   DEFAULT 0
   ) RETURN CLOB;
   
   FUNCTION sdo2sql(
       p_input            IN  MDSYS.SDO_ELEM_INFO_ARRAY
      ,p_pretty_print     IN  NUMBER   DEFAULT 0
   ) RETURN CLOB;

   FUNCTION sdo2sql(
       p_input            IN  MDSYS.SDO_ORDINATE_ARRAY
      ,p_pretty_print     IN  NUMBER   DEFAULT 0
   ) RETURN CLOB;

   FUNCTION sdo2sql(
       p_input            IN  MDSYS.SDO_DIM_ARRAY
      ,p_pretty_print     IN  NUMBER   DEFAULT 0
   ) RETURN CLOB;
   
   -- Note if the package fails to compile in Oracle 12c due to the Georaster
   -- object below, then either comment out this function in both spec and body
   -- or activate the Georaster object as detailed at
   -- https://docs.oracle.com/database/121/GEORS/release_changes.htm#GEORS1382
   FUNCTION sdo2sql(
       p_input            IN  MDSYS.SDO_GEORASTER
      ,p_pretty_print     IN  NUMBER   DEFAULT 0
   ) RETURN CLOB;
   
   FUNCTION sdo2sql(
       p_input            IN  MDSYS.SDO_RASTER
      ,p_pretty_print     IN  NUMBER DEFAULT 0
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_sdotxt_main.sdo2sql_nvl

   Utility to convert an Oracle Spatial object into text format with an NVL 
   option to return a given output when input is NULL.

   Parameters:

      p_input - MDSYS.SDO_GEOMETRY to convert to text format.
      p_is_null - value to return if input object is NULL.
      p_2d_flag - optional TRUE/FALSE flag to remove any third or fourth 
      dimensions on geometry before text conversion.
      p_output_srid - optional srid to transform geometry to before text 
      conversion.
      p_pretty_print - optional pretty print indent value
      
   Returns:

      CLOB text value representing an Oracle Spatial object.

   */
   FUNCTION sdo2sql_nvl(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_is_null          IN  CLOB
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'FALSE'
      ,p_output_srid      IN  NUMBER   DEFAULT NULL
      ,p_pretty_print     IN  NUMBER   DEFAULT 0
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_sdotxt_main.blob2sql

   Utility to convert a blob into textual hex usable as a right side assignment
   in SQL or PLSQL.  In order to use the results in SQL this is greatly limited 
   to 4000 characters and in PLSQL to 32676 characters which when dumping a 
   BLOB is pretty limiting.  Use blob2plsql for a more scaleable work-around.

   Parameters:

      p_input - BLOB to convert to sql text.
      
   Returns:

      CLOB result.

   */
   FUNCTION blob2sql(
       p_input        IN  BLOB
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_sdotxt_main.blob2plsql

   Utility to convert a blob into textual hex usable as a series of DBMS_LOB
   statements which can be then be combined and used as a bind variable in 
   PLSQL dynamic SQL statememts.

   Parameters:

      p_input - BLOB to convert to sql text.
      p_lob_name - the lob variable name in the statements, default is dz_lob.
      Use different names if you are dumping multiple blobs.
      p_delim_value - the delimiter to place at the end of each statement, the 
      default is a line feed to make sqlplus happy.  Set to NULL if you want no
      linefeeds.
      
   Returns:

      CLOB result.

   */
   FUNCTION blob2plsql(
       p_input        IN  BLOB
      ,p_lob_name     IN  VARCHAR2 DEFAULT 'dz_lob'
      ,p_delim_value  IN  VARCHAR2 DEFAULT CHR(10)
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_sdotxt_main.dump_string_endpoints

   Utility to convert to text the ordinates of the endpoints of a given linestring.

   Parameters:

      p_input - MDSYS.SDO_GEOMETRY to convert endpoints to ordinates as text.
      
   Returns:

      VARCHAR2 text value showing the ordinates of the endpoints of a linestring.

   */
   FUNCTION dump_string_endpoints(
      p_input             IN  MDSYS.SDO_GEOMETRY
   ) RETURN VARCHAR2;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_sdotxt_main.dump_string_endpoints

   Utility to convert to text the ordinates of the endpoints of two linestrings.

   Parameters:

      p_input_1 - MDSYS.SDO_GEOMETRY convert endpoints to ordinates as text.
      p_input_2 - MDSYS.SDO_GEOMETRY convert endpoints to ordinates as text.
      
   Returns:

      VARCHAR2 text value showing the ordinates of the endpoints of two 
      linestrings.

   */
   FUNCTION dump_string_endpoints(
       p_input_1          IN  MDSYS.SDO_GEOMETRY
      ,p_input_2          IN  MDSYS.SDO_GEOMETRY
   ) RETURN VARCHAR2;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_sdotxt_main.dump_sdo_subelements

   Utility to convert to text the component objects of a geometry collection.

   Parameters:

      p_input - MDSYS.SDO_GEOMETRY collection to convert to text as individual
      objects.
      
   Returns:

      CLOB text value of the individual components.

   */
   FUNCTION dump_sdo_subelements(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_indent           IN  VARCHAR2 DEFAULT ''
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_sdotxt_main.dump_single_point_ordinate

   Utility to extract a given ordinate from within a MDSYS.SDO_GEOMETRY.

   Parameters:

      p_input - MDSYS.SDO_GEOMETRY from which to extract a given ordinate.
      p_vertice_type - Either X, Y, Z or M.
      p_vertice_position - vertice position in the geometry, default is 1.
      
   Returns:

      NUMBER value of the ordinate.

   */
   FUNCTION dump_single_point_ordinate(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_vertice_type     IN  VARCHAR2
      ,p_vertice_position IN  NUMBER DEFAULT 1
   ) RETURN NUMBER;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_sdotxt_main.dump_mbr

   Utility to convert to text the MBR surrounding a given geometry object.

   Parameters:

      p_input - MDSYS.SDO_GEOMETRY to which derive the MBR to dump to text.
      
   Returns:

      VARCHAR2 text value of the converted MBR.

   */
   FUNCTION dump_mbr(
      p_input            IN  MDSYS.SDO_GEOMETRY
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_sdotxt_main.label_ordinates

   Utility to converts all vertices in a geometry into a pipelined flow of
   points labelled by vertice number.

   Parameters:

      p_input - MDSYS.SDO_GEOMETRY to convert to labeled points.
      
   Returns:

      PIPELINED table of dz_sdotxt_labeled objects.

   */
   FUNCTION label_ordinates(
      p_input           IN  MDSYS.SDO_GEOMETRY
   ) RETURN dz_sdotxt_labeled_list PIPELINED;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_sdotxt_main.label_measures

   Utility to converts all vertices in a geometry into a pipelined flow of
   points labelled by LRS measure value.

   Parameters:

      p_input - MDSYS.SDO_GEOMETRY to convert to labeled points.
      
   Returns:

      PIPELINED table of dz_sdotxt_labeled objects.

   */
   FUNCTION label_measures(
      p_input           IN  MDSYS.SDO_GEOMETRY
   ) RETURN dz_sdotxt_labeled_list PIPELINED;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_sdotxt_main.break_2499

   Utility to take a very long sdo text representation and add linefeeds to
   meet the sqlplus 2499 character length restrictions.

   Parameters:

      p_input - CLOB of sdo object representation.
      p_delim_character - delimiter to add to input, default is linefeed chr(10).
      p_break_character - character upon which to add a delimiter, default is
      comma.
      p_break_point - character count near which to add delimiters, default is
      sqlplus 2499 limit.
      
   Returns:

      CLOB with breaking characters added after commas.

   */
   FUNCTION break_2499(
       p_input           IN  CLOB
      ,p_delim_character IN  VARCHAR2 DEFAULT CHR(10)
      ,p_break_character IN  VARCHAR2 DEFAULT ','
      ,p_break_point     IN  NUMBER DEFAULT 2499
   ) RETURN CLOB;

END dz_sdotxt_main;
/

GRANT EXECUTE ON dz_sdotxt_main TO public;

