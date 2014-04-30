

declare

fecha_hora varchar2(25);

BEGIN
--    fecha_hora := to_char(sysdate,'yyyy-mm-dd_hh24-mi-ss');
    fecha_hora := 'MOBILECASH';
    begin
 fnd_file.put_names('test' || fecha_hora ||  '.log', 'test' || fecha_hora ||  '.out', 'XX_SV_MOBILECASH_RECEIPT');
 exception 
 when others
 then
 dbms_output.put_line('Error'|| sqlerrm ); 
 end;
 
 fnd_file.put_line(fnd_file.output,'Called stored  procedure'); 
 /* Some logic here... */ 
 fnd_file.put_line(fnd_file.output, 'Reached point A'); 
 /* More logic, etc... */
 fnd_file.put_line(fnd_file.log, 'Before closing directory');  
 fnd_file.close;
 exception 
 when others
 then
 dbms_output.put_line('Error'|| sqlerrm ); 

END; 

--select * from all_directories
--create or replace directory XX_SV_MOBILECASH_RECEIPT as '/interface/j_mili/DMILII/outgoing/SV_TELEMOVIL/RECEIPT'

 