DECLARE
    cursor tick is
    select h.fch_ticket,h.cod_depn,d.cod_prod,d.cantidad,d.importe
    from ventas.ticket_d_MES d, ventas.ticket_h_MES h
    where h.fch_ticket BETWEEN '06/11/2006' AND '30/11/2006'
    and h.cod_depn = 'ARM'
    and h.fch_ticket = d.fch_ticket
    and h.cod_caja = d.cod_caja
    and h.nro_ticket = d.nro_ticket
    and h.cod_local = d.cod_local
    and h.cod_sloc = d.cod_sloc;
BEGIN

for a in tick loop
    ventas.ACUM_VENTAS_PRODUCTO(a.cod_depn,a.cod_prod, a.cantidad, a.fch_ticket, a.importe);
end loop;

END;

