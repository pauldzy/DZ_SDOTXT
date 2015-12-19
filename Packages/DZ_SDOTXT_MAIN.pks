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
   
   - Input objects include MDSYS.SDO_GEOMETRY, MDSYS.SDO_GEOMETRY_ARRAY,
     MDSYS.SDO_POINT_TYPE, MDSYS.SDO_ELEM_INFO_ARRAY, MDSYS.SDO_ORDINATE_ARRAY
     and MDSYS.SDO_DIM_ARRAY.

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
      p_input           IN MDSYS.SDO_GEOMETRY
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
      p_input           IN MDSYS.SDO_GEOMETRY
   ) RETURN dz_sdotxt_labeled_list PIPELINED;

END dz_sdotxt_main;
/

GRANT EXECUTE ON dz_sdotxt_main TO public;

