PROCEDURE         EJECUTAR_ACUM_MES    (fch in date )
   IS
   cierreAep number(12,2) ;
   cierreEze number(12,2) ;
   vtas      number(12,2) ;
   vtasAep   number(12,2) ;
   vtasEze   number(12,2) ;

   interesAep   number(12,2);
   interesEze   number(12,2);

   errores     number(4) ;
BEGIN
 -- execute immediate 'Alter session set sql_trace = TRUE';

BEGIN
--Generacion de vigencia
  baires.generarvigencias(fch+1);
  commit;
EXCEPTION
  WHEN OTHERS THEN
     ROLLBACK;
     baires.manejo_error('GENERAR VIGENCIAS',sqlcode  , sqlerrm , fch);
     commit;
END;



select decode(sum(importe_interes) ,null,0,sum(importe_interes)) into interesAep
from ventas.pagos_mes p, local l
where p.cod_local = l.cod_loc
and fch_ticket = fch  And cod_depn = 'AEP' ;

select decode(sum(importe_interes) ,null,0,sum(importe_interes)) into interesEze
from ventas.pagos_mes p, local l
where p.cod_local = l.cod_loc
and fch_ticket = fch  And cod_depn = 'EZE' ;

select decode(sum(importe) ,null,0,sum(importe)) into vtasAep
from ventas.ticket_h_mes
where fch_ticket = fch  And cod_depn = 'AEP' AND TIPO_OPER <>4;

select decode(sum(importe) ,null,0,sum(importe)) into vtasEze
from ventas.ticket_h_mes
where fch_ticket = fch  And cod_depn = 'EZE' AND TIPO_OPER <>4;

begin
  select total - nvl(ajuste,0) total into cierreAep
  from ventas.cierres_general
  where fch_cierre = fch And cod_depn = 'AEP';
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    baires.manejo_error('EJEC_ACUM_MES',0  , 'No están los cierres Aeroparque', fch);
    commit;
    cierreAep:=-100;
end;

begin
  select total- nvl(ajuste,0) total into cierreEze
  from ventas.cierres_general
  where fch_cierre = fch And cod_depn = 'EZE';
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    baires.manejo_error('EJEC_ACUM_MES',0  , 'No están los cierres Ezeiza', fch);
    commit;
    cierreEze:=-100;
end;

select nvl(count(*),0) into errores
from ventas.log_excep
where fecha = fch and cod_depn in ('EZE','AEP') and tipo_ticket = 1 and nro_err not in (1) ;

if errores = 0 then

  --dbms_output.put_line ('EZE:' || to_char(cierreEze) || to_char (vtasEZE) || ' AEP:' || to_char(cierreAep)|| to_char (vtasAEP) );
  if abs (vtasEze - (cierreEze-interesEze)) < 150 and abs(vtasAep - (cierreAep-interesAep)) < 150 then

    --dbms_output.put_line ('estan todos los cierres');
    begin  -- Acumulados
       procesos_estadisticos_mes.Acumulado_por_ProdLocGrup_mes ( fch );
       procesos_estadisticos_mes.Acumulado_por_LocGrup_mes ( fch);
       procesos_estadisticos_mes.Acumulado_por_PAGOS_mes ( fch);
       procesos_estadisticos_mes.Pax_por_Espigon_mes ( fch);
       procesos_estadisticos_mes.Pax_por_Local_mes ( fch);
       procesos_estadisticos_mes.Pax_por_Grupo_mes ( fch);
       procesos_estadisticos_mes.Acumular_Descuentos_IB (fch,'EZE','INTA');
       procesos_estadisticos_mes.Acumular_Descuentos_IB (fch,'EZE','INTB');
       procesos_estadisticos_mes.Acumular_Descuentos_IB (fch,'AEP','AEP');
       procesos_estadisticos_mes.Acumulado_por_MONEDA_mes (fch) ;
       procesos_estadisticos_por_depn.VENTAS_NACES_ACUM(FCH,'EZE','INTA');
       procesos_estadisticos_por_depn.VENTAS_NACES_ACUM(FCH,'EZE','INTB');
       procesos_estadisticos_por_depn.VENTAS_NACES_ACUM(FCH,'AEP','AEP');
       procesos_estadisticos_por_depn.Acumula_ventas_rnc_mes ('INTA',fch);
       procesos_estadisticos_por_depn.Acumula_ventas_rnc_mes ('INTB',fch);
       procesos_estadisticos_por_depn.Acumula_ventas_rnc_mes ('AEP',fch);
       procesos_estadisticos_por_depn.Acumula_Puntos (fch , 'INTA');
       procesos_estadisticos_por_depn.Acumula_Puntos (fch , 'INTB');
       procesos_estadisticos_por_depn.Acumula_Puntos (fch , 'AEP');
       procesos_estadisticos_por_depn.ACUMULA_VENTAS_SECTOR (fch,'EZE','INTA') ;
       procesos_estadisticos_por_depn.ACUMULA_VENTAS_SECTOR (fch,'EZE','INTB') ;

       procesos_estadisticos_mes.Actualiza_puntos_mes ( fch ) ;

       --Acumulados por vendedor-----------------------------
       delete from estadis.venta_lpv
       where fch_ticket = fch
       and cod_local in (select cod_loc from baires.local where cod_depn in ('EZE','AEP')) ;

       insert into venta_lpv (fch_ticket,vendedor,cod_local,cod_prod,cantidad,importe)
       select fch_ticket,nvl(vendedor,0) v,cod_local,cod_prod,sum(cantidad),sum(importe)
       from ventas.ticket_d_mes
       where fch_ticket = fch
       and cod_local in (select cod_loc from baires.local where cod_depn in ('EZE','AEP'))
       group by fch_ticket,vendedor,cod_local,cod_prod ;
       ------------------------------------------------------

--       procesos_estadisticos_mes.Actualiza_puntos_mes ( fch ) ;

        commit;
    exception
        when others then
         rollback;
         baires.manejo_error('Acumulados',sqlcode  , sqlerrm , fch);
         commit;
         raise_application_error(-20001,'Error, Imposible Continuar:Revisar tabla Baires.Log_procesos');
    end;

    Begin  -- Pase de Tickets
        delete FROM ventas.pagos WHERE FCH_TICKET = fch;
        delete FROM ventas.pago_tarjeta WHERE FCH_TICKET = fch;
        delete FROM ventas.TICKET_D WHERE FCH_TICKET = fch;
        delete from ventas.TICKET_H WHERE FCH_TICKET = fch;
        delete from ventas.TICKET_puntos WHERE FCH_TICKET = fch;

        INSERT INTO ventas.TICKET_H
        SELECT * FROM ventas.TICKET_H_mes WHERE FCH_TICKET = fch;
        INSERT INTO ventas.TICKET_D
        SELECT * FROM ventas.TICKET_D_MES WHERE FCH_TICKET = fch;
        INSERT INTO ventas.TICKET_puntos
        SELECT * FROM ventas.TICKET_puntos_MES WHERE FCH_TICKET = fch;


        INSERT INTO ventas.pagos
        SELECT * FROM ventas.pagos_MES WHERE FCH_TICKET = fch;
        INSERT INTO ventas.pago_tarjeta
        SELECT * FROM ventas.pago_tarjeta_MES WHERE FCH_TICKET = fch;

        commit;
    Exception
       when others then
         rollback;
         baires.manejo_error('Pase de Tickets',sqlcode  , sqlerrm , fch);
         commit;
    End;

    --   VENTAS.pack_ventas_a.insertar_controles('AEP',FCH);
    --   VENTAS.pack_ventas_a.insertar_controles('EZE',FCH);


    Begin
      procesos_estadisticos_por_depn.Acumula_Recaudaciones_DEPN_mes ( 'EZE',fch );
      procesos_estadisticos_por_depn.Acumula_Recaudaciones_DEPN_mes ( 'AEP',fch );
      commit;
    exception
       when others then
         rollback;
         baires.manejo_error('Procesos Recaudacion',sqlcode  , sqlerrm , fch);
         commit;
    End;
    Begin
        procesos_estadisticos_por_depn.Acumula_ventas_sap_DEPN_mes ('EZE',fch);
        procesos_estadisticos_por_depn.Acumula_ventas_sap_DEPN_mes ('AEP',fch);
      commit;
    exception
       when others then
         rollback;
         baires.manejo_error('Procesos Interface SAP',sqlcode  , sqlerrm , fch);
         commit;
    End;

    Begin
      procesos_estadisticos_por_depn.Actualiza_DC (fch,'EZE', '+') ;
      procesos_estadisticos_por_depn.Actualiza_DC (fch,'AEP', '+') ;

      procesos_estadisticos_por_depn.Actualiza_Descuentos_tecla (FCH, 'EZE','INTA');
      procesos_estadisticos_por_depn.Actualiza_Descuentos_tecla (FCH, 'EZE','INTB');
      procesos_estadisticos_por_depn.Actualiza_Descuentos_tecla (FCH, 'AEP','AEP');

      procesos_estadisticos_por_depn.EJECUTAR_COMBINATORIA( FCH ,'AEP');
      procesos_estadisticos_por_depn.EJECUTAR_COMBINATORIA( FCH ,'EZE');
      procesos_estadisticos_por_depn.EJECUTAR_COMBINATORIA( FCH ,'INT');

      commit;
    exception
       when others then
         rollback;
         baires.manejo_error('Procesos DC ',sqlcode  , sqlerrm , fch);
         commit;
    End;

    --fin  Compradas/Consignadas

    select sum(importe) into vtas from venta_plg where fch_ticket = fch and cod_depn <> 'INT';

    if abs (vtas - (vtasAep+vtasEze)) <1 then
         begin
             ejecutar_act_stock (fch) ;                               -- Actualizacion de Stock MIT
             commit;
         exception
             when others then
             rollback;
             baires.manejo_error('Procesos de Stock',sqlcode  , sqlerrm , fch);
             commit;
             raise_application_error(-20001, 'Error en proceso de Stock');
         end;
    else
         rollback;
         baires.manejo_error('Procesos Compra',0  ,'Los Datos de cierre no coinciden con las ventas', fch);
         commit;
         raise_application_error(-20001, 'Los Datos de cierre no coinciden con las ventas');
    end if;

    begin
       /*procesos_estadisticos_por_depn.Acumula_Monitoreo_mes (fch,'EZE','INTB');
       procesos_estadisticos_por_depn.Acumula_Monitoreo_mes (fch,'EZE','INTAL');
       procesos_estadisticos_por_depn.Acumula_Monitoreo_mes (fch,'EZE','INTAS');
       procesos_estadisticos_por_depn.Acumula_Monitoreo_mes (fch,'AEP','AEP');*/

       --commit;
       avisos ;

        --Procedimientos para la web
        --Con dos guiones "--" se comenta la linea para que no se ejecute
        baires.actualizar_catalogo_web ;
        procesos_estadisticos_mes.INDICADORES_TIPO_NAC_WEBDB;
        procesos_estadisticos_mes.INDICADORES_WEBDB_DIA (fch) ;
        --procesos_estadisticos_mes.ACTUALIZA_PROD_PROV;
        --procesos_estadisticos_mes.INDICADORES_WEBDB ;
       --fin web
       NULL;
    exception
           when others then
             rollback;
             baires.manejo_error('Procesos WEB',sqlcode  ,sqlerrm, fch);
             commit;
    end;
    baires.manejo_error('EJEC_ACUM_MES ', 100  ,'Fin de Ejecucion de ESTADIS.EJECUTAR_CUM_MES', fch);
    commit;

  else
     baires.manejo_error('AJEC_ACUM_MES',0 ,'Los Datos de cierre no coinciden con los Tickets', fch);
     commit;
     raise_application_error(-20001, 'Los Datos de cierre no coinciden con los Tickets');
  end if;
else
     baires.manejo_error('AJEC_ACUM_MES',0 ,'Hay Errores Pendientes', fch);
     commit;
     raise_application_error(-20004, 'Hay Errores Pendientes');
end if;
     PCK_MAIL_ERROR ( fch ) ;
EXCEPTION
WHEN NO_DATA_FOUND THEN
    baires.manejo_error('AJEC_ACUM_MES',0 ,'No se encontraron datos', fch);
    commit;
    raise_application_error(-20001, 'No se encontraron datos');
END; -- Procedure
