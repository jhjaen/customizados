CREATE OR REPLACE PACKAGE PCK_BRAS_GERA_NF_CPROC IS
-- relatorio para geracao
  FUNCTION Parametros RETURN VARCHAR2;
  FUNCTION Nome RETURN VARCHAR2;
  FUNCTION Tipo RETURN VARCHAR2;
  FUNCTION Descricao RETURN VARCHAR2;
  function versao return varchar2;
  FUNCTION Executar(pCodestab     x07_docto_fiscal.cod_estab%type, --02 Estabelecimento
                    pAno           varchar2, --03 Ano de apura��o
                    pPeriD         char, --04 Periodicidade
                    pPeriodo       char, --05 Per�odo
                    pTipoGear      number,
                    pNumDocFis    x07_docto_fiscal.num_docfis%type,
                    pNumDocFisIni x07_docto_fiscal.num_docfis%type,
                    pNumDocFisFim x07_docto_fiscal.num_docfis%type) RETURN INTEGER;

  -- Procedure de Teste do Modulo pelo PLSql
  PROCEDURE TESTE;
  
  DATA_INI varchar2(10);
  wEmpresa     empresa%rowtype;
  wEstabel     estabelecimento%rowtype;
  wX04         x04_pessoa_fis_jur%rowtype;
  wEstado      estado%rowtype;

  vCol01     number := 5;         --'ESTAB'         
  vCol02     number := 10;        --'COD_FIS_JUR'   
  vCol03     number := 14;        --'CPF/CGC'       
  vCol04     number := 32;         --'RAZ�O SOCIAL'  
  vCol05     number := 10;    --'DATA PGTO TRIB'
  vCol06     number := 9;    --'AUT. PGTO'     
  vCol07     number := 4;    --'C�D. RECEITA'  
  vCol08     number := 14;    --'VALOR INSS'    
  vCol09     number := 14;    --'VALOR TOTAL'   
  vCol010    number := 4;   --'ANO COMP'      
  vCol011    number := 2;   --'MES COMP'      
  vAba       number;
  sep        varchar2(3) := ' | ';
  sep2       varchar2(3) := null;

  
  vAltPagina          number:=80;
  vAltAdd             number:=20;
  vAltLinha           number:=334;
  vAltLinhaPag        number:=vAltLinha;
  vNextPag            number:=1020;  --1728
  
  v_nfNatOperacao     number:=(81-vAltPagina+vAltAdd);
  v_nfViaTransporte   number:=(97-vAltPagina+vAltAdd);
  v_nfDatEmissao      number:=(112-vAltPagina+vAltAdd);
  
  v_razaoSocial       number:=(147-vAltPagina+vAltAdd);
  v_endCliCodFisJur   number:=(147-vAltPagina+vAltAdd);
  v_ElmPEP            number:=(158-vAltPagina+vAltAdd);
  v_OrdVenda          number:=(195-vAltPagina+vAltAdd);
  v_endCliente        number:=(167-vAltPagina+vAltAdd);
  v_endCliCEP         number:=(167-vAltPagina+vAltAdd);
  v_endCliCid         number:=(167-vAltPagina+vAltAdd);
  v_endCliUF          number:=(167-vAltPagina+vAltAdd);
  v_endCliCNPJ        number:=(196-vAltPagina+vAltAdd);
  v_endCliIE          number:=(196-vAltPagina+vAltAdd);
  
  v_dplNum            number:=(255-vAltPagina+vAltAdd);
  v_dplVlr            number:=(255-vAltPagina+vAltAdd);
  v_dplDatVenc        number:=(255-vAltPagina+vAltAdd);
  v_infoDupli         number:=(238-vAltPagina+vAltAdd);
  
  v_itensDesc         number:=(354-vAltPagina+vAltAdd);
  v_itensValor        number:=(354-vAltPagina+vAltAdd);
  --v_itensDesc         number:=(349-vAltPagina+vAltAdd);
  
  v_nfObs             number:=(849-vAltPagina+vAltAdd);
  v_nfVlrTotNota      number:=(850-vAltPagina+vAltAdd);
  v_NumNF2            number:=(965-vAltPagina+vAltAdd);
  v_fimPagina         number:=(0-vAltPagina+vAltAdd);
  
  
  vLinhaEstab  varchar2(1000);
  
  vTab         varchar2(1):=chr(9);
  vText        varchar2(32767);
  vNumLinha    number:=0;
  vCgcCpf      varchar2(25);
  
  vHeader1 varchar2(32767):=
'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>Untitled Document</title>
<style>
* {font-family: "Dotrice Bold", Courier New, Monospace; font-size: 17px; font-weight: bold; }
body             {background-image: url(PCK_BRAS_GERA_NF_CPROC.png); background-repeat: repeat-y; background-position: -20px -10px;}
div              {position: absolute; }
.NumNF1          {left:  767px; width: 77px; text-align: right;}
.ElmPEP			     {left:  748px; width: 106px; text-align:center;}
.OrdVenda	       {left:  748px; width: 106px; text-align:center;}
.infoDupli		   {left:  404px; width: 459px;}
.nfNatOperacao   {left:  503px; width: 235px;}
.nfViaTransporte {left:  503px; width: 235px;}
.nfDatEmissao    {left:  503px; width: 235px;}
.endereco        {left:  564px; width: 444px; padding: 5px;}
.razaoSocial     {left:   86px; width: 498px;}
.endCliente      {left:   86px; width: 321px;}
.endCliCEP       {left:  431px; width:  72px;}
.endCliCid       {left:  541px; width: 138px;}
.endCliUF        {left:  701px; width:  34px;}
.endCliCodFisJur {left:  631px; width: 103px;}
.endCliCNPJ      {left:   86px; width: 335px;}
.endCliIE        {left:  481px; width: 255px;}
.dplVlr          {left:   97px; width: 182px; text-align:center;}
.dplDatVenc      {left:  278px; width: 108px; text-align:center;}
.dplNum          {left:    6px; width: 79px; text-align:center;}
.nfObs           {left:   11px; width: 558px;}
.itensDesc       {left:    6px; width: 712px;}
.itensValor      {left:  719px; width: 132px; text-align: right;}
.nfVlrTotNota    {left:  694px; width: 159px; text-align: right;}
.NumNF2          {left:  748px; width: 115px;}
#div_imp         {left:  815px; top: 1430px;}
</style>
</head>
<body>';

  vBody varchar2(32767);        


  cursor Relat(pEmpresa       empresa.cod_empresa%type,
               pCodestab      estabelecimento.cod_estab%type,
               pDatIni        date,
               pDatFim        date,
               pTipoGear      varchar2,     
               pNumDocFis     x07_docto_fiscal.num_docfis%type,   
               pNumDocFisIni  x07_docto_fiscal.num_docfis%type,
               pNumDocFisFim  x07_docto_fiscal.num_docfis%type) is
      select (select obs_tributo --, c.* 
                from x07_trib_docfis c 
               where c.cod_tributo      = 'IPI'
                 and c.COD_EMPRESA      = a.COD_EMPRESA  
                 and c.COD_ESTAB        = a.COD_ESTAB    
                 and c.DATA_FISCAL      = a.DATA_FISCAL  
                 and c.MOVTO_E_S        = a.MOVTO_E_S    
                 and c.NORM_DEV         = a.NORM_DEV     
                 and c.IDENT_DOCTO      = a.IDENT_DOCTO  
                 and c.IDENT_FIS_JUR    = a.IDENT_FIS_JUR
                 and c.NUM_DOCFIS       = a.NUM_DOCFIS   
                 and c.SERIE_DOCFIS     = a.SERIE_DOCFIS 
                 and c.SUB_SERIE_DOCFIS = a.SUB_SERIE_DOCFIS) obs_tributo,
             nvl((select c.vlr_tributo --, c.* 
                    from x07_trib_docfis c 
                   where c.cod_tributo      = 'IR'
                     and c.COD_EMPRESA      = a.COD_EMPRESA  
                     and c.COD_ESTAB        = a.COD_ESTAB    
                     and c.DATA_FISCAL      = a.DATA_FISCAL  
                     and c.MOVTO_E_S        = a.MOVTO_E_S    
                     and c.NORM_DEV         = a.NORM_DEV     
                     and c.IDENT_DOCTO      = a.IDENT_DOCTO  
                     and c.IDENT_FIS_JUR    = a.IDENT_FIS_JUR
                     and c.NUM_DOCFIS       = a.NUM_DOCFIS   
                     and c.SERIE_DOCFIS     = a.SERIE_DOCFIS 
                     and c.SUB_SERIE_DOCFIS = a.SUB_SERIE_DOCFIS),0) vlr_IR,
             b.cod_natureza_op, a.*
        from x07_docto_fiscal   a, x2006_natureza_op b
       where 1 = 1
         and a.ident_natureza_op = b.ident_natureza_op(+)
         and a.COD_EMPRESA       = pEmpresa
         and a.cod_estab         = pCodestab
         and a.movto_e_s         = '9'
         and a.cod_class_doc_fis = '2'
         and ((pTipoGear = 1)
              or (pTipoGear = 2 and a.num_docfis        = nvl(pNumDocFis,'0'))
              or (pTipoGear = 3 and a.num_docfis between nvl(pNumDocFisIni,'0') and nvl(pNumDocFisFim,'0'))
              )
         --and a.data_fiscal between to_date(p_DataIni,'mm/yyyy') and last_day(to_date(p_DataIni,'mm/yyyy'))
         and a.data_fiscal between pDatIni and pDatFim
       order by a.num_docfis ASC
         ;


  cursor Linha_Relat(p_COD_EMPRESA   x08_itens_merc.cod_empresa%type,
                     p_COD_ESTAB     x08_itens_merc.COD_ESTAB%type,
                     p_DATA_FISCAL   x08_itens_merc.DATA_FISCAL%type,
                     p_MOVTO_E_S     x08_itens_merc.MOVTO_E_S%type,
                     p_NORM_DEV      x08_itens_merc.NORM_DEV%type,
                     p_IDENT_DOCTO   x08_itens_merc.IDENT_DOCTO%type,
                     p_IDENT_FIS_JUR x08_itens_merc.IDENT_FIS_JUR%type,
                     p_NUM_DOCFIS    x08_itens_merc.NUM_DOCFIS%type,
                     p_SERIE_DOCFIS  x08_itens_merc.SERIE_DOCFIS%type) is
    select x09.num_item,
           x2018.cod_servico,
           x2018.descricao,
           vlr_servico,
           grouping(x09.num_item) as grp1,
           sum(nvl(VLR_BASE_ISS_RETIDO,0)) as VLR_BASE_ISS_RETIDO  ,
           sum(nvl(VLR_ISS_RETIDO     ,0)) as VLR_ISS_RETIDO       ,
           sum(nvl(vlr_base_inss      ,0)) as vlr_base_inss        ,
           sum(nvl(VLR_INSS_RETIDO    ,0)) as VLR_INSS_RETIDO      ,
           sum(nvl(VLR_PIS_RETIDO     ,0)) as VLR_PIS_RETIDO       ,
           sum(nvl(VLR_COFINS_RETIDO  ,0)) as VLR_COFINS_RETIDO    ,
           sum(nvl(vlr_csll           ,0)) as vlr_csll
           
      from x09_itens_serv x09, x2018_servicos x2018
     where 1 = 1
       and x2018.ident_servico = x09.ident_servico
          --
       and x09.COD_EMPRESA = '001' --p_COD_EMPRESA
       and x09.cod_estab = p_COD_ESTAB
       and x09.data_fiscal = p_DATA_FISCAL
       and x09.movto_e_s = p_MOVTO_E_S
       and x09.norm_dev = p_NORM_DEV
       and x09.IDENT_DOCTO = p_IDENT_DOCTO
       and x09.IDENT_FIS_JUR = p_IDENT_FIS_JUR
       and x09.NUM_DOCFIS = p_NUM_DOCFIS
       and x09.SERIE_DOCFIS = p_SERIE_DOCFIS
      group by cube((x09.num_item,
                     x2018.cod_servico,
                     x2018.descricao,
                     vlr_servico))
                 ;
         
  -- Variaveis de Cursor
  wRelat Relat%rowtype;
  wLinha_relat Linha_Relat%rowtype;


END PCK_BRAS_GERA_NF_CPROC;
/
CREATE OR REPLACE PACKAGE BODY PCK_BRAS_GERA_NF_CPROC IS

  --MCOD_EMPRESA varchar2(10):= LIB_PARAMETROS.RECUPERAR('EMPRESA');
  --MCOD_ESTAB   varchar2(10):= NVL(LIB_PARAMETROS.RECUPERAR('ESTABELECIMENTO'), '');
  --MUSUARIO     varchar2(10):= LIB_PARAMETROS.RECUPERAR('USUARIO');

  function numFormat(vNumero in number) return varchar2 is
    Result varchar2(100) := '';
  begin
    Result := replace(replace(replace(to_char(nvl(vNumero,0), '9,999,990.99'),'.','*'),',','.'),'*',',');
    return(Result);
  end numFormat;

  function porcFormat(vNumero in number) return varchar2 is
    Result varchar2(100) := '';
  begin
    Result := replace(replace(replace(to_char(vNumero, '90.99'),'.','*'),',','.'),'*',',')|| '% ';
    return(Result);
  end porcFormat;

  function centralizar(pTexto in varchar2, pQtd in number,pPree in varchar2 default '-') return varchar2 is
    Result varchar2(200):='';
  begin
    if mod(pQtd,2) = 0 then
      Result := rpad(lpad(pTexto,trunc(pQtd/2)+trunc(length(pTexto)/2),pPree),pQtd,pPree);
    else
      Result := rpad(lpad(pTexto,trunc(pQtd/2)+1+trunc(length(pTexto)/2),pPree),pQtd,pPree);
    end if;
    return(Result);
  end centralizar;

  FUNCTION Parametros RETURN VARCHAR2 IS
    pstr VARCHAR2(5000);
    iniPerd number;
    iniPeri number;
    iniAno  date;    
  BEGIN
   --mcod_empresa := LIB_PARAMETROS.RECUPERAR('EMPRESA');

    -- Razao Social
    Begin
      select Razao_social,cnpj
        into wEmpresa.razao_social,wEmpresa.Cnpj
        from empresa
       where cod_empresa = LIB_PARAMETROS.RECUPERAR('EMPRESA');
    exception
      when others then
        wEmpresa.razao_social := 'Nao Identificada';
    end;

    begin
      select to_date(decode(to_char(add_months(sysdate, -1), 'yyyy') - to_char(sysdate, 'yyyy'),0,to_char(sysdate, 'yyyy'),to_char(sysdate, 'yyyy') - 1),'yyyy') as iniAno,
             1 as iniPerd,
             to_char(add_months(sysdate, -1), 'mm') * 1 as iniPeri
        into iniAno, iniPerd, iniPeri
        from dual;
    end;

    --01
    LIB_PROC.ADD_PARAM(PSTR, lpad(' ', 62, ' '), 'varchar2', 'Text', 'N');
    
    --02
    LIB_PROC.ADD_PARAM(PSTR,
                       lpad(' ', 62, ' ') ||
                       '*****  '||nome||'  *****',
                       'varchar2',
                       'Text',
                       'N');
    --03                   
    LIB_PROC.ADD_PARAM(PSTR,
                       lpad(' ', 45, ' ') || 'Empresa:   ' ||
                       wEmpresa.razao_social,
                       'varchar2',
                       'Text',
                       'N');

    --04
    LIB_PROC.ADD_PARAM(PSTR,
                       'Estabelecimento',
                       'Varchar2',
                       'ComboBox',
                       'N',
                       '00015',
                       NULL,
                       'select distinct estab.cod_estab, estab.cod_estab || '' - '' || estab.razao_social razao_social
                                  FROM estabelecimento estab
                                 where 1 = 1
                                   and estab.cod_empresa = ''' ||LIB_PARAMETROS.RECUPERAR('EMPRESA')|| '''');

    --05
    LIB_PROC.ADD_PARAM(PSTR,
                       'Ano de apura��o',
                       'Varchar2',
                       'Textbox',
                       'S',
                       to_char(iniAno, 'yyyy'),
                       '####',
                       papresenta => 'S');

    --06
    LIB_PROC.ADD_PARAM(PSTR,
                       'Periodicidade',
                       'Varchar2',
                       'ListBox',
                       'S',
                       iniPerd,
                       null,
                       '1=Mensal,6=Bimestral,3=Trimestral,5=Quadrimestral,4=Semestral', --,2=Anual N�o est� funcionando
                       papresenta => 'S');

    --07
    LIB_PROC.ADD_PARAM(PSTR,
                       'Per�odo',
                       'Varchar2',
                       'Combobox',
                       'S',
                       iniPeri,
                       NULL,
                       '      select mes, descricao from mes where 1 = :6
                        union select trimestre, trimestre||''� Trimestre'' from mes where 3 = :6
                        union select semestre, semestre||''� Semestre'' from mes where 4 = :6
                        union select Quadrimestre, Quadrimestre||''� Quadrimestre'' from mes where 5 = :6
                        union select bimestre, bimestre||''� bimestre'' from mes where 6 = :6',
                       papresenta => 'S',
                       phabilita => ':6 != ''2''');
    
    --08
    LIB_PROC.ADD_PARAM(PSTR,
                       'Gerar',
                       'Varchar2',
                       'RadioButton',
                       'N',
                       '1',
                       null,
                       '1=Todo Per�odo,2=Unica NF,3=Sequencia De NF',
                       papresenta => 'S');                       

    LIB_PROC.ADD_PARAM(PSTR, lpad(' ', 62, ' '), 'varchar2', 'Text', 'N');
    LIB_PROC.ADD_PARAM(PSTR, lpad(' ', 63, ' ')||'Informe o Numero da NF', 'varchar2', 'Text', 'N');
    
    --10
    LIB_PROC.ADD_PARAM(PSTR,
                       'Numero da NF',
                       'Varchar2',
                       'Textbox',
                       'S',
                       null,
                       '############',
                       papresenta => 'S',
                       phabilita => '(nvl( :8 , 1 ) = 2)');

    
    LIB_PROC.ADD_PARAM(PSTR, lpad(' ', 62, ' '), 'varchar2', 'Text', 'N');
    LIB_PROC.ADD_PARAM(PSTR, lpad(' ', 63, ' ')||'Informe a Sequencia da NF', 'varchar2', 'Text', 'N');
    
    --12
    LIB_PROC.ADD_PARAM(PSTR,
                       'NF inicial',
                       'Varchar2',
                       'Textbox',
                       'S',
                       null,
                       '############',
                       papresenta => 'S',
                       phabilita => '(nvl( :8 , 1 ) = 3)');
                       
    --13
    LIB_PROC.ADD_PARAM(PSTR,
                       'NF Final',
                       'Varchar2',
                       'Textbox',
                       'S',
                       null,
                       '############',
                       papresenta => 'S',
                       phabilita => '(nvl( :8 , 1 ) = 3)');

    LIB_PROC.ADD_PARAM(PSTR, lpad(' ', 62, ' '), 'varchar2', 'Text', 'N');
    
    LIB_PROC.ADD_PARAM(PSTR,
                       'Modulo Desenvolvido para ' || wEmpresa.razao_social,
                       'varchar2',
                       'Text',
                       'N');

    LIB_PROC.ADD_PARAM(PSTR,
                       'Versao : ' || VERSAO,
                       'varchar2',
                       'Text',
                       'N');

   RETURN pstr;

  END;

  FUNCTION VERSAO RETURN VARCHAR2 IS
  BEGIN
    RETURN '1.0';
  END;

  FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Geracao de NF';
  END;

  FUNCTION Tipo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Relatorios';
  END;

  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Geracao de NF';
  END;

  FUNCTION Executar(pCodestab     x07_docto_fiscal.cod_estab%type, --02 Estabelecimento
                    pAno           varchar2, --03 Ano de apura��o
                    pPeriD         char, --04 Periodicidade
                    pPeriodo       char, --05 Per�odo
                    pTipoGear      number,
                    pNumDocFis    x07_docto_fiscal.num_docfis%type,
                    pNumDocFisIni x07_docto_fiscal.num_docfis%type,
                    pNumDocFisFim x07_docto_fiscal.num_docfis%type) RETURN INTEGER IS

    -- Variaveis de Trabalho */
    mproc_id            Integer;
    --mLinha              Varchar2(2000);
    --v_tot07             number :=0;
    --v_tot08             number :=0;
    vPeriodo     varchar2(20);
    vDatIni      date;
    vDatFim      date;
  BEGIN
    execute immediate 'alter session set NLS_LANGUAGE = ''PORTUGUESE''';
    
    if pPeriD = 1 then -- mensal
      select a.descricao,
             add_months(last_day(to_date(lpad(min(mes),2,'0')||pAno,'mmyyyy'))+1,-1),
             last_day(to_date(lpad(max(mes),2,'0')||pAno,'mmyyyy'))
        into vPeriodo, vDatIni, vDatFim
        from mes a where a.mes = pPeriodo
       group by descricao;
    elsif pPeriD = 3 then -- trimestral
      select trimestre||'� Trimestre',
             add_months(last_day(to_date(lpad(min(mes),2,'0')||pAno,'mmyyyy'))+1,-1),
             last_day(to_date(lpad(max(mes),2,'0')||pAno,'mmyyyy'))
        into vPeriodo, vDatIni, vDatFim
        from mes a where a.trimestre = pPeriodo
       group by trimestre;
    elsif pPeriD = 2 then -- anual
      select 'Anual',
             add_months(last_day(to_date(lpad(min(mes),2,'0')||pAno,'mmyyyy'))+1,-1),
             last_day(to_date(lpad(max(mes),2,'0')||pAno,'mmyyyy'))
        into vPeriodo, vDatIni, vDatFim
        from mes a ;
    elsif pPeriD = 4 then -- Semestral
      select semestre||'� Semestre',
             add_months(last_day(to_date(lpad(min(mes),2,'0')||pAno,'mmyyyy'))+1,-1),
             last_day(to_date(lpad(max(mes),2,'0')||pAno,'mmyyyy'))
        into vPeriodo, vDatIni, vDatFim
        from mes a where a.semestre = pPeriodo
       group by semestre;
    elsif pPeriD = 5 then -- quadrimestre
      select a.quadrimestre||'� quadrimestre',
             add_months(last_day(to_date(lpad(min(mes),2,'0')||pAno,'mmyyyy'))+1,-1),
             last_day(to_date(lpad(max(mes),2,'0')||pAno,'mmyyyy'))
        into vPeriodo, vDatIni, vDatFim
        from mes a where a.quadrimestre = pPeriodo
       group by quadrimestre;
    elsif pPeriD = 6 then -- bimestre
      select a.bimestre||'� bimestre',
             add_months(last_day(to_date(lpad(min(mes),2,'0')||pAno,'mmyyyy'))+1,-1),
             last_day(to_date(lpad(max(mes),2,'0')||pAno,'mmyyyy'))
        into vPeriodo, vDatIni, vDatFim
        from mes a where a.bimestre = pPeriodo
       group by bimestre order by bimestre;
    end if;
    
    
    -- Cria Processo
    MPROC_ID := LIB_PROC.new('PCK_BRAS_GERA_NF_CPROC', 48, 150);
    
    LIB_PROC.ADD_TIPO(MPROC_ID, 3, 'Nota Fiscal', 3);
    LIB_PROC.ADD_TIPO(MPROC_ID, 4, pCodestab||'_NFS_'||to_char(vDatIni,'yyyymmdd')||'-'||to_char(vDatFim,'yyyymmdd')||'.xls', 2);
    
    -- Razao Social
    Begin
      select upper(       a.tp_logradouro
                   ||' '||a.endereco
                   ||', '||a.num_endereco
                   ||' - CEP: '||a.cep
                   ||' - FONE: ('||a.ddd
                   ||') '||a.telefone
                   ||'<br>BAIRRO: '||a.bairro
                   ||' - '||a.cidade
                   ||' - '||b.cod_estado
                   ||'<br> INSCR. C.N.P.J.(M.F.): '||a.cgc
                   ||'<br> INSCR. MUNICIPAL: '||a.insc_municipal)
        into vLinhaEstab
        from estabelecimento a,
             estado          b
       where 1=1
         and a.ident_estado = b.ident_estado
         and cod_empresa = LIB_PARAMETROS.RECUPERAR('EMPRESA')
         and a.cod_estab = pCodestab;
    exception
      when others then
        wEmpresa.razao_social := 'Nao Identificada';
    end;

    LIB_PROC.add(plinha => vHeader1,pTipo => 3); 
    --LIB_PROC.add(plinha => vHeader2,pTipo => 3); 
                           
    vBody :=  '<div class="endereco" id="endereco">'||vLinhaEstab||'</div>';
    --LIB_PROC.add(vBody, null, null, 3);    
    
    if Linha_Relat%isopen then
      close Linha_Relat;
    end if;
    
    vAltPagina := 80;
    vAltLinha  := 354;
    
    
    vText :=          'NUM_DOCFIS'         ||vTab;
    vText := vText || 'COD_NATUREZA_OP'    ||vTab;
    vText := vText || 'NFVIATRANSPORTE'    ||vTab;
    vText := vText || 'DATA_EMISSAO'       ||vTab;
    vText := vText || 'MES_ANO'            ||vTab;
    vText := vText || 'RAZAO_SOCIAL'       ||vTab;
    vText := vText || 'COD_FIS_JUR'        ||vTab;
    vText := vText || 'ENDERECO'           ||vTab;
    vText := vText || 'CEP'                ||vTab;
    vText := vText || 'CIDADE'             ||vTab;
    vText := vText || 'COD_ESTADO'         ||vTab;
    vText := vText || 'CPF_CGC'            ||vTab;
    vText := vText || 'INSC_ESTADUAL'      ||vTab;
    vText := vText || 'DPLNUM'             ||vTab;
    vText := vText || 'DPLVLR'             ||vTab;
    vText := vText || 'DT_PAGTO_NF'        ||vTab;
    vText := vText || 'OBS_TRIBUTO'        ||vTab;
    vText := vText || 'VLR_TOT_NOTA'       ||vTab;
    -- itens
    vText := vText || 'DSC_1'              ||vTab;
    vText := vText || 'VLR_1'              ||vTab;
    vText := vText || 'DSC_2'              ||vTab;
    vText := vText || 'VLR_2'              ||vTab;
    vText := vText || 'DSC_3'              ||vTab;
    vText := vText || 'VLR_3'              ||vTab;
    vText := vText || 'DSC_4'              ||vTab;
    vText := vText || 'VLR_4'              ||vTab;
    -- fim itens
    vText := vText || 'VLR_BASE_INSS'      ||vTab;
    vText := vText || 'VLR_INSS_RETIDO'    ||vTab;
    vText := vText || 'VLR_COFINS_RETIDO'  ||vTab;
    vText := vText || 'VLR_PIS_RETIDO'     ||vTab;
    vText := vText || 'VLR_CSLL'           ||vTab;
    vText := vText || 'ELEMENTO_PEP'       ||vTab;
    vText := vText || 'NUM_ORDEM'          ||vTab;
    vText := vText || 'VLR_ISS_RETIDO'     ||vTab;
    vText := vText || 'VLR_IR'             ||vTab;     
         
    LIB_PROC.add(vText, null, null, 4);   

    if Relat%ISOPEN then
       close Relat;
    end if;

    open Relat(LIB_PARAMETROS.RECUPERAR('EMPRESA'), 
               pCodestab,
               vDatIni,
               vDatFim,
               pTipoGear,     
               pNumDocFis,   
               pNumDocFisIni,
               pNumDocFisFim);
    loop
      -- Pegar Registros
      fetch Relat
        into wRelat;
      exit when Relat%NOTFOUND;
      
      begin
        select c.*
          into wX04
          from x04_pessoa_fis_jur c
         where 1=1
           and c.ident_fis_jur = wRelat.Ident_Fis_Jur; 
      exception
        when others then
          null;
      end;
      
      select case length(wX04.Cpf_Cgc) --when 14 then regexp_replace(LPAD(wX04.Cpf_Cgc, 15, '0'),'([0-9]{3})([0-9]{3})([0-9]{3})([0-9]{4})([0-9]{2})','\1.\2.\3/\4-\5')
                                       when 14 then substr(wX04.Cpf_Cgc,-14,2)
                                                    ||'.'||substr(wX04.Cpf_Cgc,-12,3)
                                                    ||'.'||substr(wX04.Cpf_Cgc,-9,3)
                                                    ||'/'||substr(wX04.Cpf_Cgc,-6,4)
                                                    ||'-'||substr(wX04.Cpf_Cgc,-2)
                                       when 11 then regexp_replace(wX04.Cpf_Cgc,'([0-9]{3})([0-9]{3})([0-9]{3})([0-9]{2})','\1.\2.\3-\4')
                                       else '0' end
         into vCgcCpf
         from dual; 
      
      begin
        select d.*
          into wEstado
          from estado d
         where 1=1
           and d.ident_estado = wX04.ident_estado; 
      exception
        when others then
          null;
      end;  
      
      vBody := '<div class="NumNF1" id="NumNF1" style="top: '||(vAltPagina)||'px">'||wRelat.Num_Docfis||'</div>';
      LIB_PROC.add(vBody, null, null, 3);
      
      vBody := '<div class="ElmPEP" id="ElmPEP" style="top: '||(vAltPagina+v_ElmPEP)||'px">'||wRelat.Dsc_Reservado1||'</div>';
      LIB_PROC.add(vBody, null, null, 3);
      
      vBody := '<div class="OrdVenda" id="OrdVenda" style="top: '||(vAltPagina+v_OrdVenda)||'px">'||wRelat.Dsc_Reservado2||'</div>';
      LIB_PROC.add(vBody, null, null, 3);
      
      vBody := '<div class="nfNatOperacao" id="nfNatOperacao" style="top: '||(vAltPagina+v_nfNatOperacao)||'px">PRESTACAO DE SERVICOS</div>';
      LIB_PROC.add(vBody, null, null, 3);

      --vBody := '<div class="nfViaTransporte" id="nfViaTransporte" style="top: '||(vAltPagina+v_nfViaTransporte)||'px">||nfViaTransporte||</div>';
      --LIB_PROC.add(vBody, null, null, 3);

      vBody := '<div class="nfDatEmissao" id="nfDatEmissao" style="top: '||(vAltPagina+v_nfDatEmissao)||'px">'||wRelat.Data_Emissao||'</div>';
      LIB_PROC.add(vBody, null, null, 3);

      vBody := '<div class="razaoSocial" id="razaoSocial" style="top: '||(vAltPagina+v_razaoSocial)||'px">'||wX04.Razao_Social||'</div>';
      LIB_PROC.add(vBody, null, null, 3);

      vBody := '<div class="endCliCodFisJur" id="endCliCodFisJur" style="top: '||(vAltPagina+v_endCliCodFisJur)||'px">'||wX04.Cod_Fis_Jur||'</div>';
      LIB_PROC.add(vBody, null, null, 3);

      vBody := '<div class="endCliente" id="endCliente" style="top: '||(vAltPagina+v_endCliente)||'px">'||wX04.Endereco||'</div>';
      LIB_PROC.add(vBody, null, null, 3);

      vBody := '<div class="endCliCEP" id="endCliCEP" style="top: '||(vAltPagina+v_endCliCEP)||'px">'||wX04.Cep||'</div>';
      LIB_PROC.add(vBody, null, null, 3);

      vBody := '<div class="endCliCid" id="endCliCid" style="top: '||(vAltPagina+v_endCliCid)||'px">'||wX04.Cidade||'</div>';
      LIB_PROC.add(vBody, null, null, 3);

      vBody := '<div class="endCliUF" id="endCliUF" style="top: '||(vAltPagina+v_endCliUF)||'px">'||wEstado.Cod_Estado||'</div>';
      LIB_PROC.add(vBody, null, null, 3);

      vBody := '<div class="endCliCNPJ" id="endCliCNPJ" style="top: '||(vAltPagina+v_endCliCNPJ)||'px">'||vCgcCpf||'</div>';
      LIB_PROC.add(vBody, null, null, 3);

      vBody := '<div class="endCliIE" id="endCliIE" style="top: '||(vAltPagina+v_endCliIE)||'px">'||wX04.Insc_Estadual||'</div>';
      LIB_PROC.add(vBody, null, null, 3);
      --
      vBody := '<div class="dplNum" id="dplNum" style="top: '||(vAltPagina+v_dplNum)||'px">'||wRelat.Num_Docfis||'</div>';
      LIB_PROC.add(vBody, null, null, 3);

      vBody := '<div class="dplVlr" id="dplVlr" style="top: '||(vAltPagina+v_dplVlr)||'px">'||numFormat(wRelat.Dsc_Reservado7)||'</div>';
      LIB_PROC.add(vBody, null, null, 3);

      vBody := '<div class="dplDatVenc" id="dplDatVenc" style="top: '||(vAltPagina+v_dplDatVenc)||'px">'||wRelat.Dt_Pagto_Nf||'</div>';
      LIB_PROC.add(vBody, null, null, 3);
      
      vBody := '<div class="infoDupli" id="infoDupli" style="top: '||(vAltPagina+v_infoDupli)||'px">RETENCAO DE I.R S/SERVICO: R$ '||numFormat(wRelat.vlr_ir)||
                                                                                               '<br>RETENCAO DE I.S.S S/SERVICO: R$ '||numFormat(wRelat.VLR_ISS_RETIDO)||'</div>';
      LIB_PROC.add(vBody, null, null, 3);
      
      
      
      

      --
      
      vBody := '<div class="nfObs" id="nfObs" style="top: '||(vAltPagina+v_nfObs)||'px">'||wRelat.dsc_RESERVADO5||'</div>';
      LIB_PROC.add(vBody, null, null, 3);

      vBody := '<div class="NumNF2" id="NumNF2" style="top: '||(vAltPagina+v_NumNF2)||'px">'||wRelat.Num_Docfis||'</div>';
      LIB_PROC.add(vBody, null, null, 3);
      --LIB_PROC.add(wRelat.Endereco||chr(9), null, null, 4);

      vBody := '<div class="nfVlrTotNota" id="nfVlrTotNota" style="top: '||(vAltPagina+v_nfVlrTotNota)||'px">'||numFormat(wRelat.Vlr_Tot_Nota)||'</div>';
      LIB_PROC.add(vBody, null, null, 3);

      vText :=          wRelat.Num_Docfis               ||vTab;
      vText := vText || wRelat.Cod_Natureza_Op          ||vTab;
      vText := vText || null                            ||vTab;
      vText := vText || wRelat.Data_Emissao             ||vTab;
      vText := vText || replace(to_char(wRelat.Data_Emissao,'MONTH/yyyy'),' ')            ||vTab;
      vText := vText || wX04.Razao_Social               ||vTab;
      vText := vText || wX04.Cod_Fis_Jur                ||vTab;
      vText := vText || wX04.Endereco                   ||vTab;
      vText := vText || wX04.Cep                        ||vTab;
      vText := vText || wX04.Cidade                     ||vTab;
      vText := vText || wEstado.Cod_Estado              ||vTab;
      vText := vText || vCgcCpf                         ||vTab;
      vText := vText || wRelat.Insc_Estadual            ||vTab;
      vText := vText || wRelat.Num_Docfis               ||vTab;
      vText := vText || numFormat(wRelat.Dsc_Reservado7)||vTab;
      vText := vText || wRelat.Dt_Pagto_Nf              ||vTab;
      vText := vText || wRelat.Obs_Tributo              ||vTab;
      vText := vText || numFormat(wRelat.Vlr_Tot_Nota)  ||vTab;


      -- x09
      if Linha_Relat%ISOPEN then
         close Linha_Relat;
      end if;


      vNumLinha := 0;
      open Linha_Relat(wRelat.COD_EMPRESA,
                       wRelat.COD_ESTAB,
                       wRelat.DATA_FISCAL,
                       wRelat.MOVTO_E_S,
                       wRelat.NORM_DEV,
                       wRelat.IDENT_DOCTO,
                       wRelat.IDENT_FIS_JUR,
                       wRelat.NUM_DOCFIS,
                       wRelat.SERIE_DOCFIS);
      loop
        -- Pegar Registros
        fetch Linha_Relat
          into wLinha_Relat;
        exit when Linha_Relat%NOTFOUND;
      
      
        if wLinha_relat.grp1 = 0 then
          vBody := '<div class="itensDesc" id="itensDesc" style="top: '||(vAltLinha)||'px;">'||wLinha_relat.Cod_Servico||' - '||wLinha_relat.descricao||'</div>';
          LIB_PROC.add(vBody, null, null, 3);
          vBody := '<div class="itensValor" id="itensValor" style="top: '||(vAltLinha)||'px;">'||numFormat(wLinha_relat.Vlr_Servico)||'</div>';
          LIB_PROC.add(vBody, null, null, 3);
          
          vAltLinha := vAltLinha + 20;
          
          vText := vText || wLinha_relat.Cod_Servico||' - '||wLinha_relat.descricao||vTab;
          vText := vText || numFormat(wLinha_relat.Vlr_Servico)||vTab;
          
          vNumLinha := vNumLinha + 1;
          
        elsif wLinha_relat.grp1 = 1 then
          if vNumLinha < 4 then
            for a in vNumLinha..3 loop
              vText := vText ||vTab||vTab;
            end loop;
          end if;
          vBody := '<div class="itensDesc" id="itensDesc" style="top: '||(vAltLinha+10)||'px;"> <br>
            REFERENTE AO MES DE: '||replace(to_char(wRelat.Data_Emissao,'MONTH/yyyy'),' ')||'<br>
            <br>
            DEDUCOES PERMITIDAS PARA CALCULO DO INSS R$: '||numFormat(wRelat.DSC_RESERVADO6)||' <br>
            <br>
            RETENCAO DE INSS S/SERVICO R$ '||numFormat(wRelat.VLR_INSS_RETIDO)||'<br>
            <br>
            RETENCAO CONFORME ARTIGO 30 E 31 DA LEI NO. 10.833/2003<br>
            RETENCAO DE COFINS S/SERVICO R$ '||numFormat(wLinha_relat.Vlr_Cofins_Retido)||'<br>
            RETENCAO DE PIS S/SERVICO R$ '||numFormat(wLinha_relat.Vlr_Pis_Retido)||'<br>
            RETENCAO DE CSLL S/SERVICO R$ '||numFormat(wRelat.vlr_csll)||'<br>
            </div>';
          LIB_PROC.add(vBody, null, null, 3);
          
          vText := vText || numFormat(wRelat.DSC_RESERVADO6)||vTab;           --'VLR_BASE_INSS'    
          vText := vText || numFormat(wRelat.VLR_INSS_RETIDO)||vTab;          --'VLR_INSS_RETIDO'  
          vText := vText || numFormat(wRelat.Vlr_Cofins_Retido)||vTab;  	  --'VLR_COFINS_RETIDO'
          vText := vText || numFormat(wRelat.Vlr_Pis_Retido)||vTab;     	  --'VLR_PIS_RETIDO'   
          vText := vText || numFormat(wLinha_relat.vlr_csll)||vTab;           --'VLR_CSLL'         
          vText := vText || wRelat.Dsc_Reservado1 ||vTab;                     --'ELEMENTO_PEP'     
          vText := vText || wRelat.Dsc_Reservado2 ||vTab;                     --'NUM_ORDEM'      
          vText := vText || numFormat(wRelat.VLR_ISS_RETIDO) ||vTab;          --'VLR_ISS_RETIDO'       
          vText := vText || numFormat(wRelat.vlr_ir) ||vTab;                  --'VLR_IR'    
                                                                                       
        end if;


      
      end loop;
      close Linha_Relat;

      vAltLinha  := vAltLinha + vNextPag - 20;      
      vAltPagina := vAltPagina + vNextPag;

      
      LIB_PROC.add(vText, null, null, 4);
      lib_proc.add_log(wRelat.COD_EMPRESA||' - '||
                       wRelat.COD_ESTAB||' - '||
                       wRelat.DATA_FISCAL||' - '||
                       wRelat.MOVTO_E_S||' - '||
                       wRelat.NORM_DEV||' - '||
                       wRelat.IDENT_DOCTO||' - '||
                       wRelat.IDENT_FIS_JUR||' - '||
                       wRelat.NUM_DOCFIS||' - '||
                       wRelat.SERIE_DOCFIS, 1);
    end loop;
    close Relat;
    
    --vBody := '<div class="fimPagina" id="fimPagina" style="top: '||(vAltPagina)||'px">&nbsp;</div></body></html>';
    vBody := '</body></html>';
    LIB_PROC.add(vBody, null, null, 3);

    --vHTML := vHeader||vBody;
    -- Inicializa HTML
    --LIB_PROC.add(plinha => vHTML,pTipo => 3);
  
    --LIB_PROC.add(plinha => LIB_HTML.linha_separadora, pTipo  => 3);

    --LIB_PROC.add(plinha => LIB_HTML.fim ,ptipo => 3);

    LIB_PROC.CLOSE();
    RETURN mproc_id;
END;

  -------------------------------------------------------------------------
  -- Procedure para Teste
  -------------------------------------------------------------------------

  PROCEDURE TESTE IS
    MPROC_ID INTEGER;
  BEGIN
    LIB_PARAMETROS.SALVAR('EMPRESA', '001');
    --MCOD_EMPRESA := '001';
    MPROC_ID     := EXECUTAR('035',
                             '2012',
                             '1',
                             '1',
                             2,
                             '000089315',
                             '0',
                             '0');

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('---Arquivo Magnetico----');
    DBMS_OUTPUT.PUT_LINE('');
    LIB_PROC.LIST_OUTPUT(MPROC_ID, 2);
  END;

END;
/
