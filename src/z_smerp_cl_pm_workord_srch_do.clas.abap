class Z_SMERP_CL_PM_WORKORD_SRCH_DO definition
  public
  inheriting from /SYCLO/CL_CORE_DO_HANDLER_BASE
  create public .

public section.
*"* public components of class Z_SMERP_CL_PM_WORKORD_SRCH_DO
*"* do not include other source files here!!!

  methods /SYCLO/IF_CORE_DO_HANDLER~GET
    redefinition .
  methods /SYCLO/IF_CORE_DO_HANDLER~UPDATE
    redefinition .
protected section.
*"* protected components of class Z_SMERP_CL_PM_WORKORD_SRCH_DO
*"* do not include other source files here!!!

  data GR_PLANT_BAPI type /SYCLO/CORE_RANGE_TAB .
  data GR_PLANT_DOF type /SYCLO/CORE_RANGE_TAB .
  data GV_HIER_LEVEL type INT4 .
  data GT_ORDERS type ZSMERP_PM_WRKORD_UPD_TTY .
private section.
*"* private components of class Z_SMERP_CL_PM_WORKORD_SRCH_DO
*"* do not include other source files here!!!
ENDCLASS.



CLASS Z_SMERP_CL_PM_WORKORD_SRCH_DO IMPLEMENTATION.


METHOD /syclo/if_core_do_handler~get.

  TYPES: BEGIN OF lty_afvc_aufk,
        aufnr TYPE aufk-aufnr,
        auart TYPE aufk-auart,
        ktext TYPE aufk-ktext,
        vornr TYPE afvc-vornr,
        arbid TYPE afih-gewrk,
        equnr TYPE afih-equnr,
        tplnr TYPE iflo-tplnr,
        wosta TYPE aufk-objnr,
        objnr TYPE aufk-objnr,
        stort TYPE pmloc,
        msgrp TYPE raumnr,
        adrnr TYPE adrnr,
        gstrp TYPE co_gstrp,
        gltrp TYPE co_gltrp,
        iphas TYPE pm_phase,
        iloan TYPE iloan,
        priok TYPE priok,
        END OF lty_afvc_aufk.

  TYPES: BEGIN OF lty_status,
     objnr TYPE aufk-objnr,
     sy_status TYPE bsvx-sttxt,
     us_status TYPE bsvx-sttxt,
    END OF lty_status,

   BEGIN OF lty_wosta,
     wosta TYPE aufk-objnr,
   END OF lty_wosta,

    BEGIN OF lty_adrc,
      adrnr TYPE adrnr,
      street TYPE adrc-street,
      city TYPE adrc-city1,
      region TYPE adrc-region,
    END OF lty_adrc.

  TYPES: BEGIN OF lty_arbpl,
    arbid TYPE afih-gewrk,
    arbpl TYPE arbpl,
    ktext TYPE crtx-ktext,
    END OF lty_arbpl.

***********************************************************************
* Data Declaration Section
************************************************************************
*OO Reference Variables
  DATA: lref_data TYPE REF TO data,                         "#EC NEEDED
        lref_exception TYPE REF TO cx_root,
        lref_do_serv TYPE REF TO /syclo/cl_core_do_services.

  DATA: lv_stat_exist TYPE xfeld,
        lv_stsma TYPE jsto-stsma,
        lv_stonr TYPE tj30-stonr.

*Tables & Structures
  "The following structure contains reference to all available filters
  "from ConfigPanel. Filter name is consistent with what is declared
  "in filter service method GET_DATA_FILTER_LIST
*  DATA: BEGIN OF ls_dof_filter_vals,
*          arbpl  TYPE REF TO /syclo/core_range_tab,
*          auart  TYPE REF TO /syclo/core_range_tab,
*          tplnr  TYPE REF TO /syclo/core_range_tab,
*          equnr  TYPE REF TO /syclo/core_range_tab,
*          gltrs  TYPE REF TO /syclo/core_range_tab,
*          stort  TYPE REF TO /syclo/core_range_tab,
*          msgrp  TYPE REF TO /syclo/core_range_tab,
*          street TYPE REF TO /syclo/core_range_tab,
*          city   TYPE REF TO /syclo/core_range_tab,
*          iphas  TYPE REF TO /syclo/core_range_tab,
*        END OF ls_dof_filter_vals.

  "The following structure contains reference to all supported import
  "parameters supported by MDO handler. Parameter name is set to the same
  "as what is defined in BAPI wrapper sigature for simplicity.
  DATA: BEGIN OF ls_mdo_input_vals,
          it_arbpl_ra TYPE REF TO /syclo/core_range_tab,
          it_auart_ra TYPE REF TO /syclo/core_range_tab,
          it_tplnr_ra TYPE REF TO /syclo/core_range_tab,
          it_equnr_ra TYPE REF TO /syclo/core_range_tab,
          it_gltrs_ra TYPE REF TO /syclo/core_range_tab,
          it_stort_ra TYPE REF TO /syclo/core_range_tab,
          it_iphas_ra TYPE REF TO /syclo/core_range_tab,
          it_msgrp_ra TYPE REF TO /syclo/core_range_tab,
          it_street_ra TYPE REF TO /syclo/core_range_tab,
          it_city_ra   TYPE REF TO /syclo/core_range_tab,
          it_priok_ra TYPE REF TO /syclo/core_range_tab,
        END OF ls_mdo_input_vals.

  "The following structure contains reference to all supported output parameter
  "from MDO handler. Output parameter name is set to the same as what is declared
  "in receiving BAPI warpper signature for simplicity.
  DATA: BEGIN OF ls_mdo_output_vals,
    et_workord_srch TYPE REF TO zsmerp_pm_workord_srch_tty,
        END OF ls_mdo_output_vals.

  DATA: ls_return TYPE bapiret2,
        lt_afvc_aufk TYPE STANDARD TABLE OF lty_afvc_aufk,
        lt_objnr TYPE STANDARD TABLE OF lty_afvc_aufk,
        lt_adrnr TYPE STANDARD TABLE OF lty_afvc_aufk,
        ls_adrnr LIKE LINE OF lt_adrnr,
        lt_adrc  TYPE STANDARD TABLE OF lty_adrc,
        ls_adrc  TYPE lty_adrc,
        lt_wosta TYPE STANDARD TABLE OF lty_wosta,
        ls_objnr TYPE lty_afvc_aufk,
        lv_objnr TYPE jsto-objnr,
        lt_arbpl TYPE STANDARD TABLE OF lty_arbpl,
        ls_arbpl TYPE lty_arbpl,
        lt_arbid TYPE STANDARD TABLE OF lty_afvc_aufk,
        ls_afvc_aufk TYPE lty_afvc_aufk,
        lt_status TYPE SORTED TABLE OF lty_status WITH UNIQUE KEY objnr,
        ls_status TYPE lty_status,
        ls_workord_srch TYPE zsmerp_pm_workord_srch_str.

* Field Symbols
  FIELD-SYMBOLS: <return>       TYPE bapiret2_t.

* Constants
  CONSTANTS: lc_rel   TYPE jest-stat VALUE 'I0002'.


**********************************************************************
* Main Section
**********************************************************************
  TRY.
      "Call super class method for initial logging info
      CALL METHOD super->/syclo/if_core_do_handler~get
        EXPORTING
          iref_rfc_oo_data = iref_rfc_oo_data.

      " Set return time stamp at begining if exchange process not used
      IF me->mobile_timestamp_in IS INITIAL.
        me->mobile_timestamp_out =
          /syclo/cl_core_do_services=>get_sys_timestamp( ).
      ENDIF.

*----------------------------------------------------------------------*
* Step 1 - Initialization
*----------------------------------------------------------------------*
      lref_do_serv = /syclo/cl_core_do_services=>get_do_service(
                                       iref_logger = me->logger ).

      "-->Initialize output tables
      CREATE DATA: ls_mdo_output_vals-et_workord_srch.

      " --Retrieve supplied MDO input data and map to local variables.
      " MDO input data are supplied by BAPI wrapper and mapped to MDO
      " data object by PREPROCESS_MAPPING
      me->oref_mdo_data->map_local_mobile_filter(
        CHANGING cs_filters = ls_mdo_input_vals ).

      " -->Retrieve filter settings as defined via ConfigPanel.
      " ConfigPanel filter settings has been mapped to MDO data object
      " by INITIALIZE_MDO_DATA
      "me->oref_mdo_data->map_local_dof_filter(
      "  CHANGING cs_filters = ls_dof_filter_vals ).

      "--> Apply filter rules
      SELECT aufnr ktext
             vornr arbid
             equnr tplnr
             objnr   AS wosta
             v_objnr AS objnr
             stort
             msgrp iloan
             gstrp gltrp
             iphas auart priok
        FROM viaufk_afvc
        INTO CORRESPONDING FIELDS OF TABLE lt_afvc_aufk
        WHERE auart IN ls_mdo_input_vals-it_auart_ra->*
          AND tplnr IN ls_mdo_input_vals-it_tplnr_ra->*
          AND equnr IN ls_mdo_input_vals-it_equnr_ra->*
          AND gltrp IN ls_mdo_input_vals-it_gltrs_ra->*
          AND stort IN ls_mdo_input_vals-it_stort_ra->*
          AND iphas IN ls_mdo_input_vals-it_iphas_ra->*.

      IF lt_afvc_aufk IS INITIAL.
        ASSIGN iref_rfc_oo_data->dref_return->* TO <return>.
        ls_return-type = 'I'.
        ls_return-message = 'No data found'(i01).
        APPEND ls_return TO <return>.
        RETURN.
      ENDIF.

      SELECT objnr AS wosta FROM jest
        INTO TABLE lt_wosta
        FOR ALL ENTRIES IN lt_afvc_aufk
        WHERE objnr = lt_afvc_aufk-wosta
          AND stat = lc_rel
          AND inact EQ ' '.

      IF sy-subrc EQ 0.
        SORT lt_wosta BY wosta.
      ENDIF.

      LOOP AT lt_afvc_aufk INTO ls_adrnr.
        SELECT SINGLE adrnr INTO ls_adrnr-adrnr FROM iloa
               WHERE iloan = ls_adrnr-iloan.
        IF sy-subrc = 0.
          MODIFY lt_afvc_aufk FROM ls_adrnr.
        ENDIF.
      ENDLOOP.

      lt_adrnr = lt_afvc_aufk.
      SORT lt_adrnr BY adrnr.
      DELETE ADJACENT DUPLICATES FROM lt_adrnr COMPARING adrnr.
      SELECT addrnumber AS adrnr
             street
             city1 AS city
             region
             FROM adrc
             INTO TABLE lt_adrc
             FOR ALL ENTRIES IN lt_adrnr
             WHERE addrnumber = lt_adrnr-adrnr.

      IF sy-subrc EQ 0.
        SORT lt_adrc BY adrnr.
      ENDIF.

      lt_objnr = lt_afvc_aufk.
      SORT lt_objnr BY objnr.
      DELETE ADJACENT DUPLICATES FROM lt_objnr COMPARING objnr.

      LOOP AT lt_objnr INTO ls_objnr.
        ls_status-objnr = ls_objnr-objnr.

        CALL FUNCTION 'STATUS_TEXT_EDIT'
          EXPORTING
*           CLIENT            = SY-MANDT
*           FLG_USER_STAT     = ' '
            objnr             = ls_objnr-objnr
*           ONLY_ACTIVE       = 'X'
            spras             = sy-langu
*           BYPASS_BUFFER     = ' '
          IMPORTING
            anw_stat_existing = lv_stat_exist
            e_stsma           = lv_stsma
            line              = ls_status-sy_status
            user_line         = ls_status-us_status
            stonr             = lv_stonr
          EXCEPTIONS
            object_not_found  = 0
            OTHERS            = 0.

        INSERT ls_status INTO TABLE lt_status.
        CLEAR ls_status.
      ENDLOOP.

      lt_arbid = lt_afvc_aufk.
      SORT lt_arbid BY arbid.
      DELETE ADJACENT DUPLICATES FROM lt_arbid COMPARING arbid.

      SELECT DISTINCT crhd~objid AS arbid
             crhd~arbpl
             crtx~ktext
             FROM crhd INNER JOIN crtx ON crhd~objty = crtx~objty AND
                                          crhd~objid = crtx~objid
             INTO TABLE lt_arbpl
             FOR ALL ENTRIES IN lt_arbid
             WHERE crhd~objty = 'A' AND
                   crhd~objid = lt_arbid-arbid AND
                   crhd~begda LE sy-datum AND
                   crhd~endda GE sy-datum AND
                   crhd~arbpl IN ls_mdo_input_vals-it_arbpl_ra->* AND
                   crtx~spras EQ sy-langu.

      IF sy-subrc EQ 0.
        SORT lt_arbpl BY arbid.
      ENDIF.

      LOOP AT lt_afvc_aufk INTO ls_afvc_aufk.
        ls_workord_srch-aufnr = ls_afvc_aufk-aufnr.
        ls_workord_srch-ktext = ls_afvc_aufk-ktext.
        ls_workord_srch-vornr = ls_afvc_aufk-vornr.
        ls_workord_srch-arbid = ls_afvc_aufk-arbid.
        ls_workord_srch-equnr = ls_afvc_aufk-equnr.
        ls_workord_srch-tplnr = ls_afvc_aufk-tplnr.
        ls_workord_srch-stort = ls_afvc_aufk-stort.
        ls_workord_srch-msgrp = ls_afvc_aufk-msgrp.
        ls_workord_srch-gltrp = ls_afvc_aufk-gltrp.
        ls_workord_srch-gstrp = ls_afvc_aufk-gstrp.
        ls_workord_srch-iphas = ls_afvc_aufk-iphas.
        ls_workord_srch-auart = ls_afvc_aufk-auart.
        ls_workord_srch-priok = ls_afvc_aufk-priok.

        READ TABLE lt_wosta WITH KEY wosta = ls_afvc_aufk-wosta
                            TRANSPORTING NO FIELDS
                            BINARY SEARCH.

        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        READ TABLE lt_adrc INTO ls_adrc WITH KEY adrnr = ls_afvc_aufk-adrnr
                                        BINARY SEARCH.
        IF sy-subrc EQ 0.
          ls_workord_srch-street = ls_adrc-street.
          ls_workord_srch-region = ls_adrc-region.
          ls_workord_srch-city = ls_adrc-city.
        ENDIF.

        READ TABLE lt_status INTO ls_status WITH TABLE KEY objnr = ls_afvc_aufk-objnr.
        IF sy-subrc EQ 0.
          ls_workord_srch-sys_status = ls_status-sy_status.
          ls_workord_srch-user_status = ls_status-us_status.
        ENDIF.

        IF ls_workord_srch-user_status EQ 'DISP'.
          CONTINUE.
        ENDIF.

        IF ls_workord_srch-user_status NE 'CRTD'.
          CONTINUE.
        ENDIF.

        READ TABLE lt_arbpl INTO ls_arbpl WITH KEY arbid = ls_afvc_aufk-arbid
                                          BINARY SEARCH.
        IF sy-subrc EQ 0.
          ls_workord_srch-arbpl = ls_arbpl-arbpl.
          ls_workord_srch-cr_ktext = ls_arbpl-ktext.
          APPEND ls_workord_srch TO ls_mdo_output_vals-et_workord_srch->*.
        ENDIF.

        CLEAR ls_workord_srch.
      ENDLOOP.

*----------------------------------------------------------------------*
* Step 3 - Prepare MDO output data
*----------------------------------------------------------------------*
      " -->return output data to MDO data object,
      " output data in MDO data are mapped to BAPI Wrapper
      " data container automatically by POSTPROCESS_MAPPING
      me->oref_mdo_data->set_mdo_output_via_ref_struct(
        EXPORTING is_mdo_output = ls_mdo_output_vals ).

*     Class-Based Exception Handling
    CATCH cx_root INTO lref_exception.                   "#EC CATCH_ALL
      /syclo/cl_core_appl_logger=>logger->catch_class_exception(
        EXPORTING is_bapi_input = me->str_bapi_input
                  iref_exception = lref_exception
                  iref_return_tab = iref_rfc_oo_data->dref_return ).
  ENDTRY.
ENDMETHOD.


METHOD /syclo/if_core_do_handler~update.

************************************************************************
* Types Declaration Section
************************************************************************
  TYPES: BEGIN OF lty_ops,
          aufnr TYPE aufnr,
          aufpl TYPE co_aufpl,
          arbpl TYPE arbpl,
          aplzl TYPE afvc-aplzl,
          vornr TYPE vornr,
         END OF lty_ops.

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
          it_orders TYPE REF TO zsmerp_pm_wrkord_upd_tty,
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
        ls_afih TYPE afih,
        lv_msg TYPE string.
  DATA: lv_authorized TYPE /syclo/core_boolean_dte.

  DATA: lt_aufnr TYPE zsmerp_pm_wrkord_upd_tty,
        ls_aufnr TYPE zsmerp_pm_wrkord_upd_str,
        lt_arbpl TYPE zsmerp_pm_wrkord_upd_tty,
        lv_arbpl TYPE crhd-arbpl,
        lt_operation TYPE STANDARD TABLE OF bapi_alm_order_operation,
        ls_operation TYPE bapi_alm_order_operation,
        ls_header TYPE bapi_alm_order_headers_i,
        lt_ops   TYPE STANDARD TABLE OF lty_ops,
        ls_ops   TYPE lty_ops,
        lv_objnr TYPE jsto-objnr,

  lt_methods TYPE STANDARD TABLE OF bapi_alm_order_method,
  ls_methods TYPE bapi_alm_order_method,
  lv_save    TYPE char1,
  lv_refno   TYPE ifrefnum.

*Field Symbols
  FIELD-SYMBOLS: <return_tab> TYPE bapiret2_t.
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
      CREATE DATA: ls_mdo_input_vals-it_orders.

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

*      "Check authorization
*      lv_authorized = /smerp/cl_core_mdo_tools=>check_tcode_authorization(
*        iv_user_id = me->active_sap_userid
*        it_tcode_ra = ls_dof_filter_vals-trans_code_check->* ).
*
*      IF lv_authorized = abap_false.
*        me->message = 'No authorization. Please contact system administrator.'(e06).
*        me->logger->logerror( iv_source = me->source
*                              iv_message = me->message
*                              iref_return_tab = iref_rfc_oo_data->dref_return ).
*        RETURN.
*      ENDIF.

      IF ls_mdo_input_vals-it_orders->* IS INITIAL.
        me->message = 'No records sent for update.'.
        me->logger->logerror( iv_source = me->source
                              iv_message = me->message
                              iref_return_tab = iref_rfc_oo_data->dref_return ).
        RETURN.
      ENDIF.

      REFRESH: gt_orders, lt_ops.
      me->gt_orders = ls_mdo_input_vals-it_orders->*.

      SELECT aufnr
             aufpl
             arbpl
             aplzl
             vornr
             FROM zpm_afko_afvc
             INTO TABLE lt_ops
             FOR ALL ENTRIES IN me->gt_orders
             WHERE ( aufnr = me->gt_orders-aufnr AND vornr = me->gt_orders-vornr ) AND
                   begda LE sy-datum AND
                   endda GE sy-datum.

* Get all unique work orders -  Needed to release all work orders that are not already released
      lt_aufnr = me->gt_orders.
      SORT lt_aufnr BY aufnr.
      DELETE ADJACENT DUPLICATES FROM lt_aufnr COMPARING aufnr.

* Get Work center of current user from User Parameters
      GET PARAMETER ID 'VAP' FIELD lv_arbpl.

      LOOP AT lt_aufnr INTO ls_aufnr.

        ADD 1 TO lv_refno.
        IF ls_aufnr-arbpl NE lv_arbpl.
          lv_save = abap_true.

          LOOP AT lt_ops INTO ls_ops WHERE aufnr = ls_aufnr-aufnr.
*------Prepare Method table for operation
            ls_methods-refnumber = lv_refno.
            ls_methods-objecttype = 'OPERATION'.
            ls_methods-method = 'CHANGE'.
            CONCATENATE ls_aufnr-aufnr ls_ops-vornr INTO ls_methods-objectkey.
            APPEND ls_methods TO lt_methods.
            CLEAR ls_methods.

*---------prepare line items for every Aufnr
            CLEAR : ls_operation.
            ls_operation-activity  = ls_ops-vornr.
            ls_operation-work_cntr = lv_arbpl.
            APPEND ls_operation TO lt_operation.
            CLEAR : ls_operation.
          ENDLOOP.
        ENDIF.

        SELECT SINGLE * FROM afih INTO ls_afih
               WHERE aufnr = ls_aufnr-aufnr AND
                     iphas = '0'.

        IF sy-subrc = 0.
          lv_save = abap_true.
          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
            EXPORTING
              input  = ls_aufnr-aufnr
            IMPORTING
              output = ls_aufnr-aufnr.

          ls_methods-refnumber = lv_refno.
          ls_methods-objecttype = 'HEADER'.
          ls_methods-method = 'RELEASE'.
          ls_methods-objectkey = ls_aufnr-aufnr.
          APPEND ls_methods TO lt_methods.
          CLEAR ls_methods.
        ENDIF.

        IF lv_save IS NOT INITIAL.
          CLEAR lv_save.
          ls_methods-refnumber = lv_refno.
          ls_methods-objecttype = space.
          ls_methods-method = 'SAVE'.
          ls_methods-objectkey = ls_aufnr-aufnr.
          APPEND ls_methods TO lt_methods.
          CLEAR ls_methods.
        ENDIF.

      ENDLOOP.

*----------------------------------------------------------------------*
* Step 2 - Calling standard BAPI to update Work order
*----------------------------------------------------------------------*
      ASSIGN iref_rfc_oo_data->dref_return->* TO <return_tab>.
      me->message = 'Calling FuncMod ~ BAPI_ALM_ORDER_MAINTAIN...'(i13).
      me->logger->loginfo( iv_mobile_user = me->str_bapi_input-mobile_user
                           iv_mobile_id = me->str_bapi_input-mobile_id
                           iv_user_guid = me->str_bapi_input-user_guid
                           iv_message = me->message
                           iv_source = me->source ).

* Trigger BAPI to release work orders
      IF lt_methods[] IS NOT INITIAL.
        CALL FUNCTION 'BAPI_ALM_ORDER_MAINTAIN'
          TABLES
            it_methods   = lt_methods
            it_operation = lt_operation
            return       = lt_return.

        APPEND LINES OF lt_return TO <return_tab>.

      ENDIF.

      LOOP AT lt_return INTO ls_return WHERE type = 'E'
                                          OR type = 'A'.
        EXIT.
      ENDLOOP.
      IF sy-subrc EQ 0.
* Roll back changes
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        RETURN.
      ELSE.

* Setting user statusfor operation
        LOOP AT lt_ops INTO ls_ops.
          CONCATENATE 'OV' ls_ops-aufpl ls_ops-aplzl INTO lv_objnr.

          CALL FUNCTION 'STATUS_CHANGE_EXTERN'
            EXPORTING
              objnr               = lv_objnr
              user_status         = 'E0002'
            EXCEPTIONS
              object_not_found    = 1
              status_inconsistent = 2
              status_not_allowed  = 3
              OTHERS              = 4.
        ENDLOOP.

        me->commit( CHANGING ct_messages = <return_tab> ).
      ENDIF.

*----------------------------------------------------------------------*
* Step 3 - Build output data in OO parameter format
*----------------------------------------------------------------------*
      " -->return output data to MDO data object,
      " output data in MDO data are mapped to BAPI Wrapper
      " data container automatically by POSTPROCESS_MAPPING
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
