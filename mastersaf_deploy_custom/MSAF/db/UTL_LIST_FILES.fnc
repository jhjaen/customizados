CREATE OR REPLACE FUNCTION UTL_LIST_FILES(lp_directory in VARCHAR2,
                                          lp_string    IN VARCHAR2 default null)
  RETURN file_array
  pipelined AS

  lv_pattern VARCHAR2(1024);
  lv_ns      VARCHAR2(1024);

  /*Pre-requisito:
  Executar como sys.

  create or replace view X_$KRBMSFT as select * from X$KRBMSFT;
  grant select on X_$KRBMSFT to mastersaf;
  create or replace synonym mastersaf.X_$KRBMSFT for sys.X_$KRBMSFT;*/

BEGIN

  SELECT directory_path
    INTO lv_pattern
    FROM all_directories
   WHERE directory_name = lp_directory;

  SYS.DBMS_BACKUP_RESTORE.SEARCHFILES(lv_pattern, lv_ns);

  FOR file_list IN (SELECT FNAME_KRBMSFT AS file_name
                      FROM sys.X_$KRBMSFT
                     WHERE UPPER(FNAME_KRBMSFT) LIKE '%' || NVL(lp_string, FNAME_KRBMSFT) || '%') LOOP
    PIPE ROW(file_list.file_name);
  END LOOP;

END UTL_LIST_FILES;
/
