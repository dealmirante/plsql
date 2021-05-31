select TIPO , sum(importe)importe
from
(select fch_ticket,cod_local,cod_prod,sum(cantidad)cantidad,sum(importe)importe,'Venta' TIPO
from ticket_d , BAIRES.LOCAL
where COD_LOCAL=COD_LOC AND cantidad <>0 AND COD_SDEP='CAR'
and fch_ticket between '20/02/06' and '23/02/06'
group by fch_ticket,cod_local,cod_prod
union
select fch_ticket,cod_local,cod_prod,sum(cantidad)cantidad,sum(importe)importe,
decode(tipo_descuento,20,'DutyPass',least(tipo_descuento,20),'Cliente','Promo')tipo
from ticket_d , BAIRES.LOCAL
where  COD_LOCAL=COD_LOC AND cantidad=0 AND COD_SDEP='CAR'
and fch_ticket between '20/02/06' and '23/02/06'
group by fch_ticket,cod_local,cod_prod,tipo_descuento
having sum(importe)<>0)
group by TIPO
