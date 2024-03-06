create or replace function carrega_arquivos(EXTENSAO IN VARCHAR2)  RETURN INTEGER is

pragma autonomous_transaction;

begin

   execute immediate 'truncate table t_aux_files2';

   for mreg in (select directory_name from all_directories WHERE directory_name IN (SELECT table_name FROM all_tab_privs WHERE grantee = USER AND table_name IN (SELECT directory_name FROM all_directories) AND privilege = 'READ' ) ) loop
       for reg2 in (SELECT x.nom_arq
                    FROM (select column_value,
                          ltrim(ltrim(substr(column_value, length(b.DIRECTORY_PATH) + 1), '\'),'/') nom_arq
                          from table(utl_list_files(mreg.directory_name, '.'||EXTENSAO)) a,
                                all_directories b
                           where b.DIRECTORY_NAME = mreg.directory_name) x) loop

           begin
             insert into t_aux_files2 values (mreg.directory_name, reg2.nom_arq);
           exception
             when others then
               null;
           end;

       end loop;
      commit;

   end loop;

   return 1;
end;
/
