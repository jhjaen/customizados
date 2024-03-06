create or replace view vw_param_ecd_k as
select p.rowid rowid_param1
       , p.cod_empresa_cons
       , p.cod_empresa_det
       , p.cod_empresa_contra
       , p.periodo
       , to_char('| Emp. Detentora: '|| p.cod_empresa_det       ||
               '   |   Emp. Contrapartida: '||p.cod_empresa_contra ||
               '   |   Conta Det. : ' || p.cod_conta_det      ||
               '   |   Conta Contra-Part.: '                || p.cod_conta_contra) descr_param
  from MSAF_PARAM_BLOCOK_ECD p;
