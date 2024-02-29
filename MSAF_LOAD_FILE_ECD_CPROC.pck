CREATE OR REPLACE PACKAGE MSAF_LOAD_FILE_ECD_CPROC IS

  --###########################################################################
  --## Autor    : Diego  Peres                                               ##
  --## Cria�?o  : 25/05/2020                                                 ##
  --## Empresa  : ATVI Consultoria                                           ##
  --## Objetivo : PARAMETRO PARA GERA��O DO BLOCO K - ECD                    ##
  --## Ajustes  :                                                            ##
  --##            001 - Felipe Guimaraes 17/04/2021                          ##
  --##            Permitir carga dos saldos atraves do registro K300         ##
  --###########################################################################

  /* Declara�?o de Vari�veis P�blicas */
  vNome  estabelecimento.razao_social%TYPE;

  FUNCTION Parametros RETURN         VARCHAR2;
  FUNCTION Nome RETURN               VARCHAR2;
  FUNCTION Tipo RETURN               VARCHAR2;
  FUNCTION Versao RETURN             VARCHAR2;
  FUNCTION Descricao RETURN          VARCHAR2;
  FUNCTION Modulo RETURN             VARCHAR2;
  FUNCTION Classificacao RETURN      VARCHAR2;

  FUNCTION Executar(pRegistro         VARCHAR2, -- 1= I155 + I355, 2= K300
                    pDirectory        Varchar2,
                    pFiles            lib_proc.varTab,
                    pNUtilEnc          varchar2,
                    pContaX02         varchar2
                    ) RETURN INTEGER;

  PROCEDURE MONTA_LINHA (PS_LINHA IN VARCHAR2, vn_rel number);

  procedure cabecalho(ps_nome_rel            varchar2
                   ,vn_rel                  number
                   ,vn_diretorio           varchar2
                   ,vs_nome_interface      varchar2);

  procedure final_html(vn_rel number);

  procedure dados_relatorio (vs_arquivo     varchar2
                          ,vs_qtde_reg    varchar2
                          ,vn_rel             number);


  END MSAF_LOAD_FILE_ECD_CPROC;
/
CREATE OR REPLACE PACKAGE BODY MSAF_LOAD_FILE_ECD_CPROC IS

  --###########################################################################
  --## Autor    : Diego  Peres                                               ##
  --## Cria�?o  : 25/05/2020                                                 ##
  --## Empresa  : ATVI Consultoria                                           ##
  --## Objetivo : PARAMETRO PARA GERA��O DO BLOCO K - ECD                    ##
  --## Ajustes  :                                                            ##
  --##            001 - Felipe Guimaraes 17/04/2021                          ##
  --##            Permitir carga dos saldos atraves do registro K300         ##
  --##            Ajustes para recuperar grupo e data de cadastro            ##
  --###########################################################################

  musuario        usuario_estab.cod_usuario%TYPE;
  mcod_empresa    empresa.cod_empresa%type;
  mcod_estab      estabelecimento.cod_estab%type;



  t_x2002         x2002_plano_contas%rowtype := null;
  v_achou         number := 0;

  id_x2002        x2002_plano_contas.ident_conta%type := null;

  v_grupo         x2002_plano_contas.grupo_conta%TYPE;
  v_data_grupo    x2002_plano_contas.valid_conta%TYPE;


  v_num           number :=0;
  v_qtde_reg      number :=0;

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


   v_num := carrega_arquivos('TXT');


-- 001 Inicio

    -- :1
    LIB_PROC.ADD_PARAM(PPARAM      => PSTR,
                       PTITULO     => '',
                       PTIPO       => 'varchar2',
                       PCONTROLE   => 'text',
                       PMANDATORIO => 'N',
                       PDEFAULT    => NULL,
                       PMASCARA    => NULL,
                       PVALORES    => NULL,
                       PAPRESENTA  => NULL,
                       PHABILITA   => NULL);



    -- :2
    lib_proc.add_param(pparam      => pstr,
                       ptitulo     => 'Origem dos saldos',
                       ptipo       => 'varchar2',
                       pcontrole   => 'radiobutton',
                       pmandatorio => 'S',
                       pdefault    => '1',
                       pmascara    => NULL,
                       pvalores    => '1=Registro I155 + I355 (Saldos peri�dicos),2=Registro K300 (Saldo das contas consolidadas)',
                       papresenta  => 'S',
                       phabilita   => 'S');

    -- :3
    LIB_PROC.ADD_PARAM(PPARAM      => PSTR,
                       PTITULO     => '',
                       PTIPO       => 'varchar2',
                       PCONTROLE   => 'text',
                       PMANDATORIO => 'N',
                       PDEFAULT    => NULL,
                       PMASCARA    => NULL,
                       PVALORES    => NULL,
                       PAPRESENTA  => NULL,
                       PHABILITA   => NULL);

    --:4
    LIB_PROC.add_param(pstr,
                       'Selecione o Diret�rio',
                       'Varchar2',
                       'Combobox',
                       'S',
                       NULL,
                       NULL,
                       'SELECT A.DIRECTORY_NAME,A.DIRECTORY_NAME || '' - '' || A.DIRECTORY_PATH FROM ALL_DIRECTORIES A ORDER BY 1');

    -- :5
    LIB_PROC.ADD_PARAM(PPARAM      => PSTR,
                       PTITULO     => '',
                       PTIPO       => 'varchar2',
                       PCONTROLE   => 'text',
                       PMANDATORIO => 'N',
                       PDEFAULT    => NULL,
                       PMASCARA    => NULL,
                       PVALORES    => NULL,
                       PAPRESENTA  => NULL,
                       PHABILITA   => NULL);

    -- :6
    LIB_PROC.ADD_PARAM(PPARAM      => PSTR,
                       PTITULO     => '',
                       PTIPO       => 'varchar2',
                       PCONTROLE   => 'text',
                       PMANDATORIO => 'N',
                       PDEFAULT    => NULL,
                       PMASCARA    => NULL,
                       PVALORES    => NULL,
                       PAPRESENTA  => NULL,
                       PHABILITA   => NULL);


    -- :7
    LIB_PROC.ADD_PARAM(PPARAM      => PSTR,
                       PTITULO     => '',
                       PTIPO       => 'varchar2',
                       PCONTROLE   => 'text',
                       PMANDATORIO => 'N',
                       PDEFAULT    => NULL,
                       PMASCARA    => NULL,
                       PVALORES    => NULL,
                       PAPRESENTA  => NULL,
                       PHABILITA   => NULL);

    -- :8
    LIB_PROC.ADD_PARAM(PPARAM      => PSTR,
                       PTITULO     => '*** ATEN��O: Selecione a origem de saldos (Registro K300) apenas para empresas que possuam saldos informados nesse registro.',
                       PTIPO       => 'varchar2',
                       PCONTROLE   => 'text',
                       PMANDATORIO => 'N',
                       PDEFAULT    => NULL,
                       PMASCARA    => NULL,
                       PVALORES    => NULL,
                       PAPRESENTA  => NULL,
                       PHABILITA   => NULL);

    -- :9
    LIB_PROC.ADD_PARAM(PPARAM      => PSTR,
                       PTITULO     => '',
                       PTIPO       => 'varchar2',
                       PCONTROLE   => 'text',
                       PMANDATORIO => 'N',
                       PDEFAULT    => NULL,
                       PMASCARA    => NULL,
                       PVALORES    => NULL,
                       PAPRESENTA  => NULL,
                       PHABILITA   => NULL);


    --:10
    LIB_PROC.add_param(pstr,
                       'Arquivos no Diret�rio',
                       'Varchar2',
                       'MultiSelect',
                       'N',
                       NULL,
                       NULL,
                       'select x.file_name, x.file_name  from t_aux_files2 x where directory_name = :4'
                       );
                       
    -- :11
    LIB_PROC.ADD_PARAM(PPARAM      => PSTR,
                       PTITULO     => '',
                       PTIPO       => 'varchar2',
                       PCONTROLE   => 'text',
                       PMANDATORIO => 'N',
                       PDEFAULT    => NULL,
                       PMASCARA    => NULL,
                       PVALORES    => NULL,
                       PAPRESENTA  => NULL,
                       PHABILITA   => NULL);
                       
    -- :12
    LIB_PROC.ADD_PARAM(PPARAM      => PSTR,
                       PTITULO     => 'Utilizar saldo antes do encerramento',
                       PTIPO       => 'varchar2',
                       PCONTROLE   => 'checkbox',
                       PMANDATORIO => 'N',
                       PDEFAULT    => 'N',
                       PMASCARA    => NULL,
                       PVALORES    => NULL,
                       PAPRESENTA  => 'S',
                       PHABILITA   => 'S');
                       
    -- :13
    LIB_PROC.ADD_PARAM(PPARAM      => PSTR,
                       PTITULO     => 'Contas Cont�beis',
                       PTIPO       => 'varchar2',
                       PCONTROLE   => 'textbox',
                       PMANDATORIO => 'S',
                       PDEFAULT    => 'Digite as contas separadas por v�rgula',
                       PMASCARA    => NULL,
                       PVALORES    => NULL,
                       PAPRESENTA  => 'S',
                       PHABILITA   => ':12 = ''S''');

-- 001 Fim

    RETURN pstr;
  END;

  FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN '1.0 - Carga dos Saldos via arquivos TXT - ECD';
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
    RETURN '1.0 - Carga dos Saldos via arquivos TXT - ECD';
  END;

  FUNCTION Modulo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Bloco K - ECD';
  END;

  FUNCTION Classificacao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Bloco K - ECD';
  END;


  FUNCTION Executar(pRegistro         VARCHAR2, -- 1= I155 + I355, 2= K300
                    pDirectory        Varchar2,
                    pFiles            lib_proc.varTab,
                    pNUtilEnc         varchar2,
                    pContaX02         varchar2
                    ) RETURN INTEGER IS

    -- Variaveis de Trabalho */
    mproc_id          INTEGER;
    vn_rel            number:=1;
    vs_nome_interface varchar2(300);
    vs_nome_rel       varchar2(3000);
    vs_processo       varchar2(100);
    vs_msg            varchar2(200):=null;

    --v_finalizar       number := 0;

    --Status_w         INTEGER;
    --RazaoEst_w       ESTABELECIMENTO.RAZAO_SOCIAL%TYPE;
    --CGC_w            ESTABELECIMENTO.CGC%TYPE;
    linha_log       varchar2(100);

    --Finalizar EXCEPTION;
    
    vs_ind_saldo_fim varchar2(1);
    vs_saldo_fim     varchar2(19);


  BEGIN


      BEGIN

            mproc_id := LIB_PROC.new('MSAF_LOAD_FILE_ECD_CPROC');
            LIB_PROC.add_log('Log gerado', 1);
        --    Mcod_Empresa := Pcod_empresa; --Lib_Parametros.Recuperar('EMPRESA');


    /**************************************************
     Inclui Header/Footer do Log de Erros            
    **************************************************/
    linha_log := 'Log de Processo: '||mproc_id;
    lib_proc.Add_Log('.                                                                                                        '||linha_log, 0);


    lib_proc.Add_Log(rpad('-', 200, '-'), 0);
    lib_proc.Add_Log(' ', 0);

    /**************************************************************
     Valida��o de datas inicial e final informadas com par�metro 
    **************************************************************/

--    end if;
    LIB_PROC.add_tipo(mproc_id, vn_rel, 'ECD_BLOCOK', 3,48,150, '8', 'Relatorio');

    vs_nome_rel := 'Bloco K - ECD';
    vs_nome_interface := 'Importa��o de Saldos do arquivo ECD';


             LIB_PROC.add_log('PARAMETRO INCLUIDO COM SUCESSO', 1);

            -- ### RELATORIO - HTML
             vs_processo       := pDirectory;

             cabecalho(vs_nome_rel
                             ,vn_rel
                             ,vs_processo
                             ,vs_nome_interface
                             );

                MONTA_LINHA('<tr>',vn_rel);
                MONTA_LINHA('<td colspan="2" rowspan="1"',vn_rel);
                MONTA_LINHA('style="vertical-align: top; font-weight: bold; text-align: center; color: #85929E; font-size: 16px;"> '||vs_msg || '<br>',vn_rel);
                MONTA_LINHA('</td>',vn_rel);

                begin
                  execute immediate 'truncate table treg_plano_contas_ecd';
                  exception
                    when others then
                      lib_proc.add_log('Falha ao truncar tabela treg_plano_contas_ecd: '||SQLERRM,1);
                end;

              for i IN pFiles.FIRST..pFiles.LAST loop
                 -- chamar procedure
                 PRC_LOAD_TXT_ECD(pDirectory, pFiles(i), v_qtde_reg, pRegistro);
                 
                 --utilizar saldo ecd ?
                 if
                   pNUtilEnc = 'S' THEN 
                    FOR CONTAS IN (SELECT REGEXP_SUBSTR(STR, EXP, 1, LEVEL) ITEM
                                            FROM (SELECT pContaX02 STR, '[^,]+' EXP FROM DUAL)
                                          CONNECT BY REGEXP_SUBSTR(STR, EXP, 1, LEVEL) IS NOT NULL)
                      LOOP


                      begin
                      
                        select d.ind_dc_fim
                               , d.vlr_saldo_fim
                               into
                               vs_ind_saldo_fim
                               , vs_saldo_fim
                             
                             from treg_saldo_ecd d
                             where 1=1
                             and   d.cod_conta = contas.item
                             and   upper(d.arquivo) = upper(pFiles(i))
                             and   nvl(trim(d.registro),'x') = 'I355';
                      
                        exception
                          when others then
                            --lib_proc.add_log('Erro ao buscar saldo I355, motivo: '||sqlerrm||' - '||dbms_utility.format_error_backtrace,1);
                            lib_proc.add_log('Erro ao localizar saldo no I355 para a conta cont�bil: '||contas.item,1);
                            --lib_proc.add_log('Arquivo da ECD: '||upper(pFiles(i)),1);
                            lib_proc.add_log('',1);
                      end;
                      
                      update treg_saldo_ecd x
                             set x.ind_dc_fim = vs_ind_saldo_fim
                                 , x.vlr_saldo_fim = vs_saldo_fim
                             where 1=1
                             and   x.cod_conta = contas.item
                             and   upper(x.arquivo) = upper(pFiles(i))
                             and   nvl(trim(x.registro),'x') <> 'I355'
                             and   to_char(to_date(x.periodo),'mm') = '12';
                    END LOOP;
                      
                END IF;

                 dados_relatorio(pFiles(i), v_qtde_reg, vn_rel);

                 LIB_PROC.add_log('Arquivo: ' || pFiles(i) || ' -  Qtde Registros: ' || v_qtde_reg, 1);

              end loop;
              commit;

              final_html(vn_rel);


              -- processo de inser��o na tabela X2002

              -- recuperacao do grupo de cadastros e data do plano de contas
              BEGIN

              -- grupo x2002
              saf_pega_grupo(P_CD_EMPR       => mcod_empresa,
                             P_CD_ESTAB      => mcod_estab,
                             P_CD_TABELA     => '2002',
                             P_VALID_INICIAL => ADD_MONTHS(TRUNC (SYSDATE, 'YEAR'), -1 ) +30,  -- recupera o grupo de cadastro referente ano anterior
                             P_GRUPO         => v_grupo);

              -- data do grupo x2002
              SELECT       valid_inicial
                     INTO  v_data_grupo
                     FROM  relac_tab_grupo
              WHERE  1=1
              AND    cod_empresa = mcod_empresa
              AND    cod_estab   = mcod_estab
              AND    cod_tabela  = '2002'
              AND    grupo_estab = v_grupo;

               EXCEPTION WHEN
                 OTHERS THEN
                  lib_proc.add_log('Erro ao recuperar grupo de cadastro do plano de contas: '||dbms_utility.format_error_backtrace||' - '||SQLERRM,1);
                  lib_proc.add_log(mcod_empresa||'-'|| mcod_estab ||'-'|| v_grupo,1);
              END;

              for reg2 in (select distinct b.cod_conta, b.descricao
                            from treg_saldo_ecd a, treg_plano_contas_ecd b
                           where 1 = 1
                             and a.cnpj = b.empresa
                             and a.periodo = ADD_MONTHS(TRUNC (SYSDATE, 'YEAR'), -1 ) +30 -- saldo final do ano anterior
                             and b.tipo = 'A'
                             and a.cod_conta = b.cod_conta
                             and a.cod_conta not in (select x.cod_conta
                                                      from  x2002_plano_contas x
                                                      WHERE x.grupo_conta = v_grupo)

                           ) loop

                 v_achou := 0;

                 begin
                   select 1
                     into v_achou
                    from x2002_plano_contas x
                     where 1=1
                       and x.cod_conta = reg2.cod_conta
                       AND x.grupo_conta = v_grupo
                       and rownum = 1;
                exception
                  when no_data_found then
                    v_achou := 0;
                end;


                -- Se n�o encontrou na tabela X2002, faz o processo de inser��o
                if v_achou = 0 then

                   /*begin
                     select max(ident_conta)+ 1
                      into id_x2002
                     from x2002_plano_contas;
                  exception
                    when others then
                      id_x2002 := null;
                   end;
                   */
                   saf_pega_ident('X2002_PLANO_CONTAS','IDENT_CONTA',id_x2002);

                   t_x2002.ident_conta  := id_x2002;
                   t_x2002.grupo_conta  := v_grupo;
                   t_x2002.cod_conta    := reg2.cod_conta;
                   t_x2002.valid_conta  := to_date(v_data_grupo, 'dd/mm/rrrr');
                   t_x2002.descricao    := substr(reg2.descricao, 1, 50);
                   t_x2002.ind_conta    := 'A';
                   t_x2002.ind_situacao := 'A';
                   t_x2002.ind_conta_consolid := 'S';
                   t_x2002.desc_detalhada := 'Inserida pela importa��o do Processo Customizado - Bloco K';


                   -- inserindo na X2002
                   begin
                     insert into x2002_plano_contas values t_x2002;
                   exception
                     when others then
                       LIB_PROC.add_log('N�o foi poss�vel inserir a conta ' || t_x2002.cod_conta || ' - ' || sqlerrm, 0);
                  end;

                  -- j� faz o commit para n�o prejudicar a busca das contas existentes
                  if sql%rowcount > 0 then
                     commit;
                  end if;
                end if;

             end loop;


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
                   ,vn_diretorio           varchar2
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
    MONTA_LINHA('<td colspan="2" rowspan="1"',vn_rel);
    MONTA_LINHA('style="vertical-align: top; "><big><big>'||ps_nome_rel||'</big></big> </td>',vn_rel);
    MONTA_LINHA('</tr>',vn_rel);

    MONTA_LINHA('<tr align="center">',vn_rel);
    MONTA_LINHA('<td colspan="2" rowspan="1"',vn_rel);
    MONTA_LINHA('style="vertical-align: top; "><big><big><span',vn_rel);
    MONTA_LINHA('style="font-weight: bold;font-size: 20px;">'||vs_nome_interface||'</span></big></big><br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);
    MONTA_LINHA('</tr>',vn_rel);

    MONTA_LINHA('<tr>',vn_rel);
    MONTA_LINHA('<td colspan="2" rowspan="1"',vn_rel);
    MONTA_LINHA('style="vertical-align: top; "><br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);
    MONTA_LINHA('</tr>',vn_rel);


    MONTA_LINHA('<tr>',vn_rel);
    MONTA_LINHA('<td colspan="2" rowspan="1"',vn_rel);
    MONTA_LINHA('style="vertical-align: top; width: 400px; font-weight: bold; color: green; font-size: 15px;">Diret�rio: '||vn_diretorio||'<br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);

    MONTA_LINHA('</tr>',vn_rel);

    -- inicia bloco tr
    MONTA_LINHA('<tr>',vn_rel);


    MONTA_LINHA('<td',vn_rel);
    MONTA_LINHA('style="vertical-align: top; width: 400px; background-color: #0088ff; font-weight: bold; text-align: center;">Arquivos Importados<br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);

    MONTA_LINHA('<td',vn_rel);
    MONTA_LINHA('style="vertical-align: top; width: 100px; background-color: #0088ff; font-weight: bold; text-align: center;">Registros <br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);


    MONTA_LINHA('</tr>',vn_rel);

  end;


procedure dados_relatorio (vs_arquivo     varchar2
                          ,vs_qtde_reg    varchar2
                          ,vn_rel             number) is

begin


--#######################################


    MONTA_LINHA('<tr>',vn_rel);

    MONTA_LINHA('<td style="vertical-align: top; width: 300px; text-align: left; font-weight: bold; font-size: 13px;">'||vs_arquivo||'<br>',vn_rel);
    MONTA_LINHA('</td>',vn_rel);

    MONTA_LINHA('<td style="vertical-align: top; width: 100px; text-align: center; font-weight: bold; font-size: 13px;">'||vs_qtde_reg||'<br>',vn_rel);
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

END MSAF_LOAD_FILE_ECD_CPROC;
/
