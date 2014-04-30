CREATE OR REPLACE PACKAGE BOLINF.XX_SV_RECEIPTS_PKG AUTHID CURRENT_USER AS



PROCEDURE XX_SV_CREATE_APPLY_RECEIPT ( ERRBUF              OUT VARCHAR2,
                                         RETCODE            OUT VARCHAR2,
                                         P_USER_ID          IN  NUMBER,
                                         P_RESP_ID          IN NUMBER,
                                         P_RESP_APP_ID   IN  NUMBER,
                                         P_ORG_ID            IN  NUMBER
                                      );

    PROCEDURE XX_SV_DELETE_RECEIPT_INT ( ERRBUF             OUT VARCHAR2,
                                         RETCODE          OUT VARCHAR2,
                                         ERRORS_ONLY   IN  VARCHAR2
                                       );

     FUNCTION XX_SEARCH_FACTURA ( P_NUMERO_FACTURA  IN VARCHAR2,
                               P_BILL_TO_SITE_USE_ID   IN NUMBER,
                               P_CUST_TRX_TYPE_ID     IN NUMBER
                            ) RETURN NUMBER;

    FUNCTION XX_GET_CUSTOMER_ID (TCNFOL  IN VARCHAR2) RETURN NUMBER;

    FUNCTION XX_GET_CUSTOMER_SITE_USE_ID (CAID IN NUMBER,
                                         NUMERO_FACTURA IN VARCHAR2,
                                         P_CUST_TRX_TYPE_ID   IN NUMBER
                                       ) RETURN NUMBER;

    FUNCTION XX_GET_RECEIPT_METHOD_ID (METODO IN VARCHAR2) RETURN NUMBER;

    FUNCTION XX_GET_REMIT_BANK_ACCT_ID (CUENTA IN VARCHAR2) RETURN NUMBER;

    FUNCTION XX_VALIDATE_APPLY_AMOUNT ( NUM_REC IN VARCHAR2,
                                                             FOL IN VARCHAR2
                                                           ) RETURN NUMBER;

    FUNCTION XX_SEARCH_RECEIPT( NUMERO_PAGO  IN VARCHAR2,
                                CUST_SITE  IN  VARCHAR2,
                                P_ORG_ID    IN  NUMBER
                              ) RETURN NUMBER;

    FUNCTION XX_GET_SET_OF_BOOKS (P_ORG_ID   IN NUMBER) RETURN NUMBER;

    FUNCTION XX_ORG_ID (P_NAME IN VARCHAR2) RETURN NUMBER;


    FUNCTION XX_CUST_TRX_TYPE_ID ( P_NAME IN VARCHAR2,
                                   P_SET_OF_BOOKS_ID IN NUMBER
                                 ) RETURN NUMBER;

    FUNCTION F_LIMPIAR (P_TEXTO IN VARCHAR2)  RETURN VARCHAR2;

END XX_SV_RECEIPTS_PKG;
/
