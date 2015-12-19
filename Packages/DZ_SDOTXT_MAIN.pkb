CREATE OR REPLACE PACKAGE BODY dz_sdotxt_main
AS

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
      RETURN dz_sdotxt_util.pretty('MDSYS.SDO_GEOMETRY(',p_pretty_print)
         || dz_sdotxt_util.pretty(TO_CHAR(p_input.SDO_GTYPE) || ',',p_pretty_print + 1)
         || dz_sdotxt_util.pretty(str_srid || ',',p_pretty_print + 1)
         || dz_sdotxt_util.pretty(sdo2sql(p_input.SDO_POINT,p_pretty_print + 1) || ',',p_pretty_print)
         || dz_sdotxt_util.pretty(sdo2sql(p_input.SDO_ELEM_INFO,p_pretty_print + 1) || ',',p_pretty_print)
         || dz_sdotxt_util.pretty(sdo2sql(p_input.SDO_ORDINATES,p_pretty_print + 1),p_pretty_print)
         || dz_sdotxt_util.pretty(')',p_pretty_print,NULL,NULL);

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
   FUNCTION sdo2sql (
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
   FUNCTION sdo2sql (
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
               ,p_pretty_print + 1
            );
            
         ELSE
            clb_output := clb_output || dz_sdotxt_util.pretty(
                TO_CHAR(p_input(i))
               ,p_pretty_print + 1
            );
            
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
   FUNCTION sdo2sql (
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
               ,p_pretty_print + 1
            );
            
         ELSE
            clb_output := clb_output || dz_sdotxt_util.pretty(
                TO_CHAR(p_input(i))
               ,p_pretty_print + 1
            );
            
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
   FUNCTION sdo2sql (
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
   
END dz_sdotxt_main;
/

