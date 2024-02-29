create or replace package CONF_NF_ENTR_CPROC is

	/* Declara��o de Vari�veis P�blicas */
  w_cod_emp            estabelecimento.cod_empresa%type;
  w_cod_estab          estabelecimento.cod_estab%type;
  w_razao              estabelecimento.razao_social%type;
  w_usuario            varchar2(20);

	/* VARI�VEIS DE CONTROLE DE CABE�ALHO DE RELAT�RIO */
	function parametros return varchar2;

	function nome return varchar2;

	function tipo return varchar2;

	function versao return varchar2;

	function descricao return varchar2;

	function modulo return varchar2;

	function classificacao return varchar2;

	FUNCTION Executar( P_COD_ESTAB VARCHAR2,
                    P_PERIODO_INI DATE,
                    P_PERIODO_FIM DATE,
                    P_TIPO_REL VARCHAR2,
                    P_COD_GRP_INCENT VARCHAR2) RETURN INTEGER;

end CONF_NF_ENTR_CPROC;
 
 
/
CREATE OR REPLACE PACKAGE BODY CONF_NF_ENTR_CPROC is

	mcod_empresa empresa.cod_empresa%TYPE;

  ----------------------------------------------------------------------------------------------------

	FUNCTION Parametros RETURN VARCHAR2 IS pstr VARCHAR2(5000);
    vValores varchar2(512);
	BEGIN

    vValores     := ' SELECT estab.cod_estab, razao_social ' ||
                    ' FROM estabelecimento estab, estado uf, ict_par_incent ict ' ||
                    ' WHERE estab.ident_estado = uf.ident_estado ' ||
                    ' AND estab.cod_empresa = ict.cod_empresa '||
                    ' AND estab.cod_estab = ict.cod_estab ' ||
                    ' AND estab.cod_empresa = ''' || mcod_empresa || ''' AND uf.cod_estado = ''PE'' ' ||
                    ' ORDER BY 1';

 -- :1
		LIB_PROC.add_param(pstr
                  , 'Estabelecimento:'
                  , 'Varchar2'
                  , 'Textbox'
                  , 'S'
                  , null
                  , '      '
                  , vValores
                  , 'S') ;

 -- :2
		LIB_PROC.add_param(pstr
                   , 'Data Inicial:'
                   , 'Date'
                   , 'Textbox'
                   , 'S'
                   , to_date('01'||TO_CHAR(SYSDATE,'MM/YYYY'),'dd/mm/yyyy')
                   , 'DD/MM/YYYY'
                   , null
                   , 'S') ;

 -- :3
		LIB_PROC.add_param(pstr
                  , 'Data Final:'
                  , 'Date'
                  , 'Textbox'
                  , 'S'
                  ,  LAST_DAY(SYSDATE)
                  , 'DD/MM/YYYY'
                  , null
                  ,'S') ;

 -- :4
  lib_proc.add_param(pstr
                  , 'Tipo de Livro'
                  , 'Varchar2'
                  , 'RadioButton'
                  , 'S'
                  , 1
                  , NULL
                  , '1=Incentivados,2=N�o Incentivado');

    vValores     := ' SELECT cod_grp_incent,cod_grp_incent || '' - '' || dsc_grp_incent '  ||
                    ' FROM ict_grp_incent '   ||
                    ' WHERE cod_empresa = ''' || mcod_empresa || ''' AND cod_estab = :1 ' ||
                    ' ORDER BY 1 ';

 -- :5
 		LIB_PROC.add_param(pstr
                   , 'Grupo de Incentivo: '
                   , 'Varchar2'
                   , 'Combobox'
                   , 'N'
                   , NULL
                   , NULL
                   , vValores
                   , 'S'
                   ,phabilita => ':4 NOT IN (2)');

		RETURN pstr;

	END;
  ----------------------------------------------------------------------------------------------------
	FUNCTION Nome RETURN VARCHAR2 IS
	BEGIN
		RETURN 'Relat�rio de Confer�ncia das Notas Fiscais de Entrada';
	END;
  ----------------------------------------------------------------------------------------------------
	FUNCTION Tipo RETURN VARCHAR2 IS
	BEGIN
		RETURN 'Relat�rio';
	END;
  ----------------------------------------------------------------------------------------------------
	FUNCTION Versao RETURN VARCHAR2 IS
	BEGIN
		RETURN '1.0';
	END;
  ----------------------------------------------------------------------------------------------------
	FUNCTION Descricao RETURN VARCHAR2 IS
	BEGIN
		RETURN 'Relat�rio de Confer�ncia das Notas Fiscais de Entrada';
	END;
  ----------------------------------------------------------------------------------------------------
	FUNCTION Modulo RETURN VARCHAR2 IS
	BEGIN
		RETURN 'PRODEPE';
	END;
  ----------------------------------------------------------------------------------------------------
	FUNCTION Classificacao RETURN VARCHAR2 IS
	BEGIN
		RETURN 'ESTADUAL - PRODEPE';
	END;
  ----------------------------------------------------------------------------------------------------
	FUNCTION Executar( P_COD_ESTAB      VARCHAR2,
                    P_PERIODO_INI    DATE,
                    P_PERIODO_FIM    DATE,
                    P_TIPO_REL       VARCHAR2,
                    P_COD_GRP_INCENT VARCHAR2) RETURN INTEGER IS
    /* cursores */

    cursor cNotas (P_COD_EMPRESA VARCHAR2, P_COD_ESTAB VARCHAR2, P_COD_GRP_INCENT VARCHAR2, P_DATA_INI DATE, P_DATA_FIM DATE) is
    -- Documentos com itens
    SELECT     guia.cod_grp_incent,
               docto.data_fiscal,
               docto.serie_docfis,
               docto.sub_serie_docfis,
               docto.num_docfis,
               to_char(item.num_item) item,
               cfo.cod_cfo,
               nat.cod_natureza_op,
               prod.descricao produto,
               pfj.razao_social emitente,
               item.vlr_contab_item  vlr_contab_item,
               item.vlr_tributo_icms vlr_tributo_icms,
               item.vlr_fecp_icms    vlr_fecp_icms,
               guia.ind_incent
        FROM dwt_docto_fiscal docto,
             dwt_itens_merc item,
             ict_guia_incent guia,
             x2012_cod_fiscal cfo,
             x2006_natureza_op nat,
             x2013_produto prod,
             x04_pessoa_fis_jur pfj

        WHERE docto.cod_empresa = P_COD_EMPRESA
          AND docto.cod_estab = P_COD_ESTAB
          AND docto.data_fiscal between P_DATA_INI and P_DATA_FIM
          AND docto.cod_class_doc_fis in ('1','3')
          AND docto.movto_e_s <> '9'
          AND docto.situacao <> 'S'
          AND docto.ind_transf_cred = '0'
          AND nvl(docto.ind_situacao_esp,' ') not in ('1','2','8')

          AND item.ident_docto_fiscal = docto.ident_docto_fiscal

          AND cfo.ident_cfo(+) = item.ident_cfo

          AND nat.ident_natureza_op(+) = item.ident_natureza_op

          AND prod.ident_produto = item.ident_produto

          AND pfj.ident_fis_jur = docto.ident_fis_jur

          AND guia.cod_empresa(+)          = P_COD_EMPRESA
          AND guia.cod_estab(+)            = P_COD_ESTAB
          AND guia.ident_docto_fiscal(+)   = item.ident_docto_fiscal
          AND guia.ident_itens_merc(+)     = item.ident_item_merc
          AND (( guia.cod_grp_incent IS NULL AND P_COD_GRP_INCENT IS NULL) OR
                  (guia.cod_grp_incent = P_COD_GRP_INCENT))




    UNION ALL
    -- Documentos sem itens
    SELECT     guia.cod_grp_incent,  -- 1
               docto.data_fiscal,    -- 2
               docto.serie_docfis,   -- 3
               docto.sub_serie_docfis,  -- 4
               docto.num_docfis,     -- 5
               's/item' item,        -- 6
               cfo.cod_cfo,
               nat.cod_natureza_op,
               ' ' produto,
               pfj.razao_social emitente,
               docto.vlr_tot_nota  vlr_contab_item, -- 10
               docto.vlr_tributo_icms vlr_tributo_icms, -- 11
               0    vlr_fecp_icms,
               guia.ind_incent
        FROM dwt_docto_fiscal docto,
             ict_guia_incent guia,
             x2012_cod_fiscal cfo,
             x2006_natureza_op nat,
             x04_pessoa_fis_jur pfj
        WHERE docto.cod_empresa = P_COD_EMPRESA
          AND docto.cod_estab = P_COD_ESTAB
          AND docto.data_fiscal between P_DATA_INI and P_DATA_FIM
          AND docto.cod_class_doc_fis in ('1','3')
          AND docto.movto_e_s <> '9'
          AND docto.situacao <> 'S'
          AND docto.ind_transf_cred = '0'
          AND nvl(docto.ind_situacao_esp,' ') not in ('1','2','8')

          AND cfo.ident_cfo(+) = docto.ident_cfo

          AND nat.ident_natureza_op(+) = docto.ident_natureza_op

          AND pfj.ident_fis_jur = docto.ident_fis_jur

          AND guia.cod_empresa(+)          = P_COD_EMPRESA
          AND guia.cod_estab(+)            = P_COD_ESTAB
          AND guia.ident_docto_fiscal(+)   = docto.ident_docto_fiscal
          AND (( guia.cod_grp_incent IS NULL AND P_COD_GRP_INCENT IS NULL) OR
                  (guia.cod_grp_incent = P_COD_GRP_INCENT))


          AND not exists (select 1 from dwt_itens_merc it
                          where  it.ident_docto_fiscal = docto.ident_docto_fiscal )


          ORDER BY 1,2,5,3,4,6;

    rNotas cNotas%ROWTYPE;

    /* Vari�veis locais  */

    vStatus   INTEGER;
    vRazao_social_est  estabelecimento.razao_social%TYPE;
    vProc_id             NUMBER;

    vTotVlr_contab_item_incent   NUMBER;
    vTotVlr_tributo_icms_incent  NUMBER;
    vTotVlr_fecp_icms_incent     NUMBER;
    vTotVlr_contab_item_nincent  NUMBER;
    vTotVlr_tributo_icms_nincent NUMBER;
    vTotVlr_fecp_icms_nincent    NUMBER;


    vFimNotas            BOOLEAN;
    vCod_grp_incent      ict_grp_incent.cod_grp_incent%TYPE;
    vDsc_grp_incent      ict_grp_incent.dsc_grp_incent%TYPE;

    vTitRel              VARCHAR2(170);

    /* Subrotinas */

    FUNCTION CENTRA(pDado IN VARCHAR2, pTamCol IN INTEGER) RETURN VARCHAR2 IS
      vEsqDir  Integer;  -- Espa�o entre as margens das colunas
      vTamDado Integer; -- Tamanho do campo
      vDado    Varchar2(170);
      dif      Integer := 0;
    BEGIN
       vTamDado := LENGTH(pDado);

       If vTamDado > pTamCol Then
          vDado := substr(pDado, 1,pTamCol);
       Else
          vEsqDir := trunc((pTamCol - vTamDado) / 2) ;
          vDado := rpad(' ', vEsqDir, ' ') || pDado || rpad(' ', vEsqDir, ' ');
       End If;

       dif :=  pTamCol - length(vDado);

       If dif > 0 Then
          vDado := vDado || rpad(' ',dif,' ');
       End If;
       RETURN vDado;
    END;

    -----------------------

    PROCEDURE HeaderGrupo IS
      vLinha1 VARCHAR2(170);
      vLinha2 VARCHAR2(170);

    BEGIN

      If P_TIPO_REL = 1 Then -- Livros Incentivados
         vTitRel :=  'Confer�ncia das Notas Fiscais de Entrada - Grupo de Incentivo: '||vCod_grp_incent;
         vLinha1  := '  Data    '||'|'||'      N.           '|| '|' || ' Item  '|| '|' || centra('Emitente',18)|| '|' ||  'CFOP' || '|' ||  'Nat'|| '|' || centra('Produto',20) || '|' ||  ' Valor          ' || '|' ||  ' ICMS           ' || '|' ||  ' ICMS           ' || '|' ||  ' Incentivo ';
         vLinha2  := '  Fiscal  '||'|'||'      Docto        '|| '|' || '       '|| '|' || rpad(' ',18,' ')     || '|' ||  '    ' || '|' ||  'Op '|| '|' || rpad(' ',20,' ')     || '|' ||  ' Cont�bil       ' || '|' ||   rpad(' ',16,' ')  || '|' ||  ' FECP           ' || '|' ||  '           ';

      Else -- Livro n�o incentivado
         vTitRel :=  'Confer�ncia das Notas Fiscais de Entrada - Livro N�o Incentivado';
         vLinha1  := '  Data    '||'|'||'      N.           '|| '|' || ' Item  '|| '|' || centra('Emitente',18)|| '|' ||  'CFOP' || '|' ||  'Nat'|| '|' || centra('Produto',20) || '|' ||  ' Valor          ' || '|' ||  ' ICMS           ' || '|' ||  ' ICMS           ';
         vLinha2  := '  Fiscal  '||'|'||'      Docto        '|| '|' || '       '|| '|' || rpad(' ',18,' ')     || '|' ||  '    ' || '|' ||  'Op '|| '|' || rpad(' ',20,' ')     || '|' ||  ' Cont�bil       ' || '|' ||   rpad(' ',16,' ')  || '|' ||  ' FECP           ';
      End If;

      LIB_PROC.add(centra(vTitRel,170));
      LIB_PROC.add(' ');
      LIB_PROC.add(centra('Estabelecimento: ' || vRazao_social_est,170));
      LIB_PROC.add(centra('Per�odo: ' || to_char(P_PERIODO_INI,'DD/MM/YYYY') || ' a ' || to_char(P_PERIODO_FIM,'DD/MM/YYYY'),170));
      LIB_PROC.add(LPAD('-',170,'-'));

      LIB_PROC.add(vLinha1);
      LIB_PROC.add(vLinha2);
      LIB_PROC.add(LPAD('-',170,'-'));

    END HeaderGrupo;

    -----------------------

    PROCEDURE Grava_e_Verifica (pTexto VARCHAR2) IS
    BEGIN
      lib_proc.add (pTexto);
      -- Se houve mudan�a de p�gina, coloca o header do grupo
      IF lib_proc.get_currentrow(1) = 1 THEN
        HeaderGrupo;
      END IF;
    END Grava_e_Verifica;

    -----------------------

    PROCEDURE Grava_e_Acumula( reg cNotas%ROWTYPE
                             , pTotVlr_contab_item_incent   IN OUT NUMBER
                             , pTotVlr_tributo_icms_incent  IN OUT NUMBER
                             , pTotVlr_fecp_icms_incent     IN OUT NUMBER
                             , pTotVlr_contab_item_nincent  IN OUT NUMBER
                             , pTotVlr_tributo_icms_nincent IN OUT NUMBER
                             , pTotVlr_fecp_icms_nincent    IN OUT NUMBER
                             , P_TIPO_REL VARCHAR2) IS
      vLinha lib_proc_saida.texto%type;
      vDoc_fis varchar2(19);
      vVlr_Fecp_Icms dwt_itens_merc.Vlr_Fecp_Icms%type;

    BEGIN

       select reg.Num_docfis
              || decode (ltrim(reg.Serie_docfis) , null, null, '/' || reg.Serie_docfis)
              || decode (ltrim(reg.Sub_serie_docfis) , null, null, '/' || reg.Sub_serie_docfis)
       into vDoc_fis
       from dual;

       select decode(reg.Vlr_Fecp_Icms,0,null,reg.Vlr_Fecp_Icms)
       into   vVlr_Fecp_Icms
       from   dual;


       If p_tipo_rel = 1 Then -- Livros Incentivados
          vLinha := RPAD (to_char(reg.data_fiscal,'dd/mm/yyyy')     ,10) || '|' ||
                    LPAD (vDoc_fis                                  ,19) || '|' ||
                    LPAD (reg.item                                  , 7) || '|' ||
                    RPAD (reg.emitente                              ,18) || '|' ||
                    LPAD (nvl(reg.cod_cfo,' ')                      , 4) || '|' ||
                    LPAD (nvl(reg.cod_natureza_op,' ')              , 3) || '|' ||
                    RPAD (reg.produto                               ,20) || '|' ||
                    LPAD (TO_CHAR(reg.Vlr_contab_item ,'9g999g999g990d99','NLS_NUMERIC_CHARACTERS='',.'' '),16) || '|' ||
                    LPAD (TO_CHAR(reg.Vlr_tributo_icms,'9g999g999g990d99','NLS_NUMERIC_CHARACTERS='',.'' '),16) || '|' ||
                    LPAD (nvl(TO_CHAR(vVlr_Fecp_Icms  ,'9g999g999g990d99','NLS_NUMERIC_CHARACTERS='',.'' '),' '),16) || '| ' ||
                    RPAD (centra(reg.ind_incent,3)                            , 3);
       ELSE -- Livro N�o Incentivado
          vLinha := RPAD (to_char(reg.data_fiscal,'dd/mm/yyyy')     ,10) || '|' ||
                    LPAD (vDoc_fis                                  ,19) || '|' ||
                    LPAD (reg.item                                  , 7) || '|' ||
                    RPAD (reg.emitente                              ,18) || '|' ||
                    LPAD (nvl(reg.cod_cfo,' ')                      , 4) || '|' ||
                    LPAD (nvl(reg.cod_natureza_op,' ')              , 3) || '|' ||
                    RPAD (reg.produto                               ,20) || '|' ||
                    LPAD (TO_CHAR(reg.Vlr_contab_item ,'9g999g999g990d99','NLS_NUMERIC_CHARACTERS='',.'' '),16) || '|' ||
                    LPAD (TO_CHAR(reg.Vlr_tributo_icms,'9g999g999g990d99','NLS_NUMERIC_CHARACTERS='',.'' '),16) || '|' ||
                    LPAD (nvl(TO_CHAR(vVlr_Fecp_Icms   ,'9g999g999g990d99','NLS_NUMERIC_CHARACTERS='',.'' '),' '),16);

       END IF;

       Grava_e_Verifica (vLinha);

       -- acumula valores
       If p_tipo_rel = '1' and reg.ind_incent = 'I' Then
          pTotVlr_contab_item_incent  := pTotVlr_contab_item_incent  + Nvl(reg.Vlr_contab_item,0);
          pTotVlr_tributo_icms_incent := pTotVlr_tributo_icms_incent + Nvl(reg.Vlr_tributo_icms,0);
          pTotVlr_fecp_icms_incent    := pTotVlr_fecp_icms_incent    + Nvl(vVlr_fecp_icms,0);
       Else
          pTotVlr_contab_item_nincent  := pTotVlr_contab_item_nincent  + Nvl(reg.Vlr_contab_item,0);
          pTotVlr_tributo_icms_nincent := pTotVlr_tributo_icms_nincent + Nvl(reg.Vlr_tributo_icms,0);
          pTotVlr_fecp_icms_nincent    := pTotVlr_fecp_icms_nincent    + Nvl(vVlr_fecp_icms,0);
       End If;

    END Grava_e_Acumula;

     -----------------------

     PROCEDURE Total (pVlr_contab_item_incent NUMBER
                       , pVlr_tributo_icms_incent NUMBER
                       , pVlr_fecp_icms_incent NUMBER
                       , pVlr_contab_item_nincent NUMBER
                       , pVlr_tributo_icms_nincent NUMBER
                       , pVlr_fecp_icms_nincent NUMBER) IS
     BEGIN

       Grava_e_Verifica((LPAD('-',170,'-')));

       If p_tipo_rel = 1 Then

          Grava_e_Verifica( '   Total das Opera��es com Incentivo  ' ||    rpad(' ',49,' ') ||'|' ||
                        LPAD(TO_CHAR(pVlr_contab_item_incent ,'9g999g999g990d99','NLS_NUMERIC_CHARACTERS='',.'' '),16) || '|' ||
                        LPAD(TO_CHAR(pVlr_tributo_icms_incent,'9g999g999g990d99','NLS_NUMERIC_CHARACTERS='',.'' '),16) || '|' ||
                        LPAD(TO_CHAR(pVlr_fecp_icms_incent   ,'9g999g999g990d99','NLS_NUMERIC_CHARACTERS='',.'' '),16)|| '|');

          Grava_e_Verifica( '   Total das Opera��es sem Incentivo  ' ||    rpad(' ',49,' ') ||'|' ||
                        LPAD(TO_CHAR(pVlr_contab_item_nincent ,'9g999g999g990d99','NLS_NUMERIC_CHARACTERS='',.'' '),16) || '|' ||
                        LPAD(TO_CHAR(pVlr_tributo_icms_nincent,'9g999g999g990d99','NLS_NUMERIC_CHARACTERS='',.'' '),16) || '|' ||
                        LPAD(TO_CHAR(pVlr_fecp_icms_nincent   ,'9g999g999g990d99','NLS_NUMERIC_CHARACTERS='',.'' '),16)|| '|');

          Grava_e_Verifica((LPAD('-',170,'-')));

          Grava_e_Verifica( '   Total Geral                        ' ||    rpad(' ',49,' ') ||'|' ||
                        LPAD(TO_CHAR(pVlr_contab_item_incent + pVlr_contab_item_nincent ,'9g999g999g990d99','NLS_NUMERIC_CHARACTERS='',.'' '),16) || '|' ||
                        LPAD(TO_CHAR(pVlr_tributo_icms_incent + pVlr_tributo_icms_nincent,'9g999g999g990d99','NLS_NUMERIC_CHARACTERS='',.'' '),16) || '|' ||
                        LPAD(TO_CHAR(pVlr_fecp_icms_incent + pVlr_fecp_icms_nincent   ,'9g999g999g990d99','NLS_NUMERIC_CHARACTERS='',.'' '),16)|| '|' );

       Else

          Grava_e_Verifica( '   Total Geral                        ' ||    rpad(' ',49,' ') ||'|' ||
                        LPAD(TO_CHAR(pVlr_contab_item_nincent ,'9g999g999g990d99','NLS_NUMERIC_CHARACTERS='',.'' '),16) || '|' ||
                        LPAD(TO_CHAR(pVlr_tributo_icms_nincent,'9g999g999g990d99','NLS_NUMERIC_CHARACTERS='',.'' '),16) || '|' ||
                        LPAD(TO_CHAR(pVlr_fecp_icms_nincent   ,'9g999g999g990d99','NLS_NUMERIC_CHARACTERS='',.'' '),16));

       End If;
     END Total;

  ----------------------- CORPO DA PROCEDURE EXECUTA  ------------------------------------------------------

  BEGIN

    vStatus := 0;

    -- Cria N�mero de Processo Novo
    vProc_id     := lib_proc.new('CONF_NF_ENTR_CPROC',48, 170);

    -- recupera a descri��o do estabelecimento

    BEGIN
      SELECT RAZAO_SOCIAL
      INTO vRazao_social_est
      FROM ESTABELECIMENTO
      WHERE COD_EMPRESA = mcod_empresa
        AND COD_ESTAB = P_COD_ESTAB;
    EXCEPTION
      WHEN OTHERS THEN
        vRazao_social_est := NULL;
    END;

    -- Inclui Header/Footer do Log de Processo
    lib_proc.Add_Log(LPAD('-',170,'-'),0);
    lib_proc.Add_Log(vRazao_social_est, 0);
    lib_proc.Add_Log('Relat�rio de Confer�ncia das Notas Fiscais de Entrada',0);
    lib_proc.Add_Log('Data : ' || TO_CHAR(SYSDATE),0);
    lib_proc.Add_Log(LPAD('-',170,'-'),0);
    lib_proc.Add_Log(' ', 0);
    IF mcod_empresa IS NULL THEN
      lib_proc.Add_Log('C�digo da Empresa deve ser informado no login.', 0);
      lib_proc.Add_Log(' ', 0);
      lib_proc.CLOSE;
      RETURN vProc_id;
    END IF;

    -- tipo: relatorio
    LIB_PROC.add_tipo(vProc_id, 1, 'Confer�ncia das Notas de Entrada', 1,48,170);



    OPEN cNotas (mcod_empresa, P_COD_ESTAB, P_COD_GRP_INCENT , P_PERIODO_INI, P_PERIODO_FIM);
    FETCH cNotas INTO rNotas;
    vFimNotas := cNotas%NOTFOUND;

    IF vFimNotas THEN
      lib_proc.add_log('Aviso - N�o existe movimento para o per�odo','1');
      vStatus := 1;
    END IF;

    -- para cada nota
    WHILE not vFimNotas LOOP

      -- para cada grupo de incentivo
      vCod_grp_incent := rNotas.cod_grp_incent;

     -- Inicializa vari�veis
     vTotVlr_contab_item_incent   := 0;
     vTotVlr_tributo_icms_incent  := 0;
     vTotVlr_fecp_icms_incent     := 0;
     vTotVlr_contab_item_nincent  := 0;
     vTotVlr_tributo_icms_nincent := 0;
     vTotVlr_fecp_icms_nincent    := 0;

      -- Recupera a descri��o do grupo
      IF vCod_grp_incent is not null THEN
        BEGIN
          SELECT dsc_grp_incent
            INTO vDsc_grp_incent
            FROM ict_grp_incent
           WHERE cod_empresa = mcod_empresa
             AND cod_estab  = P_COD_ESTAB
             AND cod_grp_incent = vCod_grp_incent;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vDsc_grp_incent := 'Grupo n�o cadastrado';
            lib_proc.add_log('Erro - Grupo de incentivo ' || rNotas.cod_grp_incent || ' n�o cadastrado' ,'1');
            vStatus := -1;
        END;
      END IF;

      -- coloca o header do grupo
      HeaderGrupo;

      WHILE not vFimNotas AND
         Nvl(vCod_grp_incent,' ') = Nvl(rNotas.cod_grp_incent,' ') LOOP

         Grava_e_Acumula(rNotas,vTotVlr_contab_item_incent,vTotVlr_tributo_icms_incent,vTotVlr_fecp_icms_incent,vTotVlr_contab_item_nincent,vTotVlr_tributo_icms_nincent,vTotVlr_fecp_icms_nincent,P_TIPO_REL);


         FETCH cNotas INTO rNotas;
         vFimNotas := cNotas%NOTFOUND;

      END LOOP;  -- Grupo

      -- total do grupo
        Total ( vTotVlr_contab_item_incent
              , vTotVlr_tributo_icms_incent
              , vTotVlr_fecp_icms_incent
              , vTotVlr_contab_item_nincent
              , vTotVlr_tributo_icms_nincent
              , vTotVlr_fecp_icms_nincent);

      -- Quebra a p�gina na mudan�a de grupo
      IF not vFimNotas
      AND lib_proc.get_currentrow(1) <> 1 THEN
        lib_proc.new_page;
      END IF;

    END LOOP; -- notas

    CLOSE cNotas;

    IF vStatus = 0 THEN
      lib_proc.add_log('Relat�rio de Confer�ncia das Notas Fiscais de Entrada finalizado com sucesso.','1');
    ELSIF vStatus = 1 THEN
      lib_proc.add_log('Relat�rio de Confer�ncia das Notas Fiscais de Entrada finalizado com avisos.','1');
    ELSIF vStatus = -1 THEN
      lib_proc.add_log('Relat�rio de Confer�ncia das Notas Fiscais de Entrada finalizado com erros.','1');
    END IF;
  	 lib_proc.CLOSE;
    commit;

    RETURN vProc_id;

  EXCEPTION
    WHEN OTHERS THEN
      lib_proc.add_log('Relat�rio de Confer�ncia das Notas Fiscais de Entrada finalizado com erros:' || SQLERRM,'1');
      lib_proc.CLOSE;
      RETURN vProc_id;
  END;

BEGIN

  mcod_empresa := LIB_PARAMETROS.RECUPERAR('EMPRESA')


END CONF_NF_ENTR_CPROC;
/
