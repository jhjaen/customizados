CREATE OR REPLACE PACKAGE MSAF_GERA_BLOCOK_ECD_CPROC IS

  --###########################################################################
  --## Autor    : Diego  Peres                                               ##
  --## Cria�ao  : 25/05/2020                                                 ##
  --## Empresa  : ATVI Consultoria                                           ##
  --## Objetivo : GERA��O DAS TABELAS SAFX242, SAFX243 E SAFX244             ##
  --##             PARA O BLOCO K - ECD                                      ##
  --###########################################################################

  -- Declara�?o de Vari�veis P�blicas
  Cursor C1(v_periodo in date) is
      select    c.cod_emp_part as cod_empresa,
                a.cnpj,
                a.periodo,
                b.cod_conta_cons as cod_conta,
                SUM(decode(a.ind_dc_fim,
                            'D',
                            nvl(a.vlr_saldo_fim, 0),
                            nvl(a.vlr_saldo_fim, 0) * -1)) as VLR_SALDO_FIM
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
  --## Cria�ao  : 25/05/2020                                                        ##
  --## Empresa  : ATVI Consultoria                                                   ##
  --## Objetivo : GERA��O DAS TABELAS SAFX242, SAFX243 E SAFX244                   ##
  --##             PARA O BLOCO K - ECD                                              ##
  --## Ajustes  :                                                                    ##
  --##            001 - 22/04/2021                                                   ##
  --##            Inclusao do relatorio dos saldos em carregados em treg_saldo_ecd   ##
  --##                                                                               ##
  --##            002 -  30/04/2021                                                  ##
  --##            Alteracao na regra de composicao das eliminacoes                   ##
  --##            003 - 27/04/2023                                                   ##
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
                       'Per�odo',
                       'Date',
                       'Textbox',
                       'S',
                       NULL,
                       'mm/yyyy');

    -- :4
    LIB_PROC.add_param(pstr,
                       'Op��es de Processamento',
                       'Varchar2',
                       'Combobox',
                       'S',
                       '1',
                       null,
                       'select ''1'',''1 - Gerar Relat�rio para Confer�ncia'' from dual union all
                        select ''2'',''2 - Gerar SAFX'' from dual order by 1 asc');

    -- :5
    LIB_PROC.add_param(pstr,
                       'Selecione a Tabela para Gera��o',
                       'Varchar2',
                       'MultiSelect',
                       'S',
                       NULL,
                       null,
                       'select 0, to_char(''SAFX240 - Rela��o das Empresas Consolidadas'') from dual union all
                        select 1, to_char(''SAFX242 - Saldos das Contas Consolidadas'') from dual union all
                        select 2, to_char(''SAFX243 - Empresas Detentoras das Parcelas do Valor Eliminado Total'') from dual union all
                        select 3, to_char(''SAFX244 - Empresas Contrapartes das Parcelas do Valor Eliminado Total'') from dual union all
                        select 4, to_char(''SAFX262 - Mapeamento para Plano de Contas das Empresas Consolidadas (ECD)'') from dual union all
                        select 5, to_char(''SALDOS ECD - Saldos carregados atrav�s dos arquivos ECD'') from dual order by 1 asc',
                        NULL,
                        NULL
                        );

    RETURN pstr;
  END;

  FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN '4.0 - Gera��o das Tabelas para o Bloco K - ECD';
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
    RETURN 'Processo para Gera��o das tabelas SAFX242, SAFX243 e SAFX244 do Bloco K - ECD';
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

    -- Variaveis de Trabalho */
    mproc_id          INTEGER;
    mLinha            VARCHAR2(1000);
    v                 varchar2(1) := ';';
    v_vlr_elimin      number(17,2) :=0;
    --v_ind_dc_elimn    varchar2(1) := 0;
    --v_cod_conta_det   varchar2(70) :=null;
    v_vlr_consolid    number(17,2) :=0;
    v_ind_dc1         varchar2(1) := null;
    --v_ind_dc2         varchar2(1) := null;
    --v_ind_dc3         varchar2(1) := null;

    --v_cod_emp_cons   varchar2(3) := null;


    t_safx242 safx242%rowtype;
    t_safx243 safx243%rowtype;
    t_safx244 safx244%rowtype;
    t_saldo   MSAF_SALDO_DETALHADO_K%rowtype;
    v_param   number :=0;

    v_finalizar number := 0;

    --Status_w        INTEGER;
    RazaoEmp_w      EMPRESA.RAZAO_SOCIAL%TYPE;
    RazaoEst_w      ESTABELECIMENTO.RAZAO_SOCIAL%TYPE;
    CGC_w           ESTABELECIMENTO.CGC%TYPE;
    --Ind_Atividade_w ESTABELECIMENTO.Ind_Atividade%type;
    --IndConvIcms_w   ESTABELECIMENTO.IND_CONV_ICMS%TYPE;
    --CodAtividade_w  ESTABELECIMENTO.COD_ATIVIDADE%TYPE;
    --UF_estab_w      ESTADO.COD_ESTADO%TYPE;
    linha_log       varchar2(100);

    reg_partida        msaf_blocok_eliminacao%ROWTYPE;
    reg_contrapartida  msaf_blocok_eliminacao%ROWTYPE;

    --Finalizar EXCEPTION;

  BEGIN

    BEGIN

      mproc_id := LIB_PROC.new('MSAF_GERA_BLOCOK_ECD_CPROC');
      LIB_PROC.add_log('Log gerado', 1);
      --    Mcod_Empresa := Pcod_empresa; --Lib_Parametros.Recuperar('EMPRESA');

      --**************************************************/
      -- Inclui Header/Footer do Log de Erros            */
      --**************************************************/
      lib_proc.Add_Log(RazaoEmp_w, 0);
      lib_proc.Add_Log('Filial: ' || Pcod_Estab || ' - ' || RazaoEst_w, 0);
      lib_proc.Add_Log('CNPJ: ' || CGC_w, 0);
      lib_proc.Add_Log('.                                                                                                          Relat�rio de Log',
                       0);
      -- lib_proc.Add_Log('.                                                                                               Dt.Ini : ' ||
      --                to_date(pData_Ini,'DD/MM/YYYY') || '  -  Dt.Fim: ' ||to_date(pData_Fim,'DD/MM/YYYY') , 0);

      linha_log := 'Log de Processo: ' || mproc_id;
      lib_proc.Add_Log('.                                                                                                        ' ||
                       linha_log,
                       0);

      lib_proc.Add_Log(rpad('-', 200, '-'), 0);
      lib_proc.Add_Log(' ', 0);

      --**************************************************************/
      -- Valida��o de datas inicial e final informadas com par�metro */
      --**************************************************************/

      If pCod_empresa is null Then
        lib_proc.Add_Log('Erro: A Empresa deve ser informada.', 0);
        lib_proc.Add_Log(' ', 0);
        v_finalizar := v_finalizar + 1;
      End If;

      If pCod_Estab is null Then
        lib_proc.Add_Log('Erro: O campo C�digo do Estabelecimento deve ser informado.',
                         0);
        lib_proc.Add_Log(' ', 0);
        v_finalizar := v_finalizar + 1;
      End If;

      If pPeriodo is null Then
        lib_proc.Add_Log('Erro: O Per�odo deve ser informado.', 0);
        lib_proc.Add_Log(' ', 0);
        v_finalizar := v_finalizar + 1;
      End If;

      if v_finalizar > 0 then
        lib_proc.CLOSE;
        RETURN mproc_id;
      end if;
      
      begin
        execute immediate 'truncate table MSAF_SALDO_DETALHADO_K';
        execute immediate 'truncate table MSAF_BLOCOK_ELIMINACAO';

        EXECUTE IMMEDIATE 'alter session set nls_numeric_characters = '',.''';
        exception
          when others then
            lib_proc.add_log('Erro inesperado ao truncar tabelas e alterar sessao: '||SQLERRM,1);
      end;

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
      -- A composicao das eliminacoes ser� feita em 3 etapas (Eliminacoes informadas manualmente, Eliminacoes atraves da conta consolidadora, Eliminacoes atraves da conta analitica)

      -- 003
      -- 27/04/2023
      -- DO LOOP ABAIXO, MANTER APENAS O CURSOR DE ELEIMINACOES MANUAIS
      -- AINDA NO LOOP, MANTER A INSERCAO DA CONTRAPARTIDA
      -- FORA DO LOOP, INCLUIR A NOVA REGRA DE COMPOSICAO DE SALDOS


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

                         , '0'
                       FROM  MSAF_PARAM_BLOCOK_ECD PARAM
                       WHERE 1=1
                       AND   param.cod_empresa_cons = Pcod_empresa
                       AND   param.Periodo          = last_day(pPeriodo)
                       AND   NVL(param.vlr_eliminacao,0) >0)
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

             -- Inclusao ajuste 003
            
            begin
            
            for calc in (SELECT PARAM.COD_EMPRESA_CONS
                               , PARAM.PERIODO
                               , PARAM.COD_EMPRESA_DET
                               , PARAM.COD_CONTA_DET
                               , PARAM.COD_EMPRESA_CONTRA
                               , PARAM.COD_CONTA_CONTRA
                               , PARAM.Ind_Utiliza_Saldo_Fim
                                                         
                          FROM MSAF_PARAM_BLOCOK_ECD        PARAM
                                                         
                         WHERE 1 = 1
                           -- FILTROS
                           AND PARAM.COD_EMPRESA_CONS       = Pcod_empresa
                           AND PARAM.PERIODO                = last_day(pPeriodo)
                           AND NVL(PARAM.VLR_ELIMINACAO, 0) = 0
                           
                           /*
                           and PARAM.cod_empresa_det = '1'
                           and PARAM.cod_conta_det   = '0011303007'
                           and PARAM.cod_empresa_contra = '200'
                           */
                           )
                           
                           loop
                             
                           reg_partida        := null;
                           reg_contrapartida  := null;
                             
                             

                             -- linha 01 do lancamento
                             reg_partida.cod_empresa        := calc.cod_empresa_cons;
                             reg_partida.data_saldo         := last_day(calc.periodo);
                             reg_partida.cod_empresa_det    := calc.cod_empresa_det;
                             reg_partida.cod_conta_det      := calc.cod_conta_det;
                             reg_partida.cod_empresa_contra := calc.cod_empresa_contra;
                             reg_partida.cod_conta_contra   := calc.cod_conta_contra;
                             reg_partida.origem             := '1';
                             
                             begin
                               
                               select --nvl(max(abs(d.vlr_saldo_fim)),0)
                                      nvl(d.vlr_saldo_fim,0)
                                      into reg_partida.vlr_eliminacao
                                      from msaf_saldo_detalhado_k d
                                      where 1=1
                                      and   d.cod_empresa         = calc.cod_empresa_cons
                                      and   d.data_saldo_cons     = last_day(calc.periodo)
                                      and   d.cod_conta           = calc.cod_conta_contra--calc.cod_conta_det
                                      and   d.cod_emp_part        = calc.cod_empresa_contra;

                                 /*select decode(sign(reg_partida.vlr_eliminacao),1,'C','D')
                                      into reg_partida.ind_deb_cred
                                      from dual;*/ 
                               select decode(sign(reg_partida.vlr_eliminacao),1,'D','C')
                                      into reg_partida.ind_deb_cred
                                      from dual;
                             
                             exception
                               when no_data_found then
                                 reg_partida.vlr_eliminacao := '0';
                                 reg_partida.ind_deb_cred   := 'C';
                             end;
                             

                             -- linha 02 do lancamento (reversao)
                             reg_contrapartida.cod_empresa        := reg_partida.cod_empresa;
                             reg_contrapartida.data_saldo         := reg_partida.data_saldo;
                             reg_contrapartida.cod_empresa_det    := reg_partida.cod_empresa_contra;
                             reg_contrapartida.cod_conta_det      := reg_partida.cod_conta_contra;
                             reg_contrapartida.cod_empresa_contra := reg_partida.cod_empresa_det;
                             reg_contrapartida.cod_conta_contra   := reg_partida.cod_conta_det;
                             reg_contrapartida.origem             := '2';

                             begin
                               select --nvl(max(abs(d.vlr_saldo_fim)),0)
                                      nvl(d.vlr_saldo_fim,0)
                                      into reg_contrapartida.vlr_eliminacao
                                      from msaf_saldo_detalhado_k d
                                      where 1=1
                                      and   d.cod_empresa         = calc.cod_empresa_cons
                                      and   d.data_saldo_cons     = last_day(calc.periodo)
                                      and   d.cod_conta           = calc.cod_conta_det--calc.cod_conta_contra
                                      and   d.cod_emp_part        = calc.cod_empresa_det;--calc.cod_empresa_contra;

                               select decode(sign(reg_contrapartida.vlr_eliminacao),1,'D','C')
                                      into reg_contrapartida.ind_deb_cred
                                      from dual;


                             exception
                               when no_data_found then
                                 reg_contrapartida.vlr_eliminacao := '0';
                                 reg_contrapartida.ind_deb_cred   := 'C';
                             end;

                             
                             reg_partida.vlr_eliminacao := abs(reg_partida.vlr_eliminacao);
                             reg_contrapartida.vlr_eliminacao := abs(reg_contrapartida.vlr_eliminacao);
                             -- insere na tabela de eliminacao
                             
                             if
                               reg_partida.vlr_eliminacao > 0 then
                               
                              insert into MSAF_BLOCOK_ELIMINACAO values reg_partida;
                              
                              insert into MSAF_BLOCOK_ELIMINACAO values reg_contrapartida;
                               
                             end if;
                             
                             
                           end loop;
                           
                           -- remocao de registros caso hajam duplicidades
                           begin
                             for del in (select bke.rowid
                                                 , bke.cod_empresa
                                                 , bke.data_saldo
                                                 , bke.cod_conta_det
                                                 , bke.ind_deb_cred
                                                 , bke.vlr_eliminacao
                                                 , row_number() over(partition by bke.cod_empresa
                                                                                  , bke.data_saldo
                                                                                  , bke.cod_conta_det
                                                                                  , bke.ind_deb_cred
                                                                                  , bke.vlr_eliminacao
                                                                                  order by 
                                                                                  bke.cod_empresa
                                                                                  , bke.data_saldo
                                                                                  , bke.cod_conta_det
                                                                                  , bke.ind_deb_cred
                                                                                  , bke.vlr_eliminacao
                                                                                  ) as count
                                           from MSAF_BLOCOK_ELIMINACAO bke)
                                           loop
                                             if
                                               del.count > 1 then
                                               delete from MSAF_BLOCOK_ELIMINACAO d
                                                      where d.rowid = del.rowid;
                                             end if;
                                           end loop;
                                           commit;
                           end;
                           
                           -- tratamento para conta de encerramento
                           begin
                             for del in (select d.rowid from MSAF_BLOCOK_ELIMINACAO d
                                               where d.cod_empresa_contra = '1'
                                               and d.cod_conta_contra = '0033101009'
                                         )
                                         loop
                                           delete from MSAF_BLOCOK_ELIMINACAO
                                            where rowid = del.rowid;
                                         end loop;
                           end;
                           
                           -- inversao manual para conta de encerramento
                           begin
                             for inv in (select * from MSAF_BLOCOK_ELIMINACAO
                                                   where cod_empresa_det = '1'
                                                   and cod_conta_det = '0033101009'
                                        )
                                        loop
                                          
                                        insert into MSAF_BLOCOK_ELIMINACAO(COD_EMPRESA,
                                                                           DATA_SALDO,
                                                                           COD_EMPRESA_DET,
                                                                           COD_CONTA_DET,
                                                                           COD_EMPRESA_CONTRA,
                                                                           COD_CONTA_CONTRA,
                                                                           IND_DEB_CRED,
                                                                           VLR_ELIMINACAO,
                                                                           ORIGEM)
                                                                           values
                                                                           (inv.cod_empresa,
                                                                            inv.data_saldo,
                                                                            inv.cod_empresa_contra,
                                                                            inv.cod_conta_contra,
                                                                            inv.cod_empresa_det,
                                                                            inv.cod_conta_det,
                                                                            case when inv.ind_deb_cred = 'C' then 'D' else 'C' end,
                                                                            inv.vlr_eliminacao,
                                                                            inv.origem
                                                                           );
                                        
                                        end loop;
                           end;
                           commit;
           
           exception
              when others then
               lib_proc.add_log('Erro inesperado ao inserir dados na tabela MSAF_BLOCOK_ELIMINACAO: '||SQLERRM||' - '||dbms_utility.format_error_backtrace,1);
               commit;
           end;

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
                        group by q.cod_empresa
                              ,q.cod_estab
                              ,q.data_saldo_cons
                              ,q.cod_conta
                         order by q.cod_conta asc ) loop


              t_safx242 := null;
              
              
              -- verifica se tem eliminacao
              begin
                select sum(decode(f.ind_deb_cred,'C',f.vlr_eliminacao*-1,f.vlr_eliminacao))
                into   v_vlr_elimin
                from MSAF_BLOCOK_ELIMINACAO f
                where 1=1
                  and f.cod_empresa    = mreg.cod_empresa
                  and f.data_saldo     = mreg.data_saldo_cons
                  --and f.cod_conta_det  = mreg.cod_conta;
                  and f.cod_conta_contra  = mreg.cod_conta;                  
              exception
                when others then
                  v_vlr_elimin := 0;
              end;



               if pTipo = '2' then -- Gera a tabela SAFX242

                   t_safx242.cod_empresa     := Pcod_empresa;
                   t_safx242.cod_estab       := pCod_Estab;
                   t_safx242.data_saldo_cons := to_char(mreg.data_saldo_cons, 'YYYYMMDD');
                   t_safx242.cod_conta       := mreg.cod_conta;
                   
                   t_safx242.vlr_aglutinado := abs(nvl(mreg.vlr_saldo_fim,0)) * 100;
                   t_safx242.ind_aglutinado := case when nvl(mreg.vlr_saldo_fim,0) < 0 then 'C' else 'D' end;
                   
                   t_safx242.vlr_eliminacao := abs(nvl(v_vlr_elimin, 0)) * 100;
                   t_safx242.ind_eliminacao := case when nvl(v_vlr_elimin,0) < 0 then 'C' else 'D' end;

                   t_safx242.vlr_consolidado := abs( ( (nvl(mreg.vlr_saldo_fim,0)) + (nvl(v_vlr_elimin*-1, 0)) ) ) * 100;
                   t_safx242.ind_consolidado := case when ( (nvl(mreg.vlr_saldo_fim,0)) + (nvl(v_vlr_elimin, 0)) ) < 0 then 'C' else 'D' end;



              mLinha := NULL;
              mLinha := LIB_STR.w(mLinha,
                                  Pcod_empresa                                                               || v ||
                                  pCod_Estab                                                                 || v ||
                                  to_char(mreg.data_saldo_cons, 'YYYYMMDD')                                  || v ||
                                  mreg.cod_conta                                                             || v ||
                                  
                                  form_vlr(abs(nvl(mreg.vlr_saldo_fim,0)))                                   || v ||
                                  case when nvl(mreg.vlr_saldo_fim,0) < 0 then 'C' else 'D' end              || v ||

                                  form_vlr(abs(nvl(v_vlr_elimin, 0)))                                        || v ||
                                  case when nvl(v_vlr_elimin,0) < 0 then 'D' else 'C' end                    || v ||

                                  form_vlr( ( (nvl(mreg.vlr_saldo_fim,0)) + (nvl(v_vlr_elimin, 0)) ) )       || v ||
                                  case when ( (nvl(mreg.vlr_saldo_fim,0)) + (nvl(v_vlr_elimin, 0)) ) < 0 then 'C' else 'D' end,
                                  
                                  1);
                                  
               LIB_PROC.add(mLinha, null, null, pTab(pCursorRel));


                    begin
                    -- gerar safx242 apenas o que tiver movimento

                       if
                         ( nvl(trim(t_safx242.vlr_eliminacao),0)
                           +
                           nvl(trim(t_safx242.vlr_aglutinado),0)
                           +
                           nvl(trim(t_safx242.vlr_consolidado),0)
                           <> 0
                         ) then
                         insert into safx242 values t_safx242;
                       end if;




                       
                       
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

          for reg1 in (SELECT B.COD_EMPRESA
                             , A.DATA_SALDO
                             , A.COD_EMPRESA_DET                                 AS EMPRESA_PART
                             , A.COD_CONTA_DET AS COD_CONTA
                             
                             --, DECODE(SIGN(SUM(A.VLR_ELIMINACAO)), -1, 'D', 'C') AS IND_DC_ELIMIN
                             --, SUM(A.VLR_ELIMINACAO)                             AS VLR_ELIMIN
                             
                             , sum(decode(a.ind_deb_cred,'C',a.vlr_eliminacao*-1,a.vlr_eliminacao)) as VLR_ELIMIN
                             , DECODE(SIGN(sum(decode(a.ind_deb_cred,'C',a.vlr_eliminacao*-1,a.vlr_eliminacao))), -1, 'C', 'D') AS IND_DC_ELIMIN

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
                        --v_ind_dc1 := reg1.ind_dc_elimin;
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
                                        reg1.ind_dc_elimin,
                                        1);
                     LIB_PROC.add(mLinha, null, null, pTab(pCursorRel));

                     if pTipo = '2' then -- Gera a tabela SAFX243

                         t_safx243.cod_empresa       := Pcod_empresa;
                         t_safx243.cod_estab         := pCod_Estab;
                         t_safx243.data_saldo_cons   := to_char(reg1.data_saldo, 'YYYYMMDD');
                         t_safx243.cod_conta         := reg1.cod_conta;
                         t_safx243.cod_emp_part      := reg1.empresa_part;
                         t_safx243.vlr_eliminado_tot := abs(reg1.vlr_elimin) * 100;
                         t_safx243.ind_eliminado_tot := reg1.ind_dc_elimin;
                          begin
                          
                             if
                               nvl(trim(t_safx243.vlr_eliminado_tot),0) <> 0 then
                               insert into safx243 values t_safx243;                               
                             end if;  
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

          for mreg in (SELECT f.cod_empresa,
                               f.data_saldo,
                               f.cod_empresa_det COD_EMPRESA_CONS,
                               f.cod_conta_det COD_CONTA_CONS,
                               f.cod_empresa_contra,
                               f.cod_conta_contra,
                               f.ind_deb_cred IND_DC_ELIMIN,
                               f.vlr_eliminacao VLR_ELIMINACAO,
                               f.origem
                          FROM MSAF_BLOCOK_ELIMINACAO f, estabelecimento g, x240_inf_empresa_cons h
                         WHERE 1 = 1
                           AND f.cod_empresa = pCod_empresa
                           AND f.cod_empresa = g.cod_empresa
                           AND g.cod_estab = pCod_Estab
                           AND g.cgc = h.cnpj
                           AND f.data_saldo = h.data_fim_cons
                           AND f.data_saldo = last_day(pPeriodo)
                           AND F.VLR_ELIMINACAO > 0
                           ) LOOP

                  -- efeito contra-partida, o valor a credito ser� DEBITO
                  --if mreg.vlr_eliminacao < 0 then
                      v_ind_dc1 := mreg.IND_DC_ELIMIN;
                  --else
                  --    v_ind_dc1 := 'D';
                  --end if;

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
                       t_safx244.pst_id                                     := mreg.origem;
                        begin
                           insert into safx244 values t_safx244;
                        exception
                          when others then
                            null;
                        end;
                   end if;

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

    END;
    
    LIB_PROC.add_log(mproc_id || '  Processo ', 1);
      LIB_PROC.CLOSE();

      RETURN mproc_id;
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
                        'Per�odo: ' || to_char(p_periodo, 'MM/YYYY') ||
                        ';;;;;;;;;;;;;;;;;;;;;',
                        1);
    LIB_PROC.add(mLinha, null, null, ptipo);

    mLinha := NULL;
    mLinha := LIB_STR.w(mLinha, ';;;;;;;;;;;;;;;;;;;;;', 1);
    LIB_PROC.add(mLinha, null, null, ptipo);

    if ptipo = '1' then

          mLinha := NULL;
          mLinha := LIB_STR.w(mLinha,
                              'Relat�rio de Gera��o da SAFX242 - Saldos das Contas Consolidadas;;;;;;;;;;;;;;;;;;;;;',
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
                              'Relat�rio de Gera��o da SAFX243 - Empresas Detentoras das Parcelas do Valor Eliminado Total;;;;;;;;;;;;;;;;;;;;;',
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
                              'Relat�rio de Gera��o da SAFX244 - Empresas Contrapartes das Parcelas do Valor Eliminado Total;;;;;;;;;;;;;;;;;;;;;',
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
                              'Relat�rio de Gera��o da SAFX262 - Mapeamento para Plano de Contas das Empresas Consolidadas (ECD);;;;;;;;;;;;;;;;;;;;;',
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
                              'SALDOS ECD - Saldos carregados atrav�s dos arquivos ECD;;;;;;;;;;;;;;;;;;;;;',
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
