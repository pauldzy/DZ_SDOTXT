
--*************************--
PROMPT sqlplus_header.sql;

WHENEVER SQLERROR EXIT -99;
WHENEVER OSERROR  EXIT -98;
SET DEFINE OFF;



--*************************--
PROMPT DZ_SDOTXT_LABELED.tps;

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


--*************************--
PROMPT DZ_SDOTXT_LABELED.tpb;

CREATE OR REPLACE TYPE BODY dz_sdotxt_labeled
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_sdotxt_labeled
   RETURN SELF AS RESULT
   AS
   BEGIN
      RETURN;
      
   END dz_sdotxt_labeled;
 
END;
/


--*************************--
PROMPT DZ_SDOTXT_LABELED_LIST.tps;

CREATE OR REPLACE TYPE dz_sdotxt_labeled_list FORCE                 
AS 
TABLE OF dz_sdotxt_labeled;
/

GRANT EXECUTE ON dz_sdotxt_labeled_list TO public;


--*************************--
PROMPT DZ_SDOTXT_UTIL.pks;

CREATE OR REPLACE PACKAGE dz_sdotxt_util
AUTHID CURRENT_USER
AS
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION downsize_2d(
      p_input      IN MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION downsize_2dM(
      p_input         IN  MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION downsize_3d(
      p_input      IN MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION indent(
      p_level      IN NUMBER,
      p_amount     IN VARCHAR2 DEFAULT '   '
   ) RETURN VARCHAR2;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION pretty(
      p_input      IN CLOB,
      p_level      IN NUMBER,
      p_amount     IN VARCHAR2 DEFAULT '   ',
      p_linefeed   IN VARCHAR2 DEFAULT CHR(10)
   ) RETURN CLOB;
   
END dz_sdotxt_util;
/

GRANT EXECUTE ON dz_sdotxt_util TO PUBLIC;


--*************************--
PROMPT DZ_SDOTXT_UTIL.pkb;

CREATE OR REPLACE PACKAGE BODY dz_sdotxt_util
AS

   ----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION true_point(
      p_input      IN MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
   BEGIN

      IF p_input.SDO_POINT IS NOT NULL
      THEN
         RETURN p_input;
         
      END IF;

      IF p_input.get_gtype() = 1
      THEN
         IF p_input.get_dims() = 2
         THEN
            RETURN MDSYS.SDO_GEOMETRY(
                p_input.SDO_GTYPE
               ,p_input.SDO_SRID
               ,MDSYS.SDO_POINT_TYPE(
                   p_input.SDO_ORDINATES(1)
                  ,p_input.SDO_ORDINATES(2)
                  ,NULL
                )
               ,NULL
               ,NULL
            );
            
         ELSIF p_input.get_dims() = 3
         THEN
            RETURN MDSYS.SDO_GEOMETRY(
                p_input.SDO_GTYPE
               ,p_input.SDO_SRID
               ,MDSYS.SDO_POINT_TYPE(
                    p_input.SDO_ORDINATES(1)
                   ,p_input.SDO_ORDINATES(2)
                   ,p_input.SDO_ORDINATES(3)
                )
               ,NULL
               ,NULL
            );
            
         ELSE
            RAISE_APPLICATION_ERROR(
                -20001
               ,'function true_point can only work on 2 and 3 dimensional points - dims=' || p_input.get_dims() || ' '
            );
            
         END IF;
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'function true_point can only work on point geometries'
         );
         
      END IF;
      
   END true_point;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION downsize_2d(
      p_input   IN MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      geom_2d       MDSYS.SDO_GEOMETRY;
      dim_count     PLS_INTEGER;
      gtype         PLS_INTEGER;
      n_points      PLS_INTEGER;
      n_ordinates   PLS_INTEGER;
      i             PLS_INTEGER;
      j             PLS_INTEGER;
      k             PLS_INTEGER;
      offset        PLS_INTEGER;
      
   BEGIN

      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;

      IF LENGTH (p_input.SDO_GTYPE) = 4
      THEN
         dim_count := p_input.get_dims();
         gtype     := p_input.get_gtype();
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'unable to determine dimensionality from gtype'
         );
         
      END IF;

      IF dim_count = 2
      THEN
         RETURN p_input;
         
      END IF;

      geom_2d := MDSYS.SDO_GEOMETRY(
          2000 + gtype
         ,p_input.sdo_srid
         ,p_input.sdo_point
         ,MDSYS.SDO_ELEM_INFO_ARRAY()
         ,MDSYS.SDO_ORDINATE_ARRAY()
      );

      IF geom_2d.sdo_point IS NOT NULL
      THEN
         geom_2d.sdo_point.z   := NULL;
         geom_2d.sdo_elem_info := NULL;
         geom_2d.sdo_ordinates := NULL;
         
      ELSE
         n_points    := p_input.SDO_ORDINATES.COUNT / dim_count;
         n_ordinates := n_points * 2;
         geom_2d.SDO_ORDINATES.EXTEND(n_ordinates);
         j := p_input.SDO_ORDINATES.FIRST;
         k := 1;
         FOR i IN 1 .. n_points
         LOOP
            geom_2d.SDO_ORDINATES(k) := p_input.SDO_ORDINATES(j);
            geom_2d.SDO_ORDINATES(k + 1) := p_input.SDO_ORDINATES(j + 1);
            j := j + dim_count;
            k := k + 2;
         
         END LOOP;

         geom_2d.sdo_elem_info := p_input.sdo_elem_info;

         i := geom_2d.SDO_ELEM_INFO.FIRST;
         WHILE i < geom_2d.SDO_ELEM_INFO.LAST
         LOOP
            offset := geom_2d.SDO_ELEM_INFO(i);
            geom_2d.SDO_ELEM_INFO(i) := (offset - 1) / dim_count * 2 + 1;
            i := i + 3;
            
         END LOOP;

      END IF;

      IF geom_2d.SDO_GTYPE = 2001
      THEN
         RETURN true_point(geom_2d);
         
      ELSE
         RETURN geom_2d;
         
      END IF;

   END downsize_2d;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION downsize_2dM(
      p_input         IN  MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      geom_2dm      MDSYS.SDO_GEOMETRY;
      dim_count     PLS_INTEGER;
      measure_chk   PLS_INTEGER;
      gtype         PLS_INTEGER;
      n_points      PLS_INTEGER;
      n_ordinates   PLS_INTEGER;
      i             PLS_INTEGER;
      j             PLS_INTEGER;
      k             PLS_INTEGER;
      offset        PLS_INTEGER;
      
   BEGIN

      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;

      IF LENGTH (p_input.SDO_GTYPE) = 4
      THEN
         dim_count   := p_input.get_dims();
         measure_chk := p_input.get_lrs_dim();
         gtype       := p_input.get_gtype();
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'unable to determine dimensionality from gtype'
         );
         
      END IF;

      --------------------------------------------------------------------------
      -- Simple 2D input so just throw it back
      --------------------------------------------------------------------------
      IF dim_count = 2
      THEN
         RETURN p_input;
         
      --------------------------------------------------------------------------
      -- 2D + measure on 3 so just throw it back
      --------------------------------------------------------------------------
      ELSIF dim_count = 3
      AND measure_chk = 3
      THEN
         RETURN p_input;
         
      --------------------------------------------------------------------------
      -- Simple 3D so downsize to 2D
      --------------------------------------------------------------------------
      ELSIF dim_count = 3
      AND measure_chk = 0
      THEN
         RETURN downsize_2d(p_input);
         
      --------------------------------------------------------------------------
      -- 4D so assume measure on the 4
      --------------------------------------------------------------------------
      ELSIF dim_count = 4
      THEN
         --THIS IS BECAUSE ArcSDE is DUMB!
         measure_chk := 4;
         
      END IF;

      IF gtype = 1
      THEN
         geom_2dm := MDSYS.SDO_GEOMETRY(
             3300 + gtype
            ,p_input.sdo_srid
            ,MDSYS.SDO_POINT_TYPE(NULL,NULL,NULL)
            ,NULL
            ,NULL
         );
                 
         geom_2dm.SDO_POINT.X := p_input.SDO_ORDINATES(1);
         geom_2dm.SDO_POINT.Y := p_input.SDO_ORDINATES(2);
         geom_2dm.SDO_POINT.Z := p_input.SDO_ORDINATES(4);
         
         RETURN geom_2dm;
         
      ELSE
         geom_2dm := MDSYS.SDO_GEOMETRY(
             3300 + gtype
            ,p_input.sdo_srid
            ,NULL
            ,MDSYS.SDO_ELEM_INFO_ARRAY()
            ,MDSYS.SDO_ORDINATE_ARRAY()
         );
         
      END IF;

      n_points    := p_input.SDO_ORDINATES.COUNT / dim_count;
      n_ordinates := n_points * 3;
      geom_2dm.SDO_ORDINATES.EXTEND(n_ordinates);
      j := p_input.SDO_ORDINATES.FIRST;
      k := 1;
      
      FOR i IN 1 .. n_points
      LOOP
         geom_2dm.SDO_ORDINATES(k) := p_input.SDO_ORDINATES(j);
         geom_2dm.SDO_ORDINATES(k + 1) := p_input.SDO_ORDINATES(j + 1);
         geom_2dm.SDO_ORDINATES(k + 2) := p_input.SDO_ORDINATES(j + 3);
         j := j + dim_count;
         k := k + 3;
         
      END LOOP;

      geom_2dm.sdo_elem_info := p_input.sdo_elem_info;

      i := geom_2dm.SDO_ELEM_INFO.FIRST;
      WHILE i < geom_2dm.SDO_ELEM_INFO.LAST
      LOOP
         offset := geom_2dm.SDO_ELEM_INFO(i);
         geom_2dm.SDO_ELEM_INFO(i) := (offset - 1) / dim_count * 2 + 1;
         i := i + 3;
         
      END LOOP;

      RETURN geom_2dm;

   END downsize_2dM;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION downsize_3d(
      p_input   IN MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      geom_3d       MDSYS.SDO_GEOMETRY;
      num_lrs       NUMBER;
      dim_count     PLS_INTEGER;
      gtype         PLS_INTEGER;
      n_points      PLS_INTEGER;
      n_ordinates   PLS_INTEGER;
      i             PLS_INTEGER;
      j             PLS_INTEGER;
      k             PLS_INTEGER;
      offset        PLS_INTEGER;
      
   BEGIN

      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;

      IF LENGTH(p_input.SDO_GTYPE) = 4
      THEN
         dim_count := p_input.get_dims();
         gtype     := p_input.get_gtype();
         num_lrs   := p_input.get_lrs_dim();
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'unable to determine dimensionality from gtype'
         );
         
      END IF;

      IF dim_count = 3 AND num_lrs = 0
      THEN
         RETURN p_input;
         
      ELSIF dim_count = 3 AND num_lrs != 0
      THEN
         RETURN downsize_2d(p_input);
         
      ELSIF dim_count = 4 AND num_lrs = 0
      THEN
         -- we ASSUME that we remove the 4th dimension
         num_lrs := 4;
         
      END IF;

      geom_3d := MDSYS.SDO_GEOMETRY(
          3000 + gtype
         ,p_input.SDO_SRID
         ,p_input.SDO_POINT
         ,MDSYS.SDO_ELEM_INFO_ARRAY()
         ,MDSYS.SDO_ORDINATE_ARRAY()
      );

      IF geom_3d.sdo_point IS NOT NULL
      THEN
         geom_3d.sdo_elem_info := NULL;
         geom_3d.sdo_ordinates := NULL;
         
      ELSE
         n_points    := p_input.SDO_ORDINATES.COUNT / dim_count;
         n_ordinates := n_points * 3;
         geom_3d.SDO_ORDINATES.EXTEND(n_ordinates);
         j := p_input.SDO_ORDINATES.FIRST;
         k := 1;
         
         FOR i IN 1 .. n_points
         LOOP
            geom_3d.SDO_ORDINATES(k) := p_input.SDO_ORDINATES(j);
            geom_3d.SDO_ORDINATES(k + 1) := p_input.SDO_ORDINATES(j + 1);
            
            IF num_lrs = 4
            THEN
               geom_3d.SDO_ORDINATES(k + 2) := p_input.SDO_ORDINATES(j + 2);
               
            ELSIF num_lrs = 3
            THEN
               geom_3d.SDO_ORDINATES(k + 2) := p_input.SDO_ORDINATES(j + 3);
               
            END IF;
            
            j := j + dim_count;
            k := k + 3;
            
         END LOOP;

         geom_3d.sdo_elem_info := p_input.sdo_elem_info;

         i := geom_3d.SDO_ELEM_INFO.FIRST;
         WHILE i < geom_3d.SDO_ELEM_INFO.LAST
         LOOP
            offset := geom_3d.SDO_ELEM_INFO(i);
            geom_3d.SDO_ELEM_INFO(i) := (offset - 1) / dim_count * 3 + 1;
            i := i + 4;
            
         END LOOP;

      END IF;

      IF geom_3d.SDO_GTYPE = 2001
      THEN
         RETURN true_point(geom_3d);
         
      ELSE
         RETURN geom_3d;
         
      END IF;

   END downsize_3d;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION indent(
      p_level      IN NUMBER,
      p_amount     IN VARCHAR2 DEFAULT '   '
   ) RETURN VARCHAR2
   AS
      str_output VARCHAR2(4000 Char) := '';
      
   BEGIN
   
      IF  p_level IS NOT NULL
      AND p_level > 0
      THEN
         FOR i IN 1 .. p_level
         LOOP
            str_output := str_output || p_amount;
            
         END LOOP;
         
         RETURN str_output;
         
      ELSE
         RETURN '';
         
      END IF;
      
   END indent;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION pretty(
      p_input      IN CLOB,
      p_level      IN NUMBER,
      p_amount     IN VARCHAR2 DEFAULT '   ',
      p_linefeed   IN VARCHAR2 DEFAULT CHR(10)
   ) RETURN CLOB
   AS
      str_amount   VARCHAR2(4000 Char) := p_amount;
      str_linefeed VARCHAR2(2 Char)    := p_linefeed;
      
   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Process Incoming Parameters
      --------------------------------------------------------------------------
      IF p_amount IS NULL
      THEN
         str_amount := '   ';
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- If input is NULL, then do nothing
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 30
      -- Return indented and line fed results
      --------------------------------------------------------------------------
      IF p_level IS NULL
      THEN
         RETURN p_input;
         
      ELSIF p_level = -1
      THEN
         RETURN p_input || TO_CLOB(str_linefeed);
         
      ELSE
         RETURN TO_CLOB(indent(p_level,str_amount)) || p_input || TO_CLOB(str_linefeed);
         
      END IF;

   END pretty;
   
END dz_sdotxt_util;
/


--*************************--
PROMPT DZ_SDOTXT_MAIN.pks;

CREATE OR REPLACE PACKAGE dz_sdotxt_main
AUTHID CURRENT_USER
AS
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   header: DZ_SDOTXT
     
   - Build ID: 6
   - TFS Change Set: 8345
   
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
     MDSYS.SDO_POINT_TYPE, MDSYS.SDO_ELEM_INFO_ARRAY, MDSYS.SDO_ORDINATE_ARRAY,
     MDSYS.SDO_GEORASTER, MDSYS.SDO_RASTER and MDSYS.SDO_DIM_ARRAY.
     
   - Note that Oracle is not PostgreSQL or other database systems where large
     objects can be comfortably dumped to text.  Attempting to dump a 300,000 
     vertice geometry is going to fail, attempting to dump a 70 gig raster rdt 
     table is going to fail, attempting to feed more than a few meg
     of generated text data back through sqlplus is also going to fail.  These 
     utilities are provided for very modest purposes primarily to inspect the  
     details of small example spatial objects or package up one or two smaller 
     sized objects for transport to a collaborator.  In all situations the use
     of Oracle datapump to import and export spatial data is the way to go.

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

   Utility to convert a blob in textual hex usuable as a right side assignment
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

   Utility to convert a blob in textual hex usuable as a series of DBMS_LOB
   statements which can be then used as a bind variable in sql statememts.

   Parameters:

      p_input - BLOB to convert to sql text.
      p_lob_name - the lob variable name in the statements, default is dz_lob.
      Use different names if you are dumping multiple blobs.
      p_delim_value - the delimiter to place at the end of each statement, the 
      default is a line feed to make sqplus happy.  Set to NULL if you want no
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


--*************************--
PROMPT DZ_SDOTXT_MAIN.pkb;

CREATE OR REPLACE PACKAGE BODY dz_sdotxt_main
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION dzq(
      p_input      IN  VARCHAR2
   ) RETURN VARCHAR2
   AS
   BEGIN
      IF p_input IS NULL
      THEN
         RETURN 'NULL';
      
      ELSE
         RETURN '''' || p_input || '''';
         
      END IF;
      
   END dzq;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION dzq(
       p_input        IN  MDSYS.SDO_GEOMETRY
      ,p_pretty_print IN  NUMBER DEFAULT 0
   ) RETURN CLOB
   AS
   BEGIN
      IF p_input IS NULL
      THEN
         RETURN 'NULL';
      
      ELSE
         RETURN sdo2sql(
             p_input        => p_input
            ,p_pretty_print => p_pretty_print
         );
         
      END IF;
      
   END dzq;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION dzq(
       p_input        IN  SYS.XMLTYPE
      ,p_pretty_print IN  NUMBER DEFAULT 0
   ) RETURN CLOB
   AS
      clb_tmp CLOB;
      
   BEGIN
      IF p_input IS NULL
      THEN
         RETURN 'NULL';
      
      ELSE
         SELECT 
         XMLSERIALIZE(CONTENT p_input NO INDENT)
         INTO clb_tmp
         FROM 
         dual;
         
         RETURN 'SYS.XMLTYPE(''' || clb_tmp || ''')';
         
      END IF;
      
   END dzq;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION dzq(
       p_input        IN  BLOB
      ,p_pretty_print IN  NUMBER DEFAULT 0
   ) RETURN CLOB
   AS
      
      
   BEGIN
      IF p_input IS NULL
      THEN
         RETURN 'NULL';
      
      ELSE
         RETURN blob2sql(p_input);
         
      END IF;
      
   END dzq;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sdo2sql(
       p_input        IN  MDSYS.SDO_GEOMETRY
      ,p_2d_flag      IN  VARCHAR2 DEFAULT 'FALSE'
      ,p_output_srid  IN  NUMBER   DEFAULT NULL
      ,p_pretty_print IN  NUMBER   DEFAULT 0
   ) RETURN CLOB
   AS
      sdo_input     MDSYS.SDO_GEOMETRY := p_input;
      str_2d_flag   VARCHAR(5 Char)   := UPPER(p_2d_flag);
      str_srid      VARCHAR(12 Char);
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------   
      IF str_2d_flag IS NULL
      THEN
         str_2d_flag := 'FALSE';
         
      ELSIF str_2d_flag NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Downsize to 2D if required
      --------------------------------------------------------------------------   
      IF str_2d_flag = 'TRUE'
      THEN
         sdo_input := dz_sdotxt_util.downsize_2d(sdo_input);
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Transform if requested
      --------------------------------------------------------------------------   
      IF p_output_srid IS NOT NULL
      AND p_output_srid <> sdo_input.SDO_SRID
      THEN
         sdo_input := MDSYS.SDO_CS.TRANSFORM(
            geom    => sdo_input
           ,to_srid => p_output_srid
         );
        
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Account for NULL SRID
      -------------------------------------------------------------------------- 
      IF p_input.SDO_SRID IS NULL
      THEN
         str_srid := 'NULL';
         
      ELSE
         str_srid := TO_CHAR(p_input.SDO_SRID);
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Cough out the results
      --------------------------------------------------------------------------   
      RETURN dz_sdotxt_util.pretty(
          'MDSYS.SDO_GEOMETRY('
         ,p_pretty_print
      ) || dz_sdotxt_util.pretty(
          TO_CHAR(p_input.SDO_GTYPE) || ','
         ,p_pretty_print + 1
      ) || dz_sdotxt_util.pretty(
          str_srid || ','
         ,p_pretty_print + 1
      ) || dz_sdotxt_util.pretty(
          sdo2sql(p_input.SDO_POINT,p_pretty_print) || ','
         ,p_pretty_print
      ) || dz_sdotxt_util.pretty(
          sdo2sql(p_input.SDO_ELEM_INFO,p_pretty_print) || ','
         ,p_pretty_print
      ) || dz_sdotxt_util.pretty(
          sdo2sql(p_input.SDO_ORDINATES,p_pretty_print)
         ,p_pretty_print
      ) || dz_sdotxt_util.pretty(
          ')'
         ,p_pretty_print
         ,NULL
         ,NULL
      );

   END sdo2sql;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sdo2sql(
       p_input        IN  MDSYS.SDO_GEOMETRY_ARRAY
      ,p_2d_flag      IN  VARCHAR2 DEFAULT 'FALSE'
      ,p_output_srid  IN  NUMBER   DEFAULT NULL
      ,p_pretty_print IN  NUMBER   DEFAULT 0
   ) RETURN CLOB
   AS
      clb_output CLOB;
      
   BEGIN
      
      IF p_input IS NULL
      OR p_input.COUNT = 0
      THEN
         RETURN NULL;
         
      END IF;
      
      clb_output := '';
      FOR i IN 1 .. p_input.COUNT
      LOOP
         clb_output := clb_output || sdo2sql(
             p_input        => p_input(i)
            ,p_2d_flag      => p_2d_flag
            ,p_output_srid  => p_output_srid
            ,p_pretty_print => p_pretty_print
         ) || CHR(10);
         
      END LOOP;
      
      RETURN clb_output;
      
   END sdo2sql;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sdo2sql(
       p_input        IN MDSYS.SDO_POINT_TYPE
      ,p_pretty_print IN NUMBER   DEFAULT 0
   ) RETURN CLOB
   AS
      X          VARCHAR2(64 Char);
      Y          VARCHAR2(64 Char);
      Z          VARCHAR2(64 Char);

   BEGIN
   
      IF p_input IS NULL
      THEN
         RETURN dz_sdotxt_util.pretty(
             'NULL'
            ,p_pretty_print
            ,NULL
            ,NULL
         );
         
      END IF;

      IF p_input.X IS NULL
      THEN
         X := 'NULL';
         
      ELSE
         X := TO_CHAR(p_input.X);
         
      END IF;

      IF p_input.Y IS NULL
      THEN
         Y := 'NULL';
         
      ELSE
         Y := TO_CHAR(p_input.Y);
         
      END IF;

      IF p_input.Z IS NULL
      THEN
         Z := 'NULL';
         
      ELSE
         Z := TO_CHAR(p_input.Z);
         
      END IF;
      
      RETURN dz_sdotxt_util.pretty('MDSYS.SDO_POINT_TYPE(',p_pretty_print)
          || dz_sdotxt_util.pretty(X || ',',p_pretty_print + 1)
          || dz_sdotxt_util.pretty(Y || ',',p_pretty_print + 1)
          || dz_sdotxt_util.pretty(Z,p_pretty_print + 1)
          || dz_sdotxt_util.pretty(')',p_pretty_print,NULL,NULL);
          
   END sdo2sql;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sdo2sql(
       p_input        IN MDSYS.SDO_ELEM_INFO_ARRAY
      ,p_pretty_print IN NUMBER   DEFAULT 0
   ) RETURN CLOB
   AS
      clb_output CLOB := '';
      
   BEGIN
   
      IF p_input IS NULL
      THEN
         RETURN dz_sdotxt_util.pretty(
             'NULL'
            ,p_pretty_print
            ,NULL
            ,NULL
         );
         
      END IF;

      clb_output := dz_sdotxt_util.pretty(
          'MDSYS.SDO_ELEM_INFO_ARRAY('
         ,p_pretty_print
      );

      FOR i IN 1 .. p_input.COUNT
      LOOP
         IF i < p_input.COUNT
         THEN
            clb_output := clb_output || dz_sdotxt_util.pretty(
                TO_CHAR(p_input(i)) || ','
               ,p_pretty_print + 2
            );
            
         ELSE
            clb_output := clb_output || dz_sdotxt_util.pretty(
                TO_CHAR(p_input(i))
               ,p_pretty_print + 2
            );
            
         END IF;
  
      END LOOP;

      RETURN clb_output || dz_sdotxt_util.pretty(
          ')'
         ,p_pretty_print + 1
         ,NULL
         ,NULL
      );

   END sdo2sql;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sdo2sql(
       p_input        IN  MDSYS.SDO_ORDINATE_ARRAY
      ,p_pretty_print IN  NUMBER DEFAULT 0
   ) RETURN CLOB
   AS
      clb_output CLOB := '';
      
   BEGIN
   
      IF p_input IS NULL
      THEN
         RETURN dz_sdotxt_util.pretty(
             'NULL'
            ,p_pretty_print
            ,NULL
            ,NULL
         );
         
      END IF;
      
      clb_output := dz_sdotxt_util.pretty(
          'MDSYS.SDO_ORDINATE_ARRAY('
         ,p_pretty_print
      );
      
      FOR i IN 1 .. p_input.COUNT
      LOOP    
         IF i < p_input.COUNT
         THEN
            clb_output := clb_output || dz_sdotxt_util.pretty(
                TO_CHAR(p_input(i)) || ','
               ,p_pretty_print + 2
            );
            
         ELSE
            clb_output := clb_output || dz_sdotxt_util.pretty(
                TO_CHAR(p_input(i))
               ,p_pretty_print + 2
            );
            
         END IF;
         
      END LOOP;
      
      RETURN clb_output || dz_sdotxt_util.pretty(
          ')'
         ,p_pretty_print + 1
         ,NULL
         ,NULL
      );

   END sdo2sql;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sdo2sql(
      p_input        IN MDSYS.SDO_DIM_ARRAY,
      p_pretty_print IN NUMBER DEFAULT 0
   ) RETURN CLOB
   AS
      clb_output  CLOB;
      int_count   PLS_INTEGER;
      
   BEGIN
   
      clb_output := dz_sdotxt_util.pretty(
          'MDSYS.SDO_DIM_ARRAY('
         ,p_pretty_print
      );
      
      int_count  := p_input.COUNT;

      FOR i IN 1 .. 4
      LOOP
         IF i <= int_count
         THEN
            clb_output := clb_output
                       || dz_sdotxt_util.pretty('MDSYS.SDO_DIM_ELEMENT(',p_pretty_print + 1)
                       || dz_sdotxt_util.pretty('''' || p_input(i).SDO_DIMNAME || ''',',p_pretty_print + 2)
                       || dz_sdotxt_util.pretty(TO_CHAR(p_input(i).SDO_LB) || ',',p_pretty_print + 2)
                       || dz_sdotxt_util.pretty(TO_CHAR(p_input(i).SDO_UB) || ',',p_pretty_print + 2)
                       || dz_sdotxt_util.pretty(TO_CHAR(p_input(i).SDO_TOLERANCE),p_pretty_print + 2);
              
            IF i < int_count
            THEN
               clb_output := clb_output || dz_sdotxt_util.pretty(
                   '),'
                  ,p_pretty_print + 1
               );
               
            ELSE
               clb_output := clb_output || dz_sdotxt_util.pretty(
                   ')'
                  ,p_pretty_print + 1
               );
               
            END IF;
            
         END IF;
            
      END LOOP;
 
      RETURN clb_output || dz_sdotxt_util.pretty(
          ')'
         ,p_pretty_print
         ,NULL
         ,NULL
      );
      
   END sdo2sql;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sdo2sql(
       p_input        IN  MDSYS.SDO_GEORASTER
      ,p_pretty_print IN  NUMBER DEFAULT 0
   ) RETURN CLOB
   AS
      clb_output CLOB := '';
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN dz_sdotxt_util.pretty(
             'NULL'
            ,p_pretty_print
            ,NULL
            ,NULL
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Create the outer object
      --------------------------------------------------------------------------
      clb_output := dz_sdotxt_util.pretty(
          'MDSYS.SDO_GEORASTER('
         ,p_pretty_print
      );
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Add the attributes
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_sdotxt_util.pretty(
          TO_CHAR(p_input.rasterType) || ','
         ,p_pretty_print + 1
      ) || dz_sdotxt_util.pretty(
          dzq(
              p_input.spatialExtent
             ,p_pretty_print + 1
          ) || ','
         ,p_pretty_print 
      ) || dz_sdotxt_util.pretty(
          dzq(p_input.rasterDataTable) || ','
         ,p_pretty_print + 1
      ) || dz_sdotxt_util.pretty(
          TO_CHAR(p_input.rasterID) || ','
         ,p_pretty_print + 1
      ) || dz_sdotxt_util.pretty(
          dzq(p_input.metadata)
         ,p_pretty_print + 1
      );
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Return the results with closing parenthesis
      --------------------------------------------------------------------------
      RETURN clb_output || dz_sdotxt_util.pretty(
          ')'
         ,p_pretty_print
         ,NULL
         ,NULL
      );

   END sdo2sql;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   -- Note this function is not going to work well for large rasters
   FUNCTION sdo2sql(
       p_input        IN  MDSYS.SDO_RASTER
      ,p_pretty_print IN  NUMBER DEFAULT 0
   ) RETURN CLOB
   AS
      clb_output CLOB := '';
      
   BEGIN
      
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN dz_sdotxt_util.pretty(
             'NULL'
            ,p_pretty_print
            ,NULL
            ,NULL
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Create the outer object
      --------------------------------------------------------------------------
      clb_output := dz_sdotxt_util.pretty(
          'MDSYS.SDO_RASTER('
         ,p_pretty_print
      );
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Add the attributes
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_sdotxt_util.pretty(
          TO_CHAR(p_input.rasterID) || ','
         ,p_pretty_print + 1
      ) || dz_sdotxt_util.pretty(
          TO_CHAR(p_input.pyramidLevel) || ','
         ,p_pretty_print + 1
      ) || dz_sdotxt_util.pretty(
          TO_CHAR(p_input.bandBlockNumber) || ','
         ,p_pretty_print + 1
      ) || dz_sdotxt_util.pretty(
          TO_CHAR(p_input.rowBlockNumber) || ','
         ,p_pretty_print + 1
      ) || dz_sdotxt_util.pretty(
          TO_CHAR(p_input.columnBlockNumber) || ','
         ,p_pretty_print + 1
      ) || dz_sdotxt_util.pretty(
          dzq(
              p_input.blockMBR
             ,p_pretty_print + 1
          ) || ','
         ,p_pretty_print 
      ) || dz_sdotxt_util.pretty(
          dzq(p_input.rasterBlock)
         ,p_pretty_print + 1
      );
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Return the results with closing parenthesis
      --------------------------------------------------------------------------
      RETURN clb_output || dz_sdotxt_util.pretty(
          ')'
         ,p_pretty_print
         ,NULL
         ,NULL
      );
      
   END sdo2sql;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sdo2sql_nvl(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_is_null          IN  CLOB
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'FALSE'
      ,p_output_srid      IN  NUMBER   DEFAULT NULL
      ,p_pretty_print     IN  NUMBER   DEFAULT 0
   ) RETURN CLOB
   AS
   
   BEGIN
      IF p_input IS NULL
      THEN
         RETURN p_is_null;
         
      ELSE
         RETURN sdo2sql(
             p_input        => p_input
            ,p_2d_flag      => p_2d_flag
            ,p_output_srid  => p_output_srid
            ,p_pretty_print => p_pretty_print
         );
         
      END IF;
         
   END sdo2sql_nvl;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION blob2sql(
       p_input        IN  BLOB
   ) RETURN CLOB
   AS
      clb_tmp    CLOB := '';
      int_size   PLS_INTEGER;
      int_buffer PLS_INTEGER := 1000;
      int_loop   PLS_INTEGER;
      raw_buffer RAW(32767);
      
   BEGIN
   
      IF p_input IS NULL
      THEN
         RETURN clb_tmp;
      
      END IF;
      
      int_size := DBMS_LOB.GETLENGTH(p_input);
      int_loop := int_size / int_buffer;
      
      FOR i IN 0 .. int_loop
      LOOP
         raw_buffer := DBMS_LOB.SUBSTR(
             p_input
            ,int_buffer
            ,i * int_buffer + 1
         );
         
         IF i > 0
         THEN
            clb_tmp := clb_tmp || ' || ';
         
         END IF;
         
         clb_tmp := clb_tmp || 'HEXTORAW(''' || RAWTOHEX(raw_buffer) || ''')';
         
      END LOOP;
      
      RETURN clb_tmp;
      
   END blob2sql;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION blob2plsql(
       p_input        IN  BLOB
      ,p_lob_name     IN  VARCHAR2 DEFAULT 'dz_lob'
      ,p_delim_value  IN  VARCHAR2 DEFAULT CHR(10)
   ) RETURN CLOB
   AS
      str_lob_name    VARCHAR2(4000 Char) := p_lob_name;
      str_delim_value VARCHAR2(4000 Char) := p_delim_value;
      clb_tmp         CLOB := '';
      int_size        PLS_INTEGER;
      int_buffer      PLS_INTEGER := 1000;
      int_loop        PLS_INTEGER;
      raw_buffer      RAW(32767);
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN clb_tmp;
      
      END IF;
      
      IF str_lob_name IS NULL
      THEN
         str_lob_name := 'dz_lob';
         
      END IF;
      
      IF str_delim_value IS NULL
      THEN
         str_delim_value := CHR(10);
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Write the initial temp creation
      --------------------------------------------------------------------------
      clb_tmp := 'DBMS_LOB.CREATETEMPORARY(' || str_lob_name || ',TRUE);' || str_delim_value;
      
      --------------------------------------------------------------------------
      -- Step 30
      --  Loop through loop and write append statements
      --------------------------------------------------------------------------
      int_size := DBMS_LOB.GETLENGTH(p_input);
      int_loop := int_size / int_buffer;
      
      FOR i IN 0 .. int_loop
      LOOP
         raw_buffer := DBMS_LOB.SUBSTR(
             p_input
            ,int_buffer
            ,i * int_buffer + 1
         );
         
         clb_tmp := clb_tmp || 
                 'DBMS_LOB.APPEND(' || str_lob_name || ',' ||
                 'HEXTORAW(''' || RAWTOHEX(raw_buffer) || '''));';
         
         IF i < int_loop
         THEN
            clb_tmp := clb_tmp || str_delim_value;
         
         END IF;
         
      END LOOP;
      
      RETURN clb_tmp;
      
   END blob2plsql;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION dump_string_endpoints(
      p_input        IN  MDSYS.SDO_GEOMETRY
   ) RETURN VARCHAR2
   AS
      int_dims PLS_INTEGER;
      int_gtyp PLS_INTEGER;
      int_len  PLS_INTEGER;
      
   BEGIN
   
      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();

      IF int_gtyp <> 2
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'expected linestring but got ' || p_input.SDO_GTYPE
         );
         
      END IF;

      int_len := p_input.SDO_ORDINATES.COUNT();

      IF int_dims = 2
      THEN
         RETURN p_input.SDO_ORDINATES(1)           || ' , '
             || p_input.SDO_ORDINATES(2)           || ' <-> '
             || p_input.SDO_ORDINATES(int_len - 1) || ' , '
             || p_input.SDO_ORDINATES(int_len);
             
      ELSIF int_dims = 3
      THEN
         RETURN p_input.SDO_ORDINATES(1)           || ' , '
             || p_input.SDO_ORDINATES(2)           || ' , '
             || p_input.SDO_ORDINATES(3)           || ' <-> '
             || p_input.SDO_ORDINATES(int_len - 2) || ' , '
             || p_input.SDO_ORDINATES(int_len - 1) || ' , '
             || p_input.SDO_ORDINATES(int_len);
             
      ELSIF int_dims = 4
      THEN
         RETURN p_input.SDO_ORDINATES(1)           || ' , '
             || p_input.SDO_ORDINATES(2)           || ' , '
             || p_input.SDO_ORDINATES(3)           || ' , '
             || p_input.SDO_ORDINATES(4)           || ' <-> '
             || p_input.SDO_ORDINATES(int_len - 3) || ' , '
             || p_input.SDO_ORDINATES(int_len - 2) || ' , '
             || p_input.SDO_ORDINATES(int_len - 1) || ' , '
             || p_input.SDO_ORDINATES(int_len);
             
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'no idea what to do with ' || p_input.SDO_GTYPE
         );
         
      END IF;

   END dump_string_endpoints;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION dump_string_endpoints(
      p_input_1      IN  MDSYS.SDO_GEOMETRY,
      p_input_2      IN  MDSYS.SDO_GEOMETRY
   ) RETURN VARCHAR2
   AS
   BEGIN
      RETURN dump_string_endpoints(p_input_1) || CHR(10)
          || dump_string_endpoints(p_input_2);
          
   END dump_string_endpoints;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION dump_sdo_subelements(
       p_input        IN  MDSYS.SDO_GEOMETRY
      ,p_indent       IN  VARCHAR2 DEFAULT ''
   ) RETURN CLOB
   AS
      clb_output CLOB := '';
      int_dims   PLS_INTEGER;
      int_gtyp   PLS_INTEGER;
      
   BEGIN
   
      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();
      
      IF int_gtyp IN (4,5,6,7)
      THEN
         FOR i IN 1 .. MDSYS.SDO_UTIL.GETNUMELEM(p_input)
         LOOP
            clb_output := clb_output || sdo2sql(
                MDSYS.SDO_UTIL.EXTRACT(p_input,i)
               ,p_indent
            ) || CHR(10);
                       
         END LOOP;
         
         RETURN clb_output;
         
      ELSE
         RETURN sdo2sql(p_input,p_indent);
         
      END IF;

   END dump_sdo_subelements;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION dump_single_point_ordinate(
       p_input            IN MDSYS.SDO_GEOMETRY
      ,p_vertice_type     IN VARCHAR2
      ,p_vertice_position IN NUMBER DEFAULT 1
   ) RETURN NUMBER
   AS
      str_vertice_type     VARCHAR2(1 Char) := UPPER(p_vertice_type);
      num_vertice_position NUMBER := p_vertice_position;
      num_gtype            NUMBER;
      num_dim              NUMBER;
      num_lrs              NUMBER;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF str_vertice_type IS NULL
      OR str_vertice_type NOT IN ('X','Y','Z','M')
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'vertice type may only be X, Y, Z or M'
         );
         
      END IF;
      
      IF num_vertice_position IS NULL
      THEN
         num_vertice_position := 1;
         
      END IF;
      
      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Check that gtype and vertice type are sensible
      --------------------------------------------------------------------------
      num_gtype := p_input.get_gtype();
      num_dim   := p_input.get_dims();
      
      IF num_gtype NOT IN (1,2,3)
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'function only applies to single geometries'
         );
         
      END IF;
      
      IF str_vertice_type IN ('M','Z')
      AND num_dim < 3
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input geometry does not have Z or M dimensions'
         );
         
      END IF;
      
      num_lrs := p_input.get_lrs_dim();
      IF str_vertice_type = 'M'
      AND num_lrs = 0
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input geometry does not have M dimension indicated on sdo_gtype'
         );
         
      END IF;
      
      IF num_gtype = 1
      AND num_vertice_position <> 1
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'points can only have a single vertice'
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Check if this is a point with sdo_point type
      --------------------------------------------------------------------------
      IF p_input.SDO_POINT IS NOT NULL
      THEN
         IF str_vertice_type = 'X'
         THEN
            RETURN p_input.sdo_point.X;
            
         ELSIF str_vertice_type = 'Y'
         THEN
            RETURN p_input.sdo_point.Y;
            
         ELSIF str_vertice_type = 'Z'
         THEN
            RETURN p_input.sdo_point.Z;
            
         ELSIF str_vertice_type = 'M'
         THEN
            RAISE_APPLICATION_ERROR(
                -20001
               ,'sdo_point type geometries cannot carry M values'
            );
            
         END IF;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Check if this is a point with sdo_ordinates
      --------------------------------------------------------------------------
      IF num_gtype = 1
      THEN
         IF str_vertice_type = 'X'
         THEN
            RETURN p_input.sdo_ordinates(1);
            
         ELSIF str_vertice_type = 'Y'
         THEN
            RETURN p_input.sdo_ordinates(2);
            
         ELSIF str_vertice_type = 'Z'
         THEN
            IF num_lrs = 3
            THEN
               RETURN p_input.sdo_ordinates(4);
               
            ELSIF num_lrs = 4
            THEN
               RETURN p_input.sdo_ordinates(3);
               
            ELSE 
               RETURN p_input.sdo_ordinates(3);
               
            END IF;
            
         ELSIF str_vertice_type = 'M'
         THEN
            IF num_lrs = 3
            THEN
               RETURN p_input.sdo_ordinates(3);
               
            ELSIF num_lrs = 4
            THEN
               RETURN p_input.sdo_ordinates(4);
               
            END IF;
            
         END IF;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Process lines and polygons
      --------------------------------------------------------------------------
      RAISE_APPLICATION_ERROR(-20001,'not implemented');
      
   END dump_single_point_ordinate;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION dump_mbr(
      p_input        IN MDSYS.SDO_GEOMETRY
   ) RETURN VARCHAR2
   AS
     sdo_input MDSYS.SDO_GEOMETRY := p_input;
     
   BEGIN

      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;

      IF MDSYS.SDO_UTIL.GETNUMVERTICES(p_input) = 2
      AND p_input.SDO_ELEM_INFO(3) = 3
      THEN
         RETURN TO_CHAR(p_input.SDO_ORDINATES(1)) || ',' ||
            TO_CHAR(p_input.SDO_ORDINATES(2))     || ',' ||
            TO_CHAR(p_input.SDO_ORDINATES(3))     || ',' ||
            TO_CHAR(p_input.SDO_ORDINATES(4));
             
      ELSE
         sdo_input := MDSYS.SDO_GEOM.SDO_MBR(
            dz_sdotxt_util.downsize_2d(p_input)
         );
         
         IF ( MDSYS.SDO_UTIL.GETNUMVERTICES(sdo_input) = 2 AND sdo_input.SDO_ELEM_INFO(3) = 3) 
         OR ( MDSYS.SDO_UTIL.GETNUMVERTICES(sdo_input) = 2 AND sdo_input.SDO_ELEM_INFO(1) = 1 AND sdo_input.SDO_ELEM_INFO(3) = 1)
         THEN
            RETURN TO_CHAR(sdo_input.SDO_ORDINATES(1)) || ',' ||
               TO_CHAR(sdo_input.SDO_ORDINATES(2))     || ',' ||
               TO_CHAR(sdo_input.SDO_ORDINATES(3))     || ',' ||
               TO_CHAR(sdo_input.SDO_ORDINATES(4));
               
         ELSE
            RAISE_APPLICATION_ERROR(
                -20001
               ,'input to dump_mbr must be 2 vertice rectangle' || CHR(13) ||
                'found ' || TO_CHAR(sdo_input.SDO_GTYPE)   
            );
            
         END IF;
         
      END IF;

   END dump_mbr;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION label_ordinates(
      p_input           IN MDSYS.SDO_GEOMETRY
   ) RETURN dz_sdotxt_labeled_list PIPELINED
   AS
      num_dims  PLS_INTEGER;
      num_last  PLS_INTEGER;
      num_index PLS_INTEGER := 1;
      num_coor  PLS_INTEGER := 1;
      rec_label dz_sdotxt_labeled := dz_sdotxt_labeled();
      x         NUMBER;
      y         NUMBER;
      
   BEGIN
   
      num_dims := p_input.get_dims();
      num_last := p_input.SDO_ORDINATES.COUNT;

      WHILE num_index <= num_last
      LOOP
         x := p_input.SDO_ORDINATES(num_index);
         y := p_input.SDO_ORDINATES(num_index + 1);
         num_index := num_index + num_dims;
         rec_label.shape_label := TO_CHAR(num_coor);
         num_coor := num_coor + 1;
         
         rec_label.shape := MDSYS.SDO_GEOMETRY(
             2001
            ,p_input.SDO_SRID
            ,MDSYS.SDO_POINT_TYPE(
                 x
                ,y
                ,NULL
             )
            ,NULL
            ,NULL
         );
         
         PIPE ROW(rec_label);
         
      END LOOP;
      
   END label_ordinates;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION label_measures(
      p_input           IN MDSYS.SDO_GEOMETRY
   ) RETURN dz_sdotxt_labeled_list PIPELINED
   AS
      num_lrs   PLS_INTEGER;
      num_dims  PLS_INTEGER;
      num_last  PLS_INTEGER;
      num_index PLS_INTEGER := 1;
      num_coor  PLS_INTEGER := 1;
      rec_label dz_sdotxt_labeled := dz_sdotxt_labeled();
      x1        NUMBER;
      y1        NUMBER;
      m1        NUMBER;
      
   BEGIN
      num_lrs  := p_input.get_lrs_dim();
      num_dims := p_input.get_dims();
      
      IF num_lrs = 0
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'geometry is not LRS'
         );
         
      END IF;
      
      num_last := p_input.SDO_ORDINATES.COUNT;

      WHILE num_index <= num_last
      LOOP
         x1 := p_input.SDO_ORDINATES(num_index);
         y1 := p_input.SDO_ORDINATES(num_index + 1);
         
         IF num_lrs = 3
         THEN
            m1 := p_input.SDO_ORDINATES(num_index + 2);
            
         ELSIF num_lrs = 4
         THEN
            m1 := p_input.SDO_ORDINATES(num_index + 3);
            
         END IF;
         
         num_index := num_index + num_dims;
         rec_label.shape_label := TO_CHAR(m1);
         num_coor := num_coor + 1;
         
         rec_label.shape := MDSYS.SDO_GEOMETRY(
             2001
            ,p_input.SDO_SRID
            ,MDSYS.SDO_POINT_TYPE(
                 x1
                ,y1
                ,NULL
             )
            ,NULL
            ,NULL
         );
         
         PIPE ROW(rec_label);
         
      END LOOP;
      
   END label_measures;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION break_2499(
       p_input           IN  CLOB
      ,p_delim_character IN  VARCHAR2 DEFAULT CHR(10)
      ,p_break_character IN  VARCHAR2 DEFAULT ','
      ,p_break_point     IN  NUMBER DEFAULT 2499
   ) RETURN CLOB
   AS
      str_delim_character VARCHAR2(4000 Char) := p_delim_character;
      str_break_character VARCHAR2(4000 Char) := p_break_character;
      int_breaker_length  PLS_INTEGER;
      num_break_point     NUMBER := p_break_point;
      int_length          PLS_INTEGER;
      int_position        PLS_INTEGER;
      int_stopper         PLS_INTEGER;
      int_sanity          PLS_INTEGER;
      clb_output          CLOB := '';
      clb_tmp             CLOB;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF str_delim_character IS NULL
      THEN
         str_delim_character := CHR(10);
         
      END IF;
      
      IF str_break_character IS NULL
      THEN
         str_break_character := ',';
         
      END IF;
      int_breaker_length := LENGTH(str_break_character);
      
      IF num_break_point IS NULL
      THEN
         num_break_point := 2499;
         
      END IF;
      num_break_point := num_break_point - int_breaker_length;
      
      IF p_input IS NULL
      THEN
         RETURN p_input;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Determine length and exit if less than break point
      --------------------------------------------------------------------------
      int_length := LENGTH(p_input);
      
      IF int_length <= num_break_point
      THEN
         RETURN p_input;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Loop through the text add linefeeds near but less than the break mark
      --------------------------------------------------------------------------
      int_position := 1;
      int_sanity := 1;
      
      <<looper>>
      WHILE int_position <= int_length
      LOOP
         clb_tmp := SUBSTR(
             p_input
            ,int_position
            ,num_break_point
         );
         
         IF LENGTH(clb_tmp) < num_break_point
         THEN
            clb_output := clb_output || clb_tmp;
            int_position := int_length + 1;
            EXIT looper;
            
         END IF;         

         int_stopper := INSTR(clb_tmp,str_break_character,-1);
         IF  int_stopper = 0
         THEN
            RAISE_APPLICATION_ERROR(
                -20001
               ,'cannot break using parameters provided'
            );
            
         ELSE
            clb_output := clb_output 
                       || SUBSTR(clb_tmp,1,int_stopper + (int_breaker_length - 1)) 
                       || str_delim_character;
            
            int_position := int_position 
                         + int_stopper 
                         + (int_breaker_length - 1);
         
         END IF;
         
         int_sanity := int_sanity + 1;
         IF int_sanity > 100
         THEN
            RAISE_APPLICATION_ERROR(-20001,'sanity check');
            
         END IF;
         
      END LOOP;

      --------------------------------------------------------------------------
      -- Step 40
      -- Return what we got
      --------------------------------------------------------------------------
      RETURN clb_output;
   
   END break_2499;
   
END dz_sdotxt_main;
/


--*************************--
PROMPT DZ_SDOTXT_TEST.pks;

CREATE OR REPLACE PACKAGE dz_sdotxt_test
AUTHID DEFINER
AS

   C_TFS_CHANGESET CONSTANT NUMBER := 8345;
   C_JENKINS_JOBNM CONSTANT VARCHAR2(255 Char) := 'NULL';
   C_JENKINS_BUILD CONSTANT NUMBER := 6;
   C_JENKINS_BLDID CONSTANT VARCHAR2(255 Char) := 'NULL';
   
   C_PREREQUISITES CONSTANT MDSYS.SDO_STRING2_ARRAY := MDSYS.SDO_STRING2_ARRAY(
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prerequisites
   RETURN NUMBER;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION version
   RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION inmemory_test
   RETURN NUMBER;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION scratch_test
   RETURN NUMBER;
      
END dz_sdotxt_test;
/

GRANT EXECUTE ON dz_sdotxt_test TO PUBLIC;


--*************************--
PROMPT DZ_SDOTXT_TEST.pkb;

CREATE OR REPLACE PACKAGE BODY dz_sdotxt_test
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prerequisites
   RETURN NUMBER
   AS
      num_check NUMBER;
      
   BEGIN
      
      FOR i IN 1 .. C_PREREQUISITES.COUNT
      LOOP
         SELECT 
         COUNT(*)
         INTO num_check
         FROM 
         user_objects a
         WHERE 
             a.object_name = C_PREREQUISITES(i) || '_TEST'
         AND a.object_type = 'PACKAGE';
         
         IF num_check <> 1
         THEN
            RETURN 1;
         
         END IF;
      
      END LOOP;
      
      RETURN 0;
   
   END prerequisites;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION version
   RETURN VARCHAR2
   AS
   BEGIN
      RETURN '{"TFS":' || C_TFS_CHANGESET || ','
      || '"JOBN":"' || C_JENKINS_JOBNM || '",'   
      || '"BUILD":' || C_JENKINS_BUILD || ','
      || '"BUILDID":"' || C_JENKINS_BLDID || '"}';
      
   END version;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION inmemory_test
   RETURN NUMBER
   AS
   BEGIN
      RETURN 0;
      
   END inmemory_test;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION scratch_test
   RETURN NUMBER
   AS
   BEGIN
      RETURN 0;
      
   END scratch_test;

END dz_sdotxt_test;
/


--*************************--
PROMPT sqlplus_footer.sql;


SHOW ERROR;

DECLARE
   l_num_errors PLS_INTEGER;

BEGIN

   SELECT
   COUNT(*)
   INTO l_num_errors
   FROM
   user_errors a
   WHERE
   a.name LIKE 'DZ_SDOTXT%';

   IF l_num_errors <> 0
   THEN
      RAISE_APPLICATION_ERROR(-20001,'COMPILE ERROR');

   END IF;

   l_num_errors := DZ_SDOTXT_TEST.inmemory_test();

   IF l_num_errors <> 0
   THEN
      RAISE_APPLICATION_ERROR(-20001,'INMEMORY TEST ERROR');

   END IF;

END;
/

EXIT;

