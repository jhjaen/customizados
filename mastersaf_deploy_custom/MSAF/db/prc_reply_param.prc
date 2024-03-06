CREATE OR REPLACE PROCEDURE PRC_REPLY_PARAM(COD_EMPRESA in varchar2,
                                            TIPO        in varchar2,
                                            ORIGEM      in varchar2,
                                            DESTINO     in varchar2) IS

  wCodEmpresa varchar2(3) := null;
  wDataIni    date := null;
  wDataFim    date := null;

  --
  --
  -- REGISTROS SALDOS PERIODICOS
  t_x240 x240_inf_empresa_cons%rowtype := null;
  t_x262 sped_contas_emp_cons%rowtype := null;
  --

  cursor c_x240(p_cod_empresa varchar2, p_data_ini date, p_data_fim date) is
    select a.cod_empresa,
           a.cod_estab,
           a.data_ini_cons,
           a.data_fim_cons,
           a.cod_emp_part,
           a.nome_emp_part,
           a.cnpj,
           a.ind_evento,
           a.perc_part_tot,
           a.perc_cons,
           a.data_ini_emp,
           a.data_fim_emp,
           a.cod_pais,
           a.num_processo,
           a.ind_gravacao
      from x240_inf_empresa_cons a
     where a.cod_empresa = p_cod_empresa
       and a.data_ini_cons = p_data_ini
       and a.data_fim_cons = p_data_fim;

  cursor c_x262(p_cod_empresa varchar2, p_data_ini date, p_data_fim date) is
    select a.cod_empresa,
           a.cod_estab,
           a.data_ini_cons,
           a.data_fim_cons,
           a.cod_emp_part,
           a.grupo_conta,
           a.cod_conta,
           a.cod_conta_cons
      from sped_contas_emp_cons a
     where 1 = 1
       and a.cod_empresa = p_cod_empresa
       and a.data_ini_cons = p_data_ini
       and a.data_fim_cons = p_data_fim;

  vn_limit INTEGER;
  TYPE tb_regx240 IS TABLE OF c_x240%ROWTYPE INDEX BY BINARY_INTEGER;

  TYPE tb_regx262 IS TABLE OF c_x262%ROWTYPE INDEX BY BINARY_INTEGER;
  vr_x240 tb_regx240;
  vr_x262 tb_regx262;

begin

  wCodEmpresa := COD_EMPRESA;
  wDataIni    := to_date('01/01/' || ORIGEM, 'dd/mm/rrrr');
  wDataFim    := to_date('31/12/' || ORIGEM, 'dd/mm/rrrr');

  if TIPO = 'SAFX240' then

    OPEN c_x240(wCodEmpresa, wDataIni, wDataFim);

      FETCH c_x240 BULK COLLECT
        INTO vr_x240;
      BEGIN
        for i in 1 .. vr_x240.count loop

          vr_x240(i).data_ini_cons := to_date('01/01/' || DESTINO,
                                              'dd/mm/rrrr');
          vr_x240(i).data_fim_cons := to_date('31/12/' || DESTINO,
                                              'dd/mm/rrrr');

          vr_x240(i).data_ini_emp := to_date('01/01/' || DESTINO,
                                              'dd/mm/rrrr');
          vr_x240(i).data_fim_emp := to_date('31/12/' || DESTINO,
                                              'dd/mm/rrrr');

          begin
            INSERT INTO x240_inf_empresa_cons VALUES vr_x240(i);
          exception
            when others then
              null;
          end;
        end loop;

      END;


   elsif TIPO = 'SAFX262' then

    OPEN c_x262(wCodEmpresa, wDataIni, wDataFim);

      FETCH c_x262 BULK COLLECT
        INTO vr_x262;
      BEGIN
        for i in 1 .. vr_x262.count loop

          vr_x262(i).data_ini_cons := to_date('01/01/' || DESTINO,
                                              'dd/mm/rrrr');
          vr_x262(i).data_fim_cons := to_date('31/12/' || DESTINO,
                                              'dd/mm/rrrr');

          begin
            INSERT INTO sped_contas_emp_cons VALUES vr_x262(i);
          exception
            when others then
              null;
          end;
        end loop;

      END;

  end if;

  commit;

end;
/

