FUNCTION Z_SMERP_HR_DOCATSTIMESHEET_GET .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IS_BAPI_INPUT) TYPE  /SYCLO/CORE_BAPI_INPUT_STR OPTIONAL
*"     VALUE(IS_RETURN_DATA_DEMAND) TYPE  /SYCLO/HR_CATS_BAPI_DEMND_STR
*"       DEFAULT 'XXXX'
*"     VALUE(IV_FROM_DATE) TYPE  BEGDA OPTIONAL
*"     VALUE(IV_TO_DATE) TYPE  ENDDA OPTIONAL
*"     VALUE(IV_INCLUDE_ZERO_TIME) TYPE  WDY_BOOLEAN DEFAULT SPACE
*"  EXPORTING
*"     VALUE(ES_BAPI_OUTPUT) TYPE  /SYCLO/CORE_BAPI_OUTPUT_STR
*"  TABLES
*"      IT_EMPLOYEE_ID_RA STRUCTURE  /SYCLO/HR_PERNR_RANGE_STR OPTIONAL
*"      IT_WORKITEMID_RA STRUCTURE  /SYCLO/HR_WORKITEMID_RANGE_STR
*"       OPTIONAL
*"      IT_COUNTER_RA STRUCTURE  /SYCLO/HR_COUNTER_RANGE_STR OPTIONAL
*"      IT_PLANT_RA STRUCTURE  /SYCLO/CORE_RANGE_STR OPTIONAL
*"      IT_CO_AREA_RA STRUCTURE  /SYCLO/CORE_RANGE_STR OPTIONAL
*"      IT_SEND_CCTR_RA STRUCTURE  /SYCLO/CO_KOSTL_RANGE_STR OPTIONAL
*"      IT_ACTTYPE_RA STRUCTURE  /SYCLO/CORE_RANGE_STR OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      ET_VALID_CATSRECORDS STRUCTURE  /SYCLO/HR_VALID_CATSDB_STR
*"       OPTIONAL
*"      ET_CATSRECORDS STRUCTURE  /SYCLO/HR_CATSDB_STR OPTIONAL
*"      ET_CATSRECORDS_LONGTEXT STRUCTURE
*"        /SYCLO/HR_CATSDB_LONGTEXT_STR OPTIONAL
*"      ET_CATSRECORDS_OVERVIEW STRUCTURE
*"        /SYCLO/HR_CATSDB_OVERVIEW_STR OPTIONAL
*"----------------------------------------------------------------------
*======================================================================*
*<SMERPDOC>
*  <CREATE_DATE> 06/17/2013 </CREATE_DATE>
*  <AUTHOR> Christopher Jones </AUTHOR>
*  <DESCRIPTION>
*     BAPI wrapper fetches list of HR time sheet records for the specified
*     employees.
*  </DESCRIPTION>
*<!-- *----------------------CHANGE HISTORY-------------------------*-->
*  <REVISION_TAG date='06/17/2013' version='610_700 ERP' user='JONESCHRI1'>
*    <DESCRIPTION> Initial release. </DESCRIPTION>
*    <BugID> ERPADDON-3 </BugID>
*  </REVISION_TAG>
*<!-- *-------------------------------------------------------------*-->
*</SMERPDOC>
*======================================================================*
**********************************************************************
* SLOWENBE PwC 2014.10.01 - Adjust Time Entry Period to 3 weeks prior
* to current week.  Required for Payroll purposes
**********************************************************************


  SUBTRACT 7 FROM iv_from_date.
   ADD 20 to iv_to_date.
*  Zero Time is Required to Retrieve Wage Type related records
  IV_INCLUDE_ZERO_TIME = 'X'.

**********************************************************************
* Template Section
**********************************************************************
  include /syclo/core_bapi_template_incl.

ENDFUNCTION.
