FUNCTION z_smerp_pm_donotification_upd.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IS_BAPI_INPUT) TYPE  /SYCLO/CORE_BAPI_INPUT_STR OPTIONAL
*"     VALUE(IV_NOTIF_NO) TYPE  QMNUM
*"     VALUE(IS_NOTIF_HEADER) TYPE  BAPI2080_NOTHDRI DEFAULT SPACE
*"     VALUE(IS_NOTIF_HEADER_X) TYPE  BAPI2080_NOTHDRI_X OPTIONAL
*"  EXPORTING
*"     VALUE(ES_BAPI_OUTPUT) TYPE  /SYCLO/CORE_BAPI_OUTPUT_STR
*"     VALUE(ES_NOTIF_HEADER) TYPE  BAPI2080_NOTHDRE
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      IT_NOTIF_ITEM STRUCTURE  BAPI2080_NOTITEMI OPTIONAL
*"      IT_NOTIF_ITEM_X STRUCTURE  BAPI2080_NOTITEMI_X OPTIONAL
*"      IT_NOTIF_CAUSE STRUCTURE  BAPI2080_NOTCAUSI OPTIONAL
*"      IT_NOTIF_CAUSE_X STRUCTURE  BAPI2080_NOTCAUSI_X OPTIONAL
*"      IT_NOTIF_TASK STRUCTURE  BAPI2080_NOTTASKI OPTIONAL
*"      IT_NOTIF_TASK_X STRUCTURE  BAPI2080_NOTTASKI_X OPTIONAL
*"      IT_NOTIF_ACTIVITY STRUCTURE  BAPI2080_NOTACTVI OPTIONAL
*"      IT_NOTIF_ACTIVITY_X STRUCTURE  BAPI2080_NOTACTVI_X OPTIONAL
*"      IT_NOTIF_PARTNER STRUCTURE  BAPI2080_NOTPARTNRI OPTIONAL
*"      IT_NOTIF_PARTNER_X STRUCTURE  BAPI2080_NOTPARTNRI_X OPTIONAL
*"--------------------------------------------------------------------
*{   INSERT         D30K924796                                        1
*======================================================================*
*<SMERPDOC>
*  <CREATE_DATE> 06/20/2013 </CREATE_DATE>
*  <AUTHOR> Syam Yalamati </AUTHOR>
*  <DESCRIPTION>
*     BAPI wrapper to stream standard BAPIs to modify existing notification
*     Standard BAPIs invoked:
*       'BAPI_ALM_NOTIF_DATA_MODIFY'
*       'BAPI_ALM_NOTIF_SAVE' and 'BAPI_TRANSACTION_COMMIT'
*  </DESCRIPTION>
*<!-- *----------------------CHANGE HISTORY------------------------* -->
*  <REVISION_TAG date='06/20/2013' version='610_700 ERP' user='SYALAMA'>
*    <DESCRIPTION>Initial release.</DESCRIPTION>
*  </REVISION_TAG>
*<!-- *----------------------CHANGE HISTORY------------------------* -->
*</SMERPDOC>
*======================================================================*
************************************************************************
* Template Section
************************************************************************
  IF  is_notif_header_x IS INITIAL AND
      it_notif_item_x IS INITIAL AND
      it_notif_cause_x IS INITIAL AND
      it_notif_task_x IS INITIAL AND
      it_notif_activity_x IS INITIAL AND
      it_notif_partner_x IS INITIAL.
    "Do Nothing as nothing was actually updated
  ELSE.
    INCLUDE /syclo/core_bapi_template_incl.
  ENDIF.
ENDFUNCTION.
