select
fch_ticket
    ,decode(greatest(importe,35),35,' 0- 35'
    ,decode(greatest(importe,45),45,'35- 45'
    ,decode(greatest(importe,55),55,'45- 55'
    ,decode(greatest(importe,65),65,'55- 65'
    ,'>65')))) rango
,count(nro_ticket) cantidad
,SUM(IMPORTE)
from ventas.ticket_h
where
fch_ticket between '01/01/06' and '31/01/06'
and cod_depn = 'EZE'
and tipo_oper <> 4
AND IMPORTE > 0
group by
fch_ticket
    ,decode(greatest(importe,35),35,' 0- 35'
    ,decode(greatest(importe,45),45,'35- 45'
    ,decode(greatest(importe,55),55,'45- 55'
    ,decode(greatest(importe,65),65,'55- 65'
    ,'>65'))))

