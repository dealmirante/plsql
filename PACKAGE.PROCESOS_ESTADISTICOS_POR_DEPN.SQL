Package         PROCESOS_ESTADISTICOS_POR_DEPN
  IS
  PROCEDURE Acumulado_por_ProdLocGrup_mes ( fch IN venta_PLG.fch_ticket%type
                                            ,depn venta_PLG.cod_depn%type
                                            ,sdep venta_PLG.cod_sdep%type );

  PROCEDURE Acumulado_por_LocGrup_mes ( fch IN venta_PLG.fch_ticket%type
                                       ,depn venta_PLG.cod_depn%type
                                       ,sdep venta_PLG.cod_sdep%type );

 PROCEDURE Pax_por_Espigon_mes ( fch IN venta_PLG.fch_ticket%type
                                ,depn venta_PLG.cod_depn%type
                                ,sdep venta_PLG.cod_sdep%type );

 PROCEDURE Pax_por_Local_mes ( fch IN venta_PLG.fch_ticket%type
                              ,depn venta_PLG.cod_depn%type
                              ,sdep venta_PLG.cod_sdep%type );

PROCEDURE Pax_por_Grupo_mes ( fch IN venta_PLG.fch_ticket%type
                              ,depn venta_PLG.cod_depn%type
                              ,sdep venta_PLG.cod_sdep%type );

PROCEDURE Acumulado_por_PAGOS_mes ( fch IN venta_PLG.fch_ticket%type
                                   ,depn venta_PLG.cod_depn%type
                                   ,sdep venta_PLG.cod_sdep%type );

Procedure EJECUTAR_ACT_STOCK_DEP ( pFecha  IN date
                              ,pDepn IN venta_PLG.cod_depn%type
                              ,pSdep IN venta_PLG.cod_sdep%type
                              ,pLocal IN venta_plg.cod_local%type);

PROCEDURE Acumulado_por_MONEDA_DEPN_mes ( fch IN DATE ) ;

PROCEDURE Acumula_Recaudaciones_DEPN_mes ( pDepen in Varchar2, pFecha IN DATE );

PROCEDURE Acumula_ventas_sap_DEPN_mes ( pDepn in Varchar2, pFecha IN DATE ) ;

Procedure VENTAS_NACES_ACUM( FCH_DESDE IN DATE,  pDepn IN varchar2,pSdep IN varchar2);

PROCEDURE Acumula_ventas_rnc_mes ( pDepn in Varchar2, pFecha IN DATE ) ;

PROCEDURE Acumula_Monitoreo_mes ( FCH IN date ,pDepn in Varchar2, pSdep in Varchar2 );

Procedure Acumula_Puntos (fch date, sdep varchar2) ;

Procedure ACUMULA_VENTAS_SECTOR ( fch  in date, depn in varchar2, sdep in varchar2) ;

procedure Actualiza_DC (fch date, DEPN varchar2, SDEP varchar2) ;

PROCEDURE Separa_Rec_Debito_DEPN_mes ( pDepen in Varchar2, pFecha IN DATE );

Procedure  Actualiza_Descuentos_tecla (fch in date, Depn in varchar2, Sdep in varchar2);

Procedure    EJECUTAR_COMBINATORIA  ( pFecha  IN date
                                     ,pDepn   IN ventas.ticket_h.cod_depn%type);


END; -- Package spec
