insert into reclamos.especificacion
(cod_subtipo,cod_especificacion,descrip,cod_tipo)

select 
cod_subtipo,cod_especificacion,descrip,cod_tipo
from reclamos.especificacion@LINK_INTER_VTA.WORLD
-- ********************************************************
insert into reclamos.tipo_llamado
(cod_tipo, descrip)

select cod_tipo,descrip
from reclamos.tipo_llamado@LINK_INTER_VTA.WORLD
-- ********************************************************
insert into reclamos.subtipo_llamado
(cod_tipo,cod_subtipo,descrip)
SELECT cod_tipo,cod_subtipo,descrip
FROM RECLAMOS.subTipo_llamado@LINK_INTER_VTA.WORLD

commit
