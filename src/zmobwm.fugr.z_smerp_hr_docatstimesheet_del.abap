FUNCTION Z_SMERP_HR_DOCATSTIMESHEET_DEL.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IS_BAPI_INPUT) TYPE  /SYCLO/CORE_BAPI_INPUT_STR OPTIONAL
*"     VALUE(IV_PROFILE) TYPE  CATSVARIAN OPTIONAL
*"     VALUE(IV_TESTRUN) TYPE  TESTRUN OPTIONAL
*"     VALUE(IV_RELEASE_DATA) TYPE  RELEASE_DATA OPTIONAL
*"     VALUE(IS_WORKFLOW_AGENT) TYPE  SWHACTOR OPTIONAL
*"  EXPORTING
*"     VALUE(ES_BAPI_OUTPUT) TYPE  /SYCLO/CORE_BAPI_OUTPUT_STR
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      IT_CATSRECORDS_IN STRUCTURE  BAPICATS4
*"      IT_WORKFLOW_TEXT STRUCTURE  SOLISTI1 OPTIONAL
*"----------------------------------------------------------------------
*======================================================================*
*<SMERPDOC>
*  <CREATE_DATE> 06/17/2013 </CREATE_DATE>
*  <AUTHOR> Christopher Jones </AUTHOR>
*  <DESCRIPTION>
*     BAPI wrapper to delete existing CATS time sheet records. Standard
*     BAPI invoked: 'BAPI_CATIMESHEETMGR_DELETE'
*  </DESCRIPTION>
*<!-- *----------------------CHANGE HISTORY-------------------------*-->
*  <REVISION_TAG date='06/17/2013' version='610_700 ERP' user='JONESCHRI1'>
*    <DESCRIPTION> Initial release. </DESCRIPTION>
*    <BugID> ERPADDON-3 </BugID>
*  </REVISION_TAG>
*<!-- *-------------------------------------------------------------*-->
*</SMERPDOC>
*======================================================================*
** SLOWENBE PwC - Delete Method needs to read CATS Profile from User
**  Not provided in Standard SAP Mobile Framework for Work Manager
  IF iv_profile IS INITIAL.
    GET PARAMETER ID 'CVR' FIELD iv_profile.
  ENDIF.
** End

**********************************************************************
* Template Section
**********************************************************************
  include /syclo/core_bapi_template_incl.

ENDFUNCTION.
