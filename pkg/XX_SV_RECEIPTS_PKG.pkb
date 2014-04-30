CREATE OR REPLACE PACKAGE BODY BOLINF.XX_SV_RECEIPTS_PKG IS

     lv_amount                   NUMBER;
    v_currency_code         VARCHAR(100);
    v_receipt_number        VARCHAR(100);   --Entrada 3: Numero de Recibo
    v_receipt_date          DATE;           --Entrada 4: Fecha de Recibo
    v_gl_date               DATE;           --Entrada 5: Fecha Contable
    v_customer_id           VARCHAR(100);   --Entrada 6: ID de Cliente (Obtener de base, Consulta 1)
    v_customer_site_use_id  VARCHAR(100);   --Entrada 7: ID de Site (Consulta 2)
    v_receipt_method_id     VARCHAR(100);   --Entrada 8: Metodo de Recibo (POR CONFIRMAR)
    v_trx_number            VARCHAR(100);   --Entrada 9: Numero de Factura
    v_org_id                NUMBER;         --Entrada 10: Organizacion
    v_bank_acc_id           NUMBER;         --Entrada 11: Bank Account Site ID
    v_apply_amount          NUMBER;         --Entrada 12: Monto a aplicar de factura
    v_cust_trx_id           NUMBER;         --Entrada es el id de la factura a aplicar
    v_set_of_books_id    NUMBER;    -- Libro Contable de la Organizacion
    v_cust_trx_type_id    NUMBER;    -- Tipo de Factura
    v_tipo_factura          VARCHAR2(20);
    v_customer_trx_id    NUMBER;

    -- GLOBALES
    l_customer_trx_id     NUMBER;
    l_customer_id     NUMBER;
    l_customer_site_use_id   NUMBER;
    l_receipt_method_id   NUMBER;
    l_remittance_bank_account_id   NUMBER;
    l_apply_amount_sum    NUMBER;
    l_receipt_amount      NUMBER;
    l_rece_id     NUMBER;
    l_set_of_books   NUMBER;
    l_organization_id   NUMBER;
    l_cust_trx_type_id   NUMBER;
--    l_set_of_books_id   NUMBER;

    v_errmsg                            VARCHAR2(32767);
    p_errmsg                           VARCHAR2(32767);
    l_flag                                   VARCHAR2(1) := 'S';
    l_error                                  VARCHAR2(1) := 'N';
    l_msg_index                       NUMBER;
    l_encoded                         VARCHAR2(1);
    l_count                           NUMBER;
    l_msg_index_out                   NUMBER;
    l_continuar                    NUMBER;

    l_return_status_h   VARCHAR2 (1);    --Salida 1 de API, status Header
    l_msg_count_h       NUMBER;          --Salida 2 de API, error count Header
    l_msg_data_h        VARCHAR2 (240);  --Salida 3 de API, error data Header
    l_cr_id_h           NUMBER;          --Salida 4 de API, exitoso Header

    l_return_status_b   VARCHAR2 (1);    --Salida 1 de API, status Body
    l_msg_count_b       NUMBER;          --Salida 2 de API, error count Body
    l_msg_data_b        VARCHAR2 (240);  --Salida 3 de API, error data Body
    l_cr_id_b           NUMBER;          --Salida 4 de API, exitoso Body

    p_count             NUMBER;          --Loop de muestra de errores
    search_flag         VARCHAR2(1);     --Busqueda en caso de errores
    --+
    FT_COMPLETA         NUMBER;          --+ FLAG PARA SABER SI LA FACTURA A PLICAR ESTA COMPLETA
    v_moneda_funcional  VARCHAR2(15);
    v_rate_type         VARCHAR2(30);
    v_rate_date         DATE;
    v_amt_appl_from     NUMBER;
    v_trn_to_rec_rate   NUMBER;
    --+
    v_rec_attrib        APPS.AR_RECEIPT_API_PUB.attribute_rec_type;
    v_rec_attribute   APPS.AR_RECEIPT_API_PUB.attribute_rec_type;

    v_existe    VARCHAR2(1) := NULL;


PROCEDURE XX_SV_CREATE_APPLY_RECEIPT ( ERRBUF              OUT VARCHAR2,
                                                                     RETCODE            OUT VARCHAR2,
                                                                     P_USER_ID          IN  NUMBER,
                                                                     P_RESP_ID          IN NUMBER,
                                                                     P_RESP_APP_ID   IN  NUMBER,
                                                                     P_ORG_ID            IN  NUMBER
                                                                   ) IS


    CURSOR C_Existe IS
        SELECT 'Y'
          FROM XX_SV_CARGA_RECEIPTS A,
               APPS.FND_USER U
         WHERE (A.STATUS IN ('I','PE')
                    OR A.STATUS_RECIPT IN ('I','RE')
                    )
           AND A.USUARIO = U.USER_NAME;

    CURSOR R_HEADER_DATA IS
        SELECT DISTINCT F_LIMPIAR(A.OPERATING_UNITS) OPERATING_UNITS,
                        F_LIMPIAR(A.NUMERO_PAGO) NUMERO_PAGO,
                        F_LIMPIAR(A.TCNFOL) TCNFOL,
                        F_LIMPIAR(A.CURRENCY) CURRENCY
          FROM XX_SV_CARGA_RECEIPTS A,
               APPS.FND_USER U
         WHERE (A.STATUS IN ('I','PE')
                    OR A.STATUS_RECIPT IN ('I','RE')
                    )
             AND A.USUARIO = U.USER_NAME
         ORDER BY  F_LIMPIAR(A.NUMERO_PAGO) ;

    CURSOR R_BODY_DATA(NUM_REC VARCHAR2, FOL VARCHAR2, MONE VARCHAR2) IS
        SELECT F_LIMPIAR(OPERATING_UNITS) OPERATING_UNITS,
               F_LIMPIAR(VALOR_PAGO) VALOR_PAGO,
               F_LIMPIAR(TIPO_PAGO)    TIPO_PAGO,
               F_LIMPIAR(CURRENCY) CURRENCY,
               FECHAPAGO,
               FECHACONTA,
               F_LIMPIAR(RECEIPT_METHOD) RECEIPT_METHOD,
               F_LIMPIAR(TIPO_FACTURA) TIPO_FACTURA,
               F_LIMPIAR(NUMERO_FACTURA) NUMERO_FACTURA,
               F_LIMPIAR(NUMERO_REF_FACTURA) NUMERO_REF_FACTURA,
               F_LIMPIAR(CCFPDO) CCFPDO,
               F_LIMPIAR(TCNFOL) TCNFOL,
               F_LIMPIAR(MONTO_AFECTADO) MONTO_AFECTADO,
               F_LIMPIAR(CUENTA) CUENTA,
               F_LIMPIAR(RATE_TYPE) RATE_TYPE,                     --+
               F_LIMPIAR(AMOUNT_APPLIED_FROM) AMOUNT_APPLIED_FROM,
               F_LIMPIAR(LETRA_PAGO) LETRA_PAGO,
               F_LIMPIAR(LETRA_FACTURA) LETRA_FACTURA,
               ROWID
          FROM XX_SV_CARGA_RECEIPTS
         WHERE NVL(F_LIMPIAR(NUMERO_PAGO), 'NULL') = NVL(F_LIMPIAR(NUM_REC), 'NULL')
           AND NVL(F_LIMPIAR(TCNFOL), 'NULL') = NVL(F_LIMPIAR(FOL), 'NULL')
           AND NVL(F_LIMPIAR(CURRENCY), 'NULL') = NVL(F_LIMPIAR(MONE), 'NULL')
           AND (STATUS IN ('I','PE')
                    OR STATUS_RECIPT IN ('I','RE')
                    )
         ORDER BY VALOR_PAGO DESC;



BEGIN
         --+
         fnd_global.apps_initialize(P_USER_ID,P_RESP_ID,P_RESP_APP_ID);
         MO_GLOBAL.init('AR');
         OE_MSG_PUB.Initialize;
         --+
         APPS.FND_CLIENT_INFO.SET_ORG_CONTEXT(P_ORG_ID);
         --+
         RETCODE := '0';
         --+
         OPEN C_Existe;
         FETCH C_Existe INTO v_existe;
         IF C_Existe%NOTFOUND THEN
             v_existe := 'N';
         END IF;
         CLOSE C_Existe;

         IF v_existe = 'Y' THEN
               FOR V IN R_HEADER_DATA  LOOP
                      BEGIN

                             --+ Valores de salida Header
                             l_return_status_h   := NULL;
                             l_msg_count_h       := NULL;
                             l_msg_data_h        := NULL;
                             l_cr_id_h           := NULL;
                             search_flag         := 'Y';
                             l_error := 'N';

                             l_continuar := xx_validate_apply_amount(V.NUMERO_PAGO, V.TCNFOL);

                             IF  NVL(l_continuar,0) = 0 THEN

                                 UPDATE XX_CARGA_RECEIPTS_AS400
                                       SET STATUS = 'E',
                                              ERROR_DESCRIPTION = 'El monto total del recibo no concuerda con la suma del monto a afectar de cada factura que paga.'
                                 WHERE V.NUMERO_PAGO = NUMERO_PAGO
                                     AND V.TCNFOL = TCNFOL;

                                 COMMIT;

                                 fnd_file.PUT_LINE(fnd_file.OUTPUT, 'Error validating Reciept Number: ' || V.NUMERO_PAGO || '.');
                                 fnd_file.PUT_LINE(fnd_file.OUTPUT, '    Total receipt amount does not match apply amount sum.');

                                 RETCODE := '1';

                             ELSIF l_continuar = 1 THEN
                                 --+
                                 FOR B IN R_BODY_DATA(V.NUMERO_PAGO, V.TCNFOL, V.CURRENCY)   LOOP
                                        BEGIN
                                               --+
                                               --+ Valores para parametros de entrada
                                               v_currency_code         := B.CURRENCY;
                                               lv_amount                := B.VALOR_PAGO;
                                               v_receipt_number        := V.NUMERO_PAGO;
                                               v_receipt_date          := B.FECHAPAGO;
                                               v_gl_date               := B.FECHACONTA;
                                               v_customer_id           := xx_get_customer_id(B.TCNFOL);
                                               v_receipt_method_id     := xx_get_receipt_method_id(B.RECEIPT_METHOD);
                                               v_org_id                := xx_org_id (B.OPERATING_UNITS);
                                               v_set_of_books_id       := xx_get_set_of_books (v_org_id);
                                               v_bank_acc_id           := xx_get_remit_bank_acct_id(B.CUENTA);
                                               v_tipo_factura          := '%'||B.TIPO_FACTURA;
                                               v_cust_trx_type_id      := xx_cust_trx_type_id (v_tipo_factura, v_set_of_books_id);
                                               v_customer_site_use_id  := xx_get_customer_site_use_id(v_customer_id, B.NUMERO_FACTURA, v_cust_trx_type_id);
                                               v_customer_trx_id :=  xx_search_factura (B.NUMERO_FACTURA, v_customer_site_use_id, v_cust_trx_type_id);
                                               fnd_file.PUT_LINE(fnd_file.log, 'Paso de Validaciones para el Recibo.'||V.NUMERO_PAGO);
                                               --+
                                               apps.mo_global.set_policy_context ( 'S', v_org_id );
                                               l_return_status_b   := NULL;
                                               l_msg_count_b       := NULL;
                                               l_msg_data_b        := NULL;
                                               l_return_status_h   := NULL;
                                               l_msg_count_h       := NULL;
                                               l_msg_data_h        := NULL;
                                               l_cr_id_h               := NULL;
                                               p_errmsg              := NULL;
                                               v_errmsg              := NULL;
                                               l_error := 'N';
                                               l_flag := 'S';

                                               IF (NVL(B.NUMERO_FACTURA,'X') = 'X'  AND NVL(B.MONTO_AFECTADO,0) <> 0) THEN
                                                    p_errmsg := 'El Numero de la  Factura no puede venir vacio; ya que viene monto a ser afectado';
                                                    v_errmsg := p_errmsg;
                                                    apps.fnd_file.put_line (apps.fnd_file.log, p_errmsg);
                                                    apps.fnd_file.put_line (apps.fnd_file.output, p_errmsg);
                                                    l_flag := 'N';
                                                    l_error := 'S';

                                               ELSIF (NVL(B.NUMERO_FACTURA,'X') <> 'X'  AND NVL(B.MONTO_AFECTADO,0) = 0) THEN
                                                         p_errmsg := 'La Factura No.  '||B.NUMERO_FACTURA||' No viene con un Monto a ser Afectado ';
                                                         v_errmsg := p_errmsg;
                                                         apps.fnd_file.put_line (apps.fnd_file.log, p_errmsg);
                                                         apps.fnd_file.put_line (apps.fnd_file.output, p_errmsg);
                                                         l_flag := 'N';
                                                         l_error := 'S';
                                               END IF;

                                               IF (NVL(v_customer_trx_id,0) = 0 AND NVL(B.NUMERO_FACTURA,'X') <> 'X') THEN
                                                         p_errmsg := 'ERROR No Se Encontro La Factura No.  '||B.NUMERO_FACTURA||'  para el Tipo De Factura '||B.TIPO_FACTURA||'   y Cliente '||B.TCNFOL;
                                                         v_errmsg := p_errmsg;
                                                         apps.fnd_file.put_line (apps.fnd_file.log, p_errmsg);
                                                         apps.fnd_file.put_line (apps.fnd_file.output, p_errmsg);
                                                         l_flag := 'N';
                                                         l_error := 'S';
                                               END IF;

                                               IF NVL(v_currency_code,'X') = 'X' THEN
                                                    p_errmsg := 'La Moneda no puede venir vacia ';
                                                    v_errmsg := p_errmsg;
                                                    apps.fnd_file.put_line (apps.fnd_file.log, p_errmsg);
                                                    apps.fnd_file.put_line (apps.fnd_file.output, p_errmsg);
                                                    l_flag := 'N';
                                                    l_error := 'S';
                                               END IF;

                                               IF NVL(TRIM(B.TCNFOL),'X') = 'X' THEN
                                                    p_errmsg := 'El Cliente no puede venir vacio.';
                                                    v_errmsg := p_errmsg;
                                                    apps.fnd_file.put_line (apps.fnd_file.log, p_errmsg);
                                                    apps.fnd_file.put_line (apps.fnd_file.output, p_errmsg);
                                                    l_flag := 'N';
                                                    l_error := 'S';
                                               ELSE
                                                    IF NVL(v_customer_id,0) = 0 THEN
                                                         p_errmsg := 'El Cliente '||B.TCNFOL||' No fue Encontrado.';
                                                         v_errmsg := TRIM(v_errmsg)||' '||p_errmsg;
                                                         apps.fnd_file.put_line (apps.fnd_file.log, p_errmsg);
                                                         apps.fnd_file.put_line (apps.fnd_file.output, p_errmsg);
                                                         l_flag := 'N';
                                                         l_error := 'S';
                                                    END IF;
                                               END IF;


                                               IF (NVL(v_customer_site_use_id,0) = 0  AND NVL(B.NUMERO_FACTURA,'X') <> 'X' ) THEN
                                                    p_errmsg := 'El Sitio del Cliente de la Factura '||B.NUMERO_FACTURA||' No fue Encontrado.';
                                                    v_errmsg := TRIM(v_errmsg)||' '||p_errmsg;
                                                    apps.fnd_file.put_line (apps.fnd_file.log, p_errmsg);
                                                    apps.fnd_file.put_line (apps.fnd_file.output, p_errmsg);
                                                    l_flag := 'N';
                                                    l_error := 'S';
                                               END IF;

                                               IF NVL(B.RECEIPT_METHOD,'X') = 'X' THEN
                                                    p_errmsg := 'El Metodo de Recepcion no puede venir vacio.';
                                                    v_errmsg := p_errmsg;
                                                    apps.fnd_file.put_line (apps.fnd_file.log, p_errmsg);
                                                    apps.fnd_file.put_line (apps.fnd_file.output, p_errmsg);
                                                    l_flag := 'N';
                                                    l_error := 'S';
                                               ELSE
                                                    IF NVL(v_receipt_method_id,0) = 0 THEN
                                                         p_errmsg := 'El Metodo de Recepcion  '||B.RECEIPT_METHOD||' No fue Encontrado.';
                                                         v_errmsg := TRIM(v_errmsg)||' '||p_errmsg;
                                                         apps.fnd_file.put_line (apps.fnd_file.log, p_errmsg);
                                                         apps.fnd_file.put_line (apps.fnd_file.output, p_errmsg);
                                                         l_flag := 'N';
                                                         l_error := 'S';
                                                    END IF;
                                               END IF;

                                               IF NVL(B.CUENTA,'X') = 'X' THEN
                                                    p_errmsg := 'El Cuenta de Recepcion no puede venir vacio.';
                                                    v_errmsg := p_errmsg;
                                                    apps.fnd_file.put_line (apps.fnd_file.log, p_errmsg);
                                                    apps.fnd_file.put_line (apps.fnd_file.output, p_errmsg);
                                                    l_flag := 'N';
                                                    l_error := 'S';
                                               END IF;

                                               IF NVL(v_bank_acc_id,0) = 0 THEN
                                                    p_errmsg := 'El Numero de la Cuenta de  Banco  '||B.CUENTA||' No fue Encontrado.';
                                                    v_errmsg := TRIM(v_errmsg)||' '||p_errmsg;
                                                    apps.fnd_file.put_line (apps.fnd_file.log, p_errmsg);
                                                    apps.fnd_file.put_line (apps.fnd_file.output, p_errmsg);
                                                    l_flag := 'N';
                                                    l_error := 'S';
                                               END IF;


                                               IF  (NVL(B.MONTO_AFECTADO,0) <= 0 AND NVL(B.NUMERO_FACTURA,'X') <> 'X') THEN
                                                    p_errmsg := 'El Monto Afectado es menor o igual a cero.'||TRIM(TO_CHAR(B.MONTO_AFECTADO,'9,999,999,999.99'));
                                                    v_errmsg := TRIM(v_errmsg)||' '||p_errmsg;
                                                    apps.fnd_file.put_line (apps.fnd_file.log, p_errmsg);
                                                    apps.fnd_file.put_line (apps.fnd_file.output, p_errmsg);
                                                    l_flag := 'N';
                                                    l_error := 'S';
                                               END IF;

                                               IF  NVL(B.VALOR_PAGO,0) <= 0 THEN
                                                    p_errmsg := 'El Monto Pagado es menor o igual a cero.'||TRIM(TO_CHAR(B.VALOR_PAGO,'9,999,999,999.99'));
                                                    v_errmsg := TRIM(v_errmsg)||' '||p_errmsg;
                                                    apps.fnd_file.put_line (apps.fnd_file.log, p_errmsg);
                                                    apps.fnd_file.put_line (apps.fnd_file.output, p_errmsg);
                                                    l_flag := 'N';
                                                    l_error := 'S';
                                               END IF;

                                               --+ Variables extra
                                               p_count           := 0;


                                               IF l_error = 'N' THEN
                                                   RETCODE := '0';
                                                   l_cr_id_h :=  xx_search_receipt(V.NUMERO_PAGO, v_customer_site_use_id, v_org_id);
                                                   fnd_file.PUT_LINE(fnd_file.log, '                                   l_cr_id_h: '||TO_CHAR(l_cr_id_h));
                                               ELSE
                                                   RETCODE := '1';
                                               END IF;

                                               BEGIN
                                                    SELECT L.CURRENCY_CODE
                                                        INTO v_moneda_funcional
                                                    FROM GL_LEDGERS L
                                                    WHERE L.LEDGER_ID = v_set_of_books_id;
                                               EXCEPTION
                                                        WHEN OTHERS THEN
                                                                  v_moneda_funcional := v_currency_code;
                                               END;

                                               IF v_moneda_funcional = v_currency_code THEN
                                                   v_rate_type := NULL;
                                                   v_rate_date := null;
                                                   v_amt_appl_from := NULL;
                                                   v_trn_to_rec_rate := NULL;
                                                   --+
                                               ELSIF v_currency_code != v_moneda_funcional THEN
                                                   v_rate_type := B.RATE_TYPE;
                                                   v_rate_date := v_receipt_date;
                                                   v_amt_appl_from := B.AMOUNT_APPLIED_FROM;
                                                   v_trn_to_rec_rate := v_amt_appl_from / B.MONTO_AFECTADO;
                                               END IF;

                                               fnd_file.PUT_LINE(fnd_file.log, '  DATOS PARA EL RECIBO');
                                               fnd_file.PUT_LINE(fnd_file.log, '  v_currency_code '||v_currency_code);
                                               fnd_file.PUT_LINE(fnd_file.log, '  lv_amount '||to_char(lv_amount));
                                               fnd_file.PUT_LINE(fnd_file.log, '  v_receipt_number '||v_receipt_number);
                                               fnd_file.PUT_LINE(fnd_file.log, '  v_receipt_date '||to_char(v_receipt_date,'dd/mm/yyyy'));
                                               fnd_file.PUT_LINE(fnd_file.log, '  v_gl_date '||to_char(v_gl_date,'dd/mm/yyyy'));
                                               fnd_file.PUT_LINE(fnd_file.log, '  v_customer_id '||v_customer_id);
                                               fnd_file.PUT_LINE(fnd_file.log, '  v_customer_site_use_id '||v_customer_site_use_id);
                                               fnd_file.PUT_LINE(fnd_file.log, '  v_receipt_method_id '||v_receipt_method_id);
                                               fnd_file.PUT_LINE(fnd_file.log, '  v_org_id '||v_org_id);
                                               fnd_file.PUT_LINE(fnd_file.log, '  v_bank_acc_id '||v_bank_acc_id);
                                               fnd_file.PUT_LINE(fnd_file.log, '  v_rate_type '||v_rate_type);
                                               fnd_file.PUT_LINE(fnd_file.log, '  v_rate_date '||to_char(v_rate_date,'dd/mm/yyyy'));
                                               fnd_file.PUT_LINE(fnd_file.log, ' ');

                                               IF NVL(l_cr_id_h, 0) = 0 AND l_error = 'N' THEN
                                                    --+
                                                    --Si el ID de Recibo es NULO entonces crear recibo
                                                     fnd_file.PUT_LINE(fnd_file.log, '     Ingreso a API AR_RECEIPT_API_PUB.create_cash');

                                                    AR_RECEIPT_API_PUB.create_cash ( p_api_version       => 1.0,
                                                                                                          p_init_msg_list     => FND_API.G_TRUE,
                                                                                                          p_commit            => FND_API.G_TRUE,
                                                                                                          p_validation_level  => FND_API.G_VALID_LEVEL_FULL,
                                                                                                          x_return_status     => l_return_status_h,
                                                                                                          x_msg_count         => l_msg_count_h,
                                                                                                          x_msg_data          => l_msg_data_h,
                                                                                                          p_cr_id             => l_cr_id_h,
                                                                                                          p_currency_code     => v_currency_code,
                                                                                                          p_amount            => lv_amount,
                                                                                                          p_receipt_number    => v_receipt_number,
                                                                                                          p_receipt_date      => v_receipt_date,
                                                                                                          p_gl_date           => v_gl_date,
                                                                                                          p_customer_id       => v_customer_id,
                                                                                                          p_customer_site_use_id  => v_customer_site_use_id,
                                                                                                          p_receipt_method_id => v_receipt_method_id,
                                                                                                          p_org_id            => v_org_id,
                                                                                                          p_remittance_bank_account_id  => v_bank_acc_id,
                                                                                                          p_exchange_rate_type => v_rate_type,
                                                                                                          p_exchange_rate_date => v_rate_date,
                                                                                                          p_attribute_rec      => v_rec_attrib
                                                                                                       );

                                                    fnd_file.PUT_LINE(fnd_file.log, '              l_cr_id_h: '||TO_CHAR(l_cr_id_h));
                                                    fnd_file.PUT_LINE(fnd_file.log, '              l_return_status_h: '||l_return_status_h);
                                                    fnd_file.PUT_LINE(fnd_file.log, '              l_msg_data_h: '||l_msg_data_h);
                                                    fnd_file.PUT_LINE(fnd_file.log, ' ');

                                                    if l_return_status_h <> 'S' then
                                                        if l_msg_count_h = 1 then
                                                           apps.fnd_file.put_line (apps.fnd_file.log, '1 - '||l_msg_data_h);
                                                           apps.fnd_file.put_line (apps.fnd_file.output, '1 - '||l_msg_data_h);
                                                           v_errmsg := TRIM(v_errmsg)||' '||'1 - '||l_msg_data_h;
                                                        ELSIF l_msg_count_h > 1 THEN
                                                              l_msg_index := FND_MSG_PUB.G_FIRST;
                                                              l_encoded := FND_API.G_TRUE;
                                                              WHILE l_msg_count_h > 0 LOOP
                                                                       l_count := l_count + 1;
                                                                       FND_MSG_PUB.GET( l_msg_index, l_encoded, p_data => l_msg_data_h, p_msg_index_out => l_msg_index_out);
                                                                       apps.fnd_file.put_line (apps.fnd_file.log, l_count||'- '||l_msg_data_h);
                                                                       apps.fnd_file.put_line (apps.fnd_file.output, l_count||'- '||l_msg_data_h);
                                                                       l_msg_count_h := l_msg_count_h - 1;
                                                                       v_errmsg := TRIM(v_errmsg)||' '||l_count||'- '||l_msg_data_h;
                                                              END LOOP;
                                                        END IF;
                                                        l_flag := 'N';
                                                        l_error := 'S';
                                                        RETCODE := '1';
                                                        ROLLBACK;

                                                        UPDATE BOLINF.XX_SV_CARGA_RECEIPTS
                                                        SET STATUS_RECIPT = 'RE',
                                                              ERROR_DESCRIPTION = v_errmsg
                                                        WHERE NUMERO_PAGO = V.NUMERO_PAGO
                                                            AND NVL(TCNFOL,'XXX') = NVL(V.TCNFOL,'XXX');

                                                        COMMIT;

                                                    ELSE
                                                         COMMIT;
                                                         l_flag := 'S';
                                                         apps.fnd_file.put_line (apps.fnd_file.output, 'CREACION DEL RECIBO');
                                                         apps.fnd_file.put_line (apps.fnd_file.output, '==============================');
                                                         apps.fnd_file.put_line (apps.fnd_file.output, 'RECIBO NO.          : '||v_receipt_number);
                                                         apps.fnd_file.put_line (apps.fnd_file.output, 'MONEDA              : '||v_currency_code);
                                                         apps.fnd_file.put_line (apps.fnd_file.output, 'FECHA RECIBO        : '||TO_CHAR(v_receipt_date,'DD-MON-YYYY'));
                                                         apps.fnd_file.put_line (apps.fnd_file.output, 'FECHA CONTABLE      : '||TO_CHAR(v_gl_date,'DD-MON-YYYY'));
                                                         apps.fnd_file.put_line (apps.fnd_file.output, 'MONTO RECIBO        : '||TRIM(TO_CHAR(lv_amount,'999,999,999.99')));
                                                         apps.fnd_file.put_line (apps.fnd_file.output, 'METODO RECEPCION    : '||B.RECEIPT_METHOD);
                                                         apps.fnd_file.put_line (apps.fnd_file.output, 'CUENTA REMITENTE    : '||B.CUENTA);
                                                         apps.fnd_file.put_line (apps.fnd_file.output, 'CLIENTE             : '||B.TCNFOL);
                                                         apps.fnd_file.put_line (apps.fnd_file.output, 'RATE_TYPE           : '||v_rate_type);
                                                         apps.fnd_file.put_line (apps.fnd_file.output, 'RATE_DATE           : '||v_rate_date);
                                                         apps.fnd_file.put_line (apps.fnd_file.output, '==============================');
                                                         apps.fnd_file.new_line(fnd_file.output, 2);

                                                          UPDATE BOLINF.XX_SV_CARGA_RECEIPTS
                                                               SET STATUS_RECIPT = 'OK',
                                                                      CASH_RECEIPT_ID = l_cr_id_h,
                                                                      ERROR_DESCRIPTION = NULL
                                                          WHERE NUMERO_PAGO = V.NUMERO_PAGO
                                                            AND NVL(TCNFOL,'XXX') = NVL(V.TCNFOL,'XXX');

                                                    END IF;
                                               END IF;

                                               --Realiza aplicacion si el recibo se crea o existe y se esta reprocesando

                                               IF NVL(l_cr_id_h, 0) != 0  AND l_error = 'N' THEN

                                                   fnd_file.PUT_LINE(fnd_file.log, '     DATOS PARA EL PAGO');
                                                   fnd_file.PUT_LINE(fnd_file.log, '     v_trx_number '||v_trx_number);
                                                   fnd_file.PUT_LINE(fnd_file.log, '     v_apply_amount '||v_apply_amount);
                                                   fnd_file.PUT_LINE(fnd_file.log, '     v_customer_trx_id '||v_customer_trx_id);
                                                   fnd_file.PUT_LINE(fnd_file.log, '     v_amt_appl_from '||v_amt_appl_from);
                                                   fnd_file.PUT_LINE(fnd_file.log, '     v_trn_to_rec_rate '||v_trn_to_rec_rate);

                                                    --Si el Receipt ID no es nulo entonces revisar si se aplicara a facturas
                                                    v_trx_number   := B.NUMERO_FACTURA;       --9
                                                    v_apply_amount := B.MONTO_AFECTADO;       --12
                                                    --+
                                                    IF NVL(v_customer_trx_id,0) != 0 AND NVL(v_customer_id,0) != 0 THEN
                                                         fnd_file.PUT_LINE(fnd_file.log, '        Ingreso a API AR_RECEIPT_API_PUB.APPLY.');

                                                         AR_RECEIPT_API_PUB.APPLY ( p_api_version       => 1.0,                            --Fijo
                                                                                                      p_init_msg_list     => FND_API.G_TRUE,                 --Fijo
                                                                                                      p_commit            => FND_API.G_TRUE,                 --Fijo
                                                                                                      p_validation_level  => FND_API.G_VALID_LEVEL_FULL,     --Fijo
                                                                                                      x_return_status     => l_return_status_b,              --Salida 1
                                                                                                      x_msg_count         => l_msg_count_b,                  --Salida 2
                                                                                                      x_msg_data          => l_msg_data_b,                   --Salida 3
                                                                                                      p_cash_receipt_id   => l_cr_id_h,                      --ENTRADA
                                                                                                      p_apply_date         => v_receipt_date,
                                                                                                      p_apply_gl_date     => v_gl_date,
                                                                                                      p_customer_trx_id   => v_customer_trx_id,
                                                                                                      p_amount_applied    => v_apply_amount,
                                                                                                      p_amount_applied_from => v_amt_appl_from,
                                                                                                      p_trans_to_receipt_rate => v_trn_to_rec_rate,
                                                                                                      p_attribute_rec  =>   v_rec_attribute
                                                                                                   );

                                                         fnd_file.PUT_LINE(fnd_file.log, '              l_cr_id_h: '||TO_CHAR(l_cr_id_h));
                                                         fnd_file.PUT_LINE(fnd_file.log, '              l_return_status_b: '||l_return_status_b);
                                                         fnd_file.PUT_LINE(fnd_file.log, '              l_msg_data_b: '||l_msg_data_b);
                                                         fnd_file.PUT_LINE(fnd_file.log, ' ');

                                                         --+
                                                         IF l_return_status_b <> 'S' THEN
                                                             IF l_msg_count_b = 1 THEN
                                                                 p_errmsg := 'Error al Aplicar el Pago en el  Recibo '||v_receipt_number||' de la Factura  ' ||v_trx_number ||' por el monto de  '||TRIM(TO_CHAR(v_apply_amount,'999,999,999.99'))|| '   : '|| l_msg_data_b;
                                                                 v_errmsg := TRIM(v_errmsg)||' '||p_errmsg;
                                                                 apps.fnd_file.put_line (apps.fnd_file.log, p_errmsg);
                                                                 apps.fnd_file.put_line (apps.fnd_file.output, p_errmsg);
                                                                 l_flag := 'N';
                                                                 l_error := 'S';
                                                             ELSIF l_msg_count_b > 1 THEN
                                                                 l_msg_index := Fnd_Msg_Pub.G_FIRST;
                                                                 l_encoded := Fnd_Api.G_TRUE;
                                                                 WHILE l_msg_count_b > 0 LOOP
                                                                           l_msg_index := l_msg_index + 1;
                                                                           Fnd_Msg_Pub.GET(l_msg_index, l_encoded, p_data => l_msg_data_b,p_msg_index_out => l_msg_index_out);
                                                                           p_errmsg := p_errmsg||' '||l_msg_data_b;
                                                                           l_msg_count_b := l_msg_count_b - 1;
                                                                 END LOOP;
                                                                 p_errmsg := 'Error al Aplicar el Pago en el  Recibo '||v_receipt_number||' de la Factura  ' ||v_trx_number ||' por el monto de  '||TRIM(TO_CHAR(v_apply_amount,'999,999,999.99'))|| '   : '|| p_errmsg;
                                                                 v_errmsg := TRIM(v_errmsg)||' '||p_errmsg;
                                                                 apps.fnd_file.put_line (apps.fnd_file.log, p_errmsg);
                                                                 apps.fnd_file.put_line (apps.fnd_file.output, p_errmsg);
                                                             END IF;
                                                             l_flag := 'N';
                                                             l_error := 'S';
                                                             RETCODE := '1';
                                                             ROLLBACK;

                                                             UPDATE BOLINF.XX_SV_CARGA_RECEIPTS
                                                                    SET STATUS = 'PE',
                                                                           ERROR_DESCRIPTION = v_errmsg
                                                                     WHERE ROWID = B.ROWID;

                                                             COMMIT;
                                                         ELSE
                                                             COMMIT;
                                                             l_flag := 'S';
                                                             l_error := 'N';
                                                             apps.fnd_file.put_line (apps.fnd_file.output, 'APLICACION DE PAGO');
                                                             apps.fnd_file.put_line (apps.fnd_file.output, '===================');
                                                             apps.fnd_file.put_line (apps.fnd_file.output, 'RECIBO NO.         : '||v_receipt_number);
                                                             apps.fnd_file.put_line (apps.fnd_file.output, 'FACTURA            : '||v_trx_number);
                                                             apps.fnd_file.put_line (apps.fnd_file.output, 'MONTO APLICADO     : '||TRIM(TO_CHAR(v_apply_amount,'999,999,999.99')));
                                                             apps.fnd_file.put_line (apps.fnd_file.output, 'MONTO APPLIED FROM : '||TRIM(TO_CHAR(v_amt_appl_from,'999,999,999.99')));
                                                             apps.fnd_file.put_line (apps.fnd_file.output, 'FECHA APPLIED      : '||TO_CHAR(v_receipt_date,'DD-MON-YYYY'));
                                                             apps.fnd_file.put_line (apps.fnd_file.output, 'FECHA CONTABLE     : '||TO_CHAR(v_gl_date,'DD-MON-YYYY'));
                                                             apps.fnd_file.put_line (apps.fnd_file.output, 'RECEIPT RATE       : '||v_trn_to_rec_rate);                                                             apps.fnd_file.put_line (apps.fnd_file.output, '===================');
                                                             apps.fnd_file.new_line(fnd_file.output, 1);

                                                             UPDATE BOLINF.XX_SV_CARGA_RECEIPTS
                                                                    SET STATUS = 'OK',
                                                                           ERROR_DESCRIPTION = NULL
                                                                     WHERE ROWID = B.ROWID;

                                                             COMMIT;
                                                         END IF;

                                                    END IF;
                                               END IF;

                                               IF  l_error = 'S' THEN
                                                   UPDATE BOLINF.XX_SV_CARGA_RECEIPTS
                                                        SET STATUS = 'E',
                                                               ERROR_DESCRIPTION = v_errmsg
                                                   WHERE ROWID = B.ROWID;
                                                   COMMIT;
                                                    l_error := 'N';
                                               END IF;

                                        END;
                                 END LOOP;
                             END IF;

                      END;
               END LOOP;
               COMMIT;
         ELSE
                fnd_file.PUT_LINE(fnd_file.OUTPUT, 'NO EXISTE DATOS A SER PROCESADOS O REPROCESADOS');
         END IF;

EXCEPTION
      WHEN OTHERS THEN
                RETCODE := '2';
                errbuf := SQLERRM;
                fnd_file.PUT_LINE(fnd_file.OUTPUT, 'ERROR: '||SQLERRM);
                fnd_file.PUT_LINE(fnd_file.LOG, 'ERROR: '||SQLERRM);
                ROLLBACK;
END XX_SV_CREATE_APPLY_RECEIPT;

--+

PROCEDURE XX_SV_DELETE_RECEIPT_INT (ERRBUF             OUT VARCHAR2,
                                                                RETCODE          OUT VARCHAR2,
                                                                 ERRORS_ONLY   IN  VARCHAR2
                                                               ) IS
BEGIN

    IF ( ERRORS_ONLY = 'Y' ) THEN
        DELETE FROM XX_SV_CARGA_RECEIPTS
         WHERE STATUS IN ('PE','E');

        DELETE FROM XX_SV_CARGA_RECEIPTS
         WHERE STATUS_RECIPT IN ('RE');
          fnd_file.PUT_LINE(fnd_file.OUTPUT, 'Se marcaron los Registros con ERROR de la tabla Temporal');

    ELSE
        DELETE FROM XX_SV_CARGA_RECEIPTS;
        fnd_file.PUT_LINE(fnd_file.OUTPUT, 'Se marcaron todos los Registros de la Tabla Temporal');
    END IF;
    COMMIT;
    fnd_file.PUT_LINE(fnd_file.OUTPUT, 'Se Borraron todos los Registros Marcados');

    RETCODE := '0';
    --+

EXCEPTION
      WHEN OTHERS  THEN
                retcode := '2';
                errbuf := SQLERRM;
                fnd_file.PUT_LINE(fnd_file.OUTPUT, 'ERROR: '||SQLERRM);
                ROLLBACK;
END XX_SV_DELETE_RECEIPT_INT;

FUNCTION xx_search_factura (P_NUMERO_FACTURA  IN VARCHAR2,
                                             P_BILL_TO_SITE_USE_ID   IN NUMBER,
                                              P_CUST_TRX_TYPE_ID     IN NUMBER
                                            ) RETURN NUMBER IS


BEGIN

       SELECT CUSTOMER_TRX_ID
           INTO l_customer_trx_id
       FROM APPS.RA_CUSTOMER_TRX_ALL
       WHERE TRX_NUMBER = P_NUMERO_FACTURA
           AND BILL_TO_SITE_USE_ID = P_BILL_TO_SITE_USE_ID
           AND CUST_TRX_TYPE_ID = P_CUST_TRX_TYPE_ID;

        RETURN l_customer_trx_id;

EXCEPTION
      WHEN OTHERS  THEN
         RETURN NULL;

END xx_search_factura;

FUNCTION xx_get_customer_id (TCNFOL IN VARCHAR2) RETURN NUMBER IS
  --+

BEGIN
       Select Customer_Id
          Into l_customer_id
       From Apps.Ar_Bill_To_Addresses_Active_V A
       Where A.Orig_System_Reference = TCNFOL;

   --+
   RETURN l_customer_id;
   --+
EXCEPTION
        WHEN OTHERS THEN
                  RETURN 0;
END xx_get_customer_id;
--+
FUNCTION xx_get_customer_site_use_id (CAID IN NUMBER,
                                                             NUMERO_FACTURA IN VARCHAR2,
                                                             P_CUST_TRX_TYPE_ID  IN  NUMBER) RETURN NUMBER IS

BEGIN
     BEGIN
         SELECT TR.BILL_TO_SITE_USE_ID
            INTO l_customer_site_use_id
         FROM RA_CUSTOMER_TRX_ALL TR,
                  HZ_CUST_ACCOUNTS_ALL CA
         WHERE TR.BILL_TO_CUSTOMER_ID = CA.CUST_ACCOUNT_ID
             AND TR.TRX_NUMBER = NUMERO_FACTURA
             AND CA.CUST_ACCOUNT_ID = CAID
             AND TR.CUST_TRX_TYPE_ID = P_CUST_TRX_TYPE_ID;
     EXCEPTION
                WHEN OTHERS THEN
                          l_customer_site_use_id := NULL;
     END;


     IF NVL(l_customer_site_use_id,0) = 0 THEN
         BEGIN
              SELECT TR.BILL_TO_SITE_USE_ID
                  INTO l_customer_site_use_id
              FROM RA_CUSTOMER_TRX_ALL TR,
                       HZ_CUST_ACCOUNTS_ALL CA
              WHERE TR.BILL_TO_CUSTOMER_ID = CA.CUST_ACCOUNT_ID
                 AND TR.TRX_NUMBER = NUMERO_FACTURA
                 AND CA.CUST_ACCOUNT_ID = CAID;
         EXCEPTION
                WHEN OTHERS THEN
                          l_customer_site_use_id := NULL;
         END;

     END IF;


    RETURN l_customer_site_use_id;

EXCEPTION
      WHEN OTHERS
      THEN
         RETURN (NULL);
END xx_get_customer_site_use_id;
--+
FUNCTION xx_get_receipt_method_id (METODO IN VARCHAR2) RETURN NUMBER IS


   BEGIN

       SELECT DISTINCT RM.RECEIPT_METHOD_ID
         INTO l_receipt_method_id
         FROM AR_RECEIPT_METHODS RM
        WHERE RM.NAME = METODO;

    RETURN l_receipt_method_id;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN (NULL);
END xx_get_receipt_method_id;
--+
FUNCTION xx_get_remit_bank_acct_id (CUENTA IN VARCHAR2) RETURN NUMBER IS


   BEGIN

   SELECT BAU.BANK_ACCT_USE_ID
     INTO l_remittance_bank_account_id
     FROM CE_BANK_ACCT_USES_ALL BAU,
          CE_BANK_ACCOUNTS BA
    WHERE BAU.BANK_ACCOUNT_ID = BA.BANK_ACCOUNT_ID
      AND BA.BANK_ACCOUNT_NUM =  CUENTA;

    RETURN l_remittance_bank_account_id;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN (NULL);
END xx_get_remit_bank_acct_id;
--+
FUNCTION xx_validate_apply_amount(NUM_REC IN VARCHAR2,
                                  FOL IN VARCHAR2) RETURN NUMBER IS


BEGIN

    SELECT SUM(MONTO_AFECTADO)
      INTO l_apply_amount_sum
      FROM XX_SV_CARGA_RECEIPTS
     WHERE NVL(NUMERO_PAGO, 'NULL') = NVL(NUM_REC, 'NULL')
       AND NVL(TCNFOL, 'NULL') = NVL(FOL, 'NULL');

    SELECT VALOR_PAGO
      INTO l_receipt_amount
      FROM XX_SV_CARGA_RECEIPTS
     WHERE NVL(NUMERO_PAGO, 'NULL') = NVL(NUM_REC, 'NULL')
       AND NVL(TCNFOL, 'NULL') = NVL(FOL, 'NULL')
       AND ROWNUM = 1;

    IF  nvl(l_apply_amount_sum,0) < nvl(l_receipt_amount,0) THEN
        RETURN 1;
    ELSIF  nvl(l_apply_amount_sum,0) = nvl(l_receipt_amount,0) THEN
              RETURN 1;
    ELSE
        fnd_file.PUT_LINE(fnd_file.OUTPUT, 'El Monto del Recibo es inferios al de las Facturas');
        fnd_file.PUT_LINE(fnd_file.OUTPUT, 'Monto del Recibo: '||to_char(nvl(l_receipt_amount,0),'999,999,999.99'));
        fnd_file.PUT_LINE(fnd_file.OUTPUT, 'Monto del Factura: '||to_char(nvl(l_apply_amount_sum,0),'999,999,999.99'));
        RETURN 0;
    END IF;

EXCEPTION
      WHEN OTHERS THEN
                RETURN (NULL);
END xx_validate_apply_amount;
--+
FUNCTION xx_search_receipt(NUMERO_PAGO VARCHAR2,
                           CUST_SITE   VARCHAR2,
                           P_ORG_ID     NUMBER) RETURN NUMBER IS

    BEGIN

        SELECT CASH_RECEIPT_ID
          INTO l_rece_id
          FROM AR_CASH_RECEIPTS_ALL
         WHERE STATUS = 'UNAPP'
           AND ORG_ID = P_ORG_ID
           AND RECEIPT_NUMBER = NUMERO_PAGO
           AND CUSTOMER_SITE_USE_ID = CUST_SITE;

        RETURN l_rece_id;

   EXCEPTION
      WHEN OTHERS THEN
         RETURN (NULL);
END xx_search_receipt;

FUNCTION xx_get_set_of_books (P_ORG_ID IN NUMBER) RETURN NUMBER IS

   BEGIN

    SELECT SET_OF_BOOKS_ID
      INTO l_set_of_books
      FROM HR_OPERATING_UNITS
     WHERE ORGANIZATION_ID = P_ORG_ID;

    RETURN l_set_of_books;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN (NULL);
END xx_get_set_of_books;


FUNCTION xx_org_id (p_name IN VARCHAR2) RETURN NUMBER IS


BEGIN

   select organization_id
      into l_organization_id
   from hr_operating_units
   where name = p_name;

   return l_organization_id;

EXCEPTION
      WHEN OTHERS  THEN
         RETURN NULL;
END xx_org_id;

FUNCTION xx_cust_trx_type_id (p_name IN VARCHAR2, p_set_of_books_id IN number) RETURN NUMBER IS


BEGIN

    select cust_trx_type_id
        into l_cust_trx_type_id
    from Ra_Cust_Trx_Types_All
    where name like p_name
    and set_of_books_id = p_set_of_books_id;

   return l_cust_trx_type_id;

EXCEPTION
      WHEN OTHERS  THEN
         RETURN NULL;
END xx_cust_trx_type_id;


FUNCTION F_LIMPIAR (P_Texto IN VARCHAR2)  Return Varchar2 Is
    Lv_Texto   Varchar2(4000) := Null;
Begin

   Lv_Texto := P_Texto;

   Lv_Texto := Replace(Lv_Texto,Chr(9));
   Lv_Texto := Replace(Lv_Texto,Chr(10));
   Lv_Texto := Replace(Lv_Texto,Chr(11));
   Lv_Texto := Replace(Lv_Texto,Chr(13));
   Lv_Texto := Replace(Lv_Texto,Chr(27));
   Lv_Texto := Replace(Lv_Texto,Chr(34));
   Lv_Texto := Replace(Lv_Texto,Chr(160));
   Lv_Texto := Replace(Lv_Texto,Chr(170));
   Lv_Texto := Replace(Lv_Texto,Chr(176));
   Lv_Texto := Replace(Lv_Texto,Chr(186));
   Lv_Texto := Trim(Rtrim(Ltrim(Lv_Texto)));

   Return (Lv_Texto);
Exception
        When others then
           return(null);
end F_LIMPIAR;



END XX_SV_RECEIPTS_PKG;
/
