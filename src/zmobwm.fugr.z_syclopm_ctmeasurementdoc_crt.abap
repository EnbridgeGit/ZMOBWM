FUNCTION Z_SYCLOPM_CTMEASUREMENTDOC_CRT.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IS_BAPI_INPUT) TYPE  /SYCLO/CORE_BAPI_INPUT_STR
*"         DEFAULT SPACE
*"     VALUE(IV_MEASURING_POINT) TYPE  IMRG-POINT DEFAULT SPACE
*"     VALUE(IV_SECONDARY_INDEX) TYPE  IMPT-PSORT DEFAULT SPACE
*"     VALUE(IV_READING_DATE) TYPE  IMRG-IDATE DEFAULT SY-DATUM
*"     VALUE(IV_READING_TIME) TYPE  IMRG-ITIME DEFAULT SY-UZEIT
*"     VALUE(IV_SHORT_TEXT) TYPE  IMRG-MDTXT DEFAULT SPACE
*"     VALUE(IV_READER) TYPE  IMRG-READR DEFAULT SY-UNAME
*"     VALUE(IV_ORIGIN_INDICATOR) TYPE  IMRG-GENER DEFAULT 'A'
*"     VALUE(IV_READING_AFTER_ACTION) TYPE  IMRG-DOCAF DEFAULT SPACE
*"     VALUE(IV_RECORDED_VALUE_FLT) TYPE  IMRC_CNTRR DEFAULT SPACE
*"     VALUE(IV_RECORDED_VALUE) TYPE  RIMR0-RECDC DEFAULT SPACE
*"     VALUE(IV_RECORDED_UNIT) TYPE  RIMR0-UNITR DEFAULT SPACE
*"     VALUE(IV_DIFFERENCE_READING) TYPE  IMRG-IDIFF DEFAULT SPACE
*"     VALUE(IV_CODE_CATALOGUE) TYPE  IMRG-CODCT DEFAULT SPACE
*"     VALUE(IV_CODE_GROUP) TYPE  IMRG-CODGR DEFAULT SPACE
*"     VALUE(IV_VALUATION_CODE) TYPE  IMRG-VLCOD DEFAULT SPACE
*"     VALUE(IV_CODE_VERSION) TYPE  IMRG-CVERS DEFAULT SPACE
*"     VALUE(IV_USER_DATA) TYPE  IMRG_USR DEFAULT SPACE
*"     VALUE(IV_CUSTOM_CHECK_DUPREC) TYPE  IREF-IIND DEFAULT SPACE
*"     VALUE(IV_WITH_DIALOG_SCREEN) TYPE  IREF-IIND DEFAULT SPACE
*"     VALUE(IV_PREPARE_UPDATE) TYPE  IREF-IIND DEFAULT 'X'
*"     VALUE(IV_COMMIT_WORK) TYPE  IREF-IIND DEFAULT 'X'
*"     VALUE(IV_WAIT_AFTER_COMMIT) TYPE  IREF-IIND DEFAULT 'X'
*"     VALUE(IV_CREATE_NOTIFICATION) TYPE  IREF-IIND DEFAULT SPACE
*"     VALUE(IV_NOTIFICATION_TYPE) TYPE  QMEL-QMART DEFAULT 'M2'
*"     VALUE(IV_NOTIFICATION_PRIO) TYPE  QMEL-PRIOK DEFAULT SPACE
*"  EXPORTING
*"     VALUE(ES_BAPI_OUTPUT) TYPE  /SYCLO/CORE_BAPI_OUTPUT_STR
*"     VALUE(EV_MEASUREMENT_DOCUMENT) TYPE  IMRG-MDOCM
*"     VALUE(ES_COMPLETE_DOCUMENT) TYPE  IMRG
*"     VALUE(EV_NOTIFICATION) TYPE  QMEL-QMNUM
*"     VALUE(EV_CUSTOM_DUPREC_OCCURED) TYPE  IREF-IIND
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"--------------------------------------------------------------------
*{   INSERT         D30K924572                                        1
*======================================================================*
*<SYCLODOC>
*  <CREATE_DATE> 11/18/2008 </CREATE_DATE>
*  <AUTHOR> Wenonah Jaques (Syclo International) </AUTHOR>
*  <DESCRIPTION>
*   BAPI wrapper to stream standard BAPIs to create Measurement
*   Documents.  Standard BAPI invoked:
*     'MEASUREM_DOCUM_RFC_SINGLE_001'
*  </DESCRIPTION>
*<!-- *----------------------CHANGE HISTORY-------------------------* -->
*  <REVISION_TAG date='11/18/2008' version='310_700' user='WJAQUES' >
*    <DESCRIPTION>Initial release</DESCRIPTION>
*  </REVISION_TAG>
*<!-- *-------------------------------------------------------------* -->
*  <REVISION_TAG date='5/15/2012' version='330_700 SP4' user='JWANG' >
*    <DESCRIPTION>
*       New parameters - accept Reading/Different Reading in floating format.
*       Allows international support.  Char format & floating format are
*       mutually exclusive.
*    </DESCRIPTION>
*    <BugID> SAPPQ-697 </BugID>
*  </REVISION_TAG>
*<!-- *-------------------------------------------------------------* -->
*</SYCLODOC>
*======================================================================*
**********************************************************************
* Data Declaration Section
**********************************************************************
*Constants
  CONSTANTS: lc_bapi_name TYPE funcname VALUE 'Z_SYCLOPM_CTMEASUREMENTDOC_CRT'.

**********************************************************************
* Additional Check for MEasPt - SLOWENBE PwC Nov 30, 2014
*    If valuation code supplied, reading needs to be "", not 0
**********************************************************************
  IF NOT IV_VALUATION_CODE IS INITIAL.
    IV_RECORDED_VALUE = ''.
  ENDIF.


**********************************************************************
* Template Section
**********************************************************************
  INCLUDE /syclo/core_bapi_template_incl.




*}   INSERT
ENDFUNCTION.
