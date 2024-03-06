CREATE OR REPLACE PROCEDURE PRC_GER262_AGLUT (pExercicio VARCHAR2) IS


  CURSOR c262 IS (SELECT DISTINCT 
                         x240.cod_empresa
                       , x240.cod_estab
                       , '01/01/'||pExercicio        AS DATA_INI_CONS
                       , '31/12/'||pExercicio        AS DATA_FIM_CONS
--                       , emp.cod_empresa             AS COD_EMP_PART
                       , x240.cod_emp_part           AS COD_EMP_PART
--                       , x2002.grupo_conta
                       , NULL                        AS GRUPO_CONTA
                       , x2002.cod_conta
                       , x2103.cod_conta_aglut       AS COD_CONTA_CONS

                       FROM x240_inf_empresa_cons    x240
                            , empresa                emp
                            , x2103_contas_aglut_emp x2103
                            , x2002_plano_contas     x2002

                WHERE  1=1
                AND    x240.cnpj                         = emp.cnpj
                AND    x2103.cod_empresa                 = emp.cod_empresa
                AND    x2103.ident_conta                 = x2002.ident_conta
                AND    to_char(x240.data_ini_cons,'yyyy')= pExercicio
                AND    x240.cnpj NOT IN (SELECT cnpj FROM empresa WHERE cod_empresa = x240.cod_empresa) -- trazer estrutura das empresas exceto a consolidadora
                -- trazer apenas contas com saldo
                AND    x2002.cod_conta                 IN (SELECT b.cod_conta FROM x02_saldos a, x2002_plano_contas b WHERE a.ident_conta = b.ident_conta and a.cod_empresa = emp.cod_empresa AND a.data_saldo BETWEEN to_date('01/01'||pExercicio) AND to_date('31/12'||pExercicio) ) -- apenas contas com saldo no periodo
                --
                UNION -- para a empresa consolidadora, montar a estrutura apenas para contas que possuam saldos
                
                SELECT DISTINCT 
                         x240.cod_empresa
                       , x240.cod_estab
                       , '01/01/'||pExercicio        AS DATA_INI_CONS
                       , '31/12/'||pExercicio        AS DATA_FIM_CONS
--                       , emp.cod_empresa             AS COD_EMP_PART
                       , x240.cod_emp_part           AS COD_EMP_PART
--                       , x2002.grupo_conta
                       , NULL                        AS GRUPO_CONTA
                       , x2002.cod_conta
                       , x2103.cod_conta_aglut       AS COD_CONTA_CONS

                       FROM x240_inf_empresa_cons    x240
                            , empresa                emp
                            , x2103_contas_aglut_emp x2103
                            , x2002_plano_contas     x2002

                WHERE  1=1
                AND    x240.cnpj                         = emp.cnpj
                AND    x2103.cod_empresa                 = emp.cod_empresa
                AND    x2103.ident_conta                 = x2002.ident_conta
                AND    to_char(x240.data_ini_cons,'yyyy')= pExercicio
                AND    x240.cnpj IN (SELECT cnpj FROM empresa WHERE cod_empresa = x240.cod_empresa)
                AND    x2002.cod_conta                 IN (SELECT b.cod_conta FROM x02_saldos a, x2002_plano_contas b WHERE a.ident_conta = b.ident_conta and a.cod_empresa = x240.cod_empresa AND a.data_saldo BETWEEN to_date('01/01'||pExercicio) AND to_date('31/12'||pExercicio) ) -- apenas contas com saldo no periodo
                
                );

  v_cont             INTEGER := 0;
  v_cont_commit      INTEGER := 0;
  
  v_Erro             BOOLEAN := FALSE;
  
  v_grupo            relac_tab_grupo.grupo_estab%TYPE;

  BEGIN

     FOR x262 IN c262
       LOOP
         
        -- recuperacao do grupo de cadastros e data do plano de contas da empresa consolidadora
                
        -- grupo x2002  
        saf_pega_grupo(P_CD_EMPR       => x262.cod_empresa,
                       P_CD_ESTAB      => x262.cod_estab,
                       P_CD_TABELA     => '2002',
                       P_VALID_INICIAL => x262.DATA_FIM_CONS,
                       P_GRUPO         => v_grupo);
         
       BEGIN
         
        INSERT INTO sped_contas_emp_cons(cod_empresa,
                                         cod_estab,
                                         data_ini_cons,
                                         data_fim_cons,
                                         cod_emp_part,
                                         grupo_conta,
                                         cod_conta,
                                         cod_conta_cons)
                                         VALUES
                                         (x262.cod_empresa,
                                          x262.cod_estab,
                                          x262.data_ini_cons,
                                          x262.data_fim_cons,
                                          x262.cod_emp_part,
                                          v_grupo,
                                          x262.cod_conta,
                                          x262.cod_conta_cons
                                         );
                                         
        v_cont        := v_cont + SQL%ROWCOUNT;
        v_cont_commit := v_cont_commit + SQL%ROWCOUNT;
        
        IF
          v_cont_commit >= 2000
           THEN
             COMMIT;
             v_cont_commit := 0;
        END IF;
         
       
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            
            update sped_contas_emp_cons d
                   set d.COD_CONTA_CONS = x262.cod_conta_cons
            where  1=1
            and    d.COD_EMPRESA = x262.cod_empresa
            and    d.COD_ESTAB   = x262.cod_estab
            and    d.DATA_INI_CONS = x262.data_ini_cons
            and    d.DATA_FIM_CONS = x262.data_fim_cons
            and    d.COD_EMP_PART  = x262.cod_emp_part
            and    d.GRUPO_CONTA   = v_grupo
            and    d.COD_CONTA     = x262.cod_conta;
            
            v_cont        := v_cont + SQL%ROWCOUNT;
            v_cont_commit := v_cont_commit + SQL%ROWCOUNT;
            
            IF
              v_cont_commit >= 2000
               THEN
                 COMMIT;
                 v_cont_commit := 0;
            END IF;
            
            
          WHEN OTHERS THEN
          lib_proc.add_log('Erro ao inserir informações na tabela sped_contas_emp_cons. '||SQLERRM||' - '||dbms_utility.format_error_backtrace,1);
       END;
         
       END LOOP;


     COMMIT;
     
     IF
       v_Erro THEN
       lib_proc.add_log('Houveram erros ao criar a SAFX262, gentileza verificar os logs',1);
     ELSE
       IF v_cont > 0
         THEN
          lib_proc.add_log('Geração da SAFX262 finalizada com sucesso. Foram criados '||v_cont||' registros.',1);
       ELSE
          lib_proc.add_log('Não foram encontrados registros para geração. Certifique-se que as parametrizações tenham sido realizadas para o exercício de '||pExercicio||'.',1);
       END IF;   
       
     END IF;

  END;
/
