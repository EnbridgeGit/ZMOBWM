class Z_SMERP_CL_PM_CLSSIFICATION_DO definition
  public
  inheriting from /SYCLO/CL_CORE_DO_HANDLER_BASE
  create public .

public section.
*"* public components of class Z_SMERP_CL_PM_CLSSIFICATION_DO
*"* do not include other source files here!!!

  methods /SYCLO/IF_CORE_DO_HANDLER~UPDATE
    redefinition .
protected section.
*"* protected components of class Z_SMERP_CL_PM_CLSSIFICATION_DO
*"* do not include other source files here!!!
*"* private components of class /SYCLO/CL_PM_CLASSIFICATION_DO
*"* do not include other source files here!!!
private section.
ENDCLASS.



CLASS Z_SMERP_CL_PM_CLSSIFICATION_DO IMPLEMENTATION.


METHOD /syclo/if_core_do_handler~update.
************************************************************************
* Changes:
* SDP85964 GYMANA - Added class method call to ZPM_CL_FUNCLOC_UTIL
*                   to update Station Capacity Indicator after Equipment
*                   Characteristic change
* ACR247   GYMANA - Added code to set indicator only for engineering
*                   relevant equipment identified by level 5 FLOC
************************************************************************
**********************************************************************
* Types Declaration Section
************************************************************************
  TYPES: BEGIN OF ty_cabn,
          atinn TYPE cabn-atinn,
          atfor TYPE cabn-atfor,
         END OF ty_cabn.

************************************************************************
* Data Declaration Section
************************************************************************
*OO Reference Variables
  DATA: lref_exception TYPE REF TO cx_root,
        lref_do_serv   TYPE REF TO /syclo/cl_core_do_services. "#EC NEEDED

*Tables and Structures
  "The following structure contains reference to all supported import
  "parameters supported by MDO handler. Parameter name is set to the
  "same as what is defined in BAPI wrapper sigature for simplicity.
  DATA: BEGIN OF ls_mdo_input_vals,
          iv_equnr    TYPE REF TO equnr,
          iv_funcloc  TYPE REF TO tplnr,
          iv_classnum TYPE REF TO klasse_d,
          iv_charact  TYPE REF TO atnam,
          iv_value    TYPE REF TO atwrt,
        END OF ls_mdo_input_vals.

  "The following structure contains reference to all supported import
  "parameters supported by MDO handler. Parameter name is set to the same
  "as what is defined in BAPI wrapper sigature for simplicity.
  DATA: BEGIN OF ls_dof_filter_vals,
          trans_code_check TYPE REF TO /syclo/core_range_tab,
        END OF ls_dof_filter_vals.

*  DATA: ls_notif_header_export TYPE bapi2080_nothdre.
  DATA: lt_return TYPE bapiret2_t,
        ls_return TYPE bapiret2,
        ls_cabn   TYPE ty_cabn,
        lv_tabl   TYPE tabelle,
        lv_klart  TYPE klassenart,
        lv_atnam  TYPE atnam,
        lv_msg    TYPE string.
  DATA: lv_authorized TYPE /syclo/core_boolean_dte.

  DATA:   lv_objek    TYPE ausp-objek,
          lv_atinn  TYPE atinn,
          lv_tplkz TYPE tplkz,     "Structure indicator    SDP85964
          lv_funcloc TYPE tplnr,   "Functional Location    SDP85964
          lv_cuobj TYPE cuobj, "Internal number            ACR247
          lv_count(3) TYPE N,  "                           ACR247
          lv_clint_c1 TYPE clint value 2590, "             ACR247
          lv_clint_c2 TYPE clint value 2591, "             ACR247
          lt_num    TYPE STANDARD TABLE OF bapi1003_alloc_values_num,
          lt_char   TYPE STANDARD TABLE OF bapi1003_alloc_values_char,
          lt_curr   TYPE STANDARD TABLE OF bapi1003_alloc_values_curr.

*Field Symbols
  FIELD-SYMBOLS: <return_tab> TYPE bapiret2_t.

  FIELD-SYMBOLS: <fs_char> TYPE bapi1003_alloc_values_char,
                  <fs_num> TYPE bapi1003_alloc_values_num,
                 <fs_curr> TYPE bapi1003_alloc_values_curr.

************************************************************************
* Main Section
************************************************************************
  TRY.
      me->message = 'Entering method ~ UPDATE...'(m14).
      me->logger->loginfo( iv_mobile_user = me->str_bapi_input-mobile_user
                           iv_mobile_id = me->str_bapi_input-mobile_id
                           iv_user_guid = me->str_bapi_input-user_guid
                           iv_message = me->message
                           iv_source = me->source ).

      " Set return time stamp at begining if exchange process not used
      IF me->mobile_timestamp_in IS INITIAL.
        me->mobile_timestamp_out = /syclo/cl_core_do_services=>get_sys_timestamp( ).
      ENDIF.
*----------------------------------------------------------------------*
* Step 1 - Initialization
*----------------------------------------------------------------------*
      lref_do_serv = /syclo/cl_core_do_services=>get_do_service(
                                       iref_logger = me->logger ).

      "-->Initialize input tables
      CREATE DATA: ls_mdo_input_vals-iv_equnr.
      CREATE DATA: ls_mdo_input_vals-iv_funcloc.
      CREATE DATA: ls_mdo_input_vals-iv_classnum.
      CREATE DATA: ls_mdo_input_vals-iv_charact.
      CREATE DATA: ls_mdo_input_vals-iv_value.

      " --Retrieve supplied MDO input data and map to local variables.
      " MDO input data are supplied by BAPI wrapper and mapped to MDO
      " data object by PREPROCESS_MAPPING
      me->oref_mdo_data->map_local_mobile_filter(
        CHANGING cs_filters = ls_mdo_input_vals ).

      " -->Retrieve filter settings as defined via ConfigPanel.
      " ConfigPanel filter settings has been mapped to MDO data object
      " by INITIALIZE_MDO_DATA
      me->oref_mdo_data->map_local_dof_filter(
        CHANGING cs_filters = ls_dof_filter_vals ).

      CLEAR: lv_tabl.
      IF NOT ls_mdo_input_vals-iv_equnr->* IS INITIAL.
        lv_objek = ls_mdo_input_vals-iv_equnr->*.
        lv_tabl = 'EQUI'.
        lv_klart = '002'.
      ELSEIF NOT ls_mdo_input_vals-iv_funcloc->* IS INITIAL.
        lv_objek = ls_mdo_input_vals-iv_funcloc->*.
        lv_tabl = 'IFLOT'.
        lv_klart = '003'.
      ENDIF.

      CALL FUNCTION 'CONVERSION_EXIT_ATINN_INPUT'
        EXPORTING
          input  = ls_mdo_input_vals-iv_charact->*
        IMPORTING
          output = lv_atinn.

*BAPI_OBJCL_GETDETAIL
      CALL FUNCTION 'BAPI_OBJCL_GETDETAIL'
        EXPORTING
          objectkey       = lv_objek
          objecttable     = lv_tabl
          classnum        = ls_mdo_input_vals-iv_classnum->*
          classtype       = lv_klart
        TABLES
          allocvaluesnum  = lt_num
          allocvalueschar = lt_char
          allocvaluescurr = lt_curr
          return          = lt_return.

      SELECT SINGLE atinn atfor
             FROM cabn
             INTO ls_cabn
             WHERE atinn = lv_atinn.

      CALL FUNCTION 'CONVERSION_EXIT_ATINN_OUTPUT'
        EXPORTING
          input  = ls_mdo_input_vals-iv_charact->*
        IMPORTING
          output = lv_atnam.

      IF sy-subrc EQ 0.
        CASE ls_cabn-atfor.
          WHEN 'CHAR'.

            READ TABLE lt_char ASSIGNING <fs_char> WITH KEY charact = lv_atnam.
            IF sy-subrc EQ 0.
              CLEAR <fs_char>.
              <fs_char>-charact = lv_atnam.
              <fs_char>-value_char = ls_mdo_input_vals-iv_value->*.
            ELSE.
              APPEND INITIAL LINE TO lt_char ASSIGNING <fs_char>.
              <fs_char>-charact = lv_atnam.
              <fs_char>-value_char = ls_mdo_input_vals-iv_value->*.
            ENDIF.
          WHEN 'NUM' OR 'DATE' OR 'TIME'.
            READ TABLE lt_num ASSIGNING <fs_num> WITH KEY charact = lv_atnam.
            IF sy-subrc EQ 0.
              CLEAR <fs_num>.
              <fs_num>-charact = lv_atnam.
              <fs_num>-value_from = ls_mdo_input_vals-iv_value->*.
            ELSE.
              APPEND INITIAL LINE TO lt_num ASSIGNING <fs_num>.
              <fs_num>-charact = lv_atnam.
              <fs_num>-value_from = ls_mdo_input_vals-iv_value->*.
            ENDIF.
          WHEN 'CURR'.
            READ TABLE lt_curr ASSIGNING <fs_curr> WITH KEY charact = lv_atnam.
            IF sy-subrc EQ 0.
              CLEAR <fs_curr>.
              <fs_curr>-charact = lv_atnam.
              <fs_curr>-value_from = ls_mdo_input_vals-iv_value->*.
            ELSE.
              APPEND INITIAL LINE TO lt_curr ASSIGNING <fs_curr>.
              <fs_curr>-charact = lv_atnam.
              <fs_curr>-value_from = ls_mdo_input_vals-iv_value->*.
            ENDIF.
          WHEN 'UDEF'.
        ENDCASE.
      ELSE.
        me->message = 'Invalid Classification.'.
        me->logger->logerror( iv_source = me->source
                              iv_message = me->message
                              iref_return_tab = iref_rfc_oo_data->dref_return ).
        RETURN.
      ENDIF.

**----------------------------------------------------------------------*
** Step 2 - Calling standard BAPI to update Characteristic Value
**----------------------------------------------------------------------*
      ASSIGN iref_rfc_oo_data->dref_return->* TO <return_tab>.
      me->message = 'Calling FuncMod ~ BAPI_OBJCL_CHANGE...'(i13).
      me->logger->loginfo( iv_mobile_user = me->str_bapi_input-mobile_user
                           iv_mobile_id = me->str_bapi_input-mobile_id
                           iv_user_guid = me->str_bapi_input-user_guid
                           iv_message = me->message
                           iv_source = me->source ).

      CALL FUNCTION 'BAPI_OBJCL_CHANGE'
        EXPORTING
          objectkey          = lv_objek
          objecttable        = lv_tabl
          classnum           = ls_mdo_input_vals-iv_classnum->*
          classtype          = lv_klart
          status             = '1'
        TABLES
          allocvaluesnumnew  = lt_num
          allocvaluescharnew = lt_char
          allocvaluescurrnew = lt_curr
          return             = lt_return.

      APPEND LINES OF lt_return TO <return_tab>.

      LOOP AT lt_return INTO ls_return WHERE type = 'E'
                                          OR type = 'A'.
        EXIT.
      ENDLOOP.
      IF sy-subrc EQ 0.
* Roll back changes
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      ELSE.
        me->commit( CHANGING ct_messages = <return_tab> ).
      ENDIF.

* SDP85964 GYMANA Start

*-- Find the Functional Location

      SELECT b~tplnr into lv_funcloc
        FROM EQUZ as a INNER JOIN ILOA as b
          ON a~iloan = b~iloan
       WHERE a~equnr = ls_mdo_input_vals-iv_equnr->*.
      ENDSELECT.

      IF lv_funcloc IS INITIAL.
         RETURN.
      ENDIF.

*-- Get the structure indicator, if it is initial.

  SELECT SINGLE tplkz FROM iflot INTO lv_tplkz
     WHERE tplnr = lv_funcloc.

*-- ACR247 GYMANA start
*-- Validate that the equipment is engineering relevant
  SELECT cuobj FROM inob into lv_cuobj
   WHERE objek = lv_funcloc
     AND klart = '003'.

   IF sy-subrc EQ 0.
      SELECT COUNT( * ) FROM kssk into lv_count
       WHERE objek = lv_cuobj
         AND klart = '003'
         AND ( clint = lv_clint_c1 OR
               clint = lv_clint_c2 ).

   ENDIF.
   ENDSELECT.
*-- ACR247 GYMANA end

*-- Call method to update design capacity status indicator
   IF lv_count > 0.                                    "ACR247
      zpm_cl_funcloc_util=>handle_equi_loc_change(
        iv_equnr = ls_mdo_input_vals-iv_equnr->*       "Equip.no
        iv_tplnr = lv_funcloc                          "Func. Location
        iv_tplkz = lv_tplkz ).                         "FLOC Struct. Ind
   ENDIF.                                              "ACR247

* SDP85964 GYMANA End

*----------------------------------------------------------------------*
* Step 3 - Build output data in OO parameter format
*----------------------------------------------------------------------*
*       -->return output data to MDO data object,
*       output data in MDO data are mapped to BAPI Wrapper
*       data container automatically by POSTPROCESS_MAPPING
*      me->oref_mdo_data->set_mdo_output_via_ref_struct(
*        EXPORTING is_mdo_output = ls_mdo_output_vals ).

* Class-Based Exception Handling
    CATCH cx_root INTO lref_exception.                   "#EC CATCH_ALL
      /syclo/cl_core_appl_logger=>logger->catch_class_exception(
        EXPORTING iv_mobile_user = me->str_bapi_input-mobile_user
                  iv_mobile_id = me->str_bapi_input-mobile_id
                  iv_user_guid = me->str_bapi_input-user_guid
                  iref_exception = lref_exception
                  iref_return_tab = iref_rfc_oo_data->dref_return ).

  ENDTRY.

ENDMETHOD.
ENDCLASS.
