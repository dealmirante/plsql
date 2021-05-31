select cod_local,cod_rubr,
sum(importe) importe, sum(impant)impant, sum(unidades)unidades, sum(uniant)uniant
from
(Select  'TOT' cod_local,cod_rubr,
NVL(sum(importe),0) importe,0 impant, NVL(sum(cantidad),0) unidades, 0 uniant
From estadis.v_venta_plg
WHERE fch_ticket between To_date ('01-08-2006','dd-mm-yyyy') And To_date ('17-08-2006','dd-mm-yyyy')
And cod_rubr not in ('REG','DON')
and empresa= 5
group by cod_rubr
UNION
Select 'TOT' cod_local, cod_rubr,
0 importe ,NVL(sum(importe),0) impant ,0 unidades, NVL(sum(cantidad),0) uniant
From estadis.v_venta_plg
WHERE fch_ticket between To_date ('02-08-2005','dd-mm-yyyy') And To_date ('18-08-2005','dd-mm-yyyy')
And cod_rubr not in ('REG','DON')
and empresa= 5
group by  cod_rubr
)
group by cod_local,cod_rubr

UNION

select cod_local,cod_rubr,
sum(importe) importe, sum(impant)impant, sum(unidades)unidades, sum(uniant)uniant
from
(Select  cod_local,cod_rubr,
NVL(sum(importe),0) importe,0 impant, NVL(sum(cantidad),0) unidades, 0 uniant
From estadis.v_venta_plg
WHERE fch_ticket between To_date ('01-08-2006','dd-mm-yyyy') And To_date ('17-08-2006','dd-mm-yyyy')
And cod_rubr not in ('REG','DON')
and empresa= 5
group by cod_local,cod_rubr
UNION
Select cod_local, cod_rubr,
0 importe ,NVL(sum(importe),0) impant ,0 unidades, NVL(sum(cantidad),0) uniant
From estadis.v_venta_plg
WHERE fch_ticket between To_date ('02-08-2005','dd-mm-yyyy') And To_date ('18-08-2005','dd-mm-yyyy')
And cod_rubr not in ('REG','DON')
and empresa= 5
group by cod_local, cod_rubr
)
group by cod_local,cod_rubr

