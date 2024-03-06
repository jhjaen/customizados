CREATE OR REPLACE PACKAGE MSAF_PARAM2_BLOCOK_CPROC IS

  --###########################################################################
  --## Autor    : Diego  Peres                                               ##
  --## Criaç?o  : 25/05/2020                                                 ##
  --## Empresa  : ATVI Consultoria                                           ##
  --## Objetivo : PARAMETRO PARA GERAÇÃO DO BLOCO K - ECD                    ##
  --###########################################################################

  /* Declaraç?o de Variáveis Públicas */
  vNome  estabelecimento.razao_social%TYPE;

  FUNCTION Parametros RETURN         VARCHAR2;
  FUNCTION Nome RETURN               VARCHAR2;
  FUNCTION Tipo RETURN               VARCHAR2;
  FUNCTION Versao RETURN             VARCHAR2;
  FUNCTION Descricao RETURN          VARCHAR2;
  FUNCTION Modulo RETURN             VARCHAR2;
  FUNCTION Classificacao RETURN      VARCHAR2;

  FUNCTION Executar(pCodEmpresa       varchar2,
                    pExercicio        varchar2,
                    pReplySafx240     varchar2,
                    pReplySafx262     varchar2,
                    --pCarregaCsv       varchar2,
                    --pGeraSafx262Aglut VARCHAR2,
                    pCarregaCsvParam  VARCHAR2,
                    pDirectory        Varchar2,
                    pFiles            lib_proc.varTab
                    ) RETURN INTEGER;

  PROCEDURE Cabecalho1(ptipo VARCHAR2);


  END MSAF_PARAM2_BLOCOK_CPROC;
/
CREATE OR REPLACE PACKAGE BODY MSAF_PARAM2_BLOCOK_CPROC IS

  --###########################################################################
  --## Autor    : Diego  Peres                                               ##
  --## Criaç?o  : 25/05/2020                                                 ##
  --## Empresa  : ATVI Consultoria                                           ##
  --## Objetivo : PARAMETRO PARA GERAÇÃO DO BLOCO K - ECD                    ##
  --## Ajustes  :                                                            ##
  --##            001 - Felipe Guimaraes 19/04/2021                          ##
  --##            Permitir geracao da SAFX262 atraves das aglutinacoes       ##
  --##            Ajustes para recuperar grupo de cadastro                   ##
  --###########################################################################

  musuario        usuario_estab.cod_usuario%TYPE;
  mcod_empresa    empresa.cod_empresa%type;
  mcod_estab      estabelecimento.cod_estab%type;


    mLinha            VARCHAR2(4000);

  v_linha         varchar2(32767) := '';
  v_arquivo       utl_file.file_type;
  wDelimiter      char(1) := ';';
  v_commit        number :=0;
  v_error         varchar2(255) := null;

  t_x262          sped_contas_emp_cons%rowtype := null;
  t_sx262         safx262%rowtype := null;

  v_num           number :=0;
  v_qtde_reg      number :=0;

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

   function form_vlr(p_valor in number) return varchar2 is
    begin
      return trim(to_char(p_valor,'FM999G999G999G999G990D99990','nls_numeric_characters='',.'''));
    end;

   function form_cnpj(p_valor in varchar2) return varchar2 is
    begin

      if length(p_valor) = '11' then
         return trim(regexp_replace(LPAD(p_valor, 11, '0'), '([0-9]{3})([0-9]{3})([0-9]{3})([0-9]{2})','\1.\2.\3-\4'));
      else
         return trim(regexp_replace(LPAD(p_valor, 15, '0'),'([0-9]{3})([0-9]{3})([0-9]{3})([0-9]{4})([0-9]{2})','\1.\2.\3/\4-\5'));
      end if;
    end;

  FUNCTION Parametros RETURN VARCHAR2 IS
    pstr VARCHAR2(5000);
  BEGIN

    mcod_empresa                  := LIB_PARAMETROS.RECUPERAR('EMPRESA');
    mcod_estab                    := LIB_PARAMETROS.RECUPERAR('ESTABELECIMENTO');
    musuario                      := LIB_PARAMETROS.Recuperar('USUARIO');


    select razao_social
      into vNome
      from empresa
     where cod_empresa = mcod_empresa;

     IF
       TRIM(mcod_estab) IS NULL THEN
       SELECT      cod_estab
              INTO mcod_estab
              FROM estabelecimento
       WHERE  cod_empresa = mcod_empresa
       AND    ind_matriz_filial = 'M';
     END IF;


   v_num := carrega_arquivos('CSV');

    -- :1
    LIB_PROC.add_param(pstr,
                       'Empresa Consolidadora',
                       'Varchar2',
                       'Combobox',
                       'S',
                       mcod_empresa,
                       NULL,
                       'SELECT e.cod_empresa,e.cod_empresa  || '' - '' || e.razao_social FROM empresa e where e.cod_empresa = ' || mcod_empresa || 'ORDER BY  e.cod_empresa ASC');

    -- :2
    Lib_Proc.Add_Param(Pstr,
                       'Exercício',
                       'varchar2',
                       'Textbox',
                       'S',
                       NULL,
                       'XXXX',
                       null,
                       null,
                       null
                       /*'select ''N'' from dual where :5 <> ''S'''*/);



   -- :3
    LIB_PROC.add_param(pstr,
                       'Replicar SAFX240 - Periodo Anterior',
                       'Varchar2',
                       'CheckBox',
                       'N',
                        null,
                        null);

    -- :4
    LIB_PROC.add_param(pstr,
                       'Replicar SAFX262 - Periodo Anterior',
                       'Varchar2',
                       'CheckBox',
                       'N',
                        null,
                        null);


   -- :5
/*   
    LIB_PROC.add_param(pstr,
                       'Carregar CSV - SAFX262',
                       'Varchar2',
                       'CheckBox',
                       'N',
                        null,
                        null);

*/
/*
    -- :5
    lib_proc.add_param(pparam      => pstr,
                       ptitulo     => 'Carregar CSV - SAFX262',
                       ptipo       => 'varchar2',
                       pcontrole   => 'checkbox',
                       pmandatorio => NULL,
                       pdefault    => 'N',
                       pmascara    => NULL,
                       pvalores    => NULL,
                       papresenta  => 'S',
                       phabilita   => 'S');
*/

   -- :6
/*
    LIB_PROC.add_param(pstr,
                       'Gerar SAFX262 através da estrutura de aglutinações (SAFX2102 e SAFX2103)',
                       'Varchar2',
                       'CheckBox',
                       'N',
                        null,
                        null);
*/

   -- :5
    LIB_PROC.add_param(pstr,
                       'Carregar CSV - Parametrizações de Contas Detentoras, Contrapartidas e Eliminações',
                       'Varchar2',
                       'CheckBox',
                       'N',
                        null,
                        null);

    --:6
    LIB_PROC.add_param(pstr,
                       'Selecione o Diretório: ',
                       'Varchar2',
                       'Combobox',
                       'N',
                       NULL,
                       NULL,
                       'SELECT A.DIRECTORY_NAME,A.DIRECTORY_NAME || '' - '' || A.DIRECTORY_PATH FROM ALL_DIRECTORIES A ORDER BY 1',
                       NULL,
                       'S'
                       );



    --:7
    LIB_PROC.add_param(pstr,
                       'Arquivos no Diretório',
                       'Varchar2',
                       'MultiSelect',
                       'N',
                       NULL,
                       NULL,
                       'select x.file_name, x.file_name  from t_aux_files2 x where directory_name = :6'
                       );


    RETURN pstr;
  END;

  FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN '2.0 - Carga e Geração de parâmetros (SAFX240, SAFX262, Contas Detentoraras e Contrapartidas) - ECD';
  END Nome;

  FUNCTION Tipo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Bloco K - ECD';
  END Tipo;

  FUNCTION Versao RETURN VARCHAR2 IS
  BEGIN
    RETURN '1.0';
  END;

  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN '- SAFX240 - Replicar dados de periodos anteriores'||chr(13)||
           '- SAFX262 - Replicar dados de periodos anteriores'||chr(13)||
           '- Carregar CSV de parametros de geração do bloco k (Contas Detentoras, Contrapartidas e eliminacoes)';
  END;

  FUNCTION Modulo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Bloco K - ECD';
  END;

  FUNCTION Classificacao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Bloco K - ECD';
  END;


  FUNCTION Executar(pCodEmpresa       varchar2,
                    pExercicio        varchar2,
                    pReplySafx240     varchar2,
                    pReplySafx262     varchar2,
                    --pCarregaCsv       varchar2,
                    --pGeraSafx262Aglut VARCHAR2,
                    pCarregaCsvParam  VARCHAR2,
                    pDirectory        Varchar2,
                    pFiles            lib_proc.varTab
                    ) RETURN INTEGER IS

    /* Variaveis de Trabalho */
    mproc_id          INTEGER;
    vn_rel            number:=1;
    vs_nome_interface varchar2(300);
    vs_nome_rel       varchar2(3000);
    vs_processo       varchar2(100);
    vs_msg            varchar2(200):=null;

    v_data_ini        varchar2(8) := null;
    v_data_fim        varchar2(8) := null;

    v_grupo           sped_contas_emp_cons.grupo_conta%TYPE;

    v_finalizar       number := 0;

    Status_w         INTEGER;
    RazaoEst_w       ESTABELECIMENTO.RAZAO_SOCIAL%TYPE;
    CGC_w            ESTABELECIMENTO.CGC%TYPE;
    linha_log       varchar2(100);

    Finalizar EXCEPTION;
    exSelecao EXCEPTION;

    rParam_ecd      msaf_param_blocok_ecd%ROWTYPE;

    vn_cont         INTEGER := 0;


  BEGIN


      BEGIN

            mproc_id := LIB_PROC.new('MSAF_PARAM2_BLOCOK_CPROC');
            LIB_PROC.add_log('Log gerado', 1);


    /***************************************************/
    /* Inclui Header/Footer do Log de Erros            */
    /***************************************************/
    linha_log := 'Log de Processo: '||mproc_id;
    lib_proc.Add_Log('.                                                                                                        '||linha_log, 0);


    lib_proc.Add_Log(rpad('-', 200, '-'), 0);
    lib_proc.Add_Log(' ', 0);

    /***************************************************************/
    /* Validação de datas inicial e final informadas com parâmetro */
    /***************************************************************/

     if pReplySafx240 = 'S' then
         PRC_REPLY_PARAM(COD_EMPRESA => pCodEmpresa,
                         TIPO => 'SAFX240',
                         ORIGEM => pExercicio - 1,
                         DESTINO => pExercicio);

     end if;

     -- regra selecao carga csv
     /*
     IF
       pCarregaCsv = 'S' AND pCarregaCsvParam = 'S' THEN
       lib_proc.add_log('Selecione apenas uma opção de carga CSV por vez.',1);
       lib_proc.add_log('Processamento não realizado.',1);

       RAISE exSelecao;

     END IF;
     */

     if pReplySafx262 = 'S' then
         PRC_REPLY_PARAM(COD_EMPRESA => pCodEmpresa,
                         TIPO => 'SAFX262',
                         ORIGEM => pExercicio - 1,
                         DESTINO => pExercicio);

     end if;
     
     /*

     if (pCarregaCsv = 'S' and pDirectory is not null) THEN

     execute immediate 'truncate table safx262';

      -- grupo x2002
      saf_pega_grupo(P_CD_EMPR       => mcod_empresa,
                     P_CD_ESTAB      => mcod_estab,
                     P_CD_TABELA     => '2002',
                     P_VALID_INICIAL => ADD_MONTHS(TRUNC (SYSDATE, 'YEAR'), -1 ) +30,  -- recupera o grupo de cadastro referente ano anterior
                     P_GRUPO         => v_grupo);

      for i IN pFiles.FIRST..pFiles.LAST  loop

        v_arquivo      := utl_file.fopen(pDirectory, pFiles(i), 'R');
       -- v_arquivo      := utl_file.fopen(pDirectory, 'safx262.csv', 'R');

        loop
            begin
              utl_file.get_line(v_arquivo, v_linha);
              v_linha := replace(v_linha, '"', '');

               if v_linha not like '%COD_EMPRESA%' then

                t_x262.cod_empresa    := SUBSTR(v_linha,1,(INSTR(v_linha, wDelimiter, 1, 1) - 1));
                t_x262.cod_estab      := SUBSTR(v_linha,INSTR(v_linha, wDelimiter, 1, 1) + 1,(INSTR(v_linha, wDelimiter, 1, 2) - INSTR(v_linha, wDelimiter, 1, 1) - 1));
                v_data_ini            := SUBSTR(v_linha,INSTR(v_linha, wDelimiter, 1, 2) + 1,(INSTR(v_linha, wDelimiter, 1, 3) - INSTR(v_linha, wDelimiter, 1, 2) - 1));
                t_x262.data_ini_cons  := to_date(substr(v_data_ini, 7, 2) || '/' ||  substr(v_data_ini, 5, 2) || '/' || substr(v_data_ini, 1, 4), 'dd/mm/rrrr');
                v_data_fim            := SUBSTR(v_linha,INSTR(v_linha, wDelimiter, 1, 3) + 1,(INSTR(v_linha, wDelimiter, 1, 4) - INSTR(v_linha, wDelimiter, 1, 3) - 1));
                t_x262.data_fim_cons  := to_date(substr(v_data_fim, 7, 2) || '/' ||  substr(v_data_fim, 5, 2) || '/' || substr(v_data_fim, 1, 4), 'dd/mm/rrrr');
                t_x262.cod_emp_part   := SUBSTR(v_linha,INSTR(v_linha, wDelimiter, 1, 4) + 1,(INSTR(v_linha, wDelimiter, 1, 5) - INSTR(v_linha, wDelimiter, 1, 4) - 1));
               -- t_x262.grupo_conta    := SUBSTR(v_linha,INSTR(v_linha, wDelimiter, 1, 5) + 1,(INSTR(v_linha, wDelimiter, 1, 6) - INSTR(v_linha, wDelimiter, 1, 5) - 1));
                t_x262.grupo_conta    := v_grupo;
                t_x262.cod_conta      := SUBSTR(v_linha,INSTR(v_linha, wDelimiter, 1, 5) + 1,(INSTR(v_linha, wDelimiter, 1, 6) - INSTR(v_linha, wDelimiter, 1, 5) - 1));
                t_x262.cod_conta_cons := trim(SUBSTR(v_linha,INSTR(v_linha, wDelimiter, 1, 6) + 1, 70));

                -- alteracao para inserir dados na safx262
                t_sx262.cod_empresa := t_x262.cod_empresa;
                t_sx262.COD_ESTAB   := t_x262.cod_estab;
                t_sx262.DATA_INI_CONS := to_char(t_x262.data_ini_cons,'yyyymmdd');
                t_sx262.DATA_FIM_CONS := to_char(t_x262.data_fim_cons,'yyyymmdd');
                t_sx262.COD_EMP_PART  := t_x262.cod_emp_part;
                t_sx262.COD_CONTA     := t_x262.cod_conta;
                t_sx262.DAT_GRAVACAO  := sysdate;
                t_sx262.COD_CONTA_CONS  := t_x262.cod_conta_cons;

                --
                begin
                  --insert into sped_contas_emp_cons values t_x262;
                  insert into safx262 values t_sx262;

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
                    LIB_PROC.add_log('Erro na carga do arquivo: ' || sqlerrm, 1);
                end;
                --
             end if;
            exception
              when no_data_found then
                utl_file.fclose(v_arquivo);
                commit;
                exit;
            end;
          end loop;

        utl_file.fclose(v_arquivo);

       end loop;
    end if;
    */

/*
    IF (pGeraSafx262Aglut = 'S') THEN

       PRC_GER262_AGLUT(pExercicio);

    NULL;

    END IF;
*/


     if (pCarregaCsvParam = 'S' and pDirectory is not null) THEN -- carga de parametros (contas detentoras e contrapartidas)

     EXECUTE IMMEDIATE 'alter session set nls_numeric_characters = '',.''';
     EXECUTE IMMEDIATE 'alter session set nls_date_format = ''dd/mm/yyyy''';

      for i IN pFiles.FIRST..pFiles.LAST  LOOP

        vn_cont := 0;

        v_arquivo      := utl_file.fopen(pDirectory, pFiles(i), 'R');

        loop
            begin
              utl_file.get_line(v_arquivo, v_linha);

              IF
                f_get_string(v_linha,1,';') NOT LIKE '%EMPRESA%' THEN
                -- inicio processamento

                BEGIN
                  rParam_ecd                    := NULL;

                  rParam_ecd.Cod_Empresa_Cons  := f_get_string(v_linha,1,';');
                  rParam_ecd.Cod_Empresa_Det   := f_get_string(v_linha,2,';');
                  rParam_ecd.Cod_Conta_Det     := f_get_string(v_linha,3,';');
                  rParam_ecd.Cod_Empresa_Contra:= f_get_string(v_linha,4,';');
                  rParam_ecd.Cod_Conta_Contra  := f_get_string(v_linha,5,';');
                  rParam_ecd.Periodo           := to_date(TRIM(f_get_string(v_linha,6,';')));
                  rParam_ecd.Vlr_Eliminacao    := TRIM(f_get_string(v_linha,7,';'));
                  rParam_ecd.Ind_Dc_Vlr_Elim   := upper(replace(replace(TRIM(f_get_string(v_linha,8,';')),chr(10),''),chr(13),''));

                  INSERT INTO msaf_param_blocok_ecd VALUES rParam_ecd;

                  vn_cont := vn_cont + SQL%ROWCOUNT;

                  EXCEPTION
                    WHEN dup_val_on_index THEN

                      UPDATE msaf_param_blocok_ecd d
                             SET d.vlr_eliminacao = rParam_ecd.Vlr_Eliminacao
                                 , d.ind_dc_vlr_elim = rParam_ecd.Ind_Dc_Vlr_Elim

                             WHERE 1=1
                             AND   d.cod_empresa_cons = rParam_ecd.Cod_Empresa_Cons
                             AND   d.cod_empresa_det  = rParam_ecd.Cod_Empresa_Det
                             AND   d.cod_conta_det    = rParam_ecd.Cod_Conta_Det
                             AND   d.cod_empresa_contra = rParam_ecd.Cod_Empresa_Contra
                             AND   d.cod_conta_contra = rParam_ecd.Cod_Conta_Contra
                             AND   d.periodo          = rParam_ecd.Periodo;

                             vn_cont := vn_cont + SQL%ROWCOUNT;

                  when others then
                  lib_proc.add_log('Erro ao inserir linha: '||v_linha ,1);
                  lib_proc.add_log(dbms_utility.format_error_backtrace ,1);
                  lib_proc.add_log('',1);
                END;

              END IF;


            exception
              when no_data_found then
                utl_file.fclose(v_arquivo);
                exit;
            end;


          end loop;

        utl_file.fclose(v_arquivo);

        lib_proc.add_log('Arquivo: '||pFiles(i)||' - '||vn_cont||' registros processados.',1);

       end loop;

       COMMIT;
    end if;



    --SAFX240
    LIB_PROC.add_tipo(mproc_id,
                      '1',
                      'SAFX240_' || pCodEmpresa || '.csv',
                      2);
    Cabecalho1('1');


    for reg1 in (select a.cod_empresa,
                        a.cod_estab,
                        a.data_ini_cons,
                        a.data_fim_cons,
                        a.cod_emp_part,
                        a.nome_emp_part,
                        a.cnpj,
                        a.data_ini_emp,
                        a.data_fim_emp,
                        a.perc_part_tot,
                        a.perc_cons
                    from x240_inf_empresa_cons a
                     where 1=1
                      and a.cod_empresa = pCodEmpresa
                      and a.data_ini_cons = '01/01/'||pExercicio
                      and a.data_fim_cons = '31/12/'||pExercicio
                     order by a.cod_emp_part) loop

              mLinha := NULL;
              mLinha := LIB_STR.w(mLinha,
                                  reg1.cod_empresa                   || wDelimiter ||
                                  reg1.cod_estab                     || wDelimiter ||
                                  reg1.data_ini_cons                 || wDelimiter ||
                                  reg1.data_fim_cons                 || wDelimiter ||
                                  reg1.cod_emp_part                  || wDelimiter ||
                                  reg1.nome_emp_part                 || wDelimiter ||
                                  form_cnpj(reg1.cnpj)               || wDelimiter ||
                                  form_vlr(reg1.perc_part_tot)       || wDelimiter ||
                                  form_vlr(reg1.perc_cons),
                                  1);
               LIB_PROC.add(mLinha, null, null, '1');
       end loop;


    --SAFX240
    LIB_PROC.add_tipo(mproc_id,
                      '2',
                      'SAFX262_' || pCodEmpresa || '.csv',
                      2);
    Cabecalho1('2');


    for reg2 in (select a.cod_empresa,
                        a.cod_estab,
                        a.data_ini_cons,
                        a.data_fim_cons,
                        a.cod_emp_part,
                        a.grupo_conta,
                        a.cod_conta,
                        a.cod_conta_cons
                    from sped_contas_emp_cons a
                     where 1=1
                      and a.cod_empresa = pCodEmpresa
                      and a.data_ini_cons = '01/01/'||pExercicio
                      and a.data_fim_cons = '31/12/'||pExercicio
                     order by a.cod_conta, a.cod_conta_cons asc) loop

              mLinha := NULL;
              mLinha := LIB_STR.w(mLinha,
                                  reg2.cod_empresa           || wDelimiter ||
                                  reg2.cod_estab             || wDelimiter ||
                                  reg2.data_ini_cons         || wDelimiter ||
                                  reg2.data_fim_cons         || wDelimiter ||
                                  reg2.cod_emp_part          || wDelimiter ||
                                  reg2.grupo_conta           || wDelimiter ||
                                  reg2.cod_conta             || wDelimiter ||
                                  reg2.cod_conta_cons,
                                  1);
               LIB_PROC.add(mLinha, null, null, '2');
       end loop;


        LIB_PROC.add_log(mproc_id || '  Processo ', 1);
        LIB_PROC.CLOSE();

        RETURN mproc_id;

        EXCEPTION
          WHEN exSelecao THEN
               LIB_PROC.CLOSE();
                RETURN mproc_id;

        END;

    END;

  PROCEDURE Cabecalho1(ptipo VARCHAR2) IS

    mLinha VARCHAR2(1000);
  BEGIN


    if ptipo = '1' then

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha,
                              'SAFX240 - Relação das Empresas Consolidadas;;;;;;;;;;;;;;;;;',
                              1);
          LIB_PROC.add(mLinha, null, null, ptipo);

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha, ';;;;;;;;;;;;;;;;;;;', 1);
          LIB_PROC.add(mLinha, null, null, ptipo);

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha,
                              'COD_EMPRESA;COD_ESTAB;DATA_INI_CONS;DATA_FIM_CONS;COD_EMP_PART;RAZAO_EMP_PART;CNPJ;PERC_PART_TOT;PERC_CONS;',
                              1);
          LIB_PROC.add(mLinha, null, null, ptipo);

    elsif ptipo = '2' then

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha,
                              'SAFX262 - Mapeamento para Plano de Contas das Empresas Consolidadas (ECD);;;;;;;;;;;;;;;;;;;;;',
                              1);

          LIB_PROC.add(mLinha, null, null, ptipo);

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha, ';;;;;;;;;;;;;;;;;;;;;;;', 1);
          LIB_PROC.add(mLinha, null, null, ptipo);

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha,
                              'COD_EMPRESA;COD_ESTAB;DATA_INI_CON;DATA_FIM_CONS;COD_EMP_PART;GRUPO_CONTA;COD_CONTA;COD_CONTA_CONS;',
                              1);
          LIB_PROC.add(mLinha, null, null, ptipo);

    end if;

  END Cabecalho1;

END MSAF_PARAM2_BLOCOK_CPROC;
/
