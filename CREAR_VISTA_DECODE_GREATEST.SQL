CREATE OR REPLACE VIEW ESTADIS.V_RANGO_TICKET
( FCH_TICKET
, RANGO
, CANTIDAD
, IMPORTE
)
AS
select
fch_ticket
    ,decode(greatest(importe,35),35,' 0- 35'
    ,decode(greatest(importe,45),45,'35- 45'
    ,decode(greatest(importe,55),55,'45- 55'
    ,decode(greatest(importe,65),65,'55- 65'
    ,'>65')))) rango
,count(nro_ticket) cantidad
,SUM(IMPORTE)IMPORTE
from ventas.ticket_h
where
tipo_oper <> 4
AND IMPORTE > 0
group by
fch_ticket
    ,decode(greatest(importe,35),35,' 0- 35'
    ,decode(greatest(importe,45),45,'35- 45'
    ,decode(greatest(importe,55),55,'45- 55'
    ,decode(greatest(importe,65),65,'55- 65'
    ,'>65'))))
