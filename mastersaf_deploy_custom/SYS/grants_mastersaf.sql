create or replace view X_$KRBMSFT as select * from X$KRBMSFT;
grant select on X_$KRBMSFT to MSAF_PROD;
GRANT EXECUTE ON SYS.DBMS_BACKUP_RESTORE TO MSAF_PROD;