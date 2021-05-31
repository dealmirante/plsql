-- Create table
create table XB0502261D_MAR
(
  COD_SECC       NUMBER(3) not null,
  NUM_POL1       NUMBER(13) not null,
  NUM_END        NUMBER(5) not null,
  NUM_CUOTA      NUMBER(2) not null,
  FEC_ACTU       DATE not null,
  IMP_PREMIO_COB NUMBER(17,2),
  IMP_PRIMA_COB  NUMBER(17,2),
  MCA_1ER_COBRO  VARCHAR2(1),
  NUM_SECU_POL   NUMBER(15),
  SOLICITUD_PROP NUMBER(15),
  COD_RIES       NUMBER(4),
  COD_RAMO       NUMBER(3),
  NRO_PERIODO    NUMBER(5),
  COD_PROD       NUMBER(5)
)
tablespace DATOS;


-- Grant/Revoke object privileges 
grant select, insert, update, delete, references, alter, index on XB0502261D_MAR to PUBLIC;
-- Create the synonym 
CREATE PUBLIC SYNONYM XB0502261D_MAR FOR TRON2000.XB0502261D_MAR;



