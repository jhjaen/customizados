CREATE OR REPLACE PACKAGE MSAF_DIM_SLS_CPROC is

	-- Autor         : Leandro Pavan
	-- Created       : 27/09/2005
	-- Purpose       : Gera��o do arquivo para entrega da DIM - S�o Luis, conforme layout fornecido pela prefeitura

	/* VARI�VEIS DE CONTROLE DE CABE�ALHO DE RELAT�RIO */

	function parametros return varchar2;
	function nome return varchar2;
	function tipo return varchar2;
	function versao return varchar2;
	function descricao return varchar2;
	function modulo return varchar2;
	function classificacao return varchar2;
	function executar (pcd_estab     varchar2,
	                   pdt_inicio    date,
	                   pdt_final     date) return integer;

END MSAF_DIM_SLS_CPROC;
 
 
/
CREATE OR REPLACE PACKAGE BODY MSAF_DIM_SLS_CPROC is

	mcod_estab   estabelecimento.cod_estab%TYPE;
	mcod_empresa empresa.cod_empresa%TYPE;
	musuario     usuario_estab.cod_usuario%TYPE;

	FUNCTION Parametros RETURN VARCHAR2 IS
		pstr VARCHAR2(5000);
	BEGIN
		mcod_empresa := LIB_PARAMETROS.RECUPERAR('EMPRESA');
		mcod_estab   := NVL(LIB_PARAMETROS.RECUPERAR('ESTABELECIMENTO'), '');
    musuario     := LIB_PARAMETROS.Recuperar('USUARIO');

		LIB_PROC.add_param(pstr,
                       'Estabelecimento ',
                       'Varchar2',
                       'Combobox',
                       'S',
                       NULL,
                       NULL,
		                   'SELECT DISTINCT e.cod_estab, e.cod_estab||'' - ''||e.razao_social FROM estabelecimento e WHERE e.cod_empresa = ''' ||
								        mcod_empresa || '''');

		LIB_PROC.add_param(pstr,
                       'Per�odo Inicial ',
                       'Date',
                       'Textbox',
                       'S',
                       NULL,
                       'dd/mm/yyyy');

		LIB_PROC.add_param(pstr,
                       'Per�odo Final ',
                       'Date',
                       'Textbox',
                       'S',
                       NULL,
                       'dd/mm/yyyy');

		RETURN pstr;
	END;

	FUNCTION Nome RETURN VARCHAR2 IS
	BEGIN
		RETURN 'DIM - S�O LUIS(MA)';
	END;

	FUNCTION Tipo RETURN VARCHAR2 IS
	BEGIN
		RETURN 'DIM';
	END;

	FUNCTION Versao RETURN VARCHAR2 IS
	BEGIN
		RETURN '1.0';
	END;

	FUNCTION Descricao RETURN VARCHAR2 IS
	BEGIN
		RETURN 'DIM - S�O LUIS(MA)';
	END;

	FUNCTION Modulo RETURN VARCHAR2 IS
	BEGIN
		RETURN 'Processos Customizados';
	END;

	FUNCTION Classificacao RETURN VARCHAR2 IS
	BEGIN
		RETURN 'Processos Customizados';
	END;

	FUNCTION Executar (PCD_ESTAB   VARCHAR2,
      		           PDT_INICIO  DATE,
      		           PDT_FINAL   DATE) RETURN INTEGER IS

		/* Vari�veis de Trabalho */
    mproc_id          INTEGER;
    mLinha            VARCHAR2(1000);
    v_insc_mun        VARCHAR2(15);

	BEGIN
		-- Cria Processo
		mproc_id := LIB_PROC.new('MSAF_DIM_SLS_CPROC', 48, 150);
		LIB_PROC.add_tipo(mproc_id, 1, 'ARQ_DIM', 2);

		DECLARE
-- Inicio Cr01
   -- notas fiscais de servi�os emitidas
	  CURSOR rel_serv_saida(ccd_empresa VARCHAR2,
                        ccd_estab VARCHAR2,
                        cdt_inicio DATE,
                        cdt_final DATE) IS
          select dwt07.data_emissao,
                 'E' serie,
                 ' ' modelo,
                 'B' natureza,
                 dwt07.num_docfis,
                 dwt07.vlr_tot_nota,
                 sum(dwt09.vlr_servico) vlr_servico,
                 dwt09.aliq_tributo_iss aliquota,
                 x04.insc_municipal,
                 x04.cpf_cgc,
                 '00000000000' cpf,
                 'AVENIDA' tp_rua,
                 upper(x04.razao_social) razao_social,
                 upper(x04.endereco) endereco,
                 x04.num_endereco,
                 upper(x04.compl_endereco) compl_endereco,
                 upper(x04.bairro) bairro,
                 upper(x04.cidade) cidade,
                 upper(uf.cod_estado) uf,
                 x04.cep,
                 x04.cod_atividade,
                 dwt07.situacao
          from dwt_itens_serv dwt09, dwt_docto_fiscal dwt07, estado uf, x04_pessoa_fis_jur x04
          where dwt09.ident_docto_fiscal = dwt07.ident_docto_fiscal
          and   dwt07.ident_fis_jur      = x04.ident_fis_jur
          and   x04.ident_estado         = uf.ident_estado
          and   dwt07.cod_empresa        = ccd_empresa--'001'
          and   dwt07.cod_estab          = ccd_estab--'0001'
          and   dwt07.movto_e_s          = '9'
          and   dwt07.data_fiscal        between cdt_inicio and cdt_final
          group by dwt07.data_emissao,
                   dwt07.num_docfis,
                   dwt07.vlr_tot_nota,
                   dwt09.aliq_tributo_iss,
                   x04.insc_municipal,
                   x04.cpf_cgc,
                   upper(x04.razao_social),
                   upper(x04.endereco),
                   x04.num_endereco,
                   upper(x04.compl_endereco),
                   upper(x04.bairro),
                   upper(x04.cidade),
                   upper(uf.cod_estado),
                   x04.cep,
                   x04.cod_atividade,
                   dwt07.situacao
-- Fim Cr01


-- In�cio Cr02
   -- notas fiscais de servi�os recebidas
   CURSOR rel_serv_ent(ccd_empresa VARCHAR2,
                       ccd_estab VARCHAR2,
                       cdt_inicio DATE,
                       cdt_final DATE) IS
          select dwt07.dt_pagto_nf,
                 dwt07.data_emissao,
                 'E' serie,
                 ' ' modelo,
                 'B' natureza,
                 dwt07.num_docfis,
                 dwt07.vlr_tot_nota,
                 sum(dwt09.vlr_servico) vlr_servico,
                 dwt09.aliq_tributo_iss aliquota,
                 x04.insc_municipal,
                 x04.cpf_cgc,
                 '00000000000' cpf,
                 upper(x04.razao_social) razao_social,
                 'AVENIDA' tp_rua,
                 upper(x04.endereco) endereco,
                 x04.num_endereco,
                 upper(x04.compl_endereco) compl_endereco,
                 upper(x04.bairro) bairro,
                 upper(x04.cidade) cidade,
                 decode(x04.cod_pais,'105',upper(uf.cod_estado),'EX') uf,
                 x04.cep
          from dwt_itens_serv dwt09, dwt_docto_fiscal dwt07, estado uf, x04_pessoa_fis_jur x04
          where dwt07.ident_docto_fiscal = dwt09.ident_docto_fiscal
          and   dwt07.ident_fis_jur      = x04.ident_fis_jur
          and   x04.ident_fis_jur        = dwt09.ident_fis_jur
          and   x04.ident_estado         = uf.ident_estado
          and   dwt07.cod_empresa        = ccd_empresa--'001'
          and   dwt07.cod_estab          = ccd_estab--'0001'
          and   dwt07.movto_e_s          <>'9'
          and   dwt07.situacao           = 'N'
          and   dwt07.data_fiscal        between cdt_inicio and cdt_final
          group by dwt07.dt_pagto_nf,
                   dwt07.data_emissao,
                   dwt07.num_docfis,
                   dwt07.vlr_tot_nota,
                   dwt09.aliq_tributo_iss,
                   x04.insc_municipal,
                   x04.cpf_cgc,
                   upper(x04.razao_social),
                   upper(x04.endereco),
                   x04.num_endereco,
                   upper(x04.compl_endereco),
                   upper(x04.bairro),
                   upper(x04.cidade),
                   decode(x04.cod_pais,'105',upper(uf.cod_estado),'EX'),
                   x04.cep;
-- Fim Cr02

		BEGIN

       BEGIN
         select insc_municipal
         into v_insc_mun
         from estabelecimento
         where cod_empresa = mcod_empresa
         and   cod_estab   = pcd_estab;


       EXCEPTION
         when no_data_found then
            lib_proc.add_log('FALTA CADASTRAR A INCRI��O MUNICIPAL PARA O ESTABELECIMENTO '||pcd_estab,1);
       END;

       mLinha := rpad(' ',15,' ');
       mLinha := LIB_STR.w(mLinha, 'H', 1);
       mLinha := LIB_STR.w(mLinha, nvl(v_insc_mun,0), 2);
       mLinha := LIB_STR.w(mLinha, '500', 13);
       LIB_PROC.add(mLinha);

       -- notas fiscais de servi�os - sa�das
       FOR mreg IN rel_serv_saida(mcod_empresa, pcd_estab, pdt_inicio, pdt_final) LOOP

              mLinha := rpad(' ',332,' ');
              mLinha := LIB_STR.w(mLinha, 'E', 1);

              mLinha := LIB_STR.w(mLinha, TO_CHAR(mreg.data_emissao,'DD/MM/YYYY'), 2);
              mLinha := LIB_STR.w(mLinha, mreg.serie, 12);
              mLinha := LIB_STR.w(mLinha, ' ', 12);
              mLinha := LIB_STR.w(mLinha, mreg.natureza, 12);
              mLinha := LIB_STR.w(mLinha, LPAD(mreg.num_docfis, 9, '0'), 16);

              if nvl(upper(mreg.situacao),'N') = 'N' then
                  mLinha := LIB_STR.w(mLinha, to_char(mreg.vlr_tot_nota, '999999999999.99'), 25);
                  mLinha := LIB_STR.w(mLinha, to_char(mreg.vlr_servico, '999999999999.99'), 40);
              else
                  mLinha := LIB_STR.w(mLinha, '000000000000.00', 25);
                  mLinha := LIB_STR.w(mLinha, '000000000000.00', 40);
              end if;

              mLinha := LIB_STR.w(mLinha, 'A', 55);
              mLinha := LIB_STR.w(mLinha, to_char(mreg.aliquota, '99.99'), 56);
              mLinha := LIB_STR.w(mLinha, lpad(nvl(mreg.insc_municipal,0),11,0), 61);
              mLinha := LIB_STR.w(mLinha, lpad(nvl(mreg.cpf_cgc,0),14,0), 72);
              mLinha := LIB_STR.w(mLinha, mreg.cpf, 86);
              mLinha := LIB_STR.w(mLinha, mreg.razao_social, 97);
              mLinha := LIB_STR.w(mLinha, mreg.tp_rua, 137);
              mLinha := LIB_STR.w(mLinha, mreg.endereco, 147);
              mLinha := LIB_STR.w(mLinha, mreg.num_endereco, 197);
              mLinha := LIB_STR.w(mLinha, mreg.compl_endereco, 203);
              mLinha := LIB_STR.w(mLinha, 'BAIRRO', 223);
              mLinha := LIB_STR.w(mLinha, mreg.bairro, 233);
              mLinha := LIB_STR.w(mLinha, mreg.cidade, 283);
              mLinha := LIB_STR.w(mLinha, mreg.uf, 313);
              mLinha := LIB_STR.w(mLinha, mreg.cep, 315);
              mLinha := LIB_STR.w(mLinha, mreg.cod_atividade, 323);
              LIB_PROC.add(mLinha);

       END LOOP;

       -- notas fiscais de servi�os - entradas
       FOR mreg IN rel_serv_ent(mcod_empresa, pcd_estab, pdt_inicio, pdt_final) LOOP

              mLinha := rpad(' ',366,' ');
              mLinha := LIB_STR.w(mLinha, 'R', 1);

              mLinha := LIB_STR.w(mLinha, TO_CHAR(mreg.dt_pagto_nf,'DD/MM/YYYY'), 2);
              mLinha := LIB_STR.w(mLinha, TO_CHAR(mreg.data_emissao,'DD/MM/YYYY'), 12);
              mLinha := LIB_STR.w(mLinha, mreg.serie, 22);
              mLinha := LIB_STR.w(mLinha, ' ', 24);
              mLinha := LIB_STR.w(mLinha, mreg.natureza, 25);
              mLinha := LIB_STR.w(mLinha, LPAD(mreg.num_docfis, 9, '0'), 26);
              mLinha := LIB_STR.w(mLinha, to_char(mreg.vlr_tot_nota, '999999999999.99'), 35);
              mLinha := LIB_STR.w(mLinha, to_char(mreg.vlr_servico, '999999999999.99'), 50);
              mLinha := LIB_STR.w(mLinha, to_char(mreg.aliquota, '99.99'), 65);
              mLinha := LIB_STR.w(mLinha, '000000', 70);
              mLinha := LIB_STR.w(mLinha, '000000', 76);
              mLinha := LIB_STR.w(mLinha, lpad(nvl(mreg.insc_municipal,0),11,0), 112);
              mLinha := LIB_STR.w(mLinha, lpad(nvl(mreg.cpf_cgc,0),14,0), 123);
              mLinha := LIB_STR.w(mLinha, '00000000000', 86);
              mLinha := LIB_STR.w(mLinha, substr(mreg.razao_social,1,40), 148);
              mLinha := LIB_STR.w(mLinha, 'RUA', 188);
              mLinha := LIB_STR.w(mLinha, substr(mreg.endereco,1,50), 198);
              mLinha := LIB_STR.w(mLinha, mreg.num_endereco, 248);
              mLinha := LIB_STR.w(mLinha, mreg.compl_endereco, 254);
              mLinha := LIB_STR.w(mLinha, 'BAIRRO', 274);
              mLinha := LIB_STR.w(mLinha, mreg.bairro, 284);
              mLinha := LIB_STR.w(mLinha, mreg.cidade, 334);
              mLinha := LIB_STR.w(mLinha, mreg.uf, 364);
              mLinha := LIB_STR.w(mLinha, mreg.cep, 366);
              LIB_PROC.add(mLinha);

       END LOOP;
    END;

   LIB_PROC.CLOSE();
   RETURN mproc_id;

  END;
END MSAF_DIM_SLS_CPROC;
/
