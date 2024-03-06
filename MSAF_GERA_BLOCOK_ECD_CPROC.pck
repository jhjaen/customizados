CREATE OR REPLACE PACKAGE MSAF_GERA_BLOCOK_ECD_CPROC IS

  --###########################################################################
  --## Autor    : Diego  Peres                                               ##
  --## Criaçao  : 25/05/2020                                                 ##
  --## Empresa  : ATVI Consultoria                                           ##
  --## Objetivo : GERAÇÃO DAS TABELAS SAFX242, SAFX243 E SAFX244             ##
  --##             PARA O BLOCO K - ECD                                      ##
  --###########################################################################

  /* Declaraç?o de Variáveis Públicas */
  Cursor C1(v_periodo in date) is
      select    c.cod_emp_part cod_empresa,
                a.cnpj,
                a.periodo,
                b.cod_conta_cons cod_conta,
                SUM(decode(a.ind_dc_fim,
                            'D',
                            nvl(a.vlr_saldo_fim, 0),
                            nvl(a.vlr_saldo_fim, 0) * -1)) VLR_SALDO_FIM
            from treg_saldo_ecd a,
                 sped_contas_emp_cons b,
                 x240_inf_empresa_cons c
           where 1 = 1
             and a.cod_conta = b.cod_conta
             and a.periodo = last_day(v_periodo)
          --   and b.cod_emp_part = '1'
             and b.data_fim_cons = a.periodo
          --   and b.cod_conta_cons = '1.1.1'
             and b.cod_empresa = c.cod_empresa
             and b.cod_estab  = c.cod_estab
             and b.data_ini_cons = c.data_ini_cons
             and b.data_fim_cons = c.data_fim_cons
             and b.cod_emp_part = c.cod_emp_part
             and c.cnpj = a.cnpj
             AND TRIM(a.registro) IS NULL


           GROUP BY a.cnpj, a.periodo, c.cod_emp_part, b.cod_conta_cons
           having SUM(decode(a.ind_dc_ini, 'D', nvl(a.vlr_saldo_fim, 0), nvl(a.vlr_saldo_fim, 0) * -1)) <> 0

           UNION

      select    c.cod_emp_part cod_empresa,
                a.cnpj,
                to_date('31/12/'||to_char(to_date(v_periodo),'yyyy')) AS periodo,
                b.cod_conta_cons cod_conta,
                SUM(decode(a.ind_dc_fim,
                            'D',
                            nvl(a.vlr_saldo_fim, 0),
                            nvl(a.vlr_saldo_fim, 0) * -1)) VLR_SALDO_FIM
            from treg_saldo_ecd a,
                 sped_contas_emp_cons b,
                 x240_inf_empresa_cons c
           where 1 = 1
             and a.cod_conta = b.cod_conta
             and to_char(a.periodo,'yyyy') = to_char(to_date(v_periodo),'yyyy')
             and b.data_fim_cons = a.periodo
             and b.cod_empresa = c.cod_empresa
             and b.cod_estab  = c.cod_estab
             and b.data_ini_cons = c.data_ini_cons
             and b.data_fim_cons = c.data_fim_cons
             and b.cod_emp_part = c.cod_emp_part
             and c.cnpj = a.cnpj
             AND TRIM(a.registro) = 'I355'


           GROUP BY a.cnpj, '31/12/'||to_char(to_date(v_periodo),'yyyy'), c.cod_emp_part, b.cod_conta_cons
           having SUM(decode(a.ind_dc_ini, 'D', nvl(a.vlr_saldo_fim, 0), nvl(a.vlr_saldo_fim, 0) * -1)) <> 0

           order by cod_conta asc;

  Cursor C2(v_empresa in varchar2, v_periodo in date, v_cod_conta in varchar2) is
            select k.cod_conta_det,
               k.cod_empresa_det,
               SUM(decode(k.ind_dc_vlr_elim,
                          'D',
                          nvl(k.vlr_eliminacao, 0),
                          nvl(k.vlr_eliminacao, 0) * -1)) vlr_eliminacao
          from MSAF_PARAM_BLOCOK_ECD k, x240_inf_empresa_cons l
         where 1 = 1
           and k.cod_empresa_det = l.cod_emp_part
           and k.periodo         = last_day(l.data_fim_cons)
           and k.cod_empresa_cons = 'SOL'
           and k.cod_empresa_det = v_empresa
           and k.periodo         = last_day(v_periodo)
           and k.cod_conta_det = v_cod_conta
         group by k.cod_conta_det, k.cod_empresa_det;
    /*      select d.cod_emp_part,
                 e.cod_conta_det,
                 e.cod_emp_contr_part,
                 e.cod_conta_contr_part,
                 case
                   when e.vlr_eliminacao > 0 then
                    decode(e.ind_dc_vlr_elim,
                           'D',
                           e.vlr_eliminacao,
                           e.vlr_eliminacao * -1)
                   else
                    SUM(decode(a.ind_dc_ini,
                               'D',
                               replace(nvl(a.vlr_saldo_fim, 0), '.', ','),
                               replace(nvl(a.vlr_saldo_fim, 0), '.', ',') * -1))
                 end VLR_ELIMINACAO
            from treg_saldo_ecd        a,
                 sped_contas_emp_cons  b,
                 x2002_plano_contas    c,
                 x240_inf_empresa_cons d,
                 MSAF_PARAM_BLOCOK_ECD e
           where 1 = 1
             and d.cod_empresa = v_empresa
             and a.cnpj = d.cnpj
             and d.data_fim_cons = a.periodo
             and d.data_ini_cons = b.data_ini_cons
             and d.data_fim_cons = b.data_fim_cons
             and a.cod_conta = b.cod_conta
             and b.cod_conta_cons = c.cod_conta
             and c.valid_conta = (select max(k.valid_conta)
                                    from x2002_plano_contas k
                                   where 1 = 1
                                     and k.cod_conta = c.cod_conta)
             and a.periodo = to_date(v_periodo, 'dd/mm/rrrr')
             and d.cod_empresa = e.cod_empresa_cons
             and d.cod_emp_part = e.cod_empresa_det
             and b.cod_conta_cons = e.cod_conta_det
             and e.ano_competencia =
                 to_char(to_date(v_periodo, 'dd/mm/rrrr'), 'YYYY')
             and e.cod_conta_det = v_cod_conta
           GROUP BY a.periodo,
                    d.cod_emp_part,
                    b.cod_conta_cons,
                    e.ind_dc_vlr_elim,
                    e.cod_conta_det,
                    e.cod_emp_contr_part,
                    e.cod_conta_contr_part,
                    e.vlr_eliminacao;*/



              vNome estabelecimento.razao_social%TYPE;

  FUNCTION Parametros RETURN VARCHAR2;
  FUNCTION Nome RETURN VARCHAR2;
  FUNCTION Tipo RETURN VARCHAR2;
  FUNCTION Versao RETURN VARCHAR2;
  FUNCTION Descricao RETURN VARCHAR2;
  FUNCTION Modulo RETURN VARCHAR2;
  FUNCTION Classificacao RETURN VARCHAR2;

  FUNCTION Executar(pCod_empresa VARCHAR2,
                    pCod_Estab   VARCHAR2,
                    pPeriodo     date,
                    pTipo        Varchar2,
                    pTab         lib_proc.varTab) RETURN INTEGER;

  PROCEDURE Cabecalho1(ptipo VARCHAR2, pnome VARCHAR2, p_periodo date);

END MSAF_GERA_BLOCOK_ECD_CPROC;
/
CREATE OR REPLACE PACKAGE BODY MSAF_GERA_BLOCOK_ECD_CPROC IS

  --###################################################################################
  --## Autor    : Diego  Peres                                                       ##
  --## Criaçao  : 25/05/2020                                                         ##
  --## Empresa  : ATVI Consultoria                                                   ##
  --## Objetivo : GERAÇÃO DAS TABELAS SAFX242, SAFX243 E SAFX244                     ##
  --##             PARA O BLOCO K - ECD                                              ##
  --## Ajustes  :                                                                    ##
  --##            001 - Felipe Guimaraes 22/04/2021                                  ##
  --##            Inclusao do relatorio dos saldos em carregados em treg_saldo_ecd   ##
  --##                                                                               ##
  --##            002 - Felipe Guimaraes 30/04/2021                                  ##
  --##            Alteracao na regra de composicao das eliminacoes                   ##
  --###################################################################################

  musuario     usuario_estab.cod_usuario%TYPE;
  mcod_empresa empresa.cod_empresa%type;
  mcod_estab   estabelecimento.cod_estab%type;

  function form_vlr(p_valor in number) return varchar2 is
  begin
    return trim(to_char(p_valor,
                        'FM999G999G999G999G990D99990',
                        'nls_numeric_characters='',.'''));
  end;

   FUNCTION Parametros RETURN VARCHAR2 IS
    pstr VARCHAR2(5000);
  BEGIN

    select razao_social
      into vNome
      from empresa
     where cod_empresa = LIB_PARAMETROS.RECUPERAR('EMPRESA');

    musuario     := LIB_PARAMETROS.Recuperar('USUARIO');
    mcod_empresa := LIB_PARAMETROS.RECUPERAR('EMPRESA');
    mcod_estab   := NVL(LIB_PARAMETROS.RECUPERAR('ESTABELECIMENTO'), '');

    -- :1
    LIB_PROC.add_param(pstr,
                       'Empresa Consolidadora',
                       'Varchar2',
                       'Combobox',
                       'N',
                       mcod_empresa,
                       NULL,
                       'SELECT e.cod_empresa,e.cod_empresa  || '' - '' || e.razao_social FROM empresa e where e.cod_empresa = ' ||
                       mcod_empresa || 'ORDER BY  e.cod_empresa ASC',
                       NULL,
                       null
                       );

    -- :2
    LIB_PROC.add_param(pstr,
                       'Estabelecimento',
                       'Varchar2',
                       'Combobox',
                       'S',
                       null,
                       NULL,
                       'SELECT DISTINCT e.cod_estab, e.cod_estab||'' - ''||e.razao_social FROM estabelecimento e WHERE e.cod_empresa   = :1 and ind_matriz_filial = ''M'' order by 2',
                       NULL,
                       null
                       );

    -- :3
    Lib_Proc.Add_Param(Pstr,
                       'Período',
                       'Date',
                       'Textbox',
                       'S',
                       NULL,
                       'mm/yyyy');

    -- :4
    LIB_PROC.add_param(pstr,
                       'Opções de Processamento',
                       'Varchar2',
                       'Combobox',
                       'S',
                       '1',
                       null,
                       'select ''1'',''1 - Gerar Relatório para Conferência'' from dual union all
                        select ''2'',''2 - Gerar SAFX'' from dual order by 1 asc');

    -- :5
    LIB_PROC.add_param(pstr,
                       'Selecione a Tabela para Geração',
                       'Varchar2',
                       'MultiSelect',
                       'S',
                       NULL,
                       null,
                       'select 0, to_char(''SAFX240 - Relação das Empresas Consolidadas'') from dual union all
                        select 1, to_char(''SAFX242 - Saldos das Contas Consolidadas'') from dual union all
                        select 2, to_char(''SAFX243 - Empresas Detentoras das Parcelas do Valor Eliminado Total'') from dual union all
                        select 3, to_char(''SAFX244 - Empresas Contrapartes das Parcelas do Valor Eliminado Total'') from dual union all
                        select 4, to_char(''SAFX262 - Mapeamento para Plano de Contas das Empresas Consolidadas (ECD)'') from dual union all
                        select 5, to_char(''SALDOS ECD - Saldos carregados através dos arquivos ECD'') from dual order by 1 asc',
                        NULL,
                        NULL
                        );

    RETURN pstr;
  END;

  FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN '4.0 - Geração das Tabelas para o Bloco K - ECD';
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
    RETURN 'Processo para Geração das tabelas SAFX242, SAFX243 e SAFX244 do Bloco K - ECD';
  END;

  FUNCTION Modulo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Bloco K - ECD';
  END;

  FUNCTION Classificacao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Bloco K - ECD';
  END;

  FUNCTION Executar(pCod_empresa VARCHAR2,
                    pCod_Estab   VARCHAR2,
                    pPeriodo     date,
                    pTipo        Varchar2,
                    pTab         lib_proc.varTab) RETURN INTEGER IS

    /* Variaveis de Trabalho */
    mproc_id          INTEGER;
    mLinha            VARCHAR2(1000);
    v                 char(1) := ';';
    v_vlr_elimin      number(17,2) :=0;
    v_ind_dc_elimn    varchar(1) := 0;
    v_cod_conta_det   varchar2(70) :=null;
    v_vlr_consolid    number(17,2) :=0;
    v_ind_dc1         char(1) := null;
    v_ind_dc2         char(1) := null;
    v_ind_dc3         char(1) := null;

    v_cod_emp_cons   varchar2(3) := null;


    t_safx242 safx242%rowtype;
    t_safx243 safx243%rowtype;
    t_safx244 safx244%rowtype;
    t_saldo   MSAF_SALDO_DETALHADO_K%rowtype;
    v_param   number :=0;

    v_finalizar number := 0;

    Status_w        INTEGER;
    RazaoEmp_w      EMPRESA.RAZAO_SOCIAL%TYPE;
    RazaoEst_w      ESTABELECIMENTO.RAZAO_SOCIAL%TYPE;
    CGC_w           ESTABELECIMENTO.CGC%TYPE;
    Ind_Atividade_w ESTABELECIMENTO.Ind_Atividade%type;
    IndConvIcms_w   ESTABELECIMENTO.IND_CONV_ICMS%TYPE;
    CodAtividade_w  ESTABELECIMENTO.COD_ATIVIDADE%TYPE;
    UF_estab_w      ESTADO.COD_ESTADO%TYPE;
    linha_log       varchar2(100);

    reg_contrapartida  msaf_blocok_eliminacao%ROWTYPE;

    Finalizar EXCEPTION;

  BEGIN

    BEGIN

      mproc_id := LIB_PROC.new('MSAF_GERA_BLOCOK_ECD_CPROC');
      LIB_PROC.add_log('Log gerado', 1);
      --    Mcod_Empresa := Pcod_empresa; --Lib_Parametros.Recuperar('EMPRESA');

      /***************************************************/
      /* Inclui Header/Footer do Log de Erros            */
      /***************************************************/
      lib_proc.Add_Log(RazaoEmp_w, 0);
      lib_proc.Add_Log('Filial: ' || Pcod_Estab || ' - ' || RazaoEst_w, 0);
      lib_proc.Add_Log('CNPJ: ' || CGC_w, 0);
      lib_proc.Add_Log('.                                                                                                          Relatório de Log',
                       0);
      -- lib_proc.Add_Log('.                                                                                               Dt.Ini : ' ||
      --                to_date(pData_Ini,'DD/MM/YYYY') || '  -  Dt.Fim: ' ||to_date(pData_Fim,'DD/MM/YYYY') , 0);

      linha_log := 'Log de Processo: ' || mproc_id;
      lib_proc.Add_Log('.                                                                                                        ' ||
                       linha_log,
                       0);

      lib_proc.Add_Log(rpad('-', 200, '-'), 0);
      lib_proc.Add_Log(' ', 0);

      /***************************************************************/
      /* Validação de datas inicial e final informadas com parâmetro */
      /***************************************************************/

      If pCod_empresa is null Then
        lib_proc.Add_Log('Erro: A Empresa deve ser informada.', 0);
        lib_proc.Add_Log(' ', 0);
        v_finalizar := v_finalizar + 1;
      End If;

      If pCod_Estab is null Then
        lib_proc.Add_Log('Erro: O campo Código do Estabelecimento deve ser informado.',
                         0);
        lib_proc.Add_Log(' ', 0);
        v_finalizar := v_finalizar + 1;
      End If;

      If pPeriodo is null Then
        lib_proc.Add_Log('Erro: O Período deve ser informado.', 0);
        lib_proc.Add_Log(' ', 0);
        v_finalizar := v_finalizar + 1;
      End If;

      if v_finalizar > 0 then
        lib_proc.CLOSE;
        RETURN mproc_id;
      end if;

     execute immediate 'truncate table MSAF_SALDO_DETALHADO_K';
     execute immediate 'truncate table MSAF_BLOCOK_ELIMINACAO';

     EXECUTE IMMEDIATE 'alter session set nls_numeric_characters = '',.''';

-- GRAVA SALDOS DETALHADOS
     for reg1 in C1(last_day(pPeriodo)) loop

          v_vlr_elimin :=0;
          v_vlr_consolid :=0;

          t_saldo.cod_empresa       := Pcod_empresa;
          t_saldo.cod_estab         := Pcod_estab;
          t_saldo.data_saldo_cons   := reg1.periodo;
          t_saldo.cod_conta         := reg1.cod_conta;
          t_saldo.vlr_saldo_fim     := reg1.vlr_saldo_fim;
          t_saldo.cod_emp_part      := reg1.cod_empresa;
          t_saldo.cod_emp_contrap   := null;
          t_saldo.cod_conta_contrap := null;
          t_saldo.vlr_eliminacao    := 0;
          v_param :=0;

            if v_param = 0 then
                begin
                   insert into MSAF_SALDO_DETALHADO_K values t_saldo;
                   v_param :=1;
                exception
                  when others then
                    null;
                end;
            end if;

      end loop;


      commit;

      -- GRAVA AS ELIMINACOES
-- 002 Inicio (Alteracao na composicao das eliminacoes)
-- A composicao das eliminacoes será feita em 3 etapas (Eliminacoes informadas manualmente, Eliminacoes atraves da conta consolidadora, Eliminacoes atraves da conta analitica)

/*
      for reg1 in (select a.cod_empresa,
                           a.data_saldo_cons,
                           b.cod_conta_det,
                           d.cod_emp_part,
                           b.cod_conta_contr_part,
                           decode(sign(sum(nvl(a.vlr_saldo_fim, 0))), -1, 'C', 'D') ind_deb_cred,
                           sum(nvl(a.vlr_saldo_fim, 0)) vlr_eliminacao
                      from MSAF_SALDO_DETALHADO_K a,
                           MSAF_PARAM_BLOCOK_ECD  b,
                           estabelecimento        c,
                           x240_inf_empresa_cons  d
                     where 1 = 1
                       and a.cod_empresa = b.cod_empresa_cons
                       and a.data_saldo_cons = last_day(pPeriodo)
                       and a.cod_conta = b.cod_conta_contr_part
                       and a.cod_empresa = c.cod_empresa
                       and a.cod_estab = c.cod_estab
                       and a.cod_emp_part not in
                           (select k.cod_emp_part
                              from x240_inf_empresa_cons k
                             where k.cnpj = c.cgc
                               and k.data_fim_cons = last_day(pPeriodo)
                               and k.cod_empresa = Pcod_empresa)
                       and a.cod_empresa = Pcod_empresa
                       and a.data_saldo_cons = last_day(pPeriodo)
                       and a.cod_empresa = d.cod_empresa
                       and a.cod_emp_part = d.cod_emp_part
                       and a.data_saldo_cons = d.data_fim_cons
                       and exists (select 1
                                   from MSAF_SALDO_DETALHADO_K z
                                   where z.cod_conta = b.cod_conta_det)
                     group by a.cod_empresa,
                              b.cod_conta_det,
                              a.data_saldo_cons,
                              d.cod_emp_part,
                              b.cod_conta_contr_part) loop



             begin
               insert into MSAF_BLOCOK_ELIMINACAO values reg1;
             exception
               when others then
                 null;
             end;

      end loop;

      COMMIT;
*/

      FOR reg IN (-- cursor para eliminacoes manuais (considera o valor informado manualmente na parametrizacao)
                  SELECT param.cod_empresa_cons                AS cod_empresa
                         , param.periodo                       AS data_saldo
                         , param.cod_empresa_det               AS cod_empresa_det
                         , param.Cod_Conta_Det                 AS cod_conta_det
                         , param.cod_empresa_contra            AS cod_empresa_contr
                         , param.Cod_Conta_Contra              AS cod_conta_cont
                         , param.ind_dc_vlr_elim               AS ind_deb_cre
                         , CASE
                           WHEN param.ind_dc_vlr_elim = 'C'
                             THEN param.vlr_eliminacao*-1
                           ELSE param.vlr_eliminacao
                           END                                 AS vlr_eliminacao

                       FROM  MSAF_PARAM_BLOCOK_ECD PARAM
                       WHERE 1=1
                       AND   param.cod_empresa_cons = Pcod_empresa
                       AND   param.Periodo          = last_day(pPeriodo)
                       AND   NVL(param.vlr_eliminacao,0) >0

                  UNION -- cursor para contas consolidadoras sem eliminacao parametrizada (busca saldo final da consolidadoras)

                  SELECT param.cod_empresa_cons                AS cod_empresa
                         , param.periodo                       AS data_saldo
                         , param.cod_empresa_det               AS cod_empresa_det
                         , param.Cod_Conta_Det                 AS cod_conta_det
                         , param.cod_empresa_contra            AS cod_empresa_contr
                         , param.Cod_Conta_Contra              AS cod_conta_cont
                         , DECODE(SIGN(saldo.vlr_saldo_fim),
                                  -1,'D','C')                  AS ind_deb_cre
                         , saldo.vlr_saldo_fim                 AS vlr_eliminacao

                       FROM  MSAF_PARAM_BLOCOK_ECD PARAM, MSAF_SALDO_DETALHADO_K SALDO
                       WHERE 1=1
--                       AND   PARAM.COD_EMPRESA_DET  = saldo.cod_emp_part
--                       AND   PARAM.COD_CONTA_DET    = saldo.cod_conta

                       AND   param.Cod_Empresa_Contra = saldo.cod_emp_part
                       AND   PARAM.COD_CONTA_CONTRA = saldo.cod_conta
                       --AND   PARAM.COD_CONTA_DET    = saldo.cod_conta

                       AND   param.cod_empresa_cons = Pcod_empresa
                       AND   param.Periodo          = last_day(pPeriodo)
                       AND   NVL(param.vlr_eliminacao,0) = 0

                /*UNION -- cursor para contas analiticas sem eliminacao parametrizada (totaliza saldo final das analiticas)

                  SELECT param.cod_empresa_cons                AS cod_empresa
                         , param.periodo                       AS data_saldo
                         , param.cod_empresa_det               AS cod_empresa_det
                         , param.Cod_Conta_Det                 AS cod_conta_det
                         , param.cod_empresa_contra            AS cod_empresa_contr
                         , cons.cod_conta_cons                 AS cod_conta_cont

                         , DECODE(SIGN(SUM(DECODE(saldo.ind_dc_fim,'C',saldo.vlr_saldo_fim*-1,saldo.vlr_saldo_fim))),-1,'C','D')   AS ind_deb_cre
                         , SUM(DECODE(saldo.ind_dc_fim,'C',saldo.vlr_saldo_fim*-1,saldo.vlr_saldo_fim)) AS vlr_eliminacao

                       FROM  MSAF_PARAM_BLOCOK_ECD PARAM, X240_INF_EMPRESA_CONS X240, TREG_SALDO_ECD SALDO, SPED_CONTAS_EMP_CONS CONS
                       WHERE 1=1
                       AND   param.Cod_Empresa_Contra = x240.cod_emp_part

                       AND   x240.cnpj                = saldo.cnpj
                       AND   param.cod_conta_contra   = saldo.cod_conta
                       AND   param.Periodo            = saldo.periodo

                       AND   x240.cod_emp_part        = cons.cod_emp_part
                       AND   param.Periodo            BETWEEN cons.data_ini_cons AND cons.data_fim_cons
                       AND   saldo.cod_conta          = cons.cod_conta

                       AND   NVL(saldo.vlr_saldo_fim,0) > 0

                       AND   param.cod_empresa_cons = Pcod_empresa
                       AND   param.Periodo          = last_day(pPeriodo)
                       and   X240.Data_Fim_Cons     = last_day(pPeriodo)

                       AND   NVL(param.vlr_eliminacao,0) = 0


                       GROUP BY cod_empresa_cons
                                , param.periodo
                                , param.cod_empresa_det
                                , param.Cod_Conta_Det
                                , param.cod_empresa_contra
                                , cons.cod_conta_cons

                  */)
                  LOOP

                 BEGIN
                   insert into MSAF_BLOCOK_ELIMINACAO values reg;
                 exception
                   when others then
                     lib_proc.add_log('Erro inesperado ao inserir dados na tabela MSAF_BLOCOK_ELIMINACAO: '||SQLERRM,1);
                 END;

                 -- INSEREE CONTRAPARTIDA

                 reg_contrapartida.cod_empresa         := reg.cod_empresa;
                 reg_contrapartida.data_saldo          := reg.data_saldo;
                 reg_contrapartida.cod_empresa_det     := reg.cod_empresa_contr;
                 reg_contrapartida.cod_conta_det       := reg.cod_conta_cont;
                 reg_contrapartida.cod_empresa_contra  := reg.cod_empresa_det;
                 reg_contrapartida.cod_conta_contra    := reg.cod_conta_det;
                 reg_contrapartida.ind_deb_cred        := CASE WHEN reg.ind_deb_cre = 'C' THEN 'D' ELSE 'C' END;
                 reg_contrapartida.vlr_eliminacao      := reg.vlr_eliminacao*-1;

                 BEGIN
                   insert into MSAF_BLOCOK_ELIMINACAO values reg_contrapartida;
                 exception
                   when others then
                     lib_proc.add_log('Erro inesperado ao inserir dados na tabela MSAF_BLOCOK_ELIMINACAO: '||SQLERRM,1);
                 END;

                  END LOOP;

                  COMMIT;



-- 002 Fim


      FOR pCursorRel IN pTab.FIRST .. pTab.LAST LOOP

        if pTab(pCursorRel) = '1' then
          -- SAFX242

          LIB_PROC.add_tipo(mproc_id,
                            pTab(pCursorRel),
                            'SAFX242_' || Pcod_empresa || '.csv',
                            2);
          Cabecalho1(pTab(pCursorRel), vNome, pPeriodo);

          for mreg in (select q.cod_empresa
                              ,q.cod_estab
                              ,q.data_saldo_cons
                              ,q.cod_conta
                              ,sum(nvl(q.vlr_saldo_fim, 0)) vlr_saldo_fim
                        from MSAF_SALDO_DETALHADO_K q
                        where q.cod_empresa = Pcod_empresa
                        AND   q.data_saldo_cons = last_day(pPeriodo)
                        /*AND   EXISTS (SELECT 1 FROM msaf_param_blocok_ecd param WHERE param.cod_empresa_cons = Pcod_empresa AND param.periodo = last_day(pPeriodo) AND param.cod_conta_det = q.cod_conta)*/

                        group by q.cod_empresa
                              ,q.cod_estab
                              ,q.data_saldo_cons
                              ,q.cod_conta
                         order by q.cod_conta asc ) loop


              if mreg.vlr_saldo_fim < 0 then
                  v_ind_dc1 := 'C';
              else
                  v_ind_dc1 := 'D';
              end if;

              -- verifica se tem eliminacao
              begin
                select sum(f.vlr_eliminacao) into v_vlr_elimin
                from MSAF_BLOCOK_ELIMINACAO f
                where 1=1
                  and f.cod_empresa    = mreg.cod_empresa
                  and f.data_saldo     = mreg.data_saldo_cons
                  and f.cod_conta_det  = mreg.cod_conta;
              exception
                when others then
                  v_vlr_elimin := null;
              end;

              if v_vlr_elimin is null then

                  -- ELIMINACAO CONTRA-PARTIDA
                  begin
                    select sum(f.vlr_eliminacao) into v_vlr_elimin
                    from MSAF_BLOCOK_ELIMINACAO f
                    where 1=1
                      and f.cod_empresa      = mreg.cod_empresa
                      and f.data_saldo       = mreg.data_saldo_cons
                      and f.cod_conta_contra = mreg.cod_conta;
                  exception
                    when others then
                      v_vlr_elimin := 0;
                  end;

                  if v_vlr_elimin > 0 then
                       v_ind_dc2 := 'D';
                  else
                       v_ind_dc2 := 'C';
                  end if;

              else
                  -- ELINIACAO PARTIDA

                  if v_vlr_elimin > 0 then
                      v_ind_dc2 := 'C';
                  else
                      v_ind_dc2 := 'D';
                  end if;

              end if;

              v_vlr_elimin := nvl(v_vlr_elimin, 0);


              if v_ind_dc2 = v_ind_dc1 then
                 v_vlr_consolid := abs(mreg.vlr_saldo_fim) - abs(v_vlr_elimin);
              else
                v_vlr_consolid := abs(mreg.vlr_saldo_fim) + abs(v_vlr_elimin);
              end if;

              if nvl(v_vlr_elimin, 0) = '0' then
                 v_vlr_consolid := abs(mreg.vlr_saldo_fim);
                 v_ind_dc2 := v_ind_dc1;
              end if;


              if v_vlr_elimin = 0 or mreg.vlr_saldo_fim = 0 then
                 v_ind_dc3 := v_ind_dc1;
              else
                if v_vlr_consolid >= 0 then
                    v_ind_dc3 := v_ind_dc1;
                else
                    v_ind_dc3 := 'C';
                end if;
              end if;


              mLinha := NULL;
              mLinha := LIB_STR.w(mLinha,
                                  Pcod_empresa                       || v ||
                                  pCod_Estab                         || v ||
                                  to_char(mreg.data_saldo_cons, 'YYYYMMDD')               || v ||
                                  mreg.cod_conta                     || v ||
                                  form_vlr(abs(mreg.vlr_saldo_fim))       || v ||
                                  v_ind_dc1                          || v ||
                                  form_vlr(abs(nvl(v_vlr_elimin, 0)))            || v ||
                                  v_ind_dc2                          || v ||
                                  form_vlr(abs(v_vlr_consolid))           || v ||
                                  v_ind_dc3,
                                  1);
               LIB_PROC.add(mLinha, null, null, pTab(pCursorRel));

               if pTipo = '2' then -- Gera a tabela SAFX242

                   t_safx242.cod_empresa := Pcod_empresa;
                   t_safx242.cod_estab   := pCod_Estab;
                   t_safx242.data_saldo_cons := to_char(mreg.data_saldo_cons, 'YYYYMMDD');
                   t_safx242.cod_conta   := mreg.cod_conta;
                   t_safx242.vlr_aglutinado := abs(mreg.vlr_saldo_fim) * 100;
                   t_safx242.ind_aglutinado := v_ind_dc1;
                   t_safx242.vlr_eliminacao := abs(nvl(v_vlr_elimin, 0)) * 100;
                   t_safx242.ind_eliminacao := v_ind_dc2;
                   t_safx242.vlr_consolidado := abs(v_vlr_consolid) * 100;
                   t_safx242.ind_consolidado := v_ind_dc3;

                    begin
                       insert into safx242 values t_safx242;
                    exception
                      when others then
                        null;
                    end;

               end if;


           end loop;


        elsif pTab(pCursorRel) = '2' then
          -- SAFX243

          LIB_PROC.add_tipo(mproc_id,
                            pTab(pCursorRel),
                            'SAFX243_' || Pcod_empresa || '.csv',
                            2);
          Cabecalho1(pTab(pCursorRel), vNome, pPeriodo);

/*
          for reg1 in (select f.cod_empresa,
                       f.data_saldo,
                       f.cod_conta_det COD_CONTA,
                       h.cod_emp_part EMPRESA_PART,
                       decode(sign(sum(f.vlr_eliminacao)), -1, 'D', 'C') IND_DC_ELIMIN,
                       sum(f.vlr_eliminacao) VLR_ELIMIN
                  from MSAF_BLOCOK_ELIMINACAO f, estabelecimento g, x240_inf_empresa_cons h
                 where 1 = 1
                   and f.cod_empresa = Pcod_empresa
                   and f.cod_empresa = g.cod_empresa
                   and g.cod_estab = Pcod_estab
                   and g.cgc = h.cnpj
                   and f.data_saldo = h.data_fim_cons
                   and f.data_saldo = last_day(pPeriodo)
                 group by f.cod_empresa, f.data_saldo, h.cod_emp_part, f.cod_conta_det
                union all
                select f.cod_empresa,
                       f.data_saldo,
                       f.cod_conta_det COD_CONTA,
                       f.cod_empresa_det EMPRESA_PART,
                       decode(sign(sum(f.vlr_eliminacao)), -1, 'C', 'D') IND_DC_ELIMIN,
                       sum(f.vlr_eliminacao) VLR_ELIMIN
                  from MSAF_BLOCOK_ELIMINACAO f
                 where 1 = 1
                   and f.cod_empresa = Pcod_empresa
                   and f.data_saldo = last_day(pPeriodo)
                 group by f.cod_empresa,
                       f.data_saldo,
                       f.cod_conta_det,
                       f.cod_empresa_det) LOOP
*/
          for reg1 in (SELECT B.COD_EMPRESA
                             , A.DATA_SALDO
                             , A.COD_EMPRESA_DET                                 AS EMPRESA_PART
                             , A.COD_CONTA_DET AS COD_CONTA
                             , DECODE(SIGN(SUM(A.VLR_ELIMINACAO)), -1, 'D', 'C') AS IND_DC_ELIMIN
                             , SUM(A.VLR_ELIMINACAO)                             AS VLR_ELIMIN

                             FROM  MSAF_BLOCOK_ELIMINACAO  A
                                   , X240_INF_EMPRESA_CONS B
                             WHERE 1=1
                             AND   A.COD_EMPRESA_DET       = B.COD_EMP_PART
                             AND   A.DATA_SALDO            BETWEEN B.DATA_INI_CONS AND B.DATA_FIM_CONS

                             -- FILTROS
                             AND   B.COD_EMPRESA           = Pcod_empresa
                             AND   A.DATA_SALDO            = LAST_DAY(pPeriodo)

                             GROUP BY B.COD_EMPRESA
                                      , A.DATA_SALDO
                                      , A.COD_EMPRESA_DET
                                      , A.COD_CONTA_DET) LOOP

                 --   if reg1.vlr_eliminacao < 0 then
                        v_ind_dc1 := reg1.ind_dc_elimin;
                 --   else
                 --       v_ind_dc1 := 'D';
                 --   end if;

                    mLinha := NULL;
                    mLinha := LIB_STR.w(mLinha,
                                        Pcod_empresa                       || v ||
                                        pCod_Estab                         || v ||
                                        to_char(reg1.data_saldo, 'YYYYMMDD')               || v ||
                                        reg1.cod_conta                || v ||
                                        reg1.empresa_part                 || v ||
                                        form_vlr(abs(reg1.vlr_elimin))       || v ||
                                        v_ind_dc1,
                                        1);
                     LIB_PROC.add(mLinha, null, null, pTab(pCursorRel));

                     if pTipo = '2' then -- Gera a tabela SAFX243

                         t_safx243.cod_empresa       := Pcod_empresa;
                         t_safx243.cod_estab         := pCod_Estab;
                         t_safx243.data_saldo_cons   := to_char(reg1.data_saldo, 'YYYYMMDD');
                         t_safx243.cod_conta         := reg1.cod_conta;
                         t_safx243.cod_emp_part      := reg1.empresa_part;
                         t_safx243.vlr_eliminado_tot := abs(reg1.vlr_elimin) * 100;
                         t_safx243.ind_eliminado_tot := v_ind_dc1;
                          begin
                             insert into safx243 values t_safx243;
                          exception
                            when others then
                              null;
                          end;
                     end if;

         end loop;



        elsif pTab(pCursorRel) = '3' then
          -- SAFX244

          LIB_PROC.add_tipo(mproc_id,
                            pTab(pCursorRel),
                            'SAFX244_' || Pcod_empresa || '.csv',
                            2);
          Cabecalho1(pTab(pCursorRel), vNome, pPeriodo);
/*
          for mreg in (select f.cod_empresa,
                               f.data_saldo,
                               f.cod_conta_det COD_CONTA_CONS,
                               f.cod_conta_det,
                               h.cod_emp_part COD_EMPRESA_CONS,
                               f.cod_empresa_det,
                               decode(sign(sum(f.vlr_eliminacao)), -1, 'C', 'D') IND_DC_ELIMIN,
                               sum(f.vlr_eliminacao) VLR_ELIMINACAO
                          from MSAF_BLOCOK_ELIMINACAO f, estabelecimento g, x240_inf_empresa_cons h
                         where 1 = 1
                           and f.cod_empresa = pCod_empresa
                           and f.cod_empresa = g.cod_empresa
                           and g.cod_estab = pCod_Estab
                           and g.cgc = h.cnpj
                           and f.data_saldo = h.data_fim_cons
                           and f.data_saldo = last_day(pPeriodo)
                         group by f.cod_empresa,
                                  f.data_saldo,
                                  h.cod_emp_part,
                                  f.cod_empresa_det,
                                  f.cod_conta_det,
                                  f.cod_conta_det
                        having abs(sum(f.vlr_eliminacao)) > 0) LOOP
*/
          for mreg in (SELECT f.cod_empresa,
                               f.data_saldo,
                               f.cod_empresa_det COD_EMPRESA_CONS,
                               f.cod_conta_det COD_CONTA_CONS,
                               f.cod_empresa_contra,
                               f.cod_conta_contra,
                               decode(sign(SUM(f.vlr_eliminacao)), -1, 'C', 'D') IND_DC_ELIMIN,
                               SUM(f.vlr_eliminacao) VLR_ELIMINACAO
                          FROM MSAF_BLOCOK_ELIMINACAO f, estabelecimento g, x240_inf_empresa_cons h
                         WHERE 1 = 1
                           AND f.cod_empresa = pCod_empresa
                           AND f.cod_empresa = g.cod_empresa
                           AND g.cod_estab = pCod_Estab
                           AND g.cgc = h.cnpj
                           AND f.data_saldo = h.data_fim_cons
                           AND f.data_saldo = last_day(pPeriodo)
                         GROUP BY f.cod_empresa,
                                  f.data_saldo,
                                  f.cod_empresa_det,
                                  f.cod_conta_det,
                                  f.cod_empresa_contra,
                                  f.cod_conta_contra
                        HAVING abs(SUM(f.vlr_eliminacao)) > 0) LOOP


                  -- efeito contra-partida, o valor a credito será DEBITO
                  --if mreg.vlr_eliminacao < 0 then
                      v_ind_dc1 := mreg.IND_DC_ELIMIN;
                  --else
                  --    v_ind_dc1 := 'D';
                  --end if;


                /*  begin
                    select distinct g.cod_emp_part
                     into v_cod_emp_cons
                      from x240_inf_empresa_cons g
                    where 1=1
                      and g.cnpj = mreg.cgc
                      and last_day(g.data_fim_cons) = last_day(mreg.data_saldo_cons)
                      and g.cod_empresa = pCod_empresa;
                  exception
                    when others then
                      v_cod_emp_cons := null;
                  end;*/

                  --
                  -- partida
                  mLinha := NULL;
                  mLinha := LIB_STR.w(mLinha,
                                      Pcod_empresa                          || v ||
                                      pCod_Estab                            || v ||
                                      to_char(mreg.data_saldo, 'YYYYMMDD')  || v ||
                                      mreg.cod_conta_cons                   || v ||
                                      mreg.cod_empresa_cons                 || v ||
                                      mreg.cod_empresa_contra               || v ||
                                      mreg.cod_conta_contra                 || v ||
                                      form_vlr(abs(mreg.vlr_eliminacao))    || v ||
                                      v_ind_dc1,
                                      1);
                   LIB_PROC.add(mLinha, null, null, pTab(pCursorRel));

                   if pTipo = '2' then -- Gera a tabela SAFX244

                       t_safx244.cod_empresa                                := Pcod_empresa;
                       t_safx244.cod_estab                                  := pCod_Estab;
                       t_safx244.data_saldo_cons                            := to_char(mreg.data_saldo, 'YYYYMMDD');
                       t_safx244.cod_conta                                  := mreg.cod_conta_cons;
                       t_safx244.cod_emp_part                               := mreg.cod_empresa_cons;
                       t_safx244.cod_emp_contrap                            := mreg.cod_empresa_contra;
                       t_safx244.cod_conta_contrap                          := mreg.cod_conta_contra;
                       t_safx244.vlr_contrapartida                          := abs(mreg.vlr_eliminacao) * 100;
                       t_safx244.ind_contrapartida                          := v_ind_dc1;
                        begin
                           insert into safx244 values t_safx244;
                        exception
                          when others then
                            null;
                        end;
                   end if;
/*
                  -- contra-partida
                    if v_ind_dc1 = 'D' then
                       v_ind_dc2 := 'C';
                    else
                       v_ind_dc2 := 'D';
                    end if;

                  mLinha := NULL;
                  mLinha := LIB_STR.w(mLinha,
                                      Pcod_empresa                          || v ||
                                      pCod_Estab                            || v ||
                                      to_char(mreg.data_saldo, 'YYYYMMDD')  || v ||
                                      mreg.cod_conta_contra                 || v ||
                                      mreg.cod_empresa_contra               || v ||
                                      mreg.cod_empresa_cons                 || v ||
                                      mreg.cod_conta_cons                   || v ||
                                      form_vlr(abs(mreg.vlr_eliminacao))    || v ||
                                      v_ind_dc2,
                                      1);
                   LIB_PROC.add(mLinha, null, null, pTab(pCursorRel));

                   if pTipo = '2' then -- Gera a tabela SAFX244

                       t_safx244.cod_empresa                                := Pcod_empresa;
                       t_safx244.cod_estab                                  := pCod_Estab;
                       t_safx244.data_saldo_cons                            := to_char(mreg.data_saldo, 'YYYYMMDD');
                       t_safx244.cod_conta                                  := mreg.cod_conta_contra;
                       t_safx244.cod_emp_part                               := mreg.cod_empresa_contra;
                       t_safx244.cod_emp_contrap                            := mreg.cod_empresa_cons;
                       t_safx244.cod_conta_contrap                          := mreg.cod_conta_cons;
                       t_safx244.vlr_contrapartida                          := abs(mreg.vlr_eliminacao) * 100;
                       t_safx244.ind_contrapartida                          := v_ind_dc2;
                        begin
                           insert into safx244 values t_safx244;
                        exception
                          when others then
                            null;
                        end;
                   end if;
*/

         end loop;

        elsif pTab(pCursorRel) = '4' then
          -- SAFX262

          LIB_PROC.add_tipo(mproc_id,
                            pTab(pCursorRel),
                            'SAFX262_' || Pcod_empresa || '.csv',
                            2);
          Cabecalho1(pTab(pCursorRel), vNome, pPeriodo);


          for reg1 in (select distinct p.cod_empresa,
                                        p.cod_estab,
                                        p.data_ini_cons,
                                        p.data_fim_cons,
                                        p.cod_emp_part,
                                        p.cod_conta,
                                        p.cod_conta_cons
                          from SPED_CONTAS_EMP_CONS p
                         where p.cod_empresa = Pcod_empresa
                           and pPeriodo between p.data_ini_cons and p.data_fim_cons)loop

                    mLinha := NULL;
                    mLinha := LIB_STR.w(mLinha,
                                        Pcod_empresa                       || v ||
                                        reg1.cod_estab                     || v ||
                                        reg1.data_ini_cons                 || v ||
                                        reg1.data_fim_cons                 || v ||
                                        reg1.cod_emp_part                  || v ||
                                        reg1.cod_conta                     || v ||
                                        reg1.cod_conta_cons,
                                        1);
                     LIB_PROC.add(mLinha, null, null, pTab(pCursorRel));

         end loop;

        elsif pTab(pCursorRel) = '5' THEN -- relatorio de saldos ECD

          LIB_PROC.add_tipo(mproc_id,
                            pTab(pCursorRel),
                            'SALDOS_ECD_' || to_char(pPeriodo,'mmyyyy') || '.csv',
                            2);
          Cabecalho1(pTab(pCursorRel), vNome, pPeriodo);


          for reg1 in (SELECT distinct
                             NVL(emp.cod_empresa,x240.cod_emp_part) AS cod_empresa
                             , saldos.cnpj
                             , to_char(saldos.periodo,'mm/yyyy') AS periodo
                             , cons.cod_conta_cons
                             , saldos.cod_conta
                             , saldos.vlr_saldo_fim
                             , saldos.ind_dc_fim
                             , saldos.arquivo

                             FROM treg_saldo_ecd saldos, empresa emp, x240_inf_empresa_cons x240, sped_contas_emp_cons cons
                      WHERE  1=1
                      AND    saldos.cnpj         = emp.cnpj(+)
                      AND    saldos.cnpj         = x240.cnpj
                      AND    x240.cod_emp_part   = cons.cod_emp_part(+)
                      AND    saldos.cod_conta    = cons.cod_conta(+)
                      AND    last_day(cons.data_fim_cons) = last_day(pPeriodo)
                      AND    last_day(saldos.periodo) = last_day(pPeriodo)

                      ORDER BY 1,4,5)
                      loop

                    mLinha := NULL;
                    mLinha := LIB_STR.w(mLinha,
                                        reg1.cod_empresa                       || v ||
                                        reg1.cnpj                              || v ||
                                        reg1.periodo                           || v ||
                                        reg1.cod_conta_cons                    || v ||
                                        reg1.cod_conta                         || v ||
                                        reg1.vlr_saldo_fim                     || v ||
                                        reg1.ind_dc_fim                        || v ||
                                        reg1.arquivo,
                                        1);
                     LIB_PROC.add(mLinha, null, null, pTab(pCursorRel));

         end loop;

        end if;

      end loop;

      LIB_PROC.add_log(mproc_id || '  Processo ', 1);
      LIB_PROC.CLOSE();

      RETURN mproc_id;

    END;
  END;

  PROCEDURE Cabecalho1(ptipo VARCHAR2, pnome VARCHAR2, p_periodo date) IS

    mLinha VARCHAR2(1000);
  BEGIN

    mLinha := NULL;
    mLinha := LIB_STR.w(mLinha,
                        'Empresa: ' || pnome || ';;;;;;;;;;;;;;;;;;;;;',
                        1);
    LIB_PROC.add(mLinha, null, null, ptipo);

    mLinha := NULL;
    mLinha := LIB_STR.w(mLinha,
                        'Período: ' || to_char(p_periodo, 'MM/YYYY') ||
                        ';;;;;;;;;;;;;;;;;;;;;',
                        1);
    LIB_PROC.add(mLinha, null, null, ptipo);

    mLinha := NULL;
    mLinha := LIB_STR.w(mLinha, ';;;;;;;;;;;;;;;;;;;;;', 1);
    LIB_PROC.add(mLinha, null, null, ptipo);

    if ptipo = '1' then

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha,
                              'Relatório de Geração da SAFX242 - Saldos das Contas Consolidadas;;;;;;;;;;;;;;;;;;;;;',
                              1);
          LIB_PROC.add(mLinha, null, null, ptipo);

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha, ';;;;;;;;;;;;;;;;;;;;;;;', 1);
          LIB_PROC.add(mLinha, null, null, ptipo);

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha,
                              'COD_EMPRESA;COD_ESTAB;DATA_SALDO_CONS;COD_CONTA;VLR_AGLUTINADO;IND_AGLUTINADO;VLR_ELIMINACAO;IND_ELIMINACAO;VLR_CONSOLIDADO;IND_CONSOLIDADO;',
                              1);
          LIB_PROC.add(mLinha, null, null, ptipo);

    elsif ptipo = '2' then

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha,
                              'Relatório de Geração da SAFX243 - Empresas Detentoras das Parcelas do Valor Eliminado Total;;;;;;;;;;;;;;;;;;;;;',
                              1);

          LIB_PROC.add(mLinha, null, null, ptipo);

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha, ';;;;;;;;;;;;;;;;;;;;;;;', 1);
          LIB_PROC.add(mLinha, null, null, ptipo);

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha,
                              'COD_EMPRESA; COD_ESTAB; DATA_SALDO_CONS;COD_CONTA;COD_EMP_PART;VLR_ELIMINADO_TOT;IND_ELIMINADO_TOT;',
                              1);
          LIB_PROC.add(mLinha, null, null, ptipo);

    elsif ptipo = '3' then

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha,
                              'Relatório de Geração da SAFX244 - Empresas Contrapartes das Parcelas do Valor Eliminado Total;;;;;;;;;;;;;;;;;;;;;',
                              1);

          LIB_PROC.add(mLinha, null, null, ptipo);

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha, ';;;;;;;;;;;;;;;;;;;;;;;', 1);
          LIB_PROC.add(mLinha, null, null, ptipo);

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha,
                              'COD_EMPRESA;COD_ESTAB;DATA_SALDO_CONS;COD_CONTA;COD_EMP_PART;COD_EMP_CONTRAP;COD_CONTA_CONTRAP;VLR_CONTRAPARTIDA;IND_CONTRAPARTIDA;',
                              1);
          LIB_PROC.add(mLinha, null, null, ptipo);

    elsif ptipo = '4' then

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha,
                              'Relatório de Geração da SAFX262 - Mapeamento para Plano de Contas das Empresas Consolidadas (ECD);;;;;;;;;;;;;;;;;;;;;',
                              1);

          LIB_PROC.add(mLinha, null, null, ptipo);

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha, ';;;;;;;;;;;;;;;;;;;;;;;', 1);
          LIB_PROC.add(mLinha, null, null, ptipo);

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha,
                              'COD_EMPRESA;COD_ESTAB;DATA_INI_CONS;DATA_FIM_CONS;COD_EMP_PART;COD_CONTA;COD_CONTA_CONS;',
                              1);
          LIB_PROC.add(mLinha, null, null, ptipo);

    elsif ptipo = '5' THEN -- relatorio dos saldos ECD

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha,
                              'SALDOS ECD - Saldos carregados através dos arquivos ECD;;;;;;;;;;;;;;;;;;;;;',
                              1);

          LIB_PROC.add(mLinha, null, null, ptipo);

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha, ';;;;;;;;;;;;;;;;;;;;;;;', 1);
          LIB_PROC.add(mLinha, null, null, ptipo);

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha,
                              'COD_EMPRESA;CNPJ;PERIODO;COD_CONTA_CONS;COD_CONTA_ECD;VLR_SALDO_FIM;IND_SALDO_FIM;NOME_ARQUIVO;',
                              1);
          LIB_PROC.add(mLinha, null, null, ptipo);

    end if;

  END Cabecalho1;

END MSAF_GERA_BLOCOK_ECD_CPROC;
/
