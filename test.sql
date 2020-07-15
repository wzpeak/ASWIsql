SELECT
   :P_LOGO     p_logo,
--    UPPER(regexp_replace(legal_entity.NAME,'[^0-9a-zA-Z[:space:]]'))                com_name,
       UPPER(legal_entity.NAME)                                                            com_name,
--    UPPER(regexp_replace(legal_entity.NAME,'[^0-9a-zA-Z*\)*\(*\）*\（[:space:]]'))                com_name,
--  UPPER(legal_entity.NAME)                          com_name,
--   SUBSTR(in_head.COMMENTS,INSTR(in_head.COMMENTS,'Attn:') +5)                      attn,
 in_head.COMMENTS                     attn,
 in_head.COMMENTS                     com,
    decode(in_head.TRX_CLASS,'DM','DEBIT NOTE', 'CM','CREDIT NOTE','INV','DEBIT NOTE','ONACC','CREDIT NOTE'  )                      trx_class,
        --   TRIM(substr(party_info.PARTY_NAME,1, instr(party_info.PARTY_NAME,'(') -1) || substr(party_info.PARTY_NAME,instr(party_info.PARTY_NAME,')') +1) )                    customer,
         regexp_replace(party_info.PARTY_NAME,'[^0-9a-zA-Z[:space:]]')               customer,
        --  party_info.PARTY_NAME                      customer,
         party_info.ADDRESS1                      address1,
        --  party_info_lg.ADDRESS1                      lg_address1,
         '23rd Floor, Wheelock House, 20 Pedder Street, Central, Hong Kong'                      lg_address1,
        in_head.TRX_NUMBER,
        in_head.TRX_DATE,
        in_head.SPECIAL_INSTRUCTIONS               header_desc,
        in_head.STRUCTURED_PAYMENT_REFERENCE       stru_pay,
       in_line.DESCRIPTION,
       in_line.EXTENDED_AMOUNT
FROM
     XLE_ENTITY_PROFILES                         legal_entity,
    RA_CUSTOMER_TRX_ALL   in_head,
    RA_CUSTOMER_TRX_LINES_ALL  in_line,
     HZ_CUST_ACCOUNTS                       pty_act,
    HZ_PARTIES                             party_info,
    HZ_PARTIES                             party_info_lg

WHERE
    in_head.CUSTOMER_TRX_ID = in_line.CUSTOMER_TRX_ID
AND  in_head.BILL_TO_CUSTOMER_ID = pty_act.CUST_ACCOUNT_ID
AND  party_info.PARTY_ID = pty_act.PARTY_ID
---------2020/05/26-----------
AND  party_info_lg.PARTY_ID = legal_entity.PARTY_ID
 AND in_head.LEGAL_ENTITY_ID = legal_entity.LEGAL_ENTITY_ID
  ---  AND in_head.TRX_CLASS  IN ('CM','DM','INV')
AND ( in_head.TRX_NUMBER IN (:P_DEBIT_NOTE_NO) OR 'agn' IN (:P_DEBIT_NOTE_NO || 'agn'))  order by in_line.LINE_NUMBER


<?SUP_NAME?>
<?SUP_ADRES1?>
<?SUP_ADRES2?>
<?SUP_ADRES3?>

<xsl:value-of select='SUP_NAME'/>

<?concat(SUP_NAME,'&#x000A;',SUP_ADRES1,'&#x000A;',SUP_ADRES2,'&#x000A;',SUP_ADRES3)?>
<?concat(SUP_NAME,'&#x000A;',SUP_ADRES1,'&#x000A;',SUP_ADRES2,'&#x000A;',SUP_ADRES3)?>