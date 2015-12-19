CREATE OR REPLACE TYPE dz_sdotxt_labeled_list FORCE                 
AS 
TABLE OF dz_sdotxt_labeled;
/

GRANT EXECUTE ON dz_sdotxt_labeled_list TO public;

