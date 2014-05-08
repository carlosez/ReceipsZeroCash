
DECLARE
   fecha_hora   VARCHAR2 (25);
   v_buff       VARCHAR2 (600);
   v_retc       VARCHAR2 (600);
BEGIN
   --    fecha_hora := to_char(sysdate,'yyyy-mm-dd_hh24-mi-ss');
   fecha_hora := 'MOBILECASH';

   BEGIN
      fecha_hora := 'MOBILECASH';
      fnd_file.
      put_names ('test' || fecha_hora || '.log',
                 'test' || fecha_hora || '.out',
                 'XX_SV_MOBILECASH_RECEIPT');


      XX_SV_RECEIPTS_PKG.XX_SV_CREATE_APPLY_RECEIPT (ERRBUF      => v_buff,
                                                     RETCODE     => v_retc,
                                                     P_USER_ID   => 10585 --+ ENTRUSTCA_SV
                                                                         ,
                                                     P_RESP_ID   => 51445 --+ Receivables MobileCash (SV)
                                                                         ,
                                                     P_RESP_APP_ID => 222 --+ Receivables
                                                                         ,
                                                     P_ORG_ID    => 346 --+ MobileCash
                                                                       );
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('Error' || SQLERRM);
   END;


   /* Some logic here... */
   fnd_file.put_line (fnd_file.output, 'Reached point A');
   /* More logic, etc... */
   fnd_file.put_line (fnd_file.LOG, 'Before closing directory');
   fnd_file.close;
EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.put_line ('Error' || SQLERRM);
END;

--select * from all_directories
--create or replace directory XX_SV_MOBILECASH_RECEIPT as '/interface/j_mili/DMILII/outgoing/SV_TELEMOVIL/RECEIPT'
