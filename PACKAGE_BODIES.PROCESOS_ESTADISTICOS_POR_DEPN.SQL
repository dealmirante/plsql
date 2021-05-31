PACKAGE BODY         PROCESOS_ESTADISTICOS_POR_DEPN
IS

 Procedure  Actualiza_Descuentos_tecla (fch in date, Depn in varchar2, Sdep in varchar2)
 is

 FCH_ANT DATE ;

 Begin

    Delete From ESTADIS.VENTA_PROMOCION_TECLA
    where aniomes = to_char(fch,'yyyymm')
    and cod_depn = DEPN
    and cod_sdep = SDEP ;

      insert into ESTADIS.VENTA_PROMOCION_TECLA
    ( ANIOMES, COD_DEPN, COD_SDEP, COD_LOCAL,
      COD_RUBR, COD_SRUB, COD_FAMILIA, COD_PROV,  COD_MARCA,
      TIPO_DESCUENTO, COD_PROD, CANTIDAD, IMPORTE)
     SELECT
      TO_CHAR(fch_ticket,'YYYYMM')
     ,COD_DEPN,COD_SDEP,COD_LOCAL
     ,p.cod_rubr,cod_srub,p.cod_familia,p.cod_prov,cod_marca
     ,substr(tipo_descuento,1,1),p.cod_prod,count(*), sum(IMPORTE)
     FROM  ventas.ticket_d c ,producto p, baires.local l
     where fch_ticket between estadis.first_day(fch) and fch
     and p.cod_prod = c.cod_prod
     and ltrim(tipo_descuento) is not null
     and cod_local = cod_loc
     and cod_depn = DEPN
     and cod_sdep = SDEP
     group by    TO_CHAR(fch_ticket,'YYYYMM') ,COD_DEPN,COD_SDEP,COD_LOCAL
     ,p.cod_prod,p.cod_rubr,cod_srub,cod_familia,p.cod_prov,cod_marca,substr(tipo_descuento,1,1);

    FCH_ANT := TO_CHAR(FCH,'DD/MM/')|| TO_CHAR(TO_CHAR(FCH,'YYYY')-1)   ;

    Delete From ESTADIS.VENTA_PROMOCION_TECLA_ANTERIOR
    where aniomes = to_char(fch_ANT,'yyyymm')
    and cod_depn = DEPN
    and cod_sdep = SDEP ;

    insert into ESTADIS.VENTA_PROMOCION_TECLA_ANTERIOR
    ( ANIOMES, COD_DEPN, COD_SDEP, COD_LOCAL,
      COD_RUBR, COD_SRUB, COD_FAMILIA, COD_PROV,  COD_MARCA,
      TIPO_DESCUENTO, COD_PROD, CANTIDAD, IMPORTE)
     SELECT
      TO_CHAR(fch_ticket,'YYYYMM')
     ,COD_DEPN,COD_SDEP,COD_LOCAL
     ,p.cod_rubr,cod_srub,p.cod_familia,p.cod_prov,cod_marca
     ,substr(tipo_descuento,1,1),p.cod_prod,count(*), sum(IMPORTE)
     FROM  ventas.ticket_d c ,producto p, baires.local l
     where fch_ticket between estadis.first_day(fch_ANT) and fch_ANT
     and p.cod_prod = c.cod_prod
     and ltrim(tipo_descuento) is not null
     and cod_local = cod_loc
     and cod_depn = DEPN
     and cod_sdep = SDEP
     group by    TO_CHAR(fch_ticket,'YYYYMM') ,COD_DEPN,COD_SDEP,COD_LOCAL
     ,p.cod_prod,p.cod_rubr,cod_srub,cod_familia,p.cod_prov,cod_marca,substr(tipo_descuento,1,1);

 end;


 Procedure    EJECUTAR_ACT_STOCK_DEP
      ( pFecha  IN date
       ,pDepn   IN venta_PLG.cod_depn%type
       ,pSdep   IN venta_PLG.cod_sdep%type
       ,pLocal  IN venta_plg.cod_local%type )
    IS
      Cursor Local_Producto is
      select cod_local,cod_prod,sum(cantidad) Cantidad
      from
          venta_plg
      where
          fch_ticket = pFecha
          and cod_depn = pDepn
          and cod_sdep = pSdep
--        and cod_local = decode(length(rtrim(pLocal)),null,cod_local,pLocal)
          and nvl(cod_local,' ') = decode(length(rtrim(pLocal)),null,nvl(cod_local,' '),pLocal)
      group by
          cod_local,cod_prod
      having sum(cantidad) <> 0 ;



/*

  Cursor  Vtas_prod_comprados is
               select cod_prod, sum(cantidad) cantidad from estadis.compra_plg
                where
                    fch_ticket = pFecha and
                    cod_depn =  pDepn and
                    cod_sdep = pSdep and
                    nvl(cod_local,' ') = decode(length(rtrim(pLocal)),null,nvl(cod_local,' '),pLocal)
                group by
                     cod_prod
                having sum(cantidad) > 0;

*/


  cursor  Cur_probadores is
        select rowid id , cod_local, cod_prod, cantidad from
        ventas.ticket_tester where procesado is null and
        cod_depn =  pDepn and
        pSdep = pSdep and
        nvl(cod_local,' ') = decode(length(rtrim(pLocal)),null,nvl(cod_local,' '),pLocal) and
        tipo = 'P' for update of cantidad ;


      vStkCompra number;
      vProducto varchar2(10);
      vDeposito  number(3);
      vFchAct    date;
      vProcesado  varchar2(1);
      vLocal     baires.local.cod_loc%type;
    BEGIN
      begin
      -- Verifico la actualizacion del proceso Estadistico
         select
             prcesado into  vProcesado
         from
             control_procesos
         where
             cod_proceso='ES'   -- Proceso Estadistico
             and cod_depn = pDepn
             and cod_sdep = pSdep
             and nvl(cod_local,' ') = decode(length(rtrim(pLocal)),null,nvl(cod_local,' '),pLocal)
             and prcesado = 'S'
             and fecha = pFecha;

      exception
           when no_data_found then
            raise_application_error(-20001, 'Dependencia no Procesada en Estadistico');
      end;

      begin
         -- Verifico fechas de actualizacion de stock
         select
             prcesado into vProcesado
         from
             control_procesos
         where
             cod_proceso='SI'   -- Stock Interior
             and cod_depn = pDepn
             and cod_sdep = pSdep
             and nvl(cod_local,' ') = decode(length(rtrim(pLocal)),null,nvl(cod_local,' '),pLocal)
             and prcesado = 'S'
             and fecha = pFecha;

             raise_application_error(-20001, 'Stock ya actualizado para esta Fecha-Dependencia');

       exception
           when no_data_found then
                 -- Fecha no Actualizada para el Local
             null;
       end;



       for reg_stk in local_producto
       LOOP
            vLocal    := reg_stk.cod_local;
            vProducto := to_char(reg_stk.cod_prod);
            vDeposito := to_number(substr(reg_stk.cod_local,2,2));
            mit.K_PROCESO_STOCK.RESTAR_STOCK
            (1,vProducto,1,vDeposito,'X',100,1,reg_stk.cantidad);
            mit.K_PROCESO_STOCK.GENERO_MOVIMIENTO2(
            1,vProducto,1,1,reg_stk.cantidad,500,vDeposito,'X'
            ,100,vDeposito,'X',100,user,pFecha);
       END LOOP;


       For reg in Cur_Probadores
       loop
          vProducto := to_char(reg.cod_prod);
          vDeposito := to_number(substr(reg.cod_local,2,2));

          mit.K_PROCESO_STOCK.restar_STOCK
              (1,vProducto,1,vDeposito,'X',100,1,reg.cantidad);

          mit.K_PROCESO_STOCK.GENERO_MOVIMIENTO2(
              1,vProducto,1,1,reg.cantidad,500,vDeposito,'X'
              ,100,vDeposito,'X',100,user,pFecha);

          update ventas.ticket_tester set procesado = 'P' where
          rowid = reg.id;

       end loop;


       begin
           insert into control_procesos
             (fecha,cod_proceso,
             cod_depn,cod_sdep,cod_local,prcesado)
           values
             (pFecha,'SI',pDepn,pSdep,pLocal,'S');
       exception
           when others  then
               raise_application_error(-20001, 'Error al actualizar control Procesos');
       end;

--       commit;
-- Actualizo las Ventas en la Tabla Baires.Venta_mes
      acum_vta_mes_dep(pFecha,pDepn,pSdep,pLocal);
--      commit;

-- Ahora se carga la tabla  Baires.Stock_dia con el stock del MIT
-- con los estados 100,140,160 agrupado por deposito y código.
-- Esta tabla existe unicamente para consultas de Discoverer , y
-- Contiene el stock al cierre de día.

-- Primero la limpio
delete from  baires.stock_dia where cod_local  =  vLocal;

-- Ahora Cargo
begin
    Insert into baires.stock_dia
    (select
      cproducto cod_prod , s.tdepositored local ,sum(qcantidad) cantidad, sysdate fch_act
    from
      mit.sto_stock a,
      mit.sto_depositos s
    where
      a.cdeposito = s.cdeposito and
      a.cempresa = 1 and
      s.TDEPOSITORED = vLocal and
      a.cestado in (110,100,140,160)
   group by cproducto,s.tdepositored);
 exception
    when others then
      raise_application_error(-20001, 'Error al cargar la tabla baire.Stock_dia');
 end;

--commit;




END; -- Procedure

---------------------------------------------------

----------------------------------------
   PROCEDURE Acumulado_por_ProdLocGrup_mes ( fch IN venta_PLG.fch_ticket%type
                                           ,depn venta_PLG.cod_depn%type
                                           ,sdep venta_PLG.cod_sdep%type )
  IS
  BEGIN
    DELETE FROM VENTA_PLG
    WHERE fch_ticket = FCH AND
          cod_depn = depn and
          cod_sdep = sdep;

    -- Agregado para Ventas WEB
    DELETE FROM VENTAS_WEB.VENTA_PLG
    WHERE fch_ticket = FCH AND
          cod_depn = depn and
          cod_sdep = sdep;
    -- Fin Agregado



    INSERT INTO VENTA_PLG(
    fch_ticket,    grupo_venta,    cod_depn,    cod_sdep,    cod_local,
    cod_sloc,    cod_prod,    cod_rubr,    cod_srub,    cod_familia,
    cod_espc,    cod_prov,    cod_marca,    COMITENTE,    cantidad,    importe)
    (select
        H.fch_ticket,        H.grupo_venta,        H.cod_depn,        H.cod_sdep,
        H.cod_local,        H.cod_sloc,        D.cod_prod,        P.cod_rubr,
        P.cod_srub,        P.cod_familia,        P.cod_espc,        P.cod_prov,
        P.cod_marca,        PC.cod_comi,        sum(D.cantidad),        sum(D.importe)
   from
      ventas.ticket_h_mes H,ventas.ticket_D_mes D,
      baires.producto P,baires.prodcomi PC
   WHERE H.fch_ticket=D.fch_ticket AND
         H.cod_caja=D.cod_caja AND
         H.nro_ticket=D.nro_ticket AND
         H.cod_local=D.cod_LOCAL AND
         H.cod_sloc=D.cod_sloc AND
         H.fch_ticket = FCH and
         P.cod_prod = PC.cod_prod and
         P.cod_prod=d.cod_prod and
         h.cod_depn = depn and
         h.cod_sdep = sdep
    group by
        H.fch_ticket,H.grupo_venta,H.cod_depn,H.cod_sdep,H.cod_local,H.cod_sloc,D.cod_prod
        ,P.cod_prov,P.cod_marca,P.cod_rubr,P.cod_srub,P.cod_familia,P.cod_espc,PC.cod_comi
    );

    -- Agregado para Ventas WEB
   INSERT INTO ventas_web.VENTA_PLG(
    fch_ticket,    grupo_venta,    cod_depn,    cod_sdep,    cod_local,
    cod_sloc,    cod_prod,    cod_rubr,    cod_srub,    cod_familia,
    cod_espc,    cod_prov,    cod_marca,    COMITENTE,    cantidad,    importe)
   (select
    fch_ticket,    grupo_venta,    cod_depn,    cod_sdep,    cod_local,
    cod_sloc,    cod_prod,    cod_rubr,    cod_srub,    cod_familia,
    cod_espc,    cod_prov,    cod_marca,    COMITENTE,    cantidad,    importe
   from
      estadis.venta_plg
   where
       fch_ticket = FCH AND
       cod_depn = depn and
       cod_sdep = sdep );
   --  Fin Agregado
END;
-------------------------------------------------------------------
--------------------------------------------------------------------
-- PROCEDIMIENTO QUE ACUMULA LOS IMPORTES AGRUPADOS POR GRUPO-LOCAL
-- PARA UNA FECHA
--------------------------------------------------------------------
  PROCEDURE Acumulado_por_LocGrup_mes ( fch IN venta_PLG.fch_ticket%type
                                       ,depn venta_PLG.cod_depn%type
                                       ,sdep venta_PLG.cod_sdep%type )

  IS

  IOSC VARCHAR2(20) :='IOSCIBAIR';
  VarComi VARCHAR2(1);

  BEGIN
    DELETE FROM VENTA_LGI
    WHERE fch_ticket = FCH and
          cod_depn = depn and
          cod_sdep = sdep;

    INSERT INTO VENTA_LGI(
        fch_ticket,
        grupo_venta,
        cod_caja,
        cod_depn,
        cod_sdep,
        cod_local,
        cod_sloc,
        comitente,
        cantidad,
        importe)
            (select
            fch_ticket,
            grupo_venta,
            0,
            cod_depn,
            cod_sdep,
            cod_local,
            cod_sloc,
            'T',
--            count(nro_ticket),
            sum(decode(GREATEST(importe,0),0,0,1)),
            sum(importe)
            from ventas.ticket_h_mes
            where fch_ticket = fch AND TIPO_OPER <> 4
            and cod_depn = depn and
            cod_sdep = sdep
            group by fch_ticket,grupo_venta,cod_depn,cod_sdep,cod_local,cod_sloc
            );
-- no totales
            INSERT INTO VENTA_LGI(
                fch_ticket,
                grupo_venta,
                cod_caja,
                cod_depn,
                cod_sdep,
                cod_local,
                cod_sloc,
                comitente,
                cantidad,
                importe)
(    select H.fch_ticket,
            H.grupo_venta,
            H.cod_caja,
            H.cod_depn,
            H.cod_sdep,
            H.cod_local,
            H.cod_sloc,
            NVL(P.cod_comi,' ' ) ,
--            count(distinct(H.nro_ticket)) cant,
            0,
            sum(D.importe) imp
            from
            ventas.ticket_h_mes H,ventas.ticket_D_mes D,baires.prodcomi P
            WHERE
            H.fch_ticket=D.fch_ticket AND
            H.cod_caja=D.cod_caja AND
            H.nro_ticket=D.nro_ticket AND
            H.cod_local=D.cod_LOCAL AND
            H.cod_sloc=D.cod_sloc AND
            P.cod_prod(+)= D.cod_prod and
            H.TIPO_OPER <> 4 AND
            H.fch_ticket = fch and
            H.importe <> 0 and
            h.cod_depn = depn and
            h.cod_sdep = sdep
            group by
            H.fch_ticket,H.grupo_venta,H.cod_depn,H.cod_sdep,H.cod_local,H.cod_sloc,P.cod_comi,H.cod_caja );

    END;



--------------------------------------------------------------------
-- PROCEDIMIENTO QUE CALCULA LOS PASAJEROS ATENDIDOS POR ESPIGON
-- PARA UNA FECHA
--------------------------------------------------------------------
  PROCEDURE Pax_por_Espigon_mes ( fch IN venta_PLG.fch_ticket%type
                                ,depn venta_PLG.cod_depn%type
                                ,sdep venta_PLG.cod_sdep%type )

  IS
  cursor dif_pax_esp
  --(fch  pax_espigon.fch_vta%type )
  --                   ,depn venta_PLG.cod_depn%type
  --                   ,sdep venta_PLG.cod_sdep%type );
  is
  SELECT FCH_TICKET,nro_pax,cod_cia_aerea,
  cod_vuelo,cod_depn,cod_sdep,cod_nac
  FROM VENTAS.TICKET_H_MES
  WHERE FCH_TICKET = fch
        and  IMPORTE <= 0
        AND COD_DEPN = DEPN
        AND COD_SDEP = SDEP

  MINUS
  SELECT FCH_TICKET,nro_pax,cod_cia_aerea,
  cod_vuelo,cod_depn,cod_sdep,cod_nac
  FROM VENTAS.TICKET_H_MES
  WHERE FCH_TICKET = fch
        AND IMPORTE > 0
        AND COD_DEPN = DEPN
        AND COD_SDEP = SDEP;

  reg_dif_pax_esp dif_pax_esp%rowtype;

  BEGIN
    DELETE FROM PAX_ESPIGON
    WHERE fch_vta = FCH AND
          COD_DEPN = DEPN AND
          COD_SDEP = SDEP;
    INSERT INTO PAX_ESPIGON(
      fch_vta,
      cod_cia_aerea,
      cod_vuelo,
      cod_depn,
      cod_sdep,
      nacionalidad ,
      IMPORTE,
      cant_tickets ,
      cant_pax )
      (select
        fch_ticket,
        cod_cia_aerea,
        cod_vuelo,
        cod_depn,
        cod_sdep,
        cod_nac,
        sum(importe),
        SUM(DECODE(GREATEST(IMPORTE,0),0,0,1)),
        count(distinct(nro_pax))
        from ventas.ticket_h_mes
        where fch_ticket=fch and
              tipo_oper<>4 AND
              COD_DEPN = DEPN AND
              COD_SDEP = SDEP
        group by fch_ticket,cod_cia_aerea,cod_vuelo,cod_depn,cod_sdep,cod_nac);

        open dif_pax_esp;

        fetch dif_pax_esp into  reg_dif_pax_esp;
        while dif_pax_esp%found loop

            update pax_espigon set
            cant_pax=cant_pax-1
            where
            fch_vta = reg_dif_pax_esp.fch_ticket and
            cod_cia_aerea=reg_dif_pax_esp.cod_cia_aerea and
            cod_vuelo=reg_dif_pax_esp.cod_vuelo and
            cod_depn=reg_dif_pax_esp.cod_depn and
            cod_sdep=reg_dif_pax_esp.cod_sdep and
            nacionalidad=reg_dif_pax_esp.cod_nac ;
--            cod_local=reg_ticket_neg.cod_local and
--            cod_sloc=reg_ticket_neg.cod_sloc and ;
--
            fetch dif_pax_esp into  reg_dif_pax_esp;
        end loop;
        close dif_pax_esp;


   END ;

--------------------------------------------------------------------
-- PROCEDIMIENTO QUE CALCULA LOS PASAJEROS ATENDIDOS POR LOCAL
-- PARA UNA FECHA
--------------------------------------------------------------------
  PROCEDURE Pax_por_Local_mes ( fch IN venta_PLG.fch_ticket%type
                                ,depn venta_PLG.cod_depn%type
                                ,sdep venta_PLG.cod_sdep%type )
  IS

  cursor dif_pax_loc ----(fch  pax_local.fch_vta%type )
  is
  SELECT FCH_TICKET,nro_pax,cod_cia_aerea,
  cod_vuelo,cod_depn,cod_sdep,cod_nac,cod_local,cod_sloc
  FROM VENTAS.TICKET_H_MES
  WHERE FCH_TICKET = fch
        and  IMPORTE <= 0
        AND COD_DEPN = DEPN
        AND COD_SDEP = SDEP

  MINUS
  SELECT FCH_TICKET,nro_pax,cod_cia_aerea,
  cod_vuelo,cod_depn,cod_sdep,cod_nac,cod_local,cod_sloc
  FROM VENTAS.TICKET_H_MES
  WHERE FCH_TICKET = fch
        AND IMPORTE > 0
        AND COD_DEPN = DEPN
        AND COD_SDEP = SDEP;

  reg_dif_pax_loc dif_pax_loc%rowtype;

  BEGIN
    DELETE FROM PAX_LOCAL
    WHERE fch_vta = FCH AND
          COD_DEPN = DEPN AND
          COD_SDEP = SDEP;
    INSERT INTO PAX_LOCAL(
      fch_vta,
      cod_cia_aerea,
      cod_vuelo,
      cod_depn,
      cod_sdep,
      cod_local,
      cod_sloc,
      nacionalidad ,
      importe,
      cant_tickets ,
      cant_pax )
      (select
        fch_ticket,
        cod_cia_aerea,
        cod_vuelo,
        cod_depn,
        cod_sdep,
        cod_local,
        cod_sloc,
        cod_nac,
        sum(importe),
        SUM(DECODE(GREATEST(IMPORTE,0),0,0,1)),
        count(distinct(nro_pax))
        from ventas.ticket_h_mes
        where fch_ticket=fch
              and tipo_oper<>4
              AND COD_DEPN = DEPN
              AND COD_SDEP = SDEP
        group by fch_ticket,cod_cia_aerea,cod_vuelo,cod_depn,cod_sdep,cod_local,cod_sloc,cod_nac);

        open dif_pax_loc; ----(fch);

        fetch dif_pax_loc into  reg_dif_pax_loc;
        while dif_pax_loc%found loop

            update pax_local set
            cant_pax=cant_pax-1
            where
            fch_vta = reg_dif_pax_loc.fch_ticket and
            cod_cia_aerea=reg_dif_pax_loc.cod_cia_aerea and
            cod_vuelo=reg_dif_pax_loc.cod_vuelo and
            cod_depn=reg_dif_pax_loc.cod_depn and
            cod_sdep=reg_dif_pax_loc.cod_sdep and
            nacionalidad=reg_dif_pax_loc.cod_nac and
            cod_local=reg_dif_pax_loc.cod_local and
            cod_sloc=reg_dif_pax_loc.cod_sloc ;

            fetch dif_pax_loc into  reg_dif_pax_loc;
        end loop;
        close dif_pax_loc;



   END ;

--------------------------------------------------------------------
-- PROCEDIMIENTO QUE CALCULA LOS PASAJEROS ATENDIDOS POR LOCAL-GRUPO
-- PARA UNA FECHA
--------------------------------------------------------------------
  PROCEDURE Pax_por_Grupo_mes ( fch IN venta_PLG.fch_ticket%type
                                ,depn venta_PLG.cod_depn%type
                                ,sdep venta_PLG.cod_sdep%type )
  IS
  cursor dif_pax_gr ----(fch  pax_grupo.fch_vta%type )
  is
  SELECT FCH_TICKET,nro_pax,cod_cia_aerea,
  cod_vuelo,cod_depn,cod_sdep,cod_nac,cod_local,cod_sloc,grupo_venta
  FROM VENTAS.TICKET_H_MES
  WHERE FCH_TICKET = fch
        and  IMPORTE <= 0
        AND COD_DEPN = DEPN
        AND COD_SDEP = SDEP
  MINUS
  SELECT FCH_TICKET,nro_pax,cod_cia_aerea,
  cod_vuelo,cod_depn,cod_sdep,cod_nac,cod_local,cod_sloc,grupo_venta
  FROM VENTAS.TICKET_H_MES
  WHERE FCH_TICKET = fch
        AND IMPORTE > 0
        AND COD_DEPN = DEPN
        AND COD_SDEP = SDEP ;

  reg_dif_pax_gr dif_pax_gr%rowtype;

  BEGIN
    DELETE FROM PAX_grupo
    WHERE fch_vta = FCH AND
          COD_DEPN = DEPN AND
          COD_SDEP = SDEP;
    INSERT INTO PAX_GRUPO(
      fch_vta,
      cod_cia_aerea,
      cod_vuelo,
      cod_depn,
      cod_sdep,
      cod_local,
      cod_sloc,
      grupo_venta,
      nacionalidad ,
      IMPORTE,
      cant_tickets ,
      cant_pax )
      (select
        fch_ticket,
        cod_cia_aerea,
        cod_vuelo,
        cod_depn,
        cod_sdep,
        cod_local,
        cod_sloc,
        grupo_venta,
        cod_nac,
        SUM(IMPORTE),
        SUM(DECODE(GREATEST(IMPORTE,0),0,0,1)),
        count(distinct(nro_pax))
        from ventas.ticket_h_mes
        where fch_ticket=fch
              and tipo_oper<>4
              AND COD_DEPN = DEPN
              AND COD_SDEP = SDEP
        group by fch_ticket,cod_cia_aerea,cod_vuelo,cod_depn,cod_sdep,cod_local,cod_sloc,grupo_venta,cod_nac);

        open dif_pax_gr; ---(fch);

        fetch dif_pax_gr into  reg_dif_pax_gr;
        while dif_pax_gr%found loop

            update pax_grupo set
            cant_pax=cant_pax-1
            where
            fch_vta = reg_dif_pax_gr.fch_ticket and
            cod_cia_aerea=reg_dif_pax_gr.cod_cia_aerea and
            cod_vuelo=reg_dif_pax_gr.cod_vuelo and
            cod_depn=reg_dif_pax_gr.cod_depn and
            cod_sdep=reg_dif_pax_gr.cod_sdep and
            nacionalidad=reg_dif_pax_gr.cod_nac and
            cod_local=reg_dif_pax_gr.cod_local and
            grupo_venta=reg_dif_pax_gr.grupo_venta and
            cod_sloc=reg_dif_pax_gr.cod_sloc ;

            fetch dif_pax_gr into  reg_dif_pax_gr;
        end loop;
        close dif_pax_gr;

   END ;


-------------------------------------------------------------------
--------------------------------------------------------------------
-- PROCEDIMIENTO QUE ACUMULA LOS IMPORTES AGRUPADOS POR PAGOS-TARJETAS
-- PARA UNA FECHA
--------------------------------------------------------------------

  PROCEDURE Acumulado_por_PAGOS_mes ( fch IN venta_PLG.fch_ticket%type
                                    ,depn venta_PLG.cod_depn%type
                                    ,sdep venta_PLG.cod_sdep%type )
  IS
  cursor CUR_LPT is
  select
    P.fch_ticket,L.cod_depn, L.cod_sdep, L.cod_loc, L.cod_sloc
    ,decode(P.tipo_pago,2,99,P.TIPO_MONEDA) tipo_pago,
    NVL(PT.cod_tarjeta,0) cod_tarjeta ,
    count(P.nro_ticket) cant,
    sum(P.importe) imp
  from
    ventas.pago_tarjeta_mes PT
   ,ventas.pagos_mes P
   ,VENTAS.LOCAL_SUBLOCAL L
  WHERE
    L.COD_LOC = P.COD_LOCAL AND L.COD_SLOC = P.COD_SLOC AND
    PT.fch_ticket(+)=P.fch_ticket AND
    PT.cod_caja(+)=P.cod_caja AND
    PT.nro_ticket(+)=P.nro_ticket AND
    PT.cod_local(+)=P.cod_LOCAL AND
    PT.cod_sloc(+)=P.cod_sloc AND
    PT.NRO_SECUENCIA(+)=P.NRO_SECUENCIA AND
    P.fch_ticket = FCH
    and L.cod_DEPN = depn AND L.COD_SDEP = SDEP
  group by
    P.fch_ticket
    ,L.cod_depn,L.cod_sdep,L.cod_loc,L.cod_sloc,decode(P.tipo_pago,2,99,P.TIPO_MONEDA)
    ,PT.cod_tarjeta
  ORDER BY
      P.fch_ticket,L.cod_depn,L.cod_sdep,L.cod_loc,L.cod_sloc,decode(P.tipo_pago,2,99,P.TIPO_MONEDA)
    ,PT.cod_tarjeta ;


  BEGIN

    DELETE FROM pago_LPT
    WHERE fch_ticket = FCH AND cod_DEPN = depn AND COD_SDEP = SDEP ;

     FOR LPT IN CUR_LPT LOOP
        insert into pago_LPT(
               fch_ticket,
                cod_depn,
                cod_sdep,
                cod_local,
                cod_sloc,
                tipo_pago,
                cod_tarjeta,
                tar_descrip,
                cantidad,
                importe)
            values(
               LPT.fch_ticket,
               LPT.COD_Depn,
               LPT.COD_Sdep,
               LPT.COD_Loc,
               LPT.COD_sLoc,
               LPT.tipo_PAGO,
               LPT.COD_TARJETA,
               ' ' ,
               LPT.CANT,
               LPT.Imp);
        END LOOP;
  END ;
-------------------------------------------------------------------
--------------------------------------------------------------------
-- PROCEDIMIENTO QUE ACUMULA LOS IMPORTES EN DISTINTAS MONEDAS Y
-- TARJETAS AGRUPADOS POR TIPO DE LOCAL-NACIONALIDAD
-- PARA UNA FECHA DADA
--------------------------------------------------------------------
  PROCEDURE Acumulado_por_MONEDA_DEPN_mes ( fch IN DATE )
  IS
   BEGIN
    DELETE FROM PAGO_MONEDA
    WHERE fch_ticket = FCH and cod_depn = 'INT';

    insert into pago_moneda
    (fch_ticket,tipo_pago,cod_depn,tipo_loc,cod_moneda, nacionalidad,importe )
    (Select t.fch_ticket,tipo_pago,t.cod_depn, tipo_loc,tipo_moneda,decode(cod_nac,1,'A','E') nac,sum(p.importe) importe
     from baires.local l, ventas.pagos_mes p, ventas.ticket_h_mes t
     Where l.cod_loc = t.cod_local AND t.fch_ticket = p.fch_ticket
     and t.nro_ticket= p.nro_ticket and t.cod_caja = p.cod_caja
     and t.cod_local = p.cod_local and t.cod_sloc=p.cod_sloc and tipo_pago = 1
     and t.cod_local <> 'L03' and t.fch_ticket = fch and t.cod_depn = 'INT'
     group by  t.fch_ticket,tipo_pago,t.cod_depn,tipo_loc,decode(cod_nac,1,'A','E'),tipo_moneda
     Union
     select t.fch_ticket,tipo_pago,t.cod_depn,tipo_loc ,cod_tarjeta ,decode(cod_nac,1,'A','E') nac,sum(p.importe) importe
     From baires.local l, ventas.pagos_mes p,ventas.pago_tarjeta_mes j, ventas.ticket_h_mes t
     Where l.cod_loc = t.cod_local And t.fch_ticket = P.fch_ticket
     and t.nro_ticket= p.nro_ticket and t.cod_caja = p.cod_caja
     and t.cod_local = p.cod_local and t.cod_sloc=p.cod_sloc
     AND j.fch_ticket = p.fch_ticket and j.nro_ticket= p.nro_ticket
     and j.cod_caja = p.cod_caja and j.cod_local = p.cod_local
     and j.cod_sloc=p.cod_sloc and j.nro_secuencia = p.nro_secuencia
     and tipo_pago = 2 and t.cod_local <> 'L03' and t.fch_ticket = fch
     and t.cod_depn = 'INT'
     group by  t.fch_ticket,tipo_pago,t.cod_depn,tipo_loc,decode(cod_nac,1,'A','E'),COD_TARJETA) ;
  END;
-------------------------------------------------------------------
-- PROCEDIMIENTO QUE PREPARA LOS DATOS PARA LAS VISTAS DE
-- VENTAS POR NACIONALIDAD
--
--------------------------------------------------------------------
Procedure         VENTAS_NACES_ACUM
   ( FCH_DESDE IN DATE,
     pDepn     IN varchar2,
     pSdep     IN varchar2)
   IS
CURSOR CUR_VOLAR IS
  (SELECT fch_vuelo,cod_depn,cod_sdep
   ,decode(local,'L05','L21','L06','L21',local) local
   ,nacionalidad,tipo,SUM(cantidad) cant
   FROM   ESTADIS.PAX_VOLADOS
   Where  fch_vuelo = fch_desde --and fch_hasta
   AND COD_DEPN = pDepn AND COD_SDEP = pSdep
   GROUP BY fch_vuelo,cod_depn,cod_sdep,decode(local,'L05','L21','L06','L21',local),nacionalidad,tipo);

BEGIN
   DELETE FROM ventas_NACES
   WHERE FECHA = FCH_DESDE --AND FCH_HASTA
   AND COD_DEPN = pDepn AND COD_SDEP = pSdep ;

   INSERT INTO ventas_NACES (
          FECHA,
          COD_DEPN,
          COD_SDEP,
          COD_LOCAL,
          TIPO,
          NAC,
          IMPORTE,
          CANT_TICKET,
          CANT_PAX_ATT,
          CANT_PAX_VOL)
   (SELECT  fch_vta,PL.cod_depn,PL.cod_sdep,PL.cod_local,LT.TRANCITO,DECODE(NACIONALIDAD,1,'N','E') NAC
            , sum(importe) imp ,  sum(cant_tickets) cant_t, sum(cant_pax) cant_p, 0
    FROM estadis.pax_local PL , ESTADIS.Local_Trancito  LT
    WHERE PL.Cod_depn = LT.Cod_depn  and PL.Cod_sdep = LT.cod_sdep
    and PL.COD_LOCAL=LT.COD_LOCAL  and TIPO_VUELO = 'PI'
    and fch_vta = FCH_DESDE --and FCH_HASTA
    and pl.cod_depn = pDepn and pl.cod_sdep = pSdep
    group by fch_vta,PL.cod_depn,PL.cod_sdep,PL.cod_local,LT.TRANCITO,LT.TIPO_VUELO,DECODE(NACIONALIDAD,1,'N','E'));

   INSERT INTO VENTAS_NACES (
   FECHA,
   COD_DEPN,
   COD_SDEP,
   COD_LOCAL,
   TIPO,
   NAC,
   IMPORTE,
   CANT_TICKET,
   CANT_PAX_ATT,
   CANT_PAX_VOL)
(SELECT  fch_vta,PL.cod_depn,  PL.cod_sdep,PL.cod_local,LT.TRANCITO,DECODE(NACIONALIDAD,1,'N','E') NAC
 , sum(importe) imp ,  sum(cant_tickets) cant_t, sum(cant_pax) cant_p,0
 FROM estadis.pax_local PL , ESTADIS.Local_Trancito  LT
 WHERE
 PL.Cod_depn = LT.Cod_depn  and PL.Cod_sdep = LT.cod_sdep
 and PL.COD_LOCAL=LT.COD_LOCAL  and TIPO_VUELO <> 'PI'
 and  decode(mod(pl.cod_vuelo,2),0,'S','L') = LT.TRANCITO
 and fch_vta = FCH_DESDE --and FCH_HASTA
 and pl.cod_depn = pDepn and pl.cod_sdep = pSdep
 group by fch_vta,PL.cod_depn,PL.cod_local,PL.cod_sdep,LT.TRANCITO,LT.TIPO_VUELO, mod(pl.cod_vuelo,2),DECODE(NACIONALIDAD,1,'N','E'));

 FOR VOLADOS IN CUR_VOLAR LOOP
    UPDATE VENTAS_NACES SET CANT_PAX_VOL = CANT_PAX_VOL + VOLADOS.CANT
    WHERE COD_DEPN = VOLADOS.COD_DEPN
      AND COD_SDEP = VOLADOS.COD_SDEP
      AND COD_LOCAL = VOLADOS.LOCAL
      AND TIPO     = VOLADOS.TIPO
      AND NAC      = VOLADOS.NACIONALIDAD
      AND FECHA    = VOLADOS.FCH_VUELO;

      If SQL%rowcount =  0 Then
        INSERT INTO ventas_NACES (FECHA,COD_DEPN, COD_SDEP, COD_LOCAL
        , TIPO, NAC, IMPORTE, CANT_TICKET,  CANT_PAX_ATT, CANT_PAX_VOL)
        values
        (VOLADOS.FCH_VUELO,VOLADOS.COD_DEPN,VOLADOS.COD_SDEP,VOLADOS.LOCAL
        ,VOLADOS.TIPO,VOLADOS.NACIONALIDAD,0,0,0,VOLADOS.CANT)     ;
      end if;
 END LOOP;

END; -- Procedure
--------------------------------------------------------------------
-- PROCEDIMIENTO QUE SEPARA LOS DATOS DE RECAUDACIONES DE TARJETA
-- DE CREDITO DEL DE RECAUDACIONES DE TARJETAS DE DEBITO
--
--------------------------------------------------------------------
  PROCEDURE Separa_Rec_Debito_DEPN_mes ( pDepen in Varchar2, pFecha IN DATE )
  is

   cursor cur_debitos  is
       select fch_ticket,cod_cajero,cod_tarjeta,sum(importe_MO) imp
       from ventas.view_ticket_pagos v, baires.local l
       --ventas.pago_tarjeta_mes
       where cod_loc = cod_local
       and fch_ticket = pFecha
       and tipo_pago = 2
       and decode(cod_Depn,'INT',cod_sdep,cod_depn) = pDepen
       AND COD_TARJETA IN (1,2)
       and substr(nro_cuenta,1,6)
       in (select numero_bin from ctc.bines_debitos)
       group by  fch_ticket,cod_cajero,cod_tarjeta;

    vZeta number(3) := 0;
    vCaja number(5) := 0;
begin
for debito in cur_debitos loop
begin
    vZeta := 0 ;
    update ESTADIS.RECAUDACIONES_D
      set  IMPORTE_ARC  = IMPORTE_ARC  - debito.imp
         , IMPORTE_ASIG = IMPORTE_ASIG - debito.imp
         , IMPORTE_REG  = IMPORTE_REG  - debito.imp
    where fch_ticket      = debito.fch_ticket
          and cod_cajero  = debito.cod_cajero
          and cod_moneda  = debito.cod_tarjeta
          and nro_zeta    = vZeta
          and tipo_pago   = 'T' ;

    if sql%rowcount = 0 then
       vZeta := 1 ;
       update ESTADIS.RECAUDACIONES_D
       set  IMPORTE_ARC  = IMPORTE_ARC  - debito.imp
          , IMPORTE_ASIG = IMPORTE_ASIG - debito.imp
          , IMPORTE_REG  = IMPORTE_REG  - debito.imp
       where fch_ticket      = debito.fch_ticket
             and cod_cajero  = debito.cod_cajero
             and cod_moneda  = debito.cod_tarjeta
             and nro_zeta    = vZeta
             and tipo_pago   = 'T' ;
    end if ;

         insert into ESTADIS.RECAUDACIONES_D
       (  FCH_TICKET,
          COD_CAJA,
          COD_CAJERO,
          TIPO_PAGO,
          COD_MONEDA,
          NRO_ZETA,
          IMPORTE_REG,
          IMPORTE_ARC,
          IMPORTE_ASIG,
          NRO_SEC)
         SELECT
            FCH_TICKET,
            COD_CAJA,
            COD_CAJERO,
            TIPO_PAGO,
            COD_MONEDA + 10,
            vZeta,
            debito.imp,
            debito.imp,
            debito.imp,
            NRO_SEC +1
         FROM ESTADIS.RECAUDACIONES_D
         where fch_ticket    = debito.fch_ticket
             and cod_cajero  = debito.cod_cajero
             and cod_moneda  = debito.cod_tarjeta
             and nro_zeta    = vZeta
             and tipo_pago   = 'T' ;

        if sql%rowcount = 0 Then
            Select cod_caja,nro_zeta
            Into  vCaja , vZeta
            FROM ESTADIS.RECAUDACIONES_h
            where fch_ticket = debito.fch_ticket
            and cod_cajero   = debito.cod_cajero
            AND ROWNUM = 1 ;

            dbms_output.put_line ('NO INSERTAR');

           insert into ESTADIS.RECAUDACIONES_D
           ( FCH_TICKET,
             COD_CAJA,
             COD_CAJERO,
             TIPO_PAGO,
             COD_MONEDA,
             NRO_ZETA,
             IMPORTE_REG,
             IMPORTE_ARC,
             IMPORTE_ASIG,
             NRO_SEC)
          values
          ( debito.fch_ticket,
            vCaja,
            debito.cod_cajero,
            'T',
            debito.cod_tarjeta+10,
            vZeta,
            debito.imp,
            debito.imp,
            debito.imp,
            1
          );

        end if;

    --dbms_output.put_line (debito.cod_cajero || ' ' || debito.imp ) ;

exception
when no_data_found then
    dbms_output.put_line (debito.cod_cajero || ' no datos'   ) ;
end;
end loop;
end;
--------------------------------------------------------------------
-- PROCEDIMIENTO QUE JUNTA LOS DATOS DE RECAUDACIONES POR CAJERO - FECHA
-- Y DEJA LOS DATOS LISTOS PARA SER MODIFICADO
--
--------------------------------------------------------------------
  PROCEDURE Acumula_Recaudaciones_DEPN_mes ( pDepen in Varchar2, pFecha IN DATE )
  is

vCotizacion number;
vimporteReg number;
vImporteArq number;
vZetaTarj boolean ;
vFecha date;
vCajero number;
vNro_Zeta number;
vIdZeta number;
vImpReg number;
vImpArq number;
vTipo  varchar2(1);


  cursor recaud is
-- Efectivo sin dolares decodificando las monedas Uruguayos, Reales y Euros
--    SELECT decode(h.cod_depn,'INT',cod_sdep,cod_depn) depen,D.fch_ticket,h.cod_caja,h.cod_cajero,d.nro_zeta,I.ID_ZETA,d.imp_registrado_mo imp_reg,imp_arqueado_mo imp_arq,'E' tipo
    SELECT decode(h.cod_depn,'INT',cod_sdep,cod_depn) depen,D.fch_ticket,h.cod_caja,h.cod_cajero,d.nro_zeta,
    I.cod_pago,
    decode(i.cod_pago,1,d.imp_registrado_mo
                    ,d.imp_registrado ) imp_reg,
    decode(i.cod_pago,1,d.imp_arqueado_mo
                    ,imp_arqueado ) imp_arq,
    'E' tipo
    FROM ventas.zeta_d  D,  VENTAS.IDENTIFICAR_PAGO I , ventas.ZETA_H H
    where h.fch_ticket = pFecha
    AND D.ID_PAGO = I.COD_PAGO
    AND D.ID_PAGO <> 0 AND I.TIPO_PAGO =1
    AND H.FCH_TICKET  = D.FCH_TICKET
    AND H.COD_CAJERO = D.COD_CAJERO -- AND H.COD_CAJERO
    and h.nro_zeta = d.nro_zeta
    and decode(h.cod_depn,'INT',cod_sdep,cod_depn)  = pDepen

  union
    -- Tarjeta
    SELECT decode(h.cod_depn,'INT',cod_sdep,cod_depn) depen,d.fch_ticket,h.cod_caja ,d.cod_cajero,d.nro_zeta,cod_pago,d.imp_registrado_mo imp_reg,  0 imp_arq , 'T' tipo
    FROM ventas.zeta_d_tarjeta d, VENTAS.IDENTIFICAR_PAGO I , ventas.zeta_h h
    where h.fch_ticket = pFecha
    AND D.ID_tarjeta = I.COD_PAGO
    AND I.TIPO_PAGO =2
    and h.fch_ticket  = d.fch_ticket
    and h.cod_cajero = d.cod_cajero -- AND H.COD_CAJERO
    and h.nro_zeta  = d.nro_zeta
    and decode(h.cod_depn,'INT',cod_sdep,cod_depn)  = pDepen

  UNION
    -- Fondo
    SELECT decode(l.cod_depn,'INT',l.cod_sdep,l.cod_depn) depen,  fch_ticket,z.cod_caja,cod_cajero,nro_zeta_asociado nro_zeta,id_moneda id_zeta,sum(importe_mo) imp_reg,0 imp_arq,'F' tipo
    from   ventas.zeta_fondo z , ventas.local_caja l
    where fch_ticket  = pFecha
    and z.cod_caja = l.cod_caja
    and not (l.cod_caja < 90 and cod_depn =  'AEP')
    and decode(l.cod_depn,'INT',l.cod_sdep,l.cod_depn) = pDepen
    group by decode(l.cod_depn,'INT',l.cod_sdep,l.cod_depn)
    , fch_ticket,z.cod_caja,cod_cajero,nro_zeta_asociado ,id_moneda
  UNION
    -- Dolares
    SELECT decode(h.cod_depn,'INT',cod_sdep,cod_depn) depen,d.FCH_TICKET,cod_caja,d.COD_CAJERO,d.NRO_ZETA, 0 ID_ZETA ,imp_registrado imp_reg,IMP_ARQUEADO  imp_arq ,'T'
    FROM ventas.zeta_d  d, ventas. zeta_h h
    where h.fch_ticket = pFecha
    and id_pago = 0
    and h.fch_ticket  = d.fch_ticket
    and h.cod_cajero = d.cod_cajero -- AND H.COD_CAJERO  between 600 and 700
    and h.nro_zeta  = d.nro_zeta
    and decode(h.cod_depn,'INT',cod_sdep,cod_depn)  = pDepen

/*   UNION
    -- Completa con ceros para que no pinche el programa que lee los datos
    SELECT DISTINCT decode(h.cod_depn,'INT',cod_sdep,cod_depn) depen,d1.FCH_TICKET,h.cod_caja,d1.COD_CAJERO,d1.NRO_ZETA, 2 ID_ZETA ,0 imp_reg, 0 imp_arq ,'T'
    FROM ventas.zeta_d D1 , ventas.zeta_h h
    where h.fch_ticket = pFecha
    and h.fch_ticket  = d1.fch_ticket
    and h.cod_cajero = d1.cod_cajero --AND H.COD_CAJERO = 260
    and h.nro_zeta  = d1.nro_zeta
    and decode(h.cod_depn,'INT',cod_sdep,cod_depn)  = pDepen
    AND  NOT EXISTS
     (
         SELECT FCH_TICKET,COD_CAJERO,NRO_ZETA, 0 ID_ZETA ,0 imp_reg,IMP_ARQUEADO  imp_arq ,'T'
    FROM ventas.zeta_d DD
    where fch_ticket =  pFecha
    and id_pago = 0 AND
    D1.COD_CAJERO = DD.COD_CAJERO AND --dd.COD_CAJERO = 260 and
    D1.NRO_ZETA  = DD.NRO_ZETA  )*/
    ;

  vAuxCajero number := 0 ;
  vAuxCajA   number := 0 ;
  vAuxZeta   number := 0 ;

  pGr  varchar2 (1) ;
  pTur varchar2 (1) ;

  Cursor TG_cur is
  Select FCH_TICKET,DEPEN,COD_CAJA,COD_CAJERO
  From estadis.recaudaciones_h
  where fch_ticket = pFecha
  and grupo is null ;

  Cursor reparto_cur is
  select h.fch_ticket,h.cod_caja,h.cod_cajero,h.nro_zeta,cod_moneda,importe_arc
  from estadis.recaudaciones_d d, estadis.recaudaciones_h h
  where h.fch_ticket = pFecha
  and tipo_pago = 'T' and cod_moneda = 0
  and d.fch_ticket = h.fch_ticket
  and d.cod_caja   = h.cod_caja
  and d.cod_cajero = h.cod_cajero
  and d.nro_zeta   = h.nro_zeta
  and depen = pDepen
  --and cod_cajero = 160
  order by h.fch_ticket,h.cod_cajero,h.cod_caja,h.nro_zeta,cod_moneda ;

  Cursor rep_tarj_cur (Caja in number,Cajero in number,Zeta in number ) is
  select cod_moneda,importe_reg
  from estadis.recaudaciones_d
  where fch_ticket = pFecha
  and cod_caja = Caja
  and cod_cajero = Cajero
  and nro_zeta = Zeta
  and tipo_pago = 'T' and cod_moneda <> 0 ;

  pMon    number(3)    ;
  pImp    number(10,2) ;
  pTotCaj number(10,2) ;

BEGIN

   Delete from estadis.recaudaciones_h Where fch_ticket = pFecha And Depen = pDepen ;

   FOR REGI IN recaud
   loop
         if vAuxCajero  <> regi.cod_cajero OR vAuxCaja <> regi.cod_caja or vAuxZeta <> regi.nro_zeta then
			 vAuxCajero  := regi.cod_cajero;
			 vAuxCaja  := regi.cod_caja;
			 vAuxZeta  := regi.nro_zeta;
             --vCotizacion := ventas.Obtiene_cotizacion(regi.fch_ticket,vAuxCajero);
             vCotizacion := ventas.Obt_cotizacion_FECHA(1,regi.fch_ticket);
             Insert Into estadis.Recaudaciones_h
             (FCH_TICKET,DEPEN,COD_CAJA,COD_CAJERO,nro_zeta)
              Values
             (regi.fch_ticket,pDepen,regi.cod_caja,regi.cod_cajero,regi.nro_zeta) ;

         end if;

         if (regi.tipo = 'T') or (regi.tipo = 'E' And regi.cod_pago not in (1,2,3,14) ) then
              vimporteReg := nvl(regi.imp_reg,0) * vCotizacion ;
              vImporteArq := nvl(regi.imp_arq,0)  *  vCotizacion ;
         else
              vimporteReg := nvl(regi.imp_reg,0) ;
              vImporteArq := nvl(regi.imp_arq,0) ;
         end if;
       DBMS_OUTPUT.PUT_LINE (TO_CHAR(regi.cod_cajero)) ;
       Insert Into estadis.Recaudaciones_d
       (FCH_TICKET,
        COD_CAJA,
        COD_CAJERO,
        TIPO_PAGO,
        COD_MONEDA,
        NRO_ZETA,
        IMPORTE_REG,
        IMPORTE_ARC,
        IMPORTE_ASIG,
        nro_sec)
        Values(regi.fch_ticket,
        regi.cod_caja,
        regi.cod_cajero,
        regi.Tipo,
        regi.cod_pago,
        regi.nro_zeta,
        vImporteReg,
        vImporteArq,
        vImporteArq,
        nro_recaudacion.nextval ) ;

       end loop;

   for TG in TG_cur loop
       begin
       Select distinct sub_grupo,decode(grupo_venta,'A','M','B','T','C','N')  into pGr, pTur
       From ventas.ticket_h_mes
       where fch_ticket = tg.fch_ticket and
       cod_caja = tg.cod_caja and
       cod_cajero = tg.cod_cajero and rownum = 1 ;
       Exception When No_data_Found Then
           dbms_output.put_line(to_char(tg.cod_cajero)) ;
       End ;

       Update estadis.recaudaciones_h set grupo = pGr , turno = pTur
       Where cod_cajero =  tg.cod_cajero And cod_caja = tg.cod_caja
       And fch_ticket = tg.fch_ticket ;

   end loop;
   --Reparto del arqueo de tarjetas en cada tipo
   For rep in reparto_cur loop

       open rep_tarj_cur (rep.cod_caja,rep.cod_cajero,rep.nro_zeta) ;
       fetch  rep_tarj_cur into pMon,pImp ;

       pTotCaj := rep.importe_arc ;
       While rep_tarj_cur%found loop
          pTotCaj := pTotCaj - pImp ;

          Update recaudaciones_d set importe_arc = pImp, importe_asig = pImp
          Where  fch_ticket = pfecha
          and cod_caja   = rep.cod_caja
          and cod_cajero = rep.cod_cajero
          and nro_zeta   = rep.nro_zeta
          and tipo_pago = 'T' and cod_moneda = pMon;

          fetch  rep_tarj_cur into pMon,pImp ;
       end loop;
          Update recaudaciones_d set importe_arc  = pTotCaj,importe_asig  = pTotCaj
          Where  fch_ticket = pfecha
          and cod_caja   = rep.cod_caja
          and cod_cajero = rep.cod_cajero
          and nro_zeta   = rep.nro_zeta
          and tipo_pago = 'T' and cod_moneda = 0 ;
       close rep_tarj_cur ;
   end loop ;

   Separa_Rec_Debito_DEPN_mes ( pDepen, pFecha  ) ;
 END;

-------------------------------------------------------------------
-------------------------------------------------------------------
--Funcion Auxiliar que me devuelve un signo
Function ImporteSigno (i in Number)
return varchar2 is
Begin

    if i > 0 Then
        return '+';
    elsif i < 0 Then
        return '-' ;
    else
        return  '+' ;
    end if;

end;


--------------------------------------------------------------------
-- PROCEDIMIENTO QUE PREPARA LOS DATOS PARA LA INTERFACE DE VENTAS
--
--
--------------------------------------------------------------------
  PROCEDURE Acumula_ventas_sap_DEPN_mes ( pDepn in Varchar2, pFecha IN DATE )
  is
-- SE MODIFICA POR GABRIELA 2 Y SE REPROCESA DESDE FEBRERO 07

cursor ticket_cur is
-- TIPO 4 --
         select h.Cod_depn,h.Cod_sdep,h.fch_ticket,h.nro_impresora, h.nro_factura_fiscal
        		,decode( greatest(h.cod_cajero,10000),10000,h.cod_cajero,h.cod_cajero-10000) cod_cajero
        		,sum(h.importe) importe
        		,MAX(estadis.f_importe_pago(h.nro_ticket,h.fch_ticket,h.cod_caja,h.cod_local,h.cod_sloc,'T')) impInteres
        		,l.centro_costo
        		,h.datos_personales
          from   baires.local l,
                 ventas.ticket_h_mes h
         where   h.cod_local = l.cod_loc
           and   h.fch_ticket = pFecha
           and   decode(h.cod_depn,'INT',h.cod_sdep,h.cod_depn) = pDepn
           and   nro_impresora not in (0)
           and   h.tipo_oper = 4
      group by   h.fch_ticket,h.Cod_depn,h.Cod_sdep,nro_impresora, nro_factura_fiscal,
       decode( greatest(h.cod_cajero,10000),10000,h.cod_cajero,h.cod_cajero-10000),centro_costo,
       datos_personales
UNION ALL		-- NO Servicio --
		 select h.Cod_depn,h.Cod_sdep,h.fch_ticket,h.nro_impresora, h.nro_factura_fiscal
		       ,decode( greatest(h.cod_cajero,10000),10000,h.cod_cajero,h.cod_cajero-10000) cod_cajero
		       ,sum(d.importe) importe
		       ,max(estadis.f_importe_pago(h.nro_ticket,h.fch_ticket,h.cod_caja,h.cod_local,h.cod_sloc,'T')) impInteres
		       ,l.centro_costo
		       ,h.datos_personales
		   from	ventas.ticket_d_mes d ,
		   	    ventas.ticket_h_mes h ,
			    baires.producto p     ,
			    baires.local l
		  where h.nro_ticket = d.nro_ticket
		    and h.FCH_TICKET = d.FCH_TICKET
		    and h.COD_LOCAL  = d.COD_LOCAL
		    and h.COD_SLOC   = d.COD_SLOC
		    and h.COD_CAJA   = d.COD_CAJA
		    and h.cod_local  = l.cod_loc
		    and d.cod_prod   = p.cod_prod
		    and h.FCH_TICKET = pFecha
		    and p.COD_RUBR   <> 'SER'
		    and decode(h.cod_depn,'INT',h.cod_sdep,h.cod_depn) = pDepn
		    and nro_impresora not in (0)
	   group by h.fch_ticket,h.Cod_depn,h.Cod_sdep,nro_impresora, nro_factura_fiscal,decode( greatest(h.cod_cajero,10000),10000,h.cod_cajero,h.cod_cajero-10000),centro_costo,datos_personales
	   order by fch_ticket,Cod_depn,Cod_sdep,nro_impresora,nro_factura_fiscal ;


cursor ticket_serv is
		 -- Servicio --
		 select h.Cod_depn,h.Cod_sdep,h.fch_ticket,h.nro_impresora, h.nro_factura_fiscal
		,decode( greatest(h.cod_cajero,10000),10000,h.cod_cajero,h.cod_cajero-10000) cod_cajero
		,sum(d.importe) importe
		,sum(estadis.f_importe_pago(h.nro_ticket,h.fch_ticket,h.cod_caja,h.cod_local,h.cod_sloc,'T')) impInteres
		,l.centro_costo
		,h.datos_personales
		--, p.COD_RUBR
		--, d.COD_PROD
		from
			ventas.ticket_d_mes d ,
			ventas.ticket_h_mes h ,
			baires.producto p     ,
			baires.local l
		where h.nro_ticket = d.nro_ticket
		  and h.FCH_TICKET = d.FCH_TICKET
		  and h.COD_LOCAL  = d.COD_LOCAL
		  and h.COD_SLOC   = d.COD_SLOC
		  and h.COD_CAJA   = d.COD_CAJA
		  and h.cod_local  = l.cod_loc
		  and d.cod_prod   = p.cod_prod
		  and h.FCH_TICKET  = pFecha
		  and p.COD_RUBR   = 'SER'
		  and decode(h.cod_depn,'INT',h.cod_sdep,h.cod_depn) = pDepn
		  and nro_impresora not in (0)
		group by h.fch_ticket,h.Cod_depn,h.Cod_sdep,nro_impresora, nro_factura_fiscal,decode( greatest(h.cod_cajero,10000),10000,h.cod_cajero,h.cod_cajero-10000),centro_costo,datos_personales
		-- , p.COD_RUBR--, d.COD_PROD
		order by h.fch_ticket,h.Cod_depn,h.Cod_sdep,nro_impresora,nro_factura_fiscal ;


NroTicket     number (10) := -1 ;
NroTicketINIC number (10) := -1 ;
Impresora     number (5) := -1 ;
Cajero        number (5) := -1 ;
Fecha         date ;
Importe       number(12,2) ;
ImpInt        number(12,2) ;
vImp          varchar2(2) ;
coddepn       varchar2(4) ;
codsdep       varchar2(5) ;
CC            number(5) ;
DP            varchar2(190);

signo    varchar2 (1) := '+' ;
signoAnt varchar2 (1) ;

filaVentas ticket_cur%rowtype ;
--filaServ   ticket_serv%rowtype ;

Begin

DELETE FROM estadis.interface_ventas_sap
WHERE FCH_TICKET = pFecha And
decode(depn,'INT',sdepn,depn) = pDepn ;

open Ticket_cur ;

fetch  ticket_cur into filaVentas ;
While ticket_cur%Found loop
    fecha := filaVentas.fch_ticket ;
    While fecha = filaVentas.fch_ticket Loop --loop fecha

         Impresora := filaVentas.nro_impresora ;
         While Impresora = filaVentas.nro_impresora And fecha = filaVentas.fch_ticket loop --loop Imp

              Cajero := filaVentas.cod_cajero ;
              While Cajero = filaVentas.cod_cajero And Impresora = filaVentas.nro_impresora  And fecha = filaVentas.fch_ticket loop --loop Cajero

                 signoAnt := signo ;
                 Importe := 0 ;
                 signo   :='+';


                 NroTicket := filaVentas.nro_factura_fiscal ;
                 NroTicketINIC := filaVentas.nro_factura_fiscal ;

                   Coddepn := filaVentas.Cod_Depn ;
                   Codsdep := filaVentas.Cod_sDep ;
                   CC      := filaVentas.Centro_costo ;

                    If filaVentas.importe = 0 then

                       Importe := 0 ;
                       signo   :='+';
                       impInt := 0 ;
                       vImp := null;
                       dp := null;


                       While filaVentas.importe = 0
                       and NroTicket = filaVentas.nro_factura_fiscal
                       and Cajero = filaVentas.cod_cajero
                       And Impresora = filaVentas.nro_impresora
                       And fecha = filaVentas.fch_ticket  loop

                           NroTicket := NroTicket + 1 ;
                           fetch  ticket_cur into filaVentas ;

                          if ticket_cur%notfound then
                            exit;
                          end if;

                       end loop;

                    ElsIf filaVentas.importe < 0 AND filaVentas.importe*ventas.obt_cotizacion_fecha(1,filaVentas.fch_ticket) > -1000 then
                       vImp := null ;
                       dp := null;
                       signo   :='-';

                       Importe := filaVentas.importe ;
                       impInt := filaVentas.impInteres ;
                       NroTicket := NroTicket + 1 ;
                       fetch  ticket_cur into filaVentas ;
                    ElsIf ABS(filaVentas.importe*ventas.obt_cotizacion_fecha(1,filaVentas.fch_ticket) ) >=1000 then
                       vImp := 'M';
                       if filaVentas.importe > 0 Then
                          signo   :='+';
                       else
                          signo   :='-';
                       end if;
                       Importe := filaVentas.importe ;
                       impInt := filaVentas.impInteres ;
                       NroTicket := NroTicket + 1 ;
                       dp := filaVentas.datos_personales ;
                       fetch  ticket_cur into filaVentas ;
                    Else
                       Importe := 0;
                       impInt := 0;
                       signo   :='+';
                       vImp := null ;
                       dp := null;
                       While filaVentas.importe > 0 and (filaventas.importe*ventas.obt_cotizacion_fecha(1,filaVentas.fch_ticket)) < 1000
                       and NroTicket = filaVentas.nro_factura_fiscal
                       and Cajero = filaVentas.cod_cajero
                       And Impresora = filaVentas.nro_impresora
                       And fecha = filaVentas.fch_ticket  loop


                           Importe := Importe + filaVentas.importe;
                           impInt  := ImpInt + filaVentas.impInteres ;
                           NroTicket := NroTicket + 1 ;
                           fetch  ticket_cur into filaVentas ;

                          if ticket_cur%notfound then
                            exit;
                          end if;

                       end loop;

                    end if;


                  --Buscar los datos de las facturas fiscales si los importes som mayores a 1000
                 If Importe = 0 Then

                  insert into estadis.interface_ventas_sap
                  (depn,sdepn,FCH_TICKET,NRO_IMPRESORA,FF_DESDE,FF_HASTA,CAJERO,IMPORTE,interes,tipo,centr_costo)
                  values
                  (Coddepn,Codsdep,filaVentas.fch_ticket,Impresora,nroticketINIC,nroticket-1,999,importe,0,'N',CC);
                 elsIf Importe <> 0 Then
                  insert into estadis.interface_ventas_sap
                  (depn,sdepn,FCH_TICKET,NRO_IMPRESORA,FF_DESDE,FF_HASTA,CAJERO,IMPORTE,interes,tipo,centr_costo,datos_pax)
                  values
                  (Coddepn,Codsdep,filaVentas.fch_ticket,Impresora,nroticketINIC,nroticket-1,cajero,importe,impInt,vImp,CC,dp);


                 end if;

                 if ticket_cur%notfound then
                    exit;
                 end if;


                 if filaVentas.nro_factura_fiscal > NroTicket
                 And Impresora = filaVentas.nro_impresora
                 And fecha = filaVentas.fch_ticket
                 And signo = estadis.ImporteSigno(filaVentas.importe)
                 Then
                     NroTicketINIC := nroticket ;
                     While NroTicket <> filaVentas.nro_factura_fiscal loop
                         NroTicket := NroTicket + 1 ;
                     end loop;
                    -- Si el salteo no es de un ticket de Servicios
                    if not f_ticket_servicio(filaVentas.fch_ticket,impresora, nroticket-1)  THEN
                        insert into estadis.interface_ventas_sap
                            (depn,sdepn,FCH_TICKET,NRO_IMPRESORA,FF_DESDE,FF_HASTA,CAJERO,IMPORTE,interes,tipo,centr_costo)
                        values
                            (coddepn,codsdep,filaVentas.fch_ticket,Impresora,nroticketINIC,nroticket-1,999,0,0,'N',CC);
                    end if;

                 End if;

              End loop; --loop Cajero
         if ticket_cur%notfound then
            exit;
         end if;
         End loop; --loop Imp

    if ticket_cur%notfound then
       exit;
    end if;
    End loop ; --loop fecha
end loop;

close ticket_cur ;
-------

delete from   estadis.interface_ventas_sap
where  fch_ticket = pFecha
and tipo in('N')
and abs(ff_desde - ff_hasta) > 500 ;
-------


for  r_servicio in  ticket_serv loop

	 begin

        insert into estadis.interface_ventas_sap
         (depn,sdepn,FCH_TICKET,NRO_IMPRESORA,FF_DESDE,FF_HASTA,CAJERO,IMPORTE,interes,tipo,centr_costo)
        values
         (r_servicio.Cod_Depn,r_servicio.Cod_sDep,r_servicio.fch_ticket,r_servicio.nro_impresora
		 ,r_servicio.nro_factura_fiscal,r_servicio.nro_factura_fiscal,r_servicio.cod_cajero
		 ,r_servicio.importe,r_servicio.impInteres,'S',CC);

	 end;

end loop;


/*

-- Este es el original
cursor ticket_cur is
select h.Cod_depn,h.Cod_sdep,h.fch_ticket,nro_impresora, nro_factura_fiscal
,decode( greatest(h.cod_cajero,10000),10000,h.cod_cajero,h.cod_cajero-10000) cod_cajero
,sum(importe) importe
,sum(estadis.f_importe_pago(h.nro_ticket,h.fch_ticket,h.cod_caja,h.cod_local,h.cod_sloc,'T')) impInteres
,centro_costo
,datos_personales
from
baires.local l,
ventas.ticket_h_mes h
where
h.cod_local = l.cod_loc
and h.fch_ticket = pFecha
and decode(h.cod_depn,'INT',h.cod_sdep,h.cod_depn) = pDepn
--and cod_cajero = 341
--and nro_impresora in (157,178,238,246,184,196,245,55,50,49,53,52,237,256)
--and nro_impresora = 52
and nro_impresora not in (0)
--and importe >= 1000
group by h.fch_ticket,h.Cod_depn,h.Cod_sdep,nro_impresora, nro_factura_fiscal,decode( greatest(h.cod_cajero,10000),10000,h.cod_cajero,h.cod_cajero-10000),centro_costo,datos_personales
order by h.fch_ticket,h.Cod_depn,h.Cod_sdep,nro_impresora,nro_factura_fiscal ;

NroTicket     number (10) := -1 ;
NroTicketINIC number (10) := -1 ;
Impresora     number (5) := -1 ;
Cajero        number (5) := -1 ;
Fecha         date ;
Importe       number(12,2) ;
ImpInt        number(12,2) ;
vImp          varchar2(2) ;
coddepn       varchar2(4) ;
codsdep       varchar2(5) ;
CC            number(5) ;
DP            varchar2(190);

signo    varchar2 (1) := '+' ;
signoAnt varchar2 (1) ;

filaVentas ticket_cur%rowtype ;

Begin

DELETE FROM estadis.interface_ventas_sap
WHERE FCH_TICKET = pFecha And
decode(depn,'INT',sdepn,depn) = pDepn ;

open Ticket_cur ;

fetch  ticket_cur into filaVentas ;
While ticket_cur%Found loop
    fecha := filaVentas.fch_ticket ;
    While fecha = filaVentas.fch_ticket Loop --loop fecha

         Impresora := filaVentas.nro_impresora ;
         While Impresora = filaVentas.nro_impresora
         And fecha = filaVentas.fch_ticket
         loop --loop Imp

              Cajero := filaVentas.cod_cajero ;
              While Cajero = filaVentas.cod_cajero
              And Impresora = filaVentas.nro_impresora
              And fecha = filaVentas.fch_ticket
              loop --loop Cajero

                 signoAnt := signo ;
                 Importe := 0 ;
                 signo   :='+';


                 NroTicket := filaVentas.nro_factura_fiscal ;
                 NroTicketINIC := filaVentas.nro_factura_fiscal ;

                   Coddepn := filaVentas.Cod_Depn ;
                   Codsdep := filaVentas.Cod_sDep ;
                   CC      := filaVentas.Centro_costo ;

                    If filaVentas.importe = 0 then

                       Importe := 0 ;
                       signo   :='+';
                       impInt := 0 ;
                       vImp := null;
                       dp := null;


                       While filaVentas.importe = 0
                       and NroTicket = filaVentas.nro_factura_fiscal
                       and Cajero = filaVentas.cod_cajero
                       And Impresora = filaVentas.nro_impresora
                       And fecha = filaVentas.fch_ticket  loop

                           NroTicket := NroTicket + 1 ;
                           fetch  ticket_cur into filaVentas ;

                          if ticket_cur%notfound then
                            exit;
                          end if;

                       end loop;

                    ElsIf filaVentas.importe < 0 AND filaVentas.importe*ventas.obt_cotizacion_fecha(1,filaVentas.fch_ticket) > -1000 then
                       vImp := null ;
                       dp := null;
                       signo   :='-';

                       Importe := filaVentas.importe ;
                       impInt := filaVentas.impInteres ;
                       NroTicket := NroTicket + 1 ;
                       fetch  ticket_cur into filaVentas ;
                    ElsIf ABS(filaVentas.importe*ventas.obt_cotizacion_fecha(1,filaVentas.fch_ticket) ) >=1000 then
                       vImp := 'M';
                       if filaVentas.importe > 0 Then
                          signo   :='+';
                       else
                          signo   :='-';
                       end if;
                       Importe := filaVentas.importe ;
                       impInt := filaVentas.impInteres ;
                       NroTicket := NroTicket + 1 ;
                       dp := filaVentas.datos_personales ;
                       fetch  ticket_cur into filaVentas ;
                    Else
                       Importe := 0;
                       impInt := 0;
                       signo   :='+';
                       vImp := null ;
                       dp := null;
                       While filaVentas.importe > 0 and (filaventas.importe*ventas.obt_cotizacion_fecha(1,filaVentas.fch_ticket)) < 1000
                       and NroTicket = filaVentas.nro_factura_fiscal
                       and Cajero = filaVentas.cod_cajero
                       And Impresora = filaVentas.nro_impresora
                       And fecha = filaVentas.fch_ticket  loop


                           Importe := Importe + filaVentas.importe;
                           impInt  := ImpInt + filaVentas.impInteres ;
                           NroTicket := NroTicket + 1 ;
                           fetch  ticket_cur into filaVentas ;

                          if ticket_cur%notfound then
                            exit;
                          end if;

                       end loop;

                    end if;


                  --Buscar los datos de las facturas fiscales si los importes som mayores a 1000
                 If Importe = 0 Then

                  insert into estadis.interface_ventas_sap
                  (depn,sdepn,FCH_TICKET,NRO_IMPRESORA,FF_DESDE,FF_HASTA,CAJERO,IMPORTE,interes,tipo,centr_costo)
                  values
                  (Coddepn,Codsdep,filaVentas.fch_ticket,Impresora,nroticketINIC,nroticket-1,999,importe,0,'N',CC);
                 elsIf Importe <> 0 Then
                  insert into estadis.interface_ventas_sap
                  (depn,sdepn,FCH_TICKET,NRO_IMPRESORA,FF_DESDE,FF_HASTA,CAJERO,IMPORTE,interes,tipo,centr_costo,datos_pax)
                  values
                  (Coddepn,Codsdep,filaVentas.fch_ticket,Impresora,nroticketINIC,nroticket-1,cajero,importe,impInt,vImp,CC,dp);


                  end if;

                 if ticket_cur%notfound then
                    exit;
                 end if;


                 if filaVentas.nro_factura_fiscal > NroTicket
                 And Impresora = filaVentas.nro_impresora
                 And fecha = filaVentas.fch_ticket
                 And signo = ImporteSigno(filaVentas.importe)
                 Then
                     NroTicketINIC := nroticket ;
                     While NroTicket <> filaVentas.nro_factura_fiscal loop
                         NroTicket := NroTicket + 1 ;
                     end loop;
                     dbms_output.put_line(' AGUJERO '||' '||TO_CHAR(NROTICKETINIC)||' '||TO_CHAR(NROTICKET-1));
                    insert into estadis.interface_ventas_sap
                    (depn,sdepn,FCH_TICKET,NRO_IMPRESORA,FF_DESDE,FF_HASTA,CAJERO,IMPORTE,interes,tipo,centr_costo)
                    values
                    (coddepn,codsdep,filaVentas.fch_ticket,Impresora,nroticketINIC,nroticket-1,999,0,0,'N',CC);

                 End if;

              End loop; --loop Cajero
         if ticket_cur%notfound then
            exit;
         end if;
         End loop; --loop Imp

    if ticket_cur%notfound then
       exit;
    end if;
    End loop ; --loop fecha
end loop;

close ticket_cur ;

delete from   estadis.interface_ventas_sap
where  fch_ticket = pFecha
and tipo in('N')
and abs(ff_desde - ff_hasta) > 500 ;

*/
End;
-------------------------------------------------------------------
--------------------------------------------------------------------
PROCEDURE Acumula_ventas_rnc_mes ( pDepn in Varchar2, pFecha IN DATE )
is
Begin
Delete From venta_rnc v
Where fch_ticket = pFecha
and cod_local in
      ( Select cod_loc From baires.local Where cod_sdep = pDepn );

insert into venta_rnc
(FCH_TICKET,COD_LOCAL,COD_RUBR,COD_SRUB,COD_PROV,COD_CIA_AEREA,NRO_VUELO,IMPORTE, UNIDADES, nacionalidad)
(
select h.fch_ticket
,H.COD_LOCAL local
,p.cod_rubr
,P.COD_SRUB
,p.cod_prov
,cod_cia_aerea
,cod_vuelo
,sum(d.importe)
,sum(d.cantidad)
,cod_nac CodNac
from baires.producto p ,ventas.ticket_h_MES h, ventas.ticket_d_MES d
where
h.fch_ticket     = d.fch_ticket
and h.cod_caja   = d.cod_caja
and h.nro_ticket = d.nro_ticket
and h.cod_local  = d.cod_local
and h.cod_sloc   = d.cod_sloc
and D.fch_ticket = pFecha And h.cod_sdep = pDepn
and p.cod_prod = d.cod_prod
group by h.fch_ticket,H.COD_LOCAL,cod_nac,p.cod_rubr,P.COD_SRUB,p.cod_prov --,s.descr,i.descrip
,cod_cia_aerea
,cod_vuelo

);


End;
-------------------------------------------------------------------
--------------------------------------------------------------------
PROCEDURE Acumula_Monitoreo_mes ( FCH date ,pDepn in Varchar2, pSdep in Varchar2 )
is
/* select depn,sdep,p.cod_prod
 ,ROUND(sum(nvl(estm_ult,0)*porc/100)) Est_U
 ,ROUND(sum(nvl(estm_ult,0) * p.precio_ppal * porc /100 ),2) Est_$
  From estimado e, producto p,
  porcentaje_monitoreo g
  Where P.Cod_prod = e.Cod_prod and aniomes = to_number(to_char(sysdate,'YYYYMM'))
  and p.cod_prod in (select cod_prod from monitoreo_productos)
  and depn = pDepn And sdep = pSdep
  Group by depn,sdep,p.cod_prod ;*/


Cursor Estimado_cur is
 select depn,sdep,p.cod_prod
 ,ROUND(sum(nvl(estm_ult,0)* FUNC_PORCIENTO_MONITOREO(fch,DEPN,SDEP,'A')/100)) Est_U
 ,ROUND(sum(nvl(estm_ult,0) * p.precio_ppal * FUNC_PORCIENTO_MONITOREO(fch,DEPN,SDEP,'A') /100 ),2) Est_$
  From estimado e, producto p,
  (SELECT DISTINCT COD_DEPN DEPN,COD_SSDEP SDEP
   FROM VENTAS.APERTURA_SDEP
   WHERE COD_SDEP NOT IN ('IGUA','BARI','MDPL'))
  Where
  P.Cod_prod = e.Cod_prod and aniomes = to_number(to_char(FCH,'YYYYMM'))
  and p.cod_prod in (select cod_prod from monitoreo_productos)
  and depn = pDepn And sdep = pSdep
  Group by depn,sdep,p.cod_prod ;



Cursor Venta_cur is
  SELECT v.cod_depn,cod_ssdep,cod_prod,sum(cantidad) vta_U,sum(importe) vta_$
  From venta_plg v, ventas.apertura_sdep s
  Where fch_ticket between first_day(FCH) and FCH
  And v.cod_depn = s.cod_depn and v.cod_sdep = s.cod_sdep and v.cod_local = s.cod_local
  And cod_prod in (select cod_prod from monitoreo_productos )
  and s.cod_depn = pDepn And cod_ssdep = pSdep
  group by v.cod_depn,cod_ssdep,cod_prod ;

/* select depn,sdep,p.cod_prod
 ,ROUND(sum(nvl(estm_ult,0)*porc/100)) Py_U
 ,ROUND(sum(nvl(estm_ult,0) * p.precio_ppal * porc /100 ),2) Py_$
  From estimado e, producto p,
  porcentaje_monitoreo_py g
  Where P.Cod_prod = e.Cod_prod and aniomes = to_number(to_char(sysdate,'YYYYMM'))
  and p.cod_prod in (select cod_prod from monitoreo_productos)
  and depn = pDepn And sdep = pSdep
  Group by depn,sdep,p.cod_prod ;*/
Cursor Proyect_cur is
 select depn,sdep,p.cod_prod
 ,ROUND(sum(nvl(estm_ult,0)* FUNC_PORCIENTO_MONITOREO(fch+1,DEPN,SDEP,'P')/100)) Py_U
 ,ROUND(sum(nvl(estm_ult,0) * p.precio_ppal * FUNC_PORCIENTO_MONITOREO(fch+1,DEPN,SDEP,'P') /100 ),2) Py_$
  From estimado e, producto p,
  (SELECT DISTINCT COD_DEPN DEPN,COD_SSDEP SDEP
   FROM VENTAS.APERTURA_SDEP
   WHERE COD_SDEP NOT IN ('IGUA','BARI','MDPL'))
  Where
  P.Cod_prod = e.Cod_prod and aniomes = to_number(to_char(FCH,'YYYYMM'))
  and p.cod_prod in (select cod_prod from monitoreo_productos)
  and depn = pDepn And sdep = pSdep
  Group by depn,sdep,p.cod_prod ;

Cursor stk_cur is
select cod_ssdep,cod_depn,p.cod_prod,sum(cantidad) s_u,sum(cantidad*precio_ppal) s_i
from  ventas.apertura_sdep l, producto p,stock_dia d
where p.cod_prod in (select cod_prod from monitoreo_productos)
and l.cod_local = d.cod_local
and d.cod_local not in ('BOD','BMC')
and d.cod_prod = p.cod_prod
and cod_depn = pDepn And cod_ssdep = pSdep
Group by cod_ssdep,cod_depn,p.cod_prod ;

Begin

update estadis.monitoreo_productos set
    ESTIMADO_U = 0,
    ESTIMADO_$ = 0,
    VENTA_U = 0,
    VENTA_$ = 0,
    PROYECTAD_U = 0,
    PROYECTADO_$ = 0,
    STOCK_U = 0,
    STOCK_$ = 0
Where depn = pDepn And sdep = pSdep ;

for estimado in estimado_cur loop
    Update monitoreo_productos set
     Estimado_U = estimado.est_u
    ,Estimado_$ = estimado.est_$
    Where cod_prod = estimado.cod_prod
    And depn = estimado.depn
    And sdep = estimado.sdep ;
end loop;

for venta in venta_cur loop
    Update monitoreo_productos set
     venta_U = venta.vta_u
    ,venta_$ = venta.vta_$
    Where cod_prod = venta.cod_prod
    And depn = venta.cod_depn
    And sdep = venta.cod_ssdep ;
end loop;

If fch < last_day(fch)   Then
for proy in proyect_cur loop
    Update monitoreo_productos set
     proyectad_U = proy.Py_u
    ,proyectado_$ = proy.Py_$
    Where cod_prod = proy.cod_prod
    And depn = proy.depn
    And sdep = proy.sdep ;
end loop;
end if;

for stk in stk_cur loop
    Update monitoreo_productos set
     stock_U = stk.S_u
    ,stock_$ = stk.S_i
    Where cod_prod = stk.cod_prod
    And depn = stk.cod_depn
    And sdep = stk.cod_ssdep ;
end loop;

End ;
-------------------------------------------------------------------
-------------------------------------------------------------------
Procedure Acumula_Puntos (fch date, sdep varchar2)
 is
 Begin
    Delete from estadis.ventas_puntos
    Where fch_ticket = fch and cod_sdep = sdep ;

    insert into  ESTADIS.VENTAS_PUNTOS
    (FCH_TICKET,COD_DEPN,COD_SDEP,NACIONALIDAD, CANT_TICKET, IMPORTE,DESCUENTOS)
    SELECT h.FCH_TICKET,cod_depn,cod_sdep,cod_pais,count(*),SUM(IMPORTE), SUM(IMPORTE_DESCUENTO)
    FROM  ventas.TICKET_H_MES H, ventas.TICKET_PUNTOS_MES P
    WHERE H.FCH_TICKET = P.FCH_TICKET
    AND H.COD_CAJA = P.COD_CAJA
    AND H.NRO_TICKET = P.NRO_TICKET
    AND H.FCH_TICKET  = fch
    and cod_sdep = sdep
    and exists
    ( select * from vtol.clientes_puntos@link_webib_freeshop v where v.nro_tarjeta = P.nro_tarjeta)
    group by h.fch_ticket,cod_depn,cod_sdep,cod_pais;

 end;

-------------------------------------------------------------------
-------------------------------------------------------------------
Procedure ACUMULA_VENTAS_SECTOR
   ( fch  in date,
     depn in varchar2,
     sdep in varchar2)
   IS


BEGIN

Delete From ESTADIS.Z_VENTA_SECTOR Where fch_ticket = fch And cod_depn = DEPN And cod_sdep = SDEP ;

insert into ESTADIS.Z_VENTA_SECTOR
( FCH_TICKET
, COD_SECTOR
, COD_LOCAL
, COD_PROV
, COD_RUBRO
, COD_SRUB
, SECUENCIA
, METROS_PORC_PROV
, METROS_TOTAL_SECTOR
, IMPORTE_PROV
, UNIDADES_PROV
, COD_DEPN
, COD_SDEP)
(SELECT fch_ticket
, Z.COD_SECTOR
, Z.COD_LOCAL
, Z.COD_PROV
, Z.COD_RUBR
, Z.COD_SRUB
, secuencia
, participacion_ocupa
, METROS_CUADRADOS
, SUM(IMPORTE * participacion_venta  / 100)
, SUM(CANTIDAD)
, cod_depn
, cod_sdep
FROM VENTA_PLG P, z_sector_local_prov Z, z_sector_local L
WHERE FCH_TICKET = fch
AND P.COD_PROV   = Z.COD_PROV
AND P.COD_LOCAL  = Z.COD_LOCAL
AND L.COD_local = Z.COD_local
AND L.COD_SECTOR = Z.COD_SECTOR
AND P.COD_RUBR   = NVL(Z.COD_RUBR,P.COD_RUBR)
and cod_depn = DEPN and cod_sdep = SDEP
GROUP BY fch_ticket,Z.COD_SECTOR,Z.COD_LOCAL,METROS_CUADRADOS
,Z.COD_PROV,Z.COD_RUBR,Z.cod_SRUB,participacion_ocupa,secuencia, cod_depn, cod_sdep );


END; -- Procedure
--******************************************
procedure Actualiza_DC (fch date, DEPN varchar2, SDEP varchar2)
is
Begin

--inserto los aplicados en la table DC_D desde PAGOS
insert into   ventas.DC_D ( FECHA, NRO_TICKET, COD_CAJA, COD_LOCAL, COD_CAJERO,
                     NRO_DC,TIPO_OPER, NRO_PAX)
(select distinct fch_ticket,nro_ticket,cod_caja,cod_local,cod_cajero,nro_dc,'A',nro_pax
from ventas.view_ticket_pagos p , baires.local l
where cod_local = cod_loc
and fch_ticket = fch
and tipo_pago = 1 and tipo_moneda = 14
and cod_depn  = DEPN and nro_dc is not null
And cod_sdep  = decode(cod_depn,'INT',SDEP,cod_sdep));

--Actualizo los datos de vtol con los de los tickets
insert into vtol.DC_D@link_webib_freeshop
(NRO_DC,TIPO_OPER,FECHA,NRO_TICKET,COD_CAJA,COD_LOCAL,COD_CAJERO,NRO_PAX,MODO,SUPERVISOR)
Select NRO_DC,TIPO_OPER,FECHA,NRO_TICKET,COD_CAJA,COD_LOCAL,COD_CAJERO,NRO_PAX,MODO,SUPERVISOR
from ventas.dc_d
Where (NRO_DC,TIPO_OPER) in
 (
  SELECT NRO_DC,TIPO_OPER
  FROM VENTAS.DC_D , baires.local
  where fecha = fch and cod_loc = cod_local
  And cod_depn  = DEPN
  And cod_sdep  = decode(cod_depn,'INT',SDEP,cod_sdep)
  minus
  SELECT NRO_DC,TIPO_OPER FROM vtol.DC_D@link_webib_freeshop
 );


End;

Procedure    EJECUTAR_COMBINATORIA
      ( pFecha  IN date
       ,pDepn   IN ventas.ticket_h.cod_depn%type) is

  cursor tickets is
  select fch_ticket,cod_caja,nro_ticket,importe,cod_local,cod_sloc,cod_sdep,cod_nac
  from
        ventas.ticket_h h
  where
        fch_ticket = pFecha
        and cod_depn = pDepn
        and importe > 0;

  fecha  date;
  caja integer;
  ticket integer;
  SDepn varchar2(4);
  nac integer;

  ppvv varchar2(500);
  d_imp number(12,2);
  d_cant number (12);

  cursor detal is
  select d.fch_ticket, d.nro_ticket, d.cod_local, d.cod_sloc, d.cod_caja, p.cod_rubr, sum(d.importe) imp,
  sum(cantidad) cant
  from baires.producto p , ventas.ticket_d d
  where p.cod_prod = d.cod_prod
  and d.fch_ticket = fecha
  and d.nro_ticket = ticket
  and d.cod_caja = caja
  group by d.fch_ticket, d.nro_ticket, d.cod_local, d.cod_sloc, d.cod_caja, p.cod_rubr
  order by p.cod_rubr;
  BEGIN

  delete from estadis.ticket_combinatoria where cod_depn = pDepn and fch_ticket = pFecha ;

  for c in tickets loop
    fecha := c.fch_ticket;
    caja := c.cod_caja;
    ticket := c.nro_ticket;
    SDepn := c.cod_sdep;
    nac := c.cod_nac;
    ppvv := ' ' ;
    d_imp := 0 ;
    d_cant := 0 ;

    for d in detal loop
        ppvv := ppvv||'*'||d.cod_rubr ;
        d_imp := d_imp + d_imp ;
        d_cant := d_cant + d_cant ;
    end loop;

    insert into estadis.ticket_combinatoria
    (FCH_TICKET,NRO_TICKET,COD_LOCAL,COD_SLOC,COD_CAJA,RUBRO,D_IMP, CANT,H_IMP,COD_NAC,COD_DEPN,COD_SDEP)
    VALUES
    (FECHA,TICKET,C.COD_LOCAL,C.COD_SLOC,CAJA,PPVV,D_IMP,D_CANT,C.IMPORTE,Nac,pDepn,Sdepn);
 end loop;
 end;


END; -- END OF PACKAGE
