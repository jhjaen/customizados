CREATE OR REPLACE PROCEDURE PRC_LOAD_TXT_ECD( DIRETORIO_ORIG      in Varchar2
                                              ,ARQUIVO            in Varchar2
                                              ,WCOUNT             out NUMBER
                                              -- 001
                                              ,PREGISTRO          IN VARCHAR2 -- 1= I155 + I355, 2= K300
                                              ) IS
                                              
--###################################################################################
--## Ajustes                                                                       ##
--##                                                                               ##
--## 001 - Felipe Guimaraes 17/04/2021                                             ##
--##       Permitir carga dos saldos atraves do registro K300                      ##
--##       Implementacao da funcao f_get_string                                    ##
--##                                                                               ##
--###################################################################################


  v_linha         varchar2(3000) := '';
  v_arquivo       utl_file.file_type;
  v_data_aux      varchar(20) := '';
  v_commit        number :=0;
  v_error         varchar2(255) := null;
  v_cnpj          estabelecimento.cgc%type := null;
  
  v_data_ini      DATE;
  v_data_fim      DATE;
  
  v_limpeza       BOOLEAN := FALSE;
  --
  --
  -- REGISTROS SALDOS PERIODICOS
  t_saldo  TREG_SALDO_ECD%rowtype;
  t_plcontas TREG_PLANO_CONTAS_ECD%rowtype := null;
  --
  cursor c(p_arquivo varchar2) is
    select H.ROWID ROWID_Z
      FROM treg_saldo_ecd H
     WHERE 1 = 1
       AND h.arquivo = p_arquivo;

  TYPE tpTbRowIdZ IS TABLE OF ROWID INDEX BY BINARY_INTEGER;

  vtpTbRowIdZ tpTbRowIdZ;
  
-- 001

  FUNCTION f_get_string ( p_string         VARCHAR2
                         , p_posicao       PLS_INTEGER
                         , p_delimitador   VARCHAR2
                         ) RETURN VARCHAR2 IS
                                       
    v_string VARCHAR2(5000);

  BEGIN
    v_string := p_string || p_delimitador;
    FOR i IN 1 .. p_posicao - 1
    LOOP
      v_string := SUBSTR(v_string,INSTR(v_string,p_delimitador)+LENGTH(p_delimitador));
    END LOOP;
    RETURN SUBSTR(v_string,1,INSTR(v_string,p_delimitador)-1);

  END f_get_string;
  
-- 001

begin

    -- begin Limpeza
    open c(upper(trim(ARQUIVO)));
            --
            loop
              fetch c bulk collect
                into vtpTbRowIdZ limit 2000;

              if vtpTbRowIdZ.count > 0 then
                --
                forall vnContador in 1 .. vtpTbRowIdZ.count
                --
                  delete from treg_saldo_ecd
                   where rowid = vtpTbRowIdZ(vnContador);
                commit; -- commit a cada 2.000 registros
                --
              end if;

              exit when c%notfound;
              --
            end loop;
            --
      close c;
   -- END - Limpeza

  v_arquivo      := utl_file.fopen(DIRETORIO_ORIG, ARQUIVO, 'R');

  WCOUNT :=0;

  loop
    begin
      utl_file.get_line(v_arquivo, v_linha);

      t_saldo.arquivo := upper(trim(ARQUIVO));

      --v_registro := SUBSTR(v_linha,INSTR(v_linha, '|', 1, 1) + 1,(INSTR(v_linha, '|', 1, 2) - INSTR(v_linha, '|', 1, 1) - 1));

      -- CNPJ
      IF v_linha like  '|0000|%' THEN
        v_cnpj     := SUBSTR(v_linha,INSTR(v_linha, '|', 1, 6) + 1,(INSTR(v_linha, '|', 1, 7) - INSTR(v_linha, '|', 1, 6) - 1));
        v_data_ini := to_date(f_get_string(v_linha,4,'|'),'ddmmyyyy');
        v_data_fim := to_date(f_get_string(v_linha,5,'|'),'ddmmyyyy');
      END IF;

      t_saldo.cnpj := v_cnpj;

    /*  begin
        select a.cod_empresa, a.cod_estab
          into t_saldo.cod_empresa, t_saldo.cod_estab
          from estabelecimento a
         where 1=1
          and a.cgc = v_cnpj
          and a.dt_encerramento is null;
       exception
         when others then
           t_saldo.cod_empresa := null;
           t_saldo.cod_estab := null;
       end;
*/


-- Limpeza da tabela de saldos para registros ja processados

   BEGIN
     IF NOT v_limpeza THEN
        DELETE FROM TREG_SALDO_ECD WHERE cnpj = v_cnpj AND periodo BETWEEN v_data_ini AND v_data_fim;
        COMMIT;
        v_limpeza := TRUE;
     END IF;
   END;


-- 001 Inicio
-- Segregacao das etapas de carga para considerar carga pelos registros K030, K200 e K300

   IF PREGISTRO = '1' -- Carga atraves dos registros I155 + I355
     THEN 
       
      IF v_linha like '|I990|%' then
          commit;
          exit;
      end if;

       -- PLANO DE CONTAS ECD
        IF (v_linha like '|I050|%') THEN


           t_plcontas.empresa    := v_cnpj;

           t_plcontas.tipo       :=  SUBSTR(v_linha,INSTR(v_linha, '|', 1, 4) + 1,(INSTR(v_linha, '|', 1, 5) - INSTR(v_linha, '|', 1, 4) - 1));

           t_plcontas.cod_conta  := SUBSTR(v_linha,INSTR(v_linha, '|', 1, 6) + 1,(INSTR(v_linha, '|', 1, 7) - INSTR(v_linha, '|', 1, 6) - 1));
           t_plcontas.descricao  := SUBSTR(v_linha,INSTR(v_linha, '|', 1, 8) + 1,(INSTR(v_linha, '|', 1, 9) - INSTR(v_linha, '|', 1, 8) - 1));


            begin
              insert into treg_plano_contas_ecd values t_plcontas;

              if sql%rowcount > 0 then
                 v_commit := v_commit + 1;
              end if;

              if v_commit = 1000 then
                commit;
                v_commit := 0;
              end if;
            --
            exception
              when others then
                v_error := 'Erro: ' || sqlerrm;
            end;
            --

        END IF;
       -- end

       --
       --
       -- REGISTRO CABEÇALHO DO SALDO PERIODICO
       IF (v_linha like '|I150|%') THEN

        v_data_aux                := SUBSTR(v_linha,INSTR(v_linha, '|', 1, 3) + 1,(INSTR(v_linha, '|', 1, 4) - INSTR(v_linha, '|', 1, 3) - 1));

        t_saldo.periodo            := to_date(SUBSTR(v_data_aux,1,2) || '/' || SUBSTR(v_data_aux,3,2) || '/'|| SUBSTR(v_data_aux,5,4), 'dd/mm/rrrr');

       END IF;

       -- DETALHAMENTO SALDO PERIODICO
       IF v_linha like '|I155|%' THEN


        t_saldo.cod_conta          := SUBSTR(v_linha,INSTR(v_linha, '|', 1, 2) + 1,(INSTR(v_linha, '|', 1, 3) - INSTR(v_linha, '|', 1, 2) - 1));
        t_saldo.cod_custo          := SUBSTR(v_linha,INSTR(v_linha, '|', 1, 3) + 1,(INSTR(v_linha, '|', 1, 4) - INSTR(v_linha, '|', 1, 3) - 1));
        t_saldo.vlr_saldo_ini      := SUBSTR(v_linha,INSTR(v_linha, '|', 1, 4) + 1,(INSTR(v_linha, '|', 1, 5) - INSTR(v_linha, '|', 1, 4) - 1));
        t_saldo.ind_dc_ini         := SUBSTR(v_linha,INSTR(v_linha, '|', 1, 5) + 1,(INSTR(v_linha, '|', 1, 6) - INSTR(v_linha, '|', 1, 5) - 1));
        t_saldo.vlr_deb            := SUBSTR(v_linha,INSTR(v_linha, '|', 1, 6) + 1,(INSTR(v_linha, '|', 1, 7) - INSTR(v_linha, '|', 1, 6) - 1));
        t_saldo.vlr_cred           := SUBSTR(v_linha,INSTR(v_linha, '|', 1, 7) + 1,(INSTR(v_linha, '|', 1, 8) - INSTR(v_linha, '|', 1, 7) - 1));
        t_saldo.vlr_saldo_fim      := SUBSTR(v_linha,INSTR(v_linha, '|', 1, 8) + 1,(INSTR(v_linha, '|', 1, 9) - INSTR(v_linha, '|', 1, 8) - 1));
        t_saldo.ind_dc_fim         := SUBSTR(v_linha,INSTR(v_linha, '|', 1, 9) + 1,(INSTR(v_linha, '|', 1, 10) - INSTR(v_linha, '|', 1, 9) - 1));

            --
            begin
              insert into treg_saldo_ecd values t_saldo;

              if sql%rowcount > 0 then
                 v_commit := v_commit + 1;
                 WCOUNT := WCOUNT + 1;
              end if;

              if v_commit = 1000 then
                commit;
                v_commit := 0;
              end if;
            --
            exception
              when others then
                v_error := 'Erro: ' || sqlerrm;
            end;
            --
       END IF;
       --
       --
       -- DETALHAMENTO CONTAS RESULTADO
       IF ( v_linha like '|I350|%') THEN

        v_data_aux                 := SUBSTR(v_linha,INSTR(v_linha, '|', 1, 2) + 1,(INSTR(v_linha, '|', 1, 3) - INSTR(v_linha, '|', 1, 2) - 1));

        t_saldo.periodo            := to_date(SUBSTR(v_data_aux,1,2) || '/' || SUBSTR(v_data_aux,3,2) || '/'|| SUBSTR(v_data_aux,5,4), 'dd/mm/rrrr');

       END IF;


       IF v_linha like '|I355|%' THEN


        t_saldo.cod_conta          := SUBSTR(v_linha,INSTR(v_linha, '|', 1, 2) + 1,(INSTR(v_linha, '|', 1, 3) - INSTR(v_linha, '|', 1, 2) - 1));
        t_saldo.cod_custo          := SUBSTR(v_linha,INSTR(v_linha, '|', 1, 3) + 1,(INSTR(v_linha, '|', 1, 4) - INSTR(v_linha, '|', 1, 3) - 1));
        t_saldo.vlr_saldo_ini      := null;
        t_saldo.ind_dc_ini         := null;
        t_saldo.vlr_deb            := null;
        t_saldo.vlr_cred           := null;
        t_saldo.vlr_saldo_fim      := SUBSTR(v_linha,INSTR(v_linha, '|', 1, 4) + 1,(INSTR(v_linha, '|', 1, 5) - INSTR(v_linha, '|', 1, 4) - 1));
        t_saldo.ind_dc_fim         := SUBSTR(v_linha,INSTR(v_linha, '|', 1, 5) + 1,(INSTR(v_linha, '|', 1, 6) - INSTR(v_linha, '|', 1, 5) - 1));
        t_saldo.registro           := f_get_string(v_linha,2,'|');

            --
            begin
              insert into treg_saldo_ecd values t_saldo;

              if sql%rowcount > 0 then
                 v_commit := v_commit + 1;
                 WCOUNT := WCOUNT + 1;
              end if;

              if v_commit = 1000 then
                commit;
                v_commit := 0;
              end if;
            --
            exception
              when others then
                v_error := 'Erro: ' || sqlerrm;
            end;
            
            t_saldo.registro           := NULL;
            
            --
       END IF;
       
    END IF;

    IF PREGISTRO = '2' -- Carga atraves do registro K300
      THEN
        
      IF v_linha like '|K990|%' then
          commit;
          exit;
      end if;
      
       -- PLANO DE CONTAS ECD
        IF (v_linha like '|K200|%') THEN

           t_plcontas.empresa    := v_cnpj;

           t_plcontas.tipo       :=  f_get_string(v_linha,4,'|');

           t_plcontas.cod_conta  :=  f_get_string(v_linha,6,'|');
           t_plcontas.descricao  :=  f_get_string(v_linha,8,'|');


            begin
              insert into treg_plano_contas_ecd values t_plcontas;

              if sql%rowcount > 0 then
                 v_commit := v_commit + 1;
              end if;

              if v_commit = 1000 then
                commit;
                v_commit := 0;
              end if;
            --
            exception
              when others then
                v_error := 'Erro: ' || sqlerrm;
            end;
            --

        END IF;
        
       -- REGISTRO CABEÇALHO DO SALDO PERIODICO DO BLOCO K300
       IF (v_linha like '|K030|%') THEN

        t_saldo.periodo            := to_date(f_get_string(v_linha,4,'|'),'ddmmrrrr');

       END IF;
       
       -- DETALHAMENTO SALDO PERIODICO DO BLOCO K300
       IF v_linha like '|K300|%' THEN


        t_saldo.cod_conta          := f_get_string(v_linha,3,'|');
        t_saldo.cod_custo          := NULL;
        t_saldo.vlr_saldo_ini      := NULL;
        t_saldo.ind_dc_ini         := NULL;
        t_saldo.vlr_deb            := NULL;
        t_saldo.vlr_cred           := NULL;
        t_saldo.vlr_saldo_fim      := f_get_string(v_linha,8,'|');
        t_saldo.ind_dc_fim         := f_get_string(v_linha,9,'|');

            --
            begin
              insert into treg_saldo_ecd values t_saldo;

              if sql%rowcount > 0 then
                 v_commit := v_commit + 1;
                 WCOUNT := WCOUNT + 1;
              end if;

              if v_commit = 1000 then
                commit;
                v_commit := 0;
              end if;
            --
            exception
              when others then
                v_error := 'Erro: ' || sqlerrm;
            end;
            --
       END IF;
       
    END IF;
    
    
    exception
      when no_data_found then
        utl_file.fclose(v_arquivo);
        COMMIT;
        exit;
    end;
  end loop;
          utl_file.fclose(v_arquivo);
          commit;
end;
/
