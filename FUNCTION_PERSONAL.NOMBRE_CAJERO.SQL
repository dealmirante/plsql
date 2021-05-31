Function PERSONAL.NOMBRE_CAJERO
  ( Cajero in number)
  RETURN  varchar2 IS
   vNombre varchar2(100) ;

BEGIN
  Select nombre||' '||apellido nombre
  into   vNombre
  From  ventas.cajeros c, personal.empleado e
  Where c.legajo = e.legajo And c.cod_cajero = Cajero ;

    RETURN vNombre ;
EXCEPTION
   WHEN no_data_found THEN
       return 'No Asignado' ;
   WHEN OTHERS THEN
       return ' ';
END;
