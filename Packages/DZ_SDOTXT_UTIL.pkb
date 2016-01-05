CREATE OR REPLACE PACKAGE BODY dz_sdotxt_util
AS

   ----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION true_point(
      p_input      IN  MDSYS.SDO_GEOMETRY
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
      p_input      IN  MDSYS.SDO_GEOMETRY
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
      p_input      IN  MDSYS.SDO_GEOMETRY
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
      p_input      IN  MDSYS.SDO_GEOMETRY
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
       p_level     IN  NUMBER
      ,p_amount    IN  VARCHAR2 DEFAULT '   '
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
       p_input     IN  CLOB
      ,p_level     IN  NUMBER
      ,p_amount    IN  VARCHAR2 DEFAULT '   '
      ,p_linefeed  IN  VARCHAR2 DEFAULT CHR(10)
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
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION blob2clob(
       p_input      IN  BLOB
      ,p_decompress IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB
   AS
      l_blob         BLOB := p_input;
      l_clob         CLOB;
      l_src_offset   NUMBER;
      l_dest_offset  NUMBER;
      v_lang_context NUMBER := DBMS_LOB.DEFAULT_LANG_CTX;
      l_warning      NUMBER;
      l_amount       NUMBER;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF p_input IS NULL
      OR DBMS_LOB.GETLENGTH(p_input) = 0
      THEN
         RETURN NULL;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Decompress input blob if requested
      --------------------------------------------------------------------------
      IF p_decompress = 'TRUE'
      THEN
         l_blob := UTL_COMPRESS.LZ_UNCOMPRESS(l_blob);
          
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Generate a temporary clob to hold results
      --------------------------------------------------------------------------
      DBMS_LOB.CREATETEMPORARY(l_clob, TRUE);
      l_src_offset  := 1;
      l_dest_offset := 1;
      l_amount := DBMS_LOB.GETLENGTH(l_blob);
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Convert blob to clob
      --------------------------------------------------------------------------
      DBMS_LOB.CONVERTTOCLOB(
          l_clob
         ,l_blob
         ,l_amount
         ,l_src_offset
         ,l_dest_offset
         ,1
         ,v_lang_context
         ,l_warning
      );

      --------------------------------------------------------------------------
      -- Step 50
      -- Return results
      --------------------------------------------------------------------------
      RETURN l_clob;

   END blob2clob;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION clob2blob(
       p_input      IN  CLOB
      ,p_compress   IN  VARCHAR2 DEFAULT 'FALSE' 
      ,p_comp_qual  IN  NUMBER   DEFAULT 6 
   ) RETURN BLOB
   AS
      l_blob         BLOB;
      l_src_offset   NUMBER;
      l_dest_offset  NUMBER;
      v_lang_context NUMBER := DBMS_LOB.DEFAULT_LANG_CTX;
      l_warning      NUMBER;
      l_amount       NUMBER;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF p_input IS NULL
      OR DBMS_LOB.GETLENGTH(p_input) = 0
      THEN
         RETURN NULL;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Generate a temporary blob to hold results
      --------------------------------------------------------------------------
      DBMS_LOB.CREATETEMPORARY(l_blob, TRUE);
      l_src_offset  := 1;
      l_dest_offset := 1;
      l_amount := DBMS_LOB.GETLENGTH(p_input);
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Convert clob to blob
      --------------------------------------------------------------------------
      DBMS_LOB.CONVERTTOBLOB(
          l_blob
         ,p_input
         ,l_amount
         ,l_src_offset
         ,l_dest_offset
         ,1
         ,v_lang_context
         ,l_warning
      );
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Compress blob if requested
      --------------------------------------------------------------------------
      IF p_compress = 'TRUE'
      THEN
         RETURN UTL_COMPRESS.LZ_COMPRESS(
             src     => l_blob
            ,quality => p_comp_qual 
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Return results
      --------------------------------------------------------------------------
      RETURN l_blob;

   END clob2blob;
   
END dz_sdotxt_util;
/

