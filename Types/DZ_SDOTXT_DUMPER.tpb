CREATE OR REPLACE TYPE BODY dz_sdotxt_dumper
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_sdotxt_dumper(
      p_input      IN  CLOB
   )
   RETURN SELF AS RESULT
   AS
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Store the sql text
      --------------------------------------------------------------------------
      self.str_cursor := p_input;
      
      RETURN;
      
   END dz_sdotxt_dumper;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER FUNCTION sql_inserts(
      p_table_name  IN  VARCHAR2
   )
   RETURN CLOB
   AS
      str_insert         VARCHAR2(32000 Char);
      clb_output         CLOB;
      desctab            DBMS_SQL.DESC_TAB3;
      str_holder         VARCHAR2(32000 Char);
      num_holder         NUMBER;
      dat_holder         DATE;
      int_colcnt         PLS_INTEGER;
      sdo_holder         MDSYS.SDO_GEOMETRY;
      blb_holder         BLOB;
      int_cursor         INTEGER;
      int_exec           INTEGER;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Open the cursor
      --------------------------------------------------------------------------
      int_cursor := DBMS_SQL.OPEN_CURSOR;
      DBMS_SQL.PARSE(
          int_cursor
         ,self.str_cursor
         ,DBMS_SQL.NATIVE
      );
      int_exec := DBMS_SQL.EXECUTE(int_cursor);
   
      --------------------------------------------------------------------------
      -- Step 20
      -- Setup the sql insert
      --------------------------------------------------------------------------
      str_insert := 'INSERT INTO ' || p_table_name || CHR(10) || '(';
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Describe and define the columns
      --------------------------------------------------------------------------
      DBMS_SQL.DESCRIBE_COLUMNS3(int_cursor,int_colcnt,desctab);

      FOR i IN 1 .. int_colcnt
      LOOP
         IF desctab(i).col_type IN (1,9,96)
         THEN
            DBMS_SQL.DEFINE_COLUMN(int_cursor,i,str_holder,32000);

         ELSIF desctab(i).col_type = 2
         THEN
            DBMS_SQL.DEFINE_COLUMN(int_cursor,i,num_holder);

         ELSIF desctab(i).col_type = 12
         THEN
            DBMS_SQL.DEFINE_COLUMN(int_cursor,i,dat_holder);

         ELSIF desctab(i).col_type = 109
         AND desctab(i).col_type_name = 'SDO_GEOMETRY'
         THEN
            DBMS_SQL.DEFINE_COLUMN(int_cursor,i,sdo_holder);

         ELSIF desctab(i).col_type = 113
         THEN
            DBMS_SQL.DEFINE_COLUMN(int_cursor,i,blb_holder);
            
         END IF;
         
         str_insert := str_insert || desctab(i).col_name;
         
         IF i < int_colcnt
         THEN
            str_insert := str_insert || ',';
         
         END IF;

      END LOOP;

      str_insert := str_insert || ')' || CHR(10) || 'VALUES' || CHR(10) || '(';

      --------------------------------------------------------------------------
      -- Step 40
      -- Spin out the cursor
      --------------------------------------------------------------------------
      clb_output := '';
      WHILE DBMS_SQL.FETCH_ROWS(int_cursor) > 0
      LOOP
         clb_output := clb_output || str_insert;
         
         FOR i IN 1 .. int_colcnt
         LOOP
            IF desctab(i).col_type IN (1,9,96)
            THEN
               DBMS_SQL.COLUMN_VALUE(int_cursor,i,str_holder);
               clb_output := clb_output || '''' || REPLACE(str_holder,'''','''''') || '''';

            ELSIF desctab(i).col_type = 2
            THEN
               DBMS_SQL.COLUMN_VALUE(int_cursor,i,num_holder);
               clb_output := clb_output || TO_CHAR(num_holder);

            ELSIF desctab(i).col_type = 12
            THEN
               DBMS_SQL.COLUMN_VALUE(int_cursor,i,dat_holder);
               clb_output := clb_output || 'TO_DATE(''' || TO_CHAR(dat_holder,'MM/DD/YYYY') || ',''MM/DD/YYYY'')';

            ELSIF desctab(i).col_type = 109
            AND desctab(i).col_type_name = 'SDO_GEOMETRY'
            THEN
               DBMS_SQL.COLUMN_VALUE(int_cursor,i,sdo_holder);
               clb_output := clb_output || CHR(10) || 'dz_sdotxt_main.geomblob2sdo(' 
               || dz_sdotxt_main.blob2sql(
                  dz_sdotxt_main.sdo2geomblob(
                     p_input => sdo_holder
                  )
               ) || ')' || CHR(10);
            
            ELSIF desctab(i).col_type = 113
            THEN
               DBMS_SQL.COLUMN_VALUE(int_cursor,i,blb_holder);
               clb_output := clb_output || dz_sdotxt_main.blob2sql(
                  blb_holder
               );
               
            END IF;

            IF i < int_colcnt
            THEN
               clb_output := clb_output || ',';

            ELSE
               clb_output := clb_output || ');' || CHR(10);

            END IF;

         END LOOP;

      END LOOP;

      --------------------------------------------------------------------------
      -- Step 50
      -- Close the cursor
      --------------------------------------------------------------------------
      DBMS_SQL.CLOSE_CURSOR(int_cursor);
      
      --------------------------------------------------------------------------
      -- Step 60
      -- Return results
      --------------------------------------------------------------------------
      RETURN clb_output;
   
   END sql_inserts;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER FUNCTION plsql_inserts(
      p_table_name  IN  VARCHAR2
   )
   RETURN CLOB
   AS
      str_insert         VARCHAR2(32000 Char);
      str_declare        VARCHAR2(32000 Char);
      clb_output         CLOB;
      clb_record         CLOB;
      desctab            DBMS_SQL.DESC_TAB3;
      str_holder         VARCHAR2(32000 Char);
      num_holder         NUMBER;
      dat_holder         DATE;
      int_colcnt         PLS_INTEGER;
      sdo_holder         MDSYS.SDO_GEOMETRY;
      blb_holder         BLOB;
      int_lob_count      PLS_INTEGER;
      int_cursor         INTEGER;
      int_exec           INTEGER;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Open the cursor
      --------------------------------------------------------------------------
      int_cursor := DBMS_SQL.OPEN_CURSOR;
      DBMS_SQL.PARSE(
          int_cursor
         ,self.str_cursor
         ,DBMS_SQL.NATIVE
      );
      int_exec := DBMS_SQL.EXECUTE(int_cursor);
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Setup the sql insert
      --------------------------------------------------------------------------
      str_declare := 'DECLARE' || CHR(10);
      str_insert  := 'INSERT INTO ' || p_table_name || CHR(10) || '(';
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Describe and define the columns
      --------------------------------------------------------------------------
      int_lob_count := 0;
      DBMS_SQL.DESCRIBE_COLUMNS3(int_cursor,int_colcnt,desctab);

      FOR i IN 1 .. int_colcnt
      LOOP
         IF desctab(i).col_type IN (1,9,96)
         THEN
            DBMS_SQL.DEFINE_COLUMN(int_cursor,i,str_holder,32000);

         ELSIF desctab(i).col_type = 2
         THEN
            DBMS_SQL.DEFINE_COLUMN(int_cursor,i,num_holder);

         ELSIF desctab(i).col_type = 12
         THEN
            DBMS_SQL.DEFINE_COLUMN(int_cursor,i,dat_holder);

         ELSIF desctab(i).col_type = 109
         AND desctab(i).col_type_name = 'SDO_GEOMETRY'
         THEN
            DBMS_SQL.DEFINE_COLUMN(int_cursor,i,sdo_holder);
            int_lob_count := int_lob_count + 1;
            
            str_declare := str_declare|| 'dz_lob' || TO_CHAR(int_lob_count) || ' BLOB;' || CHR(10);

         ELSIF desctab(i).col_type = 113
         THEN
            DBMS_SQL.DEFINE_COLUMN(int_cursor,i,blb_holder);
            int_lob_count := int_lob_count + 1;
            
            str_declare := str_declare || 'dz_lob' || TO_CHAR(int_lob_count) || ' BLOB;' || CHR(10);
            
         END IF;
         
         str_insert := str_insert || desctab(i).col_name;
         
         IF i < int_colcnt
         THEN
            str_insert := str_insert || ',';
         
         END IF;

      END LOOP;
      
      str_declare := str_declare || 'BEGIN' || CHR(10);
      str_insert  := str_insert || ')' || CHR(10) || 'VALUES' || CHR(10) || '(';

      --------------------------------------------------------------------------
      -- Step 40
      -- Spin out the cursor
      --------------------------------------------------------------------------
      clb_output    := '';
      
      WHILE DBMS_SQL.FETCH_ROWS(int_cursor) > 0
      LOOP
         int_lob_count := 0;
         clb_output := clb_output || str_declare;
         clb_record := '';
         
         FOR i IN 1 .. int_colcnt
         LOOP
            IF desctab(i).col_type IN (1,9,96)
            THEN
               DBMS_SQL.COLUMN_VALUE(int_cursor,i,str_holder);
               clb_record := clb_record || '''' || REPLACE(str_holder,'''','''''') || '''';

            ELSIF desctab(i).col_type = 2
            THEN
               DBMS_SQL.COLUMN_VALUE(int_cursor,i,num_holder);
               clb_record := clb_record || TO_CHAR(num_holder);

            ELSIF desctab(i).col_type = 12
            THEN
               DBMS_SQL.COLUMN_VALUE(int_cursor,i,dat_holder);
               clb_record := clb_record || 'TO_DATE(''' || TO_CHAR(dat_holder,'MM/DD/YYYY') || ',''MM/DD/YYYY'')';

            ELSIF desctab(i).col_type = 109
            AND desctab(i).col_type_name = 'SDO_GEOMETRY'
            THEN
               DBMS_SQL.COLUMN_VALUE(int_cursor,i,sdo_holder);
               int_lob_count := int_lob_count + 1;
               
               clb_record := clb_record || CHR(10) || 'dz_sdotxt_main.geomblob2sdo(dz_lob' 
               || TO_CHAR(int_lob_count) || ')';
               
               clb_output := clb_output || dz_sdotxt_main.blob2plsql(
                   p_input       => dz_sdotxt_main.sdo2geomblob(
                     p_input => sdo_holder
                   )
                  ,p_lob_name    => 'dz_lob' || TO_CHAR(int_lob_count)
                  ,p_delim_value => CHR(10)
               );
            
            ELSIF desctab(i).col_type = 113
            THEN
               DBMS_SQL.COLUMN_VALUE(int_cursor,i,blb_holder);
               int_lob_count := int_lob_count + 1;
               
               clb_record := clb_record || 'dz_lob' || TO_CHAR(int_lob_count);
               
               clb_output := clb_output || dz_sdotxt_main.blob2plsql(
                   p_input       => blb_holder
                  ,p_lob_name    => 'dz_lob' || TO_CHAR(int_lob_count)
                  ,p_delim_value => CHR(10)
               );
               
            END IF;

            IF i < int_colcnt
            THEN
               clb_record := clb_record || ',';

            ELSE
               clb_record := clb_record || ');' || CHR(10);

            END IF;

         END LOOP;
         
         clb_output := clb_output || str_insert || clb_record;
         clb_output := clb_output || 'END;' || CHR(10) || '/' || CHR(10);

      END LOOP;

      --------------------------------------------------------------------------
      -- Step 50
      -- Close the cursor
      --------------------------------------------------------------------------
      DBMS_SQL.CLOSE_CURSOR(int_cursor);
      
      --------------------------------------------------------------------------
      -- Step 60
      -- Return results
      --------------------------------------------------------------------------
      RETURN clb_output;
   
   END plsql_inserts;
 
END;
/

