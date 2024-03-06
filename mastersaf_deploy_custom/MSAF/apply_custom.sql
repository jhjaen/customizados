----------------------------------------------
-- Export file for user MSAF                --
-- Created by dpere on 01/07/2020, 18:26:47 --
----------------------------------------------

spool apply_custom.log

prompt
prompt Creating Function UTL_LIST_FILES
prompt =====================================
prompt
@@db\UTL_LIST_FILES.fnc

prompt
prompt Creating table MSAF_BLOCOK_ELIMINACAO
prompt =====================================
prompt
@@db\msaf_blocok_eliminacao.tab
prompt
prompt Creating table MSAF_PARAM_BLOCOK_ECD
prompt ====================================
prompt
@@db\msaf_param_blocok_ecd.tab
prompt
prompt Creating table MSAF_SALDO_DETALHADO_K
prompt =====================================
prompt
@@db\msaf_saldo_detalhado_k.tab
prompt
prompt Creating table T_AUX_FILES2
prompt ===========================
prompt
@@db\t_aux_files2.tab
prompt
prompt Creating table TREG_PLANO_CONTAS_ECD
prompt ====================================
prompt
@@db\treg_plano_contas_ecd.tab
prompt
prompt Creating table TREG_SALDO_ECD
prompt =============================
prompt
@@db\treg_saldo_ecd.tab
prompt
prompt Creating view VW_PARAM_ECD_K
prompt ============================
prompt
@@db\vw_param_ecd_k.vw
prompt
prompt Creating function CARREGA_ARQUIVOS
prompt ==================================
prompt
@@db\carrega_arquivos.fnc
prompt
prompt Creating procedure PRC_LOAD_TXT_ECD
prompt ===================================
prompt
@@db\prc_load_txt_ecd.prc
prompt
prompt Creating procedure PRC_REPLY_PARAM
prompt ==================================
prompt
@@db\prc_reply_param.prc
prompt
prompt Creating procedure PRC_GER262_AGLUT
prompt ==================================
prompt
@@db\PRC_GER262_AGLUT.prc
prompt
prompt Creating package MSAF_GERA_BLOCOK_ECD_CPROC
prompt ===========================================
prompt
@@db\msaf_gera_blocok_ecd_cproc.pck
prompt
prompt Creating package MSAF_LOAD_FILE_ECD_CPROC
prompt =========================================
prompt
@@db\msaf_load_file_ecd_cproc.pck
prompt
prompt Creating package MSAF_PARAM_BLOCOK_CPROC
prompt ========================================
prompt
@@db\msaf_param_blocok_cproc.pck
prompt
prompt Creating package MSAF_PARAM2_BLOCOK_CPROC
prompt =========================================
prompt
@@db\msaf_param2_blocok_cproc.pck

spool off
