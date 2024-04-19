CLASS lcl_zpm_classification_update DEFINITION DEFERRED.
CLASS /smerp/cl_pm_classification_do DEFINITION LOCAL FRIENDS lcl_zpm_classification_update.
*----------------------------------------------------------------------*
*       CLASS LCL_ZPM_CLASSIFICATION_UPDATE DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_zpm_classification_update DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA obj TYPE REF TO lcl_zpm_classification_update. "#EC NEEDED
    DATA core_object TYPE REF TO /smerp/cl_pm_classification_do . "#EC NEEDED
 INTERFACES  IOW_ZPM_CLASSIFICATION_UPDATE.
    METHODS:
     constructor IMPORTING core_object
       TYPE REF TO /smerp/cl_pm_classification_do OPTIONAL.
ENDCLASS.                    "LCL_ZPM_CLASSIFICATION_UPDATE DEFINITION
*----------------------------------------------------------------------*
*       CLASS LCL_ZPM_CLASSIFICATION_UPDATE IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_zpm_classification_update IMPLEMENTATION.
  METHOD constructor.
    me->core_object = core_object.
  ENDMETHOD.                    "CONSTRUCTOR

  METHOD iow_zpm_classification_update~get.
*"------------------------------------------------------------------------*
*" Declaration of Overwrite-method, do not insert any comments here please!
*"
*"methods GET
*"  importing
*"    value(IREF_RFC_OO_DATA) type ref to /SYCLO/CL_CORE_RFC_OO_DATA .
*"------------------------------------------------------------------------*
*METHOD /syclo/if_core_do_handler~get.
*======================================================================*
*<SMERPDOC>
*  <CREATE_DATE> 06/18/2013 </CREATE_DATE>
*  <AUTHOR> Syam Yalamati </AUTHOR>
*  <DESCRIPTION>
*   This method returns list of classification details associated with
*   equipments/Flocs based on rules and other filter conditions
*   Key features include:
*   1. supports exchange process if TIMESTAMP_FROM_MOBILE is provided
*   2. supports filter settings from both ConfigPanel and BAPI Wrapper.
*      ConfigPanel filter settings supercede settings from BAPI Wrapper.
*   3. supports field selection
*  </DESCRIPTION>
*<!-- *----------------------CHANGE HISTORY------------------------* -->
*  <REVISION_TAG date='06/12/2013' version='610_700 ERP' user='YALAMATIS'>
*    <DESCRIPTION>Initial release.</DESCRIPTION>
*    <BugID> ERPADDON-42 </BugID>
*  </REVISION_TAG>
*<!-- *----------------------CHANGE HISTORY------------------------* -->
*  <REVISION_TAG date='04/25/2014' version='SMERP 610_700 SP03' user='YALAMATIS'>
*    <DESCRIPTION> BADI addition for Exchange Key list </DESCRIPTION>
*    <BugID> ERPADDON-168 </BugID>
*  </REVISION_TAG>
*<!-- *----------------------CHANGE HISTORY------------------------* -->
*  <REVISION_TAG date='07/08/2014' version='SMERP 610_700 SP04' user='YALAMATIS'>
*    <DESCRIPTION> Performance improvements </DESCRIPTION>
*    <BugID> ERPADDON-294 </BugID>
*    <Note> 2045350 </Note>
*  </REVISION_TAG>
*<!-- *----------------------CHANGE HISTORY------------------------* -->
*</SMERPDOC>
*======================================================================*
************************************************************************
* Data Declaration Section
************************************************************************
*OO Reference Variables
    DATA: lref_data TYPE REF TO data,
          lref_exception TYPE REF TO cx_root,
          lref_exch_keylist TYPE REF TO data,
          lref_data_manager TYPE REF TO /syclo/cl_core_rfc_oo_data,
          lref_badi_classif TYPE REF TO /smerp/mdo_pm_classif_badi,
          lref_do_serv TYPE REF TO /syclo/cl_core_do_services.

*Tables & Structures
    "The following structure contains reference to all available filters
    "from ConfigPanel. Filter name is consistent with what is declared
    "in filter service method GET_DATA_FILTER_LIST
    DATA: BEGIN OF ls_dof_filter_vals,
            objectkey TYPE REF TO /syclo/core_range_tab,
            classtype TYPE REF TO /syclo/core_range_tab,
            class_key TYPE REF TO /syclo/core_range_tab,
            char_name TYPE REF TO /syclo/core_range_tab,
            object_type TYPE REF TO /syclo/core_range_tab,
            obj_class_ind TYPE REF TO /syclo/core_range_tab,
            get_ref_char TYPE REF TO /syclo/core_range_tab,                         "<--Ins SMERP 610_700 SP04 BugID:ERPADDON-294
          END OF ls_dof_filter_vals.

    "The following structure contains reference to all supported import
    "parameters supported by MDO handler. Parameter name is set to the same
    "as what is defined in BAPI wrapper sigature for simplicity.
    DATA: BEGIN OF ls_mdo_input_vals,
            it_objectkey_ra TYPE REF TO /syclo/core_range_tab,
            it_classtype_ra TYPE REF TO /syclo/core_range_tab,
            it_class_key_ra TYPE REF TO /syclo/core_range_tab,
            it_char_name_ra TYPE REF TO /syclo/core_range_tab,
            is_cls_return_data_demand   TYPE REF TO /smerp/pm_cls_bapi_ondmnd_str,
          END OF ls_mdo_input_vals.

    "The following structure contains reference to all supported output parameter
    "from MDO handler. Output parameter name is set to the same as what is declared
    "in receiving BAPI warpper signature for simplicity.
    DATA: BEGIN OF ls_mdo_output_vals,
            et_classification       TYPE REF TO /syclo/pm_class_tab,
            et_characteristic       TYPE REF TO /syclo/pm_class_char_tab,
            et_characteristic_val   TYPE REF TO /syclo/pm_char_val_tab,
          END OF ls_mdo_output_vals.

    "Exchange Object data
    DATA: lt_exch_objclass TYPE STANDARD TABLE OF /syclo/pm_charvalkey_str,
          ls_exch_objclass LIKE LINE OF lt_exch_objclass.
    DATA: BEGIN OF ls_exch_objkey,
            objek TYPE objnum,
          END OF ls_exch_objkey,
          lt_exch_objkey LIKE STANDARD TABLE OF ls_exch_objkey.

    DATA: BEGIN OF ls_class_key,
            objek TYPE objnum,
            mafid TYPE klmaf,
            klart TYPE klassenart,
            clint TYPE clint,
            adzhl TYPE adzhl,
          END OF ls_class_key,
          lt_class_key LIKE STANDARD TABLE OF ls_class_key,
          lt_class_key_inh_tmp  LIKE STANDARD TABLE OF ls_class_key,
          lt_class_key_inh LIKE STANDARD TABLE OF ls_class_key.

    DATA: lt_clsinhchar TYPE /syclo/pm_class_char_tab,
          ls_clsinhchar LIKE LINE OF lt_clsinhchar.

    DATA: BEGIN OF ls_clinh_key,
            objek TYPE objnum,
            mafid TYPE klmaf,
            klart TYPE klassenart,
          END OF ls_clinh_key,
          lt_clinh_key LIKE STANDARD TABLE OF ls_clinh_key,
          ls_clinh_key1 LIKE ls_clinh_key.

    DATA: BEGIN OF ls_kschl,
            clint TYPE clint,
            kschl TYPE klschl,
          END OF ls_kschl,
          lt_kschl LIKE STANDARD TABLE OF ls_kschl.

    DATA: BEGIN OF ls_cabnt,
            atinn TYPE atinn,
            adzhl TYPE adzhl,
            atbez TYPE atbez,
          END OF ls_cabnt,
          lt_cabnt LIKE STANDARD TABLE OF ls_cabnt.

    DATA: BEGIN OF ls_cawnt,
            atinn TYPE atinn,
            atzhl TYPE atzhl,
            adzhl TYPE adzhl,
            atwrt TYPE atwrt,
            atwtb TYPE atwtb,
          END OF ls_cawnt,
          lt_cawnt LIKE STANDARD TABLE OF ls_cawnt.

    DATA: ls_equi TYPE equi,
          ls_objkey_ra TYPE /syclo/core_range_str,
          lt_objkey1_ra TYPE /syclo/core_range_tab,       "<--Ins SMERP 610_700 SP04 BugID:ERPADDON-294
          lt_objkey_ra TYPE /syclo/core_range_tab.

    DATA: BEGIN OF ls_objkey,                             "<--Ins SMERP 610_700 SP04 BugID:ERPADDON-294
            objkey TYPE cuobn,                            "<--Ins SMERP 610_700 SP04 BugID:ERPADDON-294
          END OF ls_objkey,                               "<--Ins SMERP 610_700 SP04 BugID:ERPADDON-294
          lt_objkey LIKE STANDARD TABLE OF ls_objkey.     "<--Ins SMERP 610_700 SP04 BugID:ERPADDON-294

    DATA: BEGIN OF ls_inobkey,
            cuobj TYPE cuobj,
            objek TYPE cuobn,
          END OF ls_inobkey,
          lt_inobkey LIKE STANDARD TABLE OF ls_inobkey.
    DATA: ls_return TYPE bapiret2.

*Variables
* SDP58326 - gymana - Changing # of dec places in lv_pack_val
    DATA: lv_select_clause TYPE string,
          lv_select_clause_tmp TYPE string,
          lv_select_clause_ref TYPE string,
          lv_index     TYPE sytabix,
          lv_char_val  TYPE qsollwertc,
          lv_clint     TYPE clint,
          lv_msg       TYPE string,
          lv_pack_val  TYPE p DECIMALS 10,                  "SDP58326
          lv_op_code1  TYPE c LENGTH 2,
          lv_op_code2  TYPE c LENGTH 2,
          lv_char_fld1 TYPE c LENGTH 16,
          lv_char_fld2 TYPE c LENGTH 16,
          lv_msehi     TYPE c LENGTH 5.
    DATA: lv_get_ref_char TYPE c LENGTH 1.                "<--Ins SMERP 610_700 SP04 BugID:ERPADDON-294

* Constants
    CONSTANTS:BEGIN OF lc_tab_name,
                kssk  TYPE string VALUE 'KSSK',
                klah  TYPE string VALUE 'KLAH',
                ksml  TYPE string VALUE 'KSML',
                cabn  TYPE string VALUE 'CABN',
                ausp  TYPE string VALUE 'AUSP',
                equi  TYPE string VALUE 'EQUI',
                iflot TYPE string VALUE 'IFLOT',
              END OF lc_tab_name.

    CONSTANTS: lc_mthd_get TYPE /syclo/core_do_mthd_dte VALUE 'GET',
               lc_mthd_type_get TYPE /syclo/core_dohandle_mtyp_dte VALUE 'GET',
               lc_class_type_equi TYPE klassenart VALUE '002',
               lc_class_type_floc TYPE klassenart VALUE '003'.

* Field Symbols
    FIELD-SYMBOLS: <return>       TYPE bapiret2_t,
                   <class>        TYPE /syclo/pm_class_str,
                   <class_t>      TYPE /syclo/pm_class_tab,
                   <char>         TYPE /syclo/pm_class_char_str,
                   <char_t>       TYPE /syclo/pm_class_char_tab,
                   <char_val>     TYPE /syclo/pm_char_val_str,
                   <char_val_t>   TYPE /syclo/pm_char_val_tab,
                   <characteristic_t>  TYPE /syclo/pm_class_char_tab,
                   <characteristic_s> TYPE  /syclo/pm_class_char_str.

**********************************************************************
* Main Section
**********************************************************************
    TRY.

        TRY.
          me->core_object->message = 'Entering method ~ GET...'(m01).
          me->core_object->logger->loginfo( is_bapi_input = me->core_object->str_bapi_input           "<-mod 310_700
*                         iv_mobile_id = me->str_bapi_input-mobile_id "<-del 310_700
                               iv_message = me->core_object->message
                               iv_source = me->core_object->source ).
*Insert start from here 320_700 SP2 bugid 28969
          IF me->core_object->str_do_proxy_setting-get_active_flag = abap_true.
            me->core_object->execute_proxy( iref_data_manager = iref_rfc_oo_data
                               iref_mdo_data = me->core_object->oref_mdo_data
                               iv_mthd_type = me->core_object->active_mthd_type ).
          ENDIF.
*Insert end here 320_700 SP2 bugid 28969

        ENDTRY.

*        "Call super class method for initial logging info
*        CALL METHOD super->/syclo/if_core_do_handler~get
*          EXPORTING
*            iref_rfc_oo_data = iref_rfc_oo_data.

        " Set return time stamp at begining if exchange process not used
        IF me->core_object->mobile_timestamp_in IS INITIAL.
          me->core_object->mobile_timestamp_out =
            /syclo/cl_core_do_services=>get_sys_timestamp( ).
        ENDIF.

*----------------------------------------------------------------------*
* Step 1 - Initialization
*----------------------------------------------------------------------*
        lref_do_serv = /syclo/cl_core_do_services=>get_do_service(
                                         iref_logger = me->core_object->logger ).

        "-->Initialize output tables
        CREATE DATA: ls_mdo_output_vals-et_classification,
                     ls_mdo_output_vals-et_characteristic,
                     ls_mdo_output_vals-et_characteristic_val.

        "-->Intialize input data for internal method call
        CREATE DATA: ls_mdo_input_vals-it_objectkey_ra,
                     ls_mdo_input_vals-it_classtype_ra,
                     ls_mdo_input_vals-it_class_key_ra,
                     ls_mdo_input_vals-it_char_name_ra,
                     ls_mdo_input_vals-is_cls_return_data_demand.

        " --Retrieve supplied MDO input data and map to local variables.
        " MDO input data are supplied by BAPI wrapper and mapped to MDO
        " data object by PREPROCESS_MAPPING
        me->core_object->oref_mdo_data->map_local_mobile_filter(
          CHANGING cs_filters = ls_mdo_input_vals ).

        " -->Retrieve filter settings as defined via ConfigPanel.
        " ConfigPanel filter settings has been mapped to MDO data object
        " by INITIALIZE_MDO_DATA
        me->core_object->oref_mdo_data->map_local_dof_filter(
          CHANGING cs_filters = ls_dof_filter_vals ).

*     BAdI permitted anytime refinement/enrichment
        TRY.
* -       Get BAdI instance
            GET BADI lref_badi_classif
              FILTERS
                filter_mobile_app = me->core_object->str_do_setting-mobile_app
                filter_mdo        = me->core_object->str_do_setting-do_id.

          CATCH cx_badi INTO lref_exception.
            CLEAR lv_msg.
            lv_msg = lref_exception->get_longtext( ).
            me->core_object->logger->logerror( iv_message = lv_msg
                              iv_source  = me->core_object->source ).
        ENDTRY.

        IF NOT lref_badi_classif IS INITIAL.
          CALL BADI lref_badi_classif->get_begin
            EXPORTING
              iref_mdo_data      = me->core_object->oref_mdo_data
            CHANGING
              cs_mdo_input_vals  = ls_mdo_input_vals
              cs_dof_filter_vals = ls_dof_filter_vals.
        ENDIF.

        "-->Retrieve object key list from exchange layer if
        "   classification exchange process is enabled.
        IF me->core_object->mobile_timestamp_in IS NOT INITIAL.
          GET REFERENCE OF lt_exch_objclass INTO lref_exch_keylist.
          me->core_object->get_keylist_from_exchobj(
            EXPORTING iref_data_manager = iref_rfc_oo_data
                      is_exch_keylist = ls_exch_objclass
            CHANGING cref_exch_keylist = lref_exch_keylist ).
          "<--Ins SMERP 610_700 SP03 BugID:ERPADDON-168 - Start
          IF NOT lref_badi_classif IS INITIAL.
            CALL BADI lref_badi_classif->get_keylist_from_exchobj
              EXPORTING
                iref_data_manager     = iref_rfc_oo_data
                is_exch_keylist       = ls_exch_objclass
                iv_exchobj            = me->core_object->str_do_setting-exchobj
                it_exchobj_assignment = me->core_object->tab_exchobj_assignment
              CHANGING
                cref_exch_keylist     = lref_exch_keylist.
          ENDIF.
          "<--Ins SMERP 610_700 SP03 BugID:ERPADDON-168 - End
          "Determine Object key from the object class exchange
          LOOP AT lt_exch_objclass INTO ls_exch_objclass.
            MOVE ls_exch_objclass-objek TO ls_exch_objkey-objek.
            APPEND ls_exch_objkey TO lt_exch_objkey.
          ENDLOOP.
          SORT lt_exch_objkey.
          DELETE ADJACENT DUPLICATES FROM lt_exch_objkey.
        ENDIF.

        "Store the ObjKey in temp. table
        CLEAR: lt_objkey_ra, lt_inobkey.
        IF ls_dof_filter_vals-objectkey->* IS NOT INITIAL.
          APPEND LINES OF ls_dof_filter_vals-objectkey->* TO lt_objkey_ra.
          CLEAR ls_dof_filter_vals-objectkey->*.
        ENDIF.
        IF ls_mdo_input_vals-it_objectkey_ra->* IS NOT INITIAL.
          APPEND LINES OF ls_mdo_input_vals-it_objectkey_ra->* TO lt_objkey_ra.
          CLEAR ls_mdo_input_vals-it_objectkey_ra->*.
        ENDIF.

        "<--Ins SMERP 610_700 SP04 BugID:ERPADDON-294 - Begin
        LOOP AT lt_objkey_ra INTO ls_objkey_ra.
          IF ls_objkey_ra-sign = 'I' AND ls_objkey_ra-option = 'EQ'.
            MOVE ls_objkey_ra-low TO ls_objkey-objkey.
            APPEND ls_objkey TO lt_objkey.
          ELSE.
            APPEND ls_objkey_ra TO lt_objkey1_ra.
          ENDIF.
        ENDLOOP.

        IF ls_dof_filter_vals-get_ref_char->* IS NOT INITIAL.
          /smerp/cl_core_mdo_tools=>get_simple_val_from_range(
            EXPORTING it_range_table = ls_dof_filter_vals-get_ref_char->*
            IMPORTING ev_low = lv_get_ref_char ).
        ENDIF.
        "<--Ins SMERP 610_700 SP04 BugID:ERPADDON-294 - End

        "Check for Multiple Objects allowed case
        IF lt_exch_objkey[] IS NOT INITIAL.
          SELECT cuobj objek FROM inob INTO TABLE lt_inobkey
            FOR ALL ENTRIES IN lt_exch_objkey
            WHERE objek EQ lt_exch_objkey-objek
              AND obtab IN ls_dof_filter_vals-object_type->*
              AND objek IN lt_objkey_ra
              AND klart IN ls_dof_filter_vals-classtype->*
              AND klart IN ls_mdo_input_vals-it_classtype_ra->*.
          LOOP AT lt_inobkey INTO ls_inobkey.
            READ TABLE lt_exch_objkey INTO ls_exch_objkey
              WITH KEY objek = ls_inobkey-objek.
            IF sy-subrc = 0.
              ls_exch_objkey-objek = ls_inobkey-cuobj.
              APPEND ls_exch_objkey TO lt_exch_objkey.
            ENDIF.
          ENDLOOP.
        ELSE.
          "<--Del SMERP 610_700 SP04 BugID:ERPADDON-294 - Begin
*        SELECT cuobj objek FROM inob INTO TABLE lt_inobkey
*          WHERE obtab IN ls_dof_filter_vals-object_type->*
*            AND objek IN lt_objkey_ra
*            AND klart IN ls_dof_filter_vals-classtype->*
*            AND klart IN ls_mdo_input_vals-it_classtype_ra->*.
          "<--Del SMERP 610_700 SP04 BugID:ERPADDON-294 - End
          "<--Ins SMERP 610_700 SP04 BugID:ERPADDON-294 - Begin
          IF lt_objkey_ra IS NOT INITIAL.
            SELECT cuobj objek FROM inob INTO TABLE lt_inobkey
              FOR ALL ENTRIES IN lt_objkey
              WHERE objek EQ lt_objkey-objkey
                AND obtab IN ls_dof_filter_vals-object_type->*
                AND objek IN lt_objkey1_ra
                AND klart IN ls_dof_filter_vals-classtype->*
                AND klart IN ls_mdo_input_vals-it_classtype_ra->*.
            "Free search not allowed due to performance issues
*        ELSE.
*          SELECT cuobj objek FROM inob INTO TABLE lt_inobkey
*            WHERE obtab IN ls_dof_filter_vals-object_type->*
*              AND objek IN lt_objkey_ra
*              AND klart IN ls_dof_filter_vals-classtype->*
*              AND klart IN ls_mdo_input_vals-it_classtype_ra->*.
          ENDIF.
          "<--Ins SMERP 610_700 SP04 BugID:ERPADDON-294 - End
        ENDIF.
        LOOP AT lt_inobkey INTO ls_inobkey.
          READ TABLE lt_objkey_ra INTO ls_objkey_ra
            WITH KEY low = ls_inobkey-objek.
          IF sy-subrc = 0.
            ls_objkey_ra-low = ls_inobkey-cuobj.
            APPEND ls_objkey_ra TO lt_objkey_ra.
*
            MOVE ls_objkey_ra-low TO ls_objkey-objkey.              "<--Ins SMERP 610_700 SP04 BugID:ERPADDON-294
            APPEND ls_objkey TO lt_objkey.                          "<--Ins SMERP 610_700 SP04 BugID:ERPADDON-294
          ENDIF.
        ENDLOOP.

        IF lt_exch_objkey[] IS NOT INITIAL.
          SELECT objek mafid klart clint adzhl FROM kssk INTO TABLE lt_class_key
            FOR ALL ENTRIES IN lt_exch_objkey
            WHERE objek EQ lt_exch_objkey-objek
              AND kssk~objek IN lt_objkey_ra
              AND kssk~mafid IN ls_dof_filter_vals-obj_class_ind->*
              AND kssk~klart IN ls_dof_filter_vals-classtype->*
              AND kssk~klart IN ls_mdo_input_vals-it_classtype_ra->*
              AND kssk~clint IN ls_dof_filter_vals-class_key->*
              AND kssk~clint IN ls_mdo_input_vals-it_class_key_ra->*.
        ELSE.
          "<--Ins SMERP 610_700 SP04 BugID:ERPADDON-294 - Begin
          IF lt_objkey IS NOT INITIAL.
            SELECT objek mafid klart clint adzhl FROM kssk INTO TABLE lt_class_key
              FOR ALL ENTRIES IN lt_objkey
              WHERE kssk~objek = lt_objkey-objkey
                AND kssk~objek IN lt_objkey1_ra
                AND kssk~mafid IN ls_dof_filter_vals-obj_class_ind->*
                AND kssk~klart IN ls_dof_filter_vals-classtype->*
                AND kssk~klart IN ls_mdo_input_vals-it_classtype_ra->*
                AND kssk~clint IN ls_dof_filter_vals-class_key->*
                AND kssk~clint IN ls_mdo_input_vals-it_class_key_ra->*.
          ENDIF.
          "<--Ins SMERP 610_700 SP04 BugID:ERPADDON-294 - End
          "<--Del SMERP 610_700 SP04 BugID:ERPADDON-294 - Begin
          "Free search not allowed due to performance issues
*       SELECT objek mafid klart clint adzhl FROM kssk INTO TABLE lt_class_key
*         WHERE kssk~objek IN lt_objkey_ra
*           AND kssk~mafid IN ls_dof_filter_vals-obj_class_ind->*
*           AND kssk~klart IN ls_dof_filter_vals-classtype->*
*           AND kssk~klart IN ls_mdo_input_vals-it_classtype_ra->*
*           AND kssk~clint IN ls_dof_filter_vals-class_key->*
*           AND kssk~clint IN ls_mdo_input_vals-it_class_key_ra->*.
          "<--Del SMERP 610_700 SP04 BugID:ERPADDON-294 - End
        ENDIF.

        IF lt_class_key IS INITIAL.
          ASSIGN iref_rfc_oo_data->dref_return->* TO <return>.
          ls_return-type = 'I'.
          ls_return-message = 'No data found'(i01).
          APPEND ls_return TO <return>.
          RETURN.
        ENDIF.

        "Construct table for inherited char values
        LOOP AT lt_class_key INTO ls_class_key.
          ls_clinh_key-objek = ls_class_key-clint.
          ls_clinh_key-mafid = ls_class_key-mafid.
          ls_clinh_key-klart = ls_class_key-klart.
          APPEND ls_clinh_key TO lt_clinh_key.
        ENDLOOP.

        "Get the inherited class from the chlid levels
        LOOP AT lt_clinh_key INTO ls_clinh_key.
          SELECT objek mafid klart clint adzhl FROM kssk
            INTO CORRESPONDING FIELDS OF TABLE lt_class_key_inh_tmp
            WHERE objek = ls_clinh_key-objek
              AND mafid = 'K'
              AND klart = ls_clinh_key-klart.
          IF sy-subrc = 0.
            APPEND LINES OF lt_class_key_inh_tmp TO lt_class_key_inh.
            LOOP AT lt_class_key_inh_tmp INTO ls_class_key.
              READ TABLE lt_clinh_key WITH KEY objek = ls_class_key-clint
                TRANSPORTING NO FIELDS.
              IF sy-subrc <> 0.
                "Construct record for iteration for child level inheritence
                ls_clinh_key1-objek = ls_class_key-clint.
                ls_clinh_key1-mafid = ls_class_key-mafid.
                ls_clinh_key1-klart = ls_class_key-klart.
                APPEND ls_clinh_key1 TO lt_clinh_key.
              ENDIF.
            ENDLOOP.
            CLEAR lt_class_key_inh_tmp.
          ENDIF.
        ENDLOOP.

        "Classifications
        IF ls_mdo_input_vals-is_cls_return_data_demand->classification IS NOT INITIAL.
          "Determine if there is a field catelog associated with this get method
          CLEAR: lv_select_clause, lv_select_clause_tmp.
          lv_select_clause = me->core_object->build_field_selector_string( iv_mthd_type = lc_mthd_type_get
                                                              iv_tabname   = lc_tab_name-kssk ).
          lv_select_clause_tmp = me->core_object->build_field_selector_string( iv_mthd_type = lc_mthd_type_get
                                                                  iv_tabname   = lc_tab_name-klah ).
          IF lv_select_clause <> '*' AND lv_select_clause_tmp <> '*'.
            CONCATENATE lv_select_clause lv_select_clause_tmp INTO lv_select_clause
                                                              SEPARATED BY space.
          ENDIF.

          SELECT (lv_select_clause) FROM kssk INNER JOIN klah ON klah~clint = kssk~clint
            INTO CORRESPONDING FIELDS OF TABLE ls_mdo_output_vals-et_classification->*
            FOR ALL ENTRIES  IN lt_class_key
            WHERE kssk~objek EQ lt_class_key-objek
              AND kssk~mafid EQ lt_class_key-mafid
              AND kssk~klart EQ lt_class_key-klart
              AND kssk~clint EQ lt_class_key-clint
              AND kssk~adzhl EQ lt_class_key-adzhl.
*
          ASSIGN ls_mdo_output_vals-et_classification->* TO <class_t>.
*
          "Get Class Keywords
          IF <class_t> IS NOT INITIAL.
            SELECT clint kschl FROM swor INTO TABLE lt_kschl
              FOR ALL ENTRIES IN <class_t>
              WHERE clint = <class_t>-clint
                AND spras = sy-langu
                AND klpos = '01'.
          ENDIF.
          SORT lt_kschl BY clint.
          LOOP AT <class_t> ASSIGNING <class>.
            READ TABLE lt_kschl INTO ls_kschl
              WITH KEY clint = <class>-clint BINARY SEARCH.
            IF sy-subrc = 0.
              MOVE ls_kschl-kschl TO <class>-kschl.
            ENDIF.

            "Update the object key in case of multiple objects allowed flag set
            READ TABLE lt_inobkey INTO ls_inobkey WITH KEY cuobj = <class>-objek.
            IF sy-subrc = 0.
              <class>-objek = ls_inobkey-objek.
            ENDIF.
            "Convert object key to original format
            IF <class>-klart = lc_class_type_equi.
              MOVE <class>-objek TO <class>-equnr.
            ELSEIF <class>-klart = lc_class_type_floc.
              MOVE <class>-objek TO <class>-tplnr.
            ELSE.
              SELECT SINGLE * FROM equi INTO ls_equi WHERE equnr = <class>-objek.
              IF sy-subrc = 0.
                MOVE <class>-objek TO <class>-equnr.
              ELSE.
                MOVE <class>-objek TO <class>-tplnr.
              ENDIF.
            ENDIF.
          ENDLOOP.
        ENDIF.

        "Charecteristics
        IF ls_mdo_input_vals-is_cls_return_data_demand->characteristic IS NOT INITIAL.
          "Determine if there is a field catelog associated with this get method
          CLEAR: lv_select_clause, lv_select_clause_tmp.
          lv_select_clause = me->core_object->build_field_selector_string( iv_mthd_type = lc_mthd_type_get
                                                              iv_tabname   = lc_tab_name-ksml ).
          lv_select_clause_tmp = me->core_object->build_field_selector_string( iv_mthd_type = lc_mthd_type_get
                                                                  iv_tabname   = lc_tab_name-cabn ).
          IF lv_select_clause <> '*' AND lv_select_clause_tmp <> '*'.
            CONCATENATE lv_select_clause lv_select_clause_tmp INTO lv_select_clause
                                                              SEPARATED BY space.
          ENDIF.

          SELECT (lv_select_clause) FROM ksml INNER JOIN cabn ON ksml~imerk = cabn~atinn
                                                             AND ksml~adzhl = cabn~adzhl
            INTO CORRESPONDING FIELDS OF TABLE ls_mdo_output_vals-et_characteristic->*
            FOR ALL ENTRIES IN lt_class_key
            WHERE ksml~clint EQ lt_class_key-clint
              AND ksml~adzhl EQ lt_class_key-adzhl
              AND ksml~klart EQ lt_class_key-klart
              AND cabn~atnam IN ls_mdo_input_vals-it_char_name_ra->*
              AND cabn~atnam IN ls_dof_filter_vals-char_name->*.
*
          "Get the inherited chars
          IF lt_class_key_inh IS NOT INITIAL.
            SELECT (lv_select_clause) FROM ksml INNER JOIN cabn ON ksml~imerk = cabn~atinn
                                                               AND ksml~adzhl = cabn~adzhl
              INTO CORRESPONDING FIELDS OF TABLE lt_clsinhchar
              FOR ALL ENTRIES IN lt_class_key_inh
              WHERE ksml~clint EQ lt_class_key_inh-clint
                AND ksml~adzhl EQ lt_class_key_inh-adzhl
                AND ksml~klart EQ lt_class_key_inh-klart
                AND cabn~atnam IN ls_mdo_input_vals-it_char_name_ra->*
                AND cabn~atnam IN ls_dof_filter_vals-char_name->*.
          ENDIF.
          "Add inherited chars to the main table
          LOOP AT lt_clsinhchar INTO ls_clsinhchar.
*            READ TABLE lt_class_key_inh INTO ls_class_key WITH KEY clint = ls_clsinhchar-clint.
            LOOP AT lt_class_key_inh INTO ls_class_key WHERE clint = ls_clsinhchar-clint.
*            IF sy-subrc = 0.
              lv_clint = ls_class_key-objek.
*
              WHILE sy-subrc = 0.
                READ TABLE lt_class_key_inh INTO ls_class_key WITH KEY clint = lv_clint.
                IF sy-subrc = 0.
                  lv_clint = ls_class_key-objek.
                ENDIF.
              ENDWHILE.
*
              IF lv_clint IS NOT INITIAL.
                MOVE lv_clint TO ls_clsinhchar-clint.
                APPEND INITIAL LINE TO ls_mdo_output_vals-et_characteristic->* ASSIGNING <char>.
                MOVE-CORRESPONDING ls_clsinhchar TO <char>.
              ENDIF.
              CLEAR lv_clint.
*            ENDIF.
            ENDLOOP.
          ENDLOOP.
          SORT ls_mdo_output_vals-et_characteristic->* BY clint atinn.
          DELETE ADJACENT DUPLICATES FROM ls_mdo_output_vals-et_characteristic->* COMPARING clint atinn.
*
          ASSIGN ls_mdo_output_vals-et_characteristic->* TO <char_t>.
*
          IF <char_t> IS NOT INITIAL.
            SELECT atinn adzhl atbez FROM cabnt INTO TABLE lt_cabnt
              FOR ALL ENTRIES IN <char_t>
              WHERE atinn = <char_t>-atinn
                AND spras = sy-langu
                AND adzhl = <char_t>-adzhl.
          ENDIF.
          SORT lt_cabnt BY atinn.
          LOOP AT <char_t> ASSIGNING <char>.
            lv_index = sy-tabix.
            "Remove the indirect reference characteristic values from the table
            "as it becomes a performance issue on the fetch
            IF lv_get_ref_char IS INITIAL.                                           "<--Ins SMERP 610_700 SP04 BugID:ERPADDON-294
              IF <char>-attab IS NOT INITIAL.
                DELETE <char_t> INDEX lv_index.
                CONTINUE.
              ENDIF.
            ENDIF.                                                                   "<--Ins SMERP 610_700 SP04 BugID:ERPADDON-294
*
            READ TABLE lt_cabnt INTO ls_cabnt WITH KEY atinn = <char>-atinn
                                     adzhl = <char>-adzhl BINARY SEARCH.
            IF sy-subrc = 0.
              MOVE ls_cabnt-atbez TO <char>-atbez.
            ENDIF.
          ENDLOOP.
        ENDIF.

        "Charecteristic Values
        IF ls_mdo_input_vals-is_cls_return_data_demand->characteristic_val IS NOT INITIAL.
          CLEAR: lv_select_clause.
          lv_select_clause = me->core_object->build_field_selector_string( iv_mthd_type = lc_mthd_type_get
                                                              iv_tabname   = lc_tab_name-ausp ).
          SELECT (lv_select_clause) FROM ausp
          INTO CORRESPONDING FIELDS OF TABLE ls_mdo_output_vals-et_characteristic_val->*
          FOR ALL ENTRIES IN lt_class_key
          WHERE objek EQ lt_class_key-objek
            AND klart EQ lt_class_key-klart
            AND mafid EQ lt_class_key-mafid.
*
          ASSIGN ls_mdo_output_vals-et_characteristic_val->* TO <char_val_t>.
          ASSIGN ls_mdo_output_vals-et_characteristic->* TO <characteristic_t>.
*
          IF <char_val_t> IS NOT INITIAL.
            SELECT cawn~atinn cawn~atzhl cawn~adzhl cawn~atwrt cawnt~atwtb
              FROM cawn INNER JOIN cawnt  ON cawn~atinn = cawnt~atinn
                                         AND cawn~atzhl = cawnt~atzhl
                                         AND cawn~adzhl = cawnt~adzhl
              INTO TABLE lt_cawnt
              FOR ALL ENTRIES IN  <char_val_t>
              WHERE cawn~atinn  = <char_val_t>-atinn
                AND cawn~atwrt  = <char_val_t>-atwrt
                AND cawnt~spras = sy-langu.
          ENDIF.
          SORT lt_cawnt BY atinn atzhl adzhl.
          LOOP AT <char_val_t> ASSIGNING <char_val>.
            CLEAR: lv_op_code1, lv_op_code2.
            CASE <char_val>-atcod.
              WHEN 1.
*              lv_op_code1 = 'EQ'.
              WHEN 2.
                lv_op_code1 = 'GE'. lv_op_code2 = 'LT'.
              WHEN 3.
                lv_op_code1 = 'GE'. lv_op_code2 = 'LE'.
              WHEN 4.
                lv_op_code1 = 'GT'. lv_op_code2 = 'LT'.
              WHEN 5.
                lv_op_code1 = 'GT'. lv_op_code2 = 'LE'.
              WHEN 6.
                lv_op_code1 = 'LT'.
              WHEN 7.
                lv_op_code1 = 'LE'.
              WHEN 8.
                lv_op_code1 = 'GT'.
              WHEN 9.
                lv_op_code1 = 'GE'.
              WHEN OTHERS.
            ENDCASE.
*         "From Value
            IF <char_val>-atflv IS NOT INITIAL.
              CLEAR: lv_char_val, lv_pack_val, lv_char_fld1, lv_char_fld2, lv_msehi.
              CALL METHOD /syclo/cl_pm_mdo_tools=>fltp_to_char_conversion
                EXPORTING
                  iv_number_of_digits = 22
                  iv_fltp_value       = <char_val>-atflv
                IMPORTING
                  ev_char_field       = lv_char_val.
              IF lv_char_val IS NOT INITIAL.
                SPLIT lv_char_val AT '.' INTO lv_char_fld1 lv_char_fld2.
                IF lv_char_fld2 = 0.
                  CONCATENATE lv_op_code1 lv_char_fld1 INTO <char_val>-atflv_char.
                ELSE.
*                  MOVE lv_char_val TO lv_pack_val.
*                  MOVE lv_pack_val TO lv_char_fld1.
                  "--------------------------handle decimal places.
                  IF <characteristic_t> IS NOT INITIAL.
                    READ TABLE <characteristic_t> ASSIGNING <characteristic_s> WITH KEY atinn = <char_val>-atinn.
                    IF <characteristic_s> IS NOT INITIAL.
                      IF <characteristic_s>-anzdz > 0.
                        CONCATENATE lv_char_fld1 '.' lv_char_fld2(<characteristic_s>-anzdz) INTO lv_char_fld1.
                      ELSE.
                        MOVE lv_char_val TO lv_char_fld1.
                      ENDIF.
                    ENDIF.
                  ELSE.
                    MOVE lv_char_val TO lv_pack_val.
                    MOVE lv_pack_val TO lv_char_fld1.
                  ENDIF.
                  "--------------------------
                  CONDENSE lv_char_fld1 NO-GAPS.
                  CONCATENATE lv_op_code1 lv_char_fld1 INTO <char_val>-atflv_char
                                                              SEPARATED BY space.
                ENDIF.
              ENDIF.
              "Check for unit
              READ TABLE <char_t> ASSIGNING <char> WITH KEY atinn = <char_val>-atinn.
              IF sy-subrc = 0.
                CALL FUNCTION 'CONVERSION_EXIT_LUNIT_OUTPUT'
                  EXPORTING
                    input          = <char>-msehi
                    language       = sy-langu
                  IMPORTING
                    output         = lv_msehi
                  EXCEPTIONS
                    unit_not_found = 1
                    OTHERS         = 2.
                IF sy-subrc <> 0.
*               MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                       WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
                ELSE.
                  CONCATENATE <char_val>-atflv_char lv_msehi INTO <char_val>-atflv_char
                                                                  SEPARATED BY space.
                ENDIF.
              ENDIF.
              CONDENSE <char_val>-atflv_char.
            ENDIF.
            "To Value
            IF <char_val>-atflb IS NOT INITIAL.
              CLEAR: lv_char_val, lv_pack_val, lv_char_fld1, lv_char_fld2.
              CALL METHOD /syclo/cl_pm_mdo_tools=>fltp_to_char_conversion
                EXPORTING
                  iv_number_of_digits = 22
                  iv_fltp_value       = <char_val>-atflb
                IMPORTING
                  ev_char_field       = lv_char_val.
              IF lv_char_val IS NOT INITIAL.
                SPLIT lv_char_val AT '.' INTO lv_char_fld1 lv_char_fld2.
                IF lv_char_fld2 = 0.
                  CONCATENATE lv_op_code1 lv_char_fld1 INTO <char_val>-atflb_char.
                ELSE.
*                  MOVE lv_char_val TO lv_pack_val.
*                  MOVE lv_pack_val TO lv_char_fld1.
                  "--------------------------handle decimal places.
                  IF <characteristic_t> IS NOT INITIAL.
                    READ TABLE <characteristic_t> ASSIGNING <characteristic_s> WITH KEY atinn = <char_val>-atinn.
                    IF <characteristic_s> IS NOT INITIAL.
                      IF <characteristic_s>-anzdz > 0.
                         CONCATENATE lv_char_fld1 '.' lv_char_fld2(<characteristic_s>-anzdz) INTO lv_char_fld1.
                      ELSE.
                        MOVE lv_char_val TO lv_char_fld1.
                      ENDIF.
                    ENDIF.
                  ELSE.
                    MOVE lv_char_val TO lv_pack_val.
                    MOVE lv_pack_val TO lv_char_fld1.
                  ENDIF.
                  "--------------------------
                  CONDENSE lv_char_fld1 NO-GAPS.
                  CONCATENATE lv_op_code2 lv_char_fld1 INTO <char_val>-atflb_char
                                                              SEPARATED BY space.
                ENDIF.
              ENDIF.
              "Check for unit
              CONCATENATE <char_val>-atflb_char lv_msehi INTO <char_val>-atflb_char
                                                              SEPARATED BY space.
              CONDENSE <char_val>-atflb_char.
            ENDIF.

*         "Char Value text
            IF <char_val>-atwrt IS NOT INITIAL.
              READ TABLE lt_cawnt INTO ls_cawnt WITH KEY atinn = <char_val>-atinn
                                                         adzhl = <char_val>-adzhl
                                                         atwrt = <char_val>-atwrt.
              IF sy-subrc = 0.
                MOVE ls_cawnt-atwtb TO <char_val>-atwtb.
              ENDIF.
            ENDIF.

            "Update the object key in case of multiple objects allowed flag set
            READ TABLE lt_inobkey INTO ls_inobkey WITH KEY cuobj = <char_val>-objek.
            IF sy-subrc = 0.
              <char_val>-objek = ls_inobkey-objek.
            ENDIF.

            "Convert object key to original format
            IF <char_val>-klart = lc_class_type_equi.
              MOVE <char_val>-objek TO <char_val>-equnr.
            ELSEIF <char_val>-klart = lc_class_type_floc.
              MOVE <char_val>-objek TO <char_val>-tplnr.
            ELSE.
              SELECT SINGLE * FROM equi INTO ls_equi WHERE equnr = <char_val>-objek.
              IF sy-subrc = 0.
                MOVE <char_val>-objek TO <char_val>-equnr.
              ELSE.
                MOVE <char_val>-objek TO <char_val>-tplnr.
              ENDIF.
            ENDIF.
          ENDLOOP.
        ENDIF.

*     End Badi
        IF NOT lref_badi_classif IS INITIAL.
          CALL BADI lref_badi_classif->get_end
            EXPORTING
              iref_mdo_data = me->core_object->oref_mdo_data
            CHANGING
              cs_mdo_output = ls_mdo_output_vals.
        ENDIF.
*----------------------------------------------------------------------*
* Step 3 - Prepare MDO output data
*----------------------------------------------------------------------*
        " -->return output data to MDO data object,
        " output data in MDO data are mapped to BAPI Wrapper
        " data container automatically by POSTPROCESS_MAPPING
        me->core_object->oref_mdo_data->set_mdo_output_via_ref_struct(
          EXPORTING is_mdo_output = ls_mdo_output_vals ).

*     Class-Based Exception Handling
      CATCH cx_root INTO lref_exception.                 "#EC CATCH_ALL
        /syclo/cl_core_appl_logger=>logger->catch_class_exception(
          EXPORTING is_bapi_input   = me->core_object->str_bapi_input
                    iref_exception  = lref_exception
                    iv_user_guid    = me->core_object->str_bapi_input-user_guid
                    iref_return_tab = iref_rfc_oo_data->dref_return ).
    ENDTRY.
*ENDMETHOD.


  ENDMETHOD.                    "IOW_ZPM_CLASSIFICATION_UPDATE~GET
ENDCLASS.
