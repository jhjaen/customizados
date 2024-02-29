CREATE OR REPLACE PACKAGE MSAF_PARAM_BLOCOK_CPROC IS

  --###########################################################################
  --## Autor    : Diego  Peres                                               ##
  --## Cria�?o  : 25/05/2020                                                 ##
  --## Empresa  : ATVI Consultoria                                           ##
  --## Objetivo : PARAMETRO PARA GERA��O DO BLOCO K - ECD                    ##
  --###########################################################################

  -- Declara�?o de Vari�veis P�blicas */
  vNome  estabelecimento.razao_social%TYPE;

  FUNCTION Parametros RETURN         VARCHAR2;
  FUNCTION Nome RETURN               VARCHAR2;
  FUNCTION Tipo RETURN               VARCHAR2;
  FUNCTION Versao RETURN             VARCHAR2;
  FUNCTION Descricao RETURN          VARCHAR2;
  FUNCTION Modulo RETURN             VARCHAR2;
  FUNCTION Classificacao RETURN      VARCHAR2;


  FUNCTION Executar(pCodEmpConsol        VARCHAR2,
                    pPeriodo             varchar2,
                    pCodEmpDetent        VARCHAR2,
                    pCodContaDet         VARCHAR2,
                    pCodEmpContPart      VARCHAR2,
                    pCodContaContPart    VARCHAR2,
                    pIndElimin           varchar2,
                    pUtilSaldo           varchar2,
                    pVlrElimin           varchar2,
                    pIndDCElimin         varchar2,
                    pTipo                Varchar2,
                    pRegistro            lib_proc.varTab
                    ) RETURN INTEGER;

  PROCEDURE MONTA_LINHA (PS_LINHA IN VARCHAR2, vn_rel number);

  procedure cabecalho(ps_nome_rel            varchar2
                   ,vn_rel                 number
                   ,vs_razao_social_matriz varchar2
                   ,vs_cnpj_matriz         varchar2
                   ,vn_num_processo        varchar2
               --    ,vd_data_ini            date
               --    ,vd_data_fim            date
                   ,vs_nome_interface      varchar2);

  procedure final_html(vn_rel number);

procedure dados_relatorio (vs_cod_empresa_cons     VARCHAR2
                          ,vs_cod_empresa_det      VARCHAR2
                          ,vs_conta_det            varchar2
                          ,vs_cod_empresa_contra   varchar2
                          ,vs_conta_contra         varchar2
                          ,vs_AnoCompet        varchar2
                          ,vs_VlrElimin        varchar2
                          ,vs_IndElimin        varchar2
                          ,vn_rel              number
                          ,vs_utiliza_saldo    varchar2);


  END MSAF_PARAM_BLOCOK_CPROC;
/
CREATE OR REPLACE PACKAGE BODY MSAF_PARAM_BLOCOK_CPROC IS

  --###########################################################################
  --## Autor    : Diego  Peres                                               ##
  --## Cria�?o  : 25/05/2020                                                 ##
  --## Empresa  : ATVI Consultoria                                           ##
  --## Objetivo : PARAMETRO PARA GERA��O DO BLOCO K - ECD                    ##
  --## Ajustes  :                                                            ##
  --##            001 - Felipe Guimaraes 21/04/2021                          ##
  --##            Permitir replicacao dos parametros de periodos anteriores  ##
  --##                                                                       ##
  --##            002 - Felipe Guimaraes 28/04/2021                          ##
  --##            Ajuste de parametros / Ajuste relatorio html               ##
  --###########################################################################

  musuario        usuario_estab.cod_usuario%TYPE;
  mcod_empresa    empresa.cod_empresa%type;
  mcod_estab      estabelecimento.cod_estab%type;

  v_grupo         x2002_plano_contas.grupo_conta%TYPE;

   function form_vlr(p_valor in number) return varchar2 is
    begin
      return trim(to_char(p_valor,'FM999G999G999G999G990D90','nls_numeric_characters='',.'''));
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
    BEGIN
      EXECUTE IMMEDIATE 'alter session set nls_numeric_characters = '',.'' ';
      exception
        when others then
          lib_proc.add_log('Falha ao alterar sessao para nls_numeric: '||SQLERRM,1);
    end;

   musuario                      := LIB_PARAMETROS.Recuperar('USUARIO');
   mcod_empresa                  := LIB_PARAMETROS.RECUPERAR('EMPRESA');
   mcod_estab                    := NVL(LIB_PARAMETROS.RECUPERAR('ESTABELECIMENTO'), '');

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

      -- grupo x2002
      saf_pega_grupo(P_CD_EMPR       => mcod_empresa,
                     P_CD_ESTAB      => mcod_estab,
                     P_CD_TABELA     => '2002',
                     P_VALID_INICIAL => ADD_MONTHS(TRUNC (SYSDATE, 'YEAR'), -1 ) +30,  -- recupera o grupo de cadastro referente ano anterior
                     P_GRUPO         => v_grupo);



    -- :1
    LIB_PROC.add_param(pstr,
                       'Empresa Consolidadora',
                       'Varchar2',
                       'Combobox',
                       'N',
                       mcod_empresa,
                       NULL,
                       'SELECT e.cod_empresa,e.cod_empresa  || '' - '' || e.razao_social FROM empresa e where e.cod_empresa = ' || mcod_empresa || 'ORDER BY  e.cod_empresa ASC');

    -- :2
    Lib_Proc.Add_Param(Pstr,
                       'Per�odo',
                       'date',
                       'Textbox',
                       'S',
                       NULL,
                       'mm/yyyy',
                       null,
                       null,
                       'S');

    -- :3
    LIB_PROC.add_param(pstr,
                       'Empresa Detentora',
                       'Varchar2',
                       'Combobox',
                       'N',
                       NULL,
                       NULL,
                       'SELECT distinct e.cod_emp_part,e.cod_emp_part  || '' - '' || e.nome_emp_part FROM x240_inf_empresa_cons e where e.cod_empresa = :1 and :2 between e.data_ini_cons and e.data_fim_cons ORDER BY  e.cod_emp_part ASC',
                       NULL,
                       ':11 in (''1'',''2'')');


    -- :4
    LIB_PROC.add_param(pstr,
                       'Conta Cont�bil Detentora',
                       'Varchar2',
                       'TextBox',
                       'N',
                       null,
                       null,
                       'SELECT distinct V.COD_CONTA, V.DESCRICAO FROM X2002_PLANO_CONTAS V  WHERE V.IND_CONTA = ''A'' AND V.IND_SITUACAO = ''A''
                             AND V.GRUPO_CONTA = '''||v_grupo||''' AND V.VALID_CONTA = (SELECT MAX(A.VALID_CONTA) FROM X2002_PLANO_CONTAS A  WHERE A.COD_CONTA = V.COD_CONTA AND A.GRUPO_CONTA = '''||v_grupo||''') ORDER BY V.COD_CONTA ASC',
                       NULL,
                       ':11 in (''1'',''2'')');


    -- :5
    LIB_PROC.add_param(pstr,
                       'Empresa Contra-partida',
                       'Varchar2',
                       'Combobox',
                       'N',
                       NULL,
                       NULL,
                       'SELECT distinct e.cod_emp_part,e.cod_emp_part  || '' - '' || e.nome_emp_part FROM x240_inf_empresa_cons e where e.cod_empresa = :1 and :2 between e.data_ini_cons and e.data_fim_cons ORDER BY  e.cod_emp_part ASC',
                       null,
                       ':11 in (''1'',''2'')'
                       );

    -- :6
    LIB_PROC.add_param(pstr,
                       'Conta Cont�bil Contra-Partida',
                       'Varchar2',
                       'TextBox',
                       'N',
                       null,
                       null,
                       'SELECT distinct V.COD_CONTA, V.DESCRICAO FROM X2002_PLANO_CONTAS V  WHERE V.IND_CONTA = ''A'' AND V.IND_SITUACAO = ''A''
                             AND V.GRUPO_CONTA = '''||v_grupo||''' AND V.VALID_CONTA = (SELECT MAX(A.VALID_CONTA) FROM X2002_PLANO_CONTAS A  WHERE A.COD_CONTA = V.COD_CONTA AND A.GRUPO_CONTA = '''||v_grupo||''') ORDER BY V.COD_CONTA ASC',
                       null,
                       ':11 in (''1'',''2'')'
                       );



    -- :7
    LIB_PROC.add_param(pstr,
                       'Informar Elimina��es',
                       'Varchar2',
                       'CheckBox',
                       'N',
                        null,
                        null,
                        NULL,
                        NULL,
                        ':11 in (''1'',''2'')');
                        
    -- :8
    lib_proc.add_param(pparam      => pstr,
                       ptitulo     => 'Utilizar saldo final',
                       ptipo       => 'varchar2',
                       pcontrole   => 'checkbox',
                       pmandatorio => 'S',
                       pdefault    => 'N',
                       pmascara    => null,
                       pvalores    => null,
                       papresenta  => 'S',
                       phabilita   => ':11 in (''1'',''2'')');


    -- :9
    Lib_Proc.Add_Param(Pstr,
                       'Valor Elimina��o',
                       'varchar2',
                       'Textbox',
                       'N',
                       NULL,
                       'XXXXXXXXXXXXXXXXX',
                      -- null,
                       null,
                       null,
                       ':11 in (''1'',''2'') and :7 = ''S''');

    -- :10
    Lib_Proc.Add_Param(Pstr,
                       'Indicador Debito/Credito',
                       'Varchar2',
                       'combobox',
                       'N',
                       NULL,
                       'XXXXXXXXXXXX',
                        'select ''D'',''D - Debito'' from dual union all
                         select ''C'',''C - Credito'' from dual order by 1',
                       null,
                       ':11 in (''1'',''2'') and :7 = ''S'''
                         );

    -- :11
    LIB_PROC.add_param(pstr,
                       'Opera��o',
                       'Varchar2',
                       'radiobutton',
                       'S',
                        '3',
                        null,
                        '1=Incluir,' || '2=Excluir,' || '3=Relat�rio Confer�ncia,' || '4=Replicar par�metros do periodo anterior');

    -- :12
    LIB_PROC.add_param(pstr,
                       'Parametros Cadastrados',
                       'Varchar2',
                       'MultiSelect',
                       'N',
                       NULL,
                       NULL,
                       'select a.rowid_param1, a.descr_param from vw_param_ecd_k a where a.cod_empresa_cons = :1 and last_day(add_months(a.periodo,-1))+1 = :2 and a.COD_EMPRESA_DET = :3 and a.COD_EMPRESA_CONTRA = :5 ORDER BY 2 asc');


    RETURN pstr;
  END;

  FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN '3.0 - Parametro Gera��o do Bloco K - ECD';
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
    RETURN 'Parametro Para Cadastro das Regras de Consolida��o para Gera��o do Bloco K - ECD';
  END;

  FUNCTION Modulo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Bloco K - ECD';
  END;

  FUNCTION Classificacao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Bloco K - ECD';
  END;


  FUNCTION Executar(pCodEmpConsol        VARCHAR2,
                    pPeriodo             varchar2,
                    pCodEmpDetent        VARCHAR2,
                    pCodContaDet         VARCHAR2,
                    pCodEmpContPart      VARCHAR2,
                    pCodContaContPart    VARCHAR2,
                    pIndElimin           varchar2,
                    pUtilSaldo           varchar2,
                    pVlrElimin           varchar2,
                    pIndDCElimin         varchar2,
                    pTipo                Varchar2,
                    pRegistro            lib_proc.varTab
                    ) RETURN INTEGER IS

    -- Variaveis de Trabalho */
    mproc_id          INTEGER;
    --mLinha            VARCHAR2(1000);
    --v_tipo            varchar2(100);
    mcod_empresa      varchar2(100); --empresa.cod_empresa%type;
    --v_result          varchar2(10) := null;
    v_rowid           varchar2(50);
    vn_rel            number:=1;
    vs_nome_interface varchar2(300);
    vs_nome_rel       varchar2(3000);
    vs_processo       varchar2(100);
    v_count           number:=0;
    vs_msg            varchar2(200);
    --v_ind_ext         varchar2(1) := null;
    --v_movto           varchar2(1) :=null;

    vVlrElimin        number :=0;

    v_finalizar       number := 0;

    --Status_w         INTEGER;
    RazaoEmp_w       EMPRESA.RAZAO_SOCIAL%TYPE;
    RazaoEst_w       ESTABELECIMENTO.RAZAO_SOCIAL%TYPE;
    CGC_w            ESTABELECIMENTO.CGC%TYPE;
    --Ind_Atividade_w  ESTABELECIMENTO.Ind_Atividade%type;
    --IndConvIcms_w    ESTABELECIMENTO.IND_CONV_ICMS%TYPE;
    --CodAtividade_w   ESTABELECIMENTO.COD_ATIVIDADE%TYPE;
    --UF_estab_w       ESTADO.COD_ESTADO%TYPE;
    linha_log       varchar2(100);

    --Finalizar EXCEPTION;


  BEGIN
    BEGIN

      mproc_id := LIB_PROC.new('MSAF_PARAM_BLOCOK_CPROC');
      LIB_PROC.add_log('Log gerado', 1);
        --    Mcod_Empresa := Pcod_empresa; --Lib_Parametros.Recuperar('EMPRESA');


     /**************************************************
     Inclui Header/Footer do Log de Erros            
     **************************************************/
      lib_proc.Add_Log(RazaoEmp_w, 0);
     --   lib_proc.Add_Log('Filial: ' || Pcod_Estab || ' - ' || RazaoEst_w, 0);
     --   lib_proc.Add_Log('CNPJ: '   || CGC_w, 0);
      lib_proc.Add_Log('.                                                                                                          Relat�rio de Log', 0);
     --  lib_proc.Add_Log('.                                                                                               Dt.Ini : ' ||
     --      to_date(pData_Ini,'DD/MM/YYYY') || '  -  Dt.Fim: ' ||to_date(pData_Fim,'DD/MM/YYYY') , 0);

      linha_log := 'Log de Processo: '||mproc_id;
      lib_proc.Add_Log('.                                                                                                        '||linha_log, 0);


      lib_proc.Add_Log(rpad('-', 200, '-'), 0);
      lib_proc.Add_Log(' ', 0);

     /**************************************************************
     Valida��o de datas inicial e final informadas com par�metro 
     **************************************************************/

      if pTipo = '1' then

        If pCodEmpConsol is null Then
           lib_proc.Add_Log('Erro: A Empresa Consolidadora deve ser informada para Inclus�o.', 0);
           lib_proc.Add_Log(' ', 0);
           v_finalizar := v_finalizar + 1;
        End If;

        If pCodEmpDetent is null Then
           lib_proc.Add_Log('Erro: A Empresa Detentora dos valores deve ser informada para Inclus�o.', 0);
           lib_proc.Add_Log(' ', 0);
           v_finalizar := v_finalizar + 1;
        End If;

        If pCodContaDet is null Then
           lib_proc.Add_Log('Erro: O campo C�digo da Conta Cont�bil da Empresa Detentora dos valores deve ser informado para Inclus�o.', 0);
           lib_proc.Add_Log(' ', 0);
           v_finalizar := v_finalizar + 1;
        End If;

        If pCodEmpContPart is null and pUtilSaldo = 'N' Then
           lib_proc.Add_Log('Erro: A Empresa Contra-Partida dos valores deve ser informada para Inclus�o.', 0);
           lib_proc.Add_Log(' ', 0);
           v_finalizar := v_finalizar + 1;
        End If;

        If pCodContaContPart is null and pUtilSaldo = 'N' Then
           lib_proc.Add_Log('Erro: O campo C�digo da Conta Cont�bil da Empresa Contra-Partida dos valores deve ser informado para Inclus�o.', 0);
           lib_proc.Add_Log(' ', 0);
           v_finalizar := v_finalizar + 1;
        End If;



        if pIndElimin = 'S' then
          begin
           vVlrElimin :=  to_number(nvl(pVlrElimin, 0));
          exception
            when others then
                 lib_proc.Add_Log('Erro: O campo Valor da Elimina��o deve ser n�merico.', 0);
                 lib_proc.Add_Log(' ', 0);
                 v_finalizar := v_finalizar + 1;
           end;
        end if;

          if pPeriodo is null then
             lib_proc.Add_Log('Erro: A compet�ncia deve ser informado para Inclus�o.', 0);
             lib_proc.Add_Log(' ', 0);
             v_finalizar := v_finalizar + 1;

          end if;


        if v_finalizar > 0 then
            lib_proc.CLOSE;
            RETURN mproc_id;
        end if;

      end if;

      LIB_PROC.add_tipo(mproc_id, vn_rel, 'ECD_BLOCOK', 3,48,150, '8', 'Relatorio');

      vs_nome_rel := 'Bloco K - ECD';
      vs_nome_interface := 'Par�metro para Determinar o Crit�rio de Consolida��o das Interfaces SAFX242, SAFX243 e SAFX244';

      if pTipo = '1' then
        begin
          INSERT INTO MSAF_PARAM_BLOCOK_ECD
                                    (COD_EMPRESA_CONS,
                                      COD_EMPRESA_DET,
                                      COD_CONTA_DET,
                                      COD_EMPRESA_CONTRA,
                                      COD_CONTA_CONTRA,
                                      PERIODO,
                                      VLR_ELIMINACAO,
                                      IND_DC_VLR_ELIM,
                                      IND_UTILIZA_SALDO_FIM)
                                    VALUES
                                      ( pCodEmpConsol,
                                        pCodEmpDetent,
                                        pCodContaDet,
                                        pCodEmpContPart,
                                        pCodContaContPart,
                                        last_day(pPeriodo),
                                        nvl(vVlrElimin, 0),
                                        pIndDCElimin,
                                        pUtilSaldo
                                       );

          --LIB_PROC.add_log('PARAMETRO INCLUIDO COM SUCESSO', 1);
          vs_msg := 'Inclus�o realizada com sucesso';
          exception
            when DUP_VAL_ON_INDEX then
              vs_msg := 'Conta Detentora e Conta Contra-Partida j� cadastrada para esta empresa Consolidadora';
              --LIB_PROC.add_log('Conta Detentora e Conta Contra-Partida j� cadastrada para esta empresa Consolidadora', 1);

          begin
            update MSAF_PARAM_BLOCOK_ECD k
                                SET k.vlr_eliminacao       = nvl(vVlrElimin, 0)
                                   ,k.ind_dc_vlr_elim      = pIndDCElimin
                                   ,k.ind_utiliza_saldo_fim = pUtilSaldo
                              where 1=1
                                and k.cod_empresa_cons  = pCodEmpConsol
                                and k.periodo           = last_day(pPeriodo)
                                AND k.cod_empresa_det   = pCodEmpDetent
                                and k.cod_conta_det     = pCodContaDet
                                AND k.cod_empresa_contra  = pCodEmpContPart
                                AND k.cod_conta_contra    = pCodContaContPart;

            LIB_PROC.add_log('PARAMETRO Atualizado', 1);
            vs_msg := 'Parametro atualizado';
            exception
              when others then
                raise_application_error(-20102, 'Nao foi possivel Atualizar o Registro, Verificar os dados' || sqlerrm);
          end;

          when OTHERS then
            raise_application_error(-20102, 'Nao foi possivel Inserir o Registro, Verificar os dados' || sqlerrm);

        end;


        LIB_PROC.add_log('PARAMETRO INCLUIDO COM SUCESSO', 1);
        -- ### RELATORIO - HTML
        vs_processo       := 'Inclus�o';
        cabecalho(vs_nome_rel
                             ,vn_rel
                             ,RazaoEst_w
                             ,CGC_w
                             ,vs_processo
                             ,vs_nome_interface
                             );
         /*dados_relatorio(vs_cod_empresa1 => pCodEmpConsol,
                                   vs_conta1 => pCodContaDet,
                                   vs_cod_empresa2 => pCodEmpDetent,
                                   vs_conta2 => pCodContaDet,
                                   vs_AnoCompet => pAnoCompetencia,
                                   vs_VlrElimin => form_vlr(nvl(vVlrElimin,0)),
                                   vs_IndElimin => pIndDCElimin,
                                   vn_rel => vn_rel);    */

        dados_relatorio(vs_cod_empresa_cons   => pCodEmpConsol,
                             vs_cod_empresa_det    => pCodEmpDetent,
                             vs_conta_det          => pCodContaDet,
                             vs_cod_empresa_contra => pCodEmpContPart,
                             vs_conta_contra       => pCodContaContPart,
                             vs_AnoCompet          => to_char(to_date(pPeriodo),'mm/yyyy'),
                             vs_VlrElimin          => nvl(vVlrElimin, 0),
                             vs_IndElimin          => pIndDCElimin,
                             vn_rel                => vn_rel,
                             vs_utiliza_saldo      => pUtilSaldo);


        MONTA_LINHA('<tr>',vn_rel);
        MONTA_LINHA('<td colspan="4" rowspan="1"',vn_rel);
        MONTA_LINHA('style="vertical-align: top; font-weight: bold; text-align: center; color: #85929E; font-size: 16px;"> '||vs_msg || '<br>',vn_rel);
        MONTA_LINHA('</td>',vn_rel);



      elsif pTipo = '2' then
        -- ### RELATORIO - HTML
        vs_processo       := ' Exclus�o';

        cabecalho(vs_nome_rel
                             ,vn_rel
                             ,RazaoEst_w
                             ,CGC_w
                             ,vs_processo
                             ,vs_nome_interface
                             );

        FOR pCursorRel IN pRegistro.FIRST..pRegistro.LAST LOOP
          for mreg in (
                         select p.rowid rowid_param, p.*
                         from MSAF_PARAM_BLOCOK_ECD p
                         where  p.rowid  = pRegistro(pCursorRel)
                         ) loop
            begin
              v_count := v_count + 1;

              delete from MSAF_PARAM_BLOCOK_ECD k
              where k.rowid       = mreg.rowid_param;

              IF SQL%NOTFOUND THEN
                LIB_PROC.add_log('Dados n�o encontrados para exclus�o', 1);

              ELSE
                LIB_PROC.add_log('Exclus�o Realizada!', 1);

                /*dados_relatorio(vs_cod_empresa1 => mreg.cod_empresa_cons,
                                   vs_conta1 => mreg.cod_conta_det,
                                   vs_cod_empresa2 => mreg.cod_empresa_det,
                                   vs_conta2 => mreg.cod_conta_contr_part,
                                   vs_AnoCompet => mreg.ano_competencia,
                                   vs_VlrElimin => form_vlr(mreg.vlr_eliminacao),
                                   vs_IndElimin => mreg.ind_dc_vlr_elim,
                                   vn_rel => vn_rel);*/

                dados_relatorio(vs_cod_empresa_cons   => mreg.cod_empresa_cons,
                             vs_cod_empresa_det    => mreg.cod_empresa_det,
                             vs_conta_det          => mreg.cod_conta_det,
                             vs_cod_empresa_contra => mreg.cod_empresa_contra,
                             vs_conta_contra       => mreg.cod_conta_contra,
                             vs_AnoCompet          => to_char(to_date(pPeriodo),'mm/yyyy'),
                             vs_VlrElimin          => form_vlr(mreg.vlr_eliminacao),
                             vs_IndElimin          => mreg.ind_dc_vlr_elim,
                             vn_rel                => vn_rel,
                             vs_utiliza_saldo      => mreg.ind_utiliza_saldo_fim);

              END IF;


              exception
                when NO_DATA_FOUND then
                  LIB_PROC.add_log('Dados n�o encontrados para exclus�o', 1);
                  v_rowid := null;
                when OTHERS then
                  raise_application_error(-20102, 'Nao foi possivel Localizar o registro, Verificar os dados');
                  v_rowid := null;

            end;
          end loop;
        end loop;

        if  v_count > 0 then
          MONTA_LINHA('<tr>',vn_rel);
          MONTA_LINHA('<td colspan="4" rowspan="1"',vn_rel);
          MONTA_LINHA('style="vertical-align: top; font-weight: bold; text-align: center; color: #85929E;font-size: 16px;"> Exclus�o realizada com sucesso !!! <br>',vn_rel);
          MONTA_LINHA('</td>',vn_rel);
        else
          MONTA_LINHA('<tr>',vn_rel);
          MONTA_LINHA('<td colspan="4" rowspan="1"',vn_rel);
          MONTA_LINHA('style="vertical-align: top; font-weight: bold; text-align: center; color: #85929E; font-size: 16px;"> Dados n�o localizados para exclus�o !!! <br>',vn_rel);
          MONTA_LINHA('</td>',vn_rel);
        end if;

      elsif pTipo = '3' then
        -- ### RELATORIO - HTML
        vs_processo       := ' Relat�rio Confer�ncia';

        cabecalho(vs_nome_rel
                             ,vn_rel
                             ,RazaoEst_w
                             ,CGC_w
                             ,vs_processo
                             ,vs_nome_interface
                             );

        LIB_PROC.add_log('Relat�rio Confer�ncia!', 1);

        for mreg in (select p.rowid as rowid_param, p.*
                         from MSAF_PARAM_BLOCOK_ECD p
                         where  p.cod_empresa_cons = pCodEmpConsol
                           and p.periodo = last_day(pPeriodo)
                         ) loop

          v_count := v_count + 1;
           /*dados_relatorio(vs_cod_empresa1 => mreg.cod_empresa_cons,
                                   vs_conta1 => mreg.cod_conta_det,
                                   vs_cod_empresa2 => mreg.cod_empresa_det,
                                   vs_conta2 => mreg.cod_conta_contr_part,
                                   vs_AnoCompet => mreg.ano_competencia,
                                   vs_VlrElimin => form_vlr(mreg.vlr_eliminacao),
                                   vs_IndElimin => mreg.ind_dc_vlr_elim,
                                   vn_rel => vn_rel);*/

          dados_relatorio(vs_cod_empresa_cons   => mreg.cod_empresa_cons,
                          vs_cod_empresa_det    => mreg.cod_empresa_det,
                          vs_conta_det          => mreg.cod_conta_det,
                          vs_cod_empresa_contra => mreg.cod_empresa_contra,
                          vs_conta_contra       => mreg.cod_conta_contra,
                          vs_AnoCompet          => to_char(to_date(pPeriodo),'mm/yyyy'),
                          vs_VlrElimin          => form_vlr(mreg.vlr_eliminacao),
                          vs_IndElimin          => mreg.ind_dc_vlr_elim,
                          vn_rel                => vn_rel,
                          vs_utiliza_saldo      => mreg.ind_utiliza_saldo_fim);

        end loop;


        if  v_count > 0 then
                        MONTA_LINHA('<tr>',vn_rel);
                        MONTA_LINHA('<td colspan="3" rowspan="1"',vn_rel);
                        MONTA_LINHA('style="vertical-align: top; font-weight: bold; text-align: center; color: #85929E;font-size: 16px;"> Relat�rio gerado com sucesso !!! <br>',vn_rel);
                        MONTA_LINHA('</td>',vn_rel);
        else
                        MONTA_LINHA('<tr>',vn_rel);
                        MONTA_LINHA('<td colspan="3" rowspan="1"',vn_rel);
                        MONTA_LINHA('style="vertical-align: top; font-weight: bold; text-align: center; color: #85929E; font-size: 16px;"> Dados n�o localizados !!! <br>',vn_rel);
                        MONTA_LINHA('</td>',vn_rel);

        end if;

       -- 001 Inicio
      elsif pTipo = '4' THEN -- replicar parametros do periodo anterior
        BEGIN
          FOR reg IN (SELECT * FROM MSAF_PARAM_BLOCOK_ECD WHERE periodo = '31/12/'|| (to_char(to_date(pPeriodo),'yyyy')-1) )
            LOOP
                     INSERT INTO MSAF_PARAM_BLOCOK_ECD(COD_EMPRESA_CONS,
                                                       COD_EMPRESA_DET,
                                                       COD_CONTA_DET,
                                                       COD_EMPRESA_CONTRA,
                                                       COD_CONTA_CONTRA,
                                                       PERIODO,
                                                       VLR_ELIMINACAO,
                                                       IND_DC_VLR_ELIM,
                                                       ind_utiliza_saldo_fim)
                                                       VALUES
                                                       (reg.cod_empresa_cons,
                                                        reg.cod_empresa_det,
                                                        reg.cod_conta_det,
                                                        reg.cod_empresa_contra,
                                                        reg.cod_conta_contra,
                                                        last_day(pPeriodo),
                                                        0,
                                                        NULL,
                                                        reg.ind_utiliza_saldo_fim);
          END LOOP;

          COMMIT;

          EXCEPTION 
            WHEN OTHERS THEN
              lib_proc.add_log('Erro ao replicar parametros do periodo anterior: '||SQLERRM||' - '||dbms_utility.format_error_stack,1);
              lib_proc.add_log('Erro ao replicar parametros do periodo anterior: '||SQLERRM||' - '||dbms_utility.format_error_backtrace,1);
        END;

         -- 001 Fim
      end if;

      final_html(vn_rel);

      --LIB_PROC.add_log(mproc_id || '  Processo ', 1);
      --LIB_PROC.CLOSE();
      --RETURN mproc_id;

    END;
    LIB_PROC.add_log(mproc_id || '  Processo ', 1);
    LIB_PROC.CLOSE();
    RETURN mproc_id;
  END;


PROCEDURE MONTA_LINHA (PS_LINHA IN VARCHAR2, vn_rel number) IS
  BEGIN
  LIB_PROC.ADD (PLINHA => REPLACE(PS_LINHA,CHR(10),''),PTIPO =>vn_rel);
END MONTA_LINHA;

procedure cabecalho(ps_nome_rel            varchar2
                   ,vn_rel                 number
                   ,vs_razao_social_matriz varchar2
                   ,vs_cnpj_matriz         varchar2
                   ,vn_num_processo        varchar2
                   ,vs_nome_interface      varchar2
                   )  is


  begin


    MONTA_LINHA('<html>',vn_rel);
    MONTA_LINHA('<head>',vn_rel);
    MONTA_LINHA('<meta content="text/html; charset=ISO-8859-1"',vn_rel);
    MONTA_LINHA('http-equiv="content-type">',vn_rel);
    MONTA_LINHA('<title>Relat�rio de execu��o</title>',vn_rel);
    MONTA_LINHA('</head>',vn_rel);
    MONTA_LINHA('<body>',vn_rel);
    MONTA_LINHA('<span style="text-decoration: underline;"></span>',vn_rel);
    MONTA_LINHA('<table style="border: 1px solid black; text-align: left; width: 100%;"',vn_rel);
    MONTA_LINHA('border="1" cellpadding="2" cellspacing="2">',vn_rel);
    MONTA_LINHA('<tbody>',vn_rel);

    MONTA_LINHA('<tr style="font-weight: bold;" align="center">',vn_rel);
    MONTA_LINHA('<td colspan="3" rowspan="1"',vn_rel);
    MONTA_LINHA('style="vertical-align: top; "><big><big>'||ps_nome_rel||'</big></big> </td>',vn_rel);
    MONTA_LINHA('</tr>',vn_rel);

    MONTA_LINHA('<tr align="center">',vn_rel);
    MONTA_LINHA('<td colspan="3" rowspan="1"',vn_rel);
    MONTA_LINHA('style="vertical-align: top; "><big><big><span',vn_rel);
    MONTA_LINHA('style="font-weight: bold;font-size: 20px;">'||vs_nome_interface||'</span></big></big><br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);
    MONTA_LINHA('</tr>',vn_rel);

    MONTA_LINHA('<tr>',vn_rel);
    MONTA_LINHA('<td colspan="3" rowspan="1"',vn_rel);
    MONTA_LINHA('style="vertical-align: top; "><br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);
    MONTA_LINHA('</tr>',vn_rel);


    MONTA_LINHA('<tr>',vn_rel);
    MONTA_LINHA('<td colspan="3" rowspan="1"',vn_rel);
    MONTA_LINHA('style="vertical-align: top; width: 400px; font-weight: bold; color: green; font-size: 15px;">Processo: '||vn_num_processo||'<br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);

    MONTA_LINHA('</tr>',vn_rel);

    -- inicia bloco tr
    MONTA_LINHA('<tr>',vn_rel);


    MONTA_LINHA('<td',vn_rel);
    MONTA_LINHA('style="vertical-align: top; width: 400px; background-color: #0088ff; font-weight: bold; text-align: center;">Empresa Consolidadora<br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);

    MONTA_LINHA('<td',vn_rel);
    MONTA_LINHA('style="vertical-align: top; width: 400px; background-color: #0088ff; font-weight: bold; text-align: center;">Empresa Detentora<br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);

    MONTA_LINHA('<td',vn_rel);
    MONTA_LINHA('style="vertical-align: top; width: 400px; background-color: #0088ff; font-weight: bold; text-align: center;">Conta Cont�bil Detentora<br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);

    MONTA_LINHA('<td',vn_rel);
    MONTA_LINHA('style="vertical-align: top; width: 400px; background-color: #0088ff; font-weight: bold; text-align: center;">Empresa Contrapartida<br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);

    MONTA_LINHA('<td',vn_rel);
    MONTA_LINHA('style="vertical-align: top; width: 400px; background-color: #0088ff; font-weight: bold; text-align: center;">Conta Cont�bil Contra-Partida<br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);

    MONTA_LINHA('<td',vn_rel);
    MONTA_LINHA('style="vertical-align: top; width: 400px; background-color: #0088ff; font-weight: bold; text-align: center;">Valor da Elimina��o<br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);

    MONTA_LINHA('<td',vn_rel);
    MONTA_LINHA('style="vertical-align: top; width: 400px; background-color: #0088ff; font-weight: bold; text-align: center;">Indicador da Elimina��o<br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);
    
    MONTA_LINHA('<td',vn_rel);
    MONTA_LINHA('style="vertical-align: top; width: 400px; background-color: #0088ff; font-weight: bold; text-align: center;">Utiliza saldo final<br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);

    MONTA_LINHA('</tr>',vn_rel);

  end;


procedure dados_relatorio (vs_cod_empresa_cons     VARCHAR2
                          ,vs_cod_empresa_det      VARCHAR2
                          ,vs_conta_det            varchar2
                          ,vs_cod_empresa_contra   varchar2
                          ,vs_conta_contra         varchar2
                          ,vs_AnoCompet        varchar2
                          ,vs_VlrElimin        varchar2
                          ,vs_IndElimin        varchar2
                          ,vn_rel              number
                          ,vs_utiliza_saldo    varchar2) is


wDscEmpresa_cons   varchar2(100) :=null;
wDscEmpresa_det    varchar2(100) :=null;
wDscEmpresa_contra varchar2(100) :=null;

wDscCodConta_det     varchar2(100) := null;
wDscCodConta_contra  varchar2(100) := null;

wDscTipoSAP    varchar2(50) := null;

begin

   begin
      select substr(to_char(l.cod_conta || ' - ' || l.descricao), 1, 100)
         into wDscCodConta_det
        from x2002_plano_contas l
       where 1=1
         and l.cod_conta   = vs_conta_det
         and l.valid_conta = (select max(k.valid_conta)
                               from x2002_plano_contas k
                               where 1=1
                                 and k.cod_conta = l.cod_conta);
   exception
     when others then
         wDscCodConta_det := vs_conta_det;
   end;

   begin
      select substr(to_char(l.cod_conta || ' - ' || l.descricao), 1, 100)
         into wDscCodConta_contra
        from x2002_plano_contas l
       where 1=1
         and l.cod_conta   = vs_conta_contra
         and l.valid_conta = (select max(k.valid_conta)
                               from x2002_plano_contas k
                               where 1=1
                                 and k.cod_conta = l.cod_conta);
   exception
     when others then
         wDscCodConta_contra := vs_conta_contra;
   end;

   begin
      select j.cod_empresa|| ' - ' ||j.razao_social
        into wDscEmpresa_cons
       from empresa j
       where 1=1
        and j.cod_empresa = vs_cod_empresa_cons;
   exception
     when others then
       wDscEmpresa_cons := vs_cod_empresa_cons;
   end;

   begin
      select j.cod_emp_part|| ' - ' ||j.nome_emp_part
        into wDscEmpresa_det
       from x240_inf_empresa_cons j
       where 1=1
        and j.cod_emp_part = vs_cod_empresa_det;
   exception
     when others then
       wDscEmpresa_det := vs_cod_empresa_det;
   end;

   begin
      select j.cod_emp_part|| ' - ' ||j.nome_emp_part
        into wDscEmpresa_contra
       from x240_inf_empresa_cons j
       where 1=1
        and j.cod_emp_part = vs_cod_empresa_contra;
   exception
     when others then
       wDscEmpresa_contra := vs_cod_empresa_contra;
   end;




--#######################################


    MONTA_LINHA('<tr>',vn_rel);

    MONTA_LINHA('<td style="vertical-align: top; width: 300px; text-align: center; font-weight: bold; font-size: 14px;">'||wDscEmpresa_cons||'<br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);

    MONTA_LINHA('<td style="vertical-align: top; width: 300px; text-align: center; font-weight: bold; font-size: 14px;">'||wDscEmpresa_det||'<br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);

    MONTA_LINHA('<td style="vertical-align: top; width: 300px; text-align: center; font-weight: bold; font-size: 14px;">'||wDscCodConta_det||'<br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);

    MONTA_LINHA('<td style="vertical-align: top; width: 300px; text-align: center; font-weight: bold; font-size: 14px;">'||wDscEmpresa_contra||'<br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);

    MONTA_LINHA('<td style="vertical-align: top; width: 300px; text-align: center; font-weight: bold; font-size: 14px;">'||wDscCodConta_contra||'<br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);

    MONTA_LINHA('<td style="vertical-align: top; width: 300px; text-align: center; font-weight: bold; font-size: 14px;">'||vs_VlrElimin||'<br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);

    MONTA_LINHA('<td style="vertical-align: top; width: 300px; text-align: center; font-weight: bold; font-size: 14px;">'||vs_IndElimin||'<br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);

    MONTA_LINHA('<td style="vertical-align: top; width: 300px; text-align: center; font-weight: bold; font-size: 14px;">'||vs_utiliza_saldo||'<br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);
    
    MONTA_LINHA('</tr>',vn_rel);

end;




procedure final_html(vn_rel number) is

  begin

    MONTA_LINHA('</tbody>',vn_rel);
    MONTA_LINHA('</table>',vn_rel);
    MONTA_LINHA('<span style="text-decoration: underline;"></span><br>',vn_rel);
    MONTA_LINHA('</body>',vn_rel);
    MONTA_LINHA('</html>',vn_rel);

end;



END MSAF_PARAM_BLOCOK_CPROC;
/
