CLASS lcl_zz_enh_ctmatplant_do DEFINITION DEFERRED.
CLASS /smerp/cl_mm_material_do DEFINITION LOCAL FRIENDS lcl_zz_enh_ctmatplant_do.
*----------------------------------------------------------------------*
*       CLASS LCL_ZZ_ENH_CTMATPLANT_DO DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_zz_enh_ctmatplant_do DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA obj TYPE REF TO lcl_zz_enh_ctmatplant_do.    "#EC NEEDED
    DATA core_object TYPE REF TO /smerp/cl_mm_material_do . "#EC NEEDED
 INTERFACES  IOW_ZZ_ENH_CTMATPLANT_DO.
    METHODS:
     constructor IMPORTING core_object
       TYPE REF TO /smerp/cl_mm_material_do OPTIONAL.
ENDCLASS.                    "LCL_ZZ_ENH_CTMATPLANT_DO DEFINITION
*----------------------------------------------------------------------*
*       CLASS LCL_ZZ_ENH_CTMATPLANT_DO IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_zz_enh_ctmatplant_do IMPLEMENTATION.
  METHOD constructor.
    me->core_object = core_object.
  ENDMETHOD.                    "CONSTRUCTOR

  METHOD iow_zz_enh_ctmatplant_do~get_matplant.
*"------------------------------------------------------------------------*
*" Declaration of Overwrite-method, do not insert any comments here please!
*"
*"methods GET_MATPLANT
*"  importing
*"    value(IREF_RFC_OO_DATA) type ref to /SYCLO/CL_CORE_RFC_OO_DATA .
*"------------------------------------------------------------------------*

* NBHANDARI - Class Override Method for Material Selection by Status MARA-MSTAE
*   Required by Union Gas to filter inactive materials.

*OO Reference Variables
    DATA: lref_data TYPE REF TO data,
          lref_exception TYPE REF TO cx_root,
          lref_do_serv TYPE REF TO /syclo/cl_core_do_services.

    DATA: lt_plant TYPE /syclo/core_range_tab.

    FIELD-SYMBOLS: <fs_plant> LIKE LINE OF lt_plant.

*Tables & Structures
    "The following structure contains reference to all available filters
    "from ConfigPanel. Filter name is consistent with what is declared
    "in filter service method GET_DATA_FILTER_LIST

    DATA: BEGIN OF ls_dof_filter_vals,
            plant                   TYPE REF TO /syclo/core_range_tab,
            material                TYPE REF TO /syclo/core_range_tab,
            materialgrp             TYPE REF TO /syclo/core_range_tab,
            materialtype            TYPE REF TO /syclo/core_range_tab,
            purchgrp                TYPE REF TO /syclo/core_range_tab,
            mrpplanner              TYPE REF TO /syclo/core_range_tab,
            ind_sector              TYPE REF TO /syclo/core_range_tab,
            item_cat                TYPE REF TO /syclo/core_range_tab,
            prod_hier               TYPE REF TO /syclo/core_range_tab,
            trans_grp               TYPE REF TO /syclo/core_range_tab,
            mat_grp_sm              TYPE REF TO /syclo/core_range_tab,
            sh_mat_typ              TYPE REF TO /syclo/core_range_tab,
            division                TYPE REF TO /syclo/core_range_tab,
            batch_mgmt_basic        TYPE REF TO /syclo/core_range_tab,
            mrp_type                TYPE REF TO /syclo/core_range_tab,
            proc_type               TYPE REF TO /syclo/core_range_tab,
            loadinggrp              TYPE REF TO /syclo/core_range_tab,
            availcheck              TYPE REF TO /syclo/core_range_tab,
            batch_mgmt_plant        TYPE REF TO /syclo/core_range_tab,
            cpmaterial              TYPE REF TO /syclo/core_range_tab,
            max_no_of_hits          TYPE REF TO /syclo/core_range_tab,
          END OF ls_dof_filter_vals.

    DATA: BEGIN OF ls_mdo_input_vals,
            it_plant_ra             TYPE REF TO /syclo/core_range_tab,
            it_material_ra          TYPE REF TO /syclo/core_range_tab,
            it_materialgrp_ra       TYPE REF TO /syclo/core_range_tab,
            it_materialtype_ra      TYPE REF TO /syclo/core_range_tab,
            it_purchgrp_ra          TYPE REF TO /syclo/core_range_tab,
            it_mrpplanner_ra        TYPE REF TO /syclo/core_range_tab,
            it_ind_sector_ra        TYPE REF TO /syclo/core_range_tab,
            it_item_cat_ra          TYPE REF TO /syclo/core_range_tab,
            it_prod_hier_ra         TYPE REF TO /syclo/core_range_tab,
            it_trans_grp_ra         TYPE REF TO /syclo/core_range_tab,
            it_mat_grp_sm_ra        TYPE REF TO /syclo/core_range_tab,
            it_sh_mat_typ_ra        TYPE REF TO /syclo/core_range_tab,
            it_division_ra          TYPE REF TO /syclo/core_range_tab,
            it_batch_mgmt_basic_ra  TYPE REF TO /syclo/core_range_tab,
            it_mrp_type_ra          TYPE REF TO /syclo/core_range_tab,
            it_proc_type_ra         TYPE REF TO /syclo/core_range_tab,
            it_loadinggrp_ra        TYPE REF TO /syclo/core_range_tab,
            it_availcheck_ra        TYPE REF TO /syclo/core_range_tab,
            it_batch_mgmt_plant_ra  TYPE REF TO /syclo/core_range_tab,
          END OF ls_mdo_input_vals.

    DATA: ls_return TYPE bapiret2.

    DATA: lt_maramarc TYPE STANDARD TABLE OF /syclo/mm_maramarc_str,
          lt_marc_deleted TYPE STANDARD TABLE OF /syclo/mm_marc_deleted_str,
          ls_maramarc LIKE LINE OF lt_maramarc,
          ls_marc_deleted LIKE LINE OF lt_marc_deleted.

*******************************************************************************************
* Date : 12/03/2015              Added by : RPATHARE
* Data declaration  to contain  manufacturer details
*********************************************************************************************
DATA : lt_maramarc_mfrdetails TYPE STANDARD TABLE OF /syclo/mm_maramarc_str,
          ls_maramarc_mfrdetails LIKE LINE OF lt_maramarc_mfrdetails.
*********************************************************************************************
    "The following structure contains reference to all supported output
    "parameter from MDO handler. Output parameter name is set to the same
    "as what is declared in receiving BAPI warpper signature for simplicity.
    DATA: BEGIN OF ls_mdo_output_vals,
            et_complex_table              TYPE REF TO /syclo/mm_maramarc_tab,
            et_exchange_action_deleted    TYPE REF TO /syclo/mm_marc_deleted_tab,
          END OF ls_mdo_output_vals.

    DATA: BEGIN OF ls_exch_matnr,
            matnr TYPE matnr,
          END OF ls_exch_matnr,
          lt_exch_matnr LIKE STANDARD TABLE OF ls_exch_matnr.

    DATA: BEGIN OF ls_key_matnr,
            matnr TYPE matnr,
            plant TYPE werks_d,
          END OF ls_key_matnr,
          lt_key_matnr LIKE STANDARD TABLE OF ls_key_matnr.
********************************************************************************************
* Date : 12/03/2015              Added by : RPATHARE
* Data declaration  to contain  manufacturer details
*********************************************************************************************
    DATA: BEGIN OF ls_mfrnr,
                mfrpn type mfrpn,
                mfrnr type mfrnr,
                bmatn TYPE mpmat,
                name1 TYPE name1_gp,
              END OF ls_mfrnr,
              lt_mfrnr LIKE STANDARD TABLE OF ls_mfrnr.
*********************************************************************************************
*Variables
    DATA: lv_select_clause TYPE string,
          lv_range_name TYPE string.
    DATA: lv_index TYPE sy-tabix.
    DATA: lv_max_no_of_hit TYPE sy-index.
    DATA: lv_cursor TYPE cursor.

    DATA: lv_dsf_supported TYPE wdy_boolean.                          "<-ins SMERP 610_700 SP03 bugid ERPADDON-145

*Field Symbols
    FIELD-SYMBOLS: <return> TYPE bapiret2_t.

    FIELD-SYMBOLS: <exch_data_tab> TYPE ANY TABLE,
                   <exch_data> TYPE any,
                   <objkey> TYPE any,
                   <changed_ts> TYPE any.
    FIELD-SYMBOLS: <dsf_segment> LIKE LINE OF me->core_object->tab_dsf_data_segments.     "<-ins SMERP 610_700 SP03 bugid ERPADDON145

*Constants
    CONSTANTS: lc_mthd TYPE /syclo/core_do_mthd_dte VALUE 'GET_MATPLANT',
               lc_dummy_key_matnr TYPE matnr VALUE '##################',
               lc_dummy_key_plant TYPE werks_d VALUE '####'.

*****************************************************
* Main Section
*****************************************************
    TRY.
        me->core_object->message = 'Entering method ~ GET_MATPLANT...'(m03).
        me->core_object->logger->loginfo( iv_mobile_user = me->core_object->str_bapi_input-mobile_user
                             iv_mobile_id = me->core_object->str_bapi_input-mobile_id
                             iv_user_guid = me->core_object->str_bapi_input-user_guid
                             iv_message = me->core_object->message
                             iv_source = me->core_object->source ).

*Step 1 - Convert RFC Parameter into OO format
        "Set return time stamp at begining if exchange process not used
        IF me->core_object->str_bapi_input-timestamp_from_mobile IS INITIAL.
          me->core_object->str_bapi_output-timestamp_to_mobile = /syclo/cl_core_do_services=>get_sys_timestamp( ).
        ENDIF.

*-----------------------------------------------------------------------*
*Step 1 - Initialization
*-----------------------------------------------------------------------*
*Insert start from here SMERP 610_700 SP03 bugid ERPADDON-145
        lv_dsf_supported = me->core_object->check_dsf_store_supported( iv_do_mthd = me->core_object->active_do_mthd ).
        IF ( lv_dsf_supported = abap_true
          AND me->core_object->staging_active = abap_true
          AND me->core_object->str_do_stg_setting-get_dstore_act = abap_true ).
          me->core_object->initialize_dsf_request(
            EXPORTING iref_data_manager = iref_rfc_oo_data
                      iv_user_guid = me->core_object->active_user_guid
            IMPORTING et_dsf_request = me->core_object->tab_dsf_data_segments ).
          LOOP AT me->core_object->tab_dsf_data_segments ASSIGNING <dsf_segment> WHERE table_alias = /syclo/cl_core_ct_handler=>const_complex_table_name
                                                                       OR table_alias = /syclo/cl_core_ct_handler=>const_exch_del_table_name.
            IF <dsf_segment>-alias_structure = space AND <dsf_segment>-mdo_data IS NOT BOUND.
              CLEAR lv_dsf_supported.
            ENDIF.
          ENDLOOP.
          IF lv_dsf_supported = abap_false.
            me->core_object->skip_dstore_package = abap_true.
          ELSE.
            RETURN.
          ENDIF.
        ENDIF.
*Insert end here SMERP 610_700 SP03 bugid ERPADDON-145

        lref_do_serv = /syclo/cl_core_do_services=>get_do_service(
                                        iref_logger = me->core_object->logger ).

        "initialize output tables
        CREATE DATA: ls_mdo_output_vals-et_complex_table,
                     ls_mdo_output_vals-et_exchange_action_deleted.

        " --Retrieve supplied MDO input data and map to local variables.
        " MDO input data are supplied by BAPI wrapper and mapped to MDO
        " data object by PREPROCESS_MAPPING
        me->core_object->oref_mdo_data->map_local_mobile_filter(
          EXPORTING iv_auto_init = abap_true
          CHANGING cs_filters = ls_mdo_input_vals ).

        " -->Retrieve filter settings as defined via ConfigPanel.
        " ConfigPanel filter settings has been mapped to MDO data object
        " by INITIALIZE_MDO_DATA
        me->core_object->oref_mdo_data->map_local_dof_filter(
          EXPORTING iv_auto_init = abap_true
          CHANGING cs_filters = ls_dof_filter_vals ).


* Read Exchange Table Data if mobile time stamp provided
        IF me->core_object->str_bapi_input-timestamp_from_mobile IS NOT INITIAL.
          "Default to start time when reading exchange table, in case there is nothing changed
          me->core_object->str_bapi_output-timestamp_to_mobile = /syclo/cl_core_do_services=>get_sys_timestamp( ).

          me->core_object->read_exchange_data( EXPORTING iv_exchobj = me->core_object->str_do_setting-exchobj
                                            iv_ts = me->core_object->str_bapi_input-timestamp_from_mobile
                                            iref_rfc_oo_data = iref_rfc_oo_data
                                  IMPORTING eref_data = lref_data ).
          IF lref_data IS BOUND.
            ASSIGN lref_data->* TO <exch_data_tab>.
            IF <exch_data_tab> IS NOT INITIAL.
              LOOP AT <exch_data_tab> ASSIGNING <exch_data>.
                ASSIGN COMPONENT 'OBJKEY' OF STRUCTURE <exch_data> TO <objkey>.
                IF sy-subrc = 0.
                  APPEND <objkey> TO lt_exch_matnr.
                ENDIF.

                ASSIGN COMPONENT 'CHANGED_TS' OF STRUCTURE <exch_data> TO <changed_ts>.
                IF sy-subrc = 0 AND <changed_ts> > me->core_object->str_bapi_output-timestamp_to_mobile.
                  me->core_object->str_bapi_output-timestamp_to_mobile = <changed_ts>.
                ENDIF.

              ENDLOOP.
            ELSE.
              APPEND lc_dummy_key_matnr TO lt_exch_matnr.
            ENDIF.
          ENDIF.
        ENDIF.

*----------------------------------------------------------------------*
* Step 2 - Determination of Object Key List for the fetch process.
*----------------------------------------------------------------------*

        IF ls_dof_filter_vals-max_no_of_hits->* IS NOT INITIAL.
          /smerp/cl_core_mdo_tools=>get_simple_val_from_range(
            EXPORTING it_range_table = ls_dof_filter_vals-max_no_of_hits->*
            IMPORTING ev_low = lv_max_no_of_hit ).
        ENDIF.

        "Determine if there is a field catelog associated with this get method
        lv_select_clause = me->core_object->build_field_selector_string( iv_mthd = lc_mthd ).

* Begin of Changes by Eldhose Mathew PwC on 1/5/2015
        IF ls_dof_filter_vals-plant->* IS NOT INITIAL.
          SELECT zmat_plant AS low
                 FROM zpmt_main_matpnt
                 INTO CORRESPONDING FIELDS OF TABLE lt_plant
                 WHERE zmain_plant IN ls_dof_filter_vals-plant->*.

          IF sy-subrc EQ 0.
            LOOP AT lt_plant ASSIGNING <fs_plant>.
              <fs_plant>-sign = 'I'.
              <fs_plant>-option = 'EQ'.
            ENDLOOP.
            ls_dof_filter_vals-plant->* = lt_plant.
          ENDIF.
        ENDIF.
* End of changes by Eldhose Mathew

        "Filter key based on DOF Rules
        IF lt_exch_matnr[] IS INITIAL.
          OPEN CURSOR lv_cursor FOR
          SELECT marc~matnr marc~werks
            FROM mara INNER JOIN marc ON mara~matnr = marc~matnr
            WHERE mara~matnr IN ls_dof_filter_vals-material->*
              AND mara~mtart IN ls_dof_filter_vals-materialtype->*
              AND mara~matkl IN ls_dof_filter_vals-materialgrp->*
              AND marc~werks IN ls_dof_filter_vals-plant->*
              AND marc~ekgrp IN ls_dof_filter_vals-purchgrp->*
              AND marc~dispo IN ls_dof_filter_vals-mrpplanner->*
              AND mara~mbrsh IN ls_dof_filter_vals-ind_sector->*
              AND mara~mtpos_mara IN ls_dof_filter_vals-item_cat->*
              AND mara~prdha IN ls_dof_filter_vals-prod_hier->*
              AND mara~tragr IN ls_dof_filter_vals-trans_grp->*
              AND mara~magrv IN ls_dof_filter_vals-mat_grp_sm->*
              AND mara~vhart IN ls_dof_filter_vals-sh_mat_typ->*
              AND mara~spart IN ls_dof_filter_vals-division->*
              AND mara~xchpf IN ls_dof_filter_vals-batch_mgmt_basic->*
              AND marc~dismm IN ls_dof_filter_vals-mrp_type->*
              AND marc~beskz IN ls_dof_filter_vals-proc_type->*
              AND marc~ladgr IN ls_dof_filter_vals-loadinggrp->*
              AND marc~mtvfp IN ls_dof_filter_vals-availcheck->*
              AND marc~xchpf IN ls_dof_filter_vals-batch_mgmt_plant->*
              " Start Change NBHANDARI PwC
              AND mara~mstae IN ls_dof_filter_vals-cpmaterial->*
              " End Change
              AND mara~matnr IN ls_mdo_input_vals-it_material_ra->*
              AND mara~mtart IN ls_mdo_input_vals-it_materialtype_ra->*
              AND mara~matkl IN ls_mdo_input_vals-it_materialgrp_ra->*
              AND marc~werks IN ls_mdo_input_vals-it_plant_ra->*
              AND marc~ekgrp IN ls_mdo_input_vals-it_purchgrp_ra->*
              AND marc~dispo IN ls_mdo_input_vals-it_mrpplanner_ra->*
              AND mara~mbrsh IN ls_mdo_input_vals-it_ind_sector_ra->*
              AND mara~mtpos_mara IN ls_mdo_input_vals-it_item_cat_ra->*
              AND mara~prdha IN ls_mdo_input_vals-it_prod_hier_ra->*
              AND mara~tragr IN ls_mdo_input_vals-it_trans_grp_ra->*
              AND mara~magrv IN ls_mdo_input_vals-it_mat_grp_sm_ra->*
              AND mara~vhart IN ls_mdo_input_vals-it_sh_mat_typ_ra->*
              AND mara~spart IN ls_mdo_input_vals-it_division_ra->*
              AND mara~xchpf IN ls_mdo_input_vals-it_batch_mgmt_basic_ra->*
              AND marc~dismm IN ls_mdo_input_vals-it_mrp_type_ra->*
              AND marc~beskz IN ls_mdo_input_vals-it_proc_type_ra->*
              AND marc~ladgr IN ls_mdo_input_vals-it_loadinggrp_ra->*
              AND marc~mtvfp IN ls_mdo_input_vals-it_availcheck_ra->*
              AND marc~xchpf IN ls_mdo_input_vals-it_batch_mgmt_plant_ra->*.

          FETCH NEXT CURSOR lv_cursor INTO TABLE lt_key_matnr PACKAGE SIZE lv_max_no_of_hit.
          CLOSE CURSOR lv_cursor.
          IF lt_key_matnr[] IS INITIAL.
            ls_key_matnr-matnr = lc_dummy_key_matnr.
            ls_key_matnr-plant = lc_dummy_key_plant.
            APPEND ls_key_matnr TO lt_key_matnr.
          ENDIF.
        ELSE.
          OPEN CURSOR lv_cursor FOR
          SELECT marc~matnr marc~werks
            FROM mara INNER JOIN marc ON mara~matnr = marc~matnr
            FOR ALL ENTRIES IN lt_exch_matnr
            WHERE mara~matnr IN ls_dof_filter_vals-material->*
              AND mara~mtart IN ls_dof_filter_vals-materialtype->*
              AND mara~matkl IN ls_dof_filter_vals-materialgrp->*
              AND marc~werks IN ls_dof_filter_vals-plant->*
              AND marc~ekgrp IN ls_dof_filter_vals-purchgrp->*
              AND marc~dispo IN ls_dof_filter_vals-mrpplanner->*

              AND mara~matnr = lt_exch_matnr-matnr

              AND mara~mbrsh IN ls_dof_filter_vals-ind_sector->*
              AND mara~mtpos_mara IN ls_dof_filter_vals-item_cat->*
              AND mara~prdha IN ls_dof_filter_vals-prod_hier->*
              AND mara~tragr IN ls_dof_filter_vals-trans_grp->*
              AND mara~magrv IN ls_dof_filter_vals-mat_grp_sm->*
              AND mara~vhart IN ls_dof_filter_vals-sh_mat_typ->*
              AND mara~spart IN ls_dof_filter_vals-division->*
              AND mara~xchpf IN ls_dof_filter_vals-batch_mgmt_basic->*
              AND marc~dismm IN ls_dof_filter_vals-mrp_type->*
              AND marc~beskz IN ls_dof_filter_vals-proc_type->*
              AND marc~ladgr IN ls_dof_filter_vals-loadinggrp->*
              AND marc~mtvfp IN ls_dof_filter_vals-availcheck->*
              AND marc~xchpf IN ls_dof_filter_vals-batch_mgmt_plant->*
              " Start Change NBHANDARI PwC
              AND mara~mstae IN ls_dof_filter_vals-cpmaterial->*
            " End Change
              AND mara~matnr IN ls_mdo_input_vals-it_material_ra->*
              AND mara~mtart IN ls_mdo_input_vals-it_materialtype_ra->*
              AND mara~matkl IN ls_mdo_input_vals-it_materialgrp_ra->*
              AND marc~werks IN ls_mdo_input_vals-it_plant_ra->*
              AND marc~ekgrp IN ls_mdo_input_vals-it_purchgrp_ra->*
              AND marc~dispo IN ls_mdo_input_vals-it_mrpplanner_ra->*
              AND mara~mbrsh IN ls_mdo_input_vals-it_ind_sector_ra->*
              AND mara~mtpos_mara IN ls_mdo_input_vals-it_item_cat_ra->*
              AND mara~prdha IN ls_mdo_input_vals-it_prod_hier_ra->*
              AND mara~tragr IN ls_mdo_input_vals-it_trans_grp_ra->*
              AND mara~magrv IN ls_mdo_input_vals-it_mat_grp_sm_ra->*
              AND mara~vhart IN ls_mdo_input_vals-it_sh_mat_typ_ra->*
              AND mara~spart IN ls_mdo_input_vals-it_division_ra->*
              AND mara~xchpf IN ls_mdo_input_vals-it_batch_mgmt_basic_ra->*
              AND marc~dismm IN ls_mdo_input_vals-it_mrp_type_ra->*
              AND marc~beskz IN ls_mdo_input_vals-it_proc_type_ra->*
              AND marc~ladgr IN ls_mdo_input_vals-it_loadinggrp_ra->*
              AND marc~mtvfp IN ls_mdo_input_vals-it_availcheck_ra->*
              AND marc~xchpf IN ls_mdo_input_vals-it_batch_mgmt_plant_ra->*.

          FETCH NEXT CURSOR lv_cursor INTO TABLE lt_key_matnr PACKAGE SIZE lv_max_no_of_hit.
          CLOSE CURSOR lv_cursor.
          IF lt_key_matnr[] IS INITIAL.
            ls_key_matnr-matnr = lc_dummy_key_matnr.
            ls_key_matnr-plant = lc_dummy_key_plant.
            APPEND ls_key_matnr TO lt_key_matnr.
          ENDIF.
        ENDIF.

        "Perform main SQL selection
        IF lt_key_matnr[] IS NOT INITIAL.
          SELECT (lv_select_clause)
            FROM mara INNER JOIN marc ON mara~matnr = marc~matnr
                       " INNER JOIN makt ON mara~matnr = makt~matnr AND makt~spras = sy-langu   "<--del SMERP 610_700 SP04 BugID ERPADDON-269
                      LEFT OUTER JOIN makt ON mara~matnr = makt~matnr AND makt~spras = sy-langu "<--ins SMERP 610_700 SP04 BugID ERPADDON-269
                      INNER JOIN t006 ON mara~meins = t006~msehi
            INTO CORRESPONDING FIELDS OF TABLE lt_maramarc
            FOR ALL ENTRIES IN lt_key_matnr
              WHERE marc~matnr = lt_key_matnr-matnr
                AND marc~werks = lt_key_matnr-plant.
        ENDIF.
********************************************************************************************************************
* Date : 12/03/2015    Added By : RPATHARE
*  Get the manufacturer and manufacturer part number
********************************************************************************************************************
        IF lt_maramarc[] IS NOT INITIAL.
           SELECT mfrpn mfrnr bmatn name1
           FROM MARA LEFT OUTER JOIN LFA1  ON mara~mfrnr = lfa1~lifnr
             INTO CORRESPONDING FIELDS OF TABLE lt_mfrnr
              FOR ALL ENTRIES IN lt_key_matnr
             WHERE mara~bmatn = lt_key_matnr-matnr
             AND  mara~lvorm <> 'X' .
        ENDIF.

*********************************************************************************************************************
        IF lt_maramarc[] IS INITIAL.
          ASSIGN iref_rfc_oo_data->dref_return->* TO <return>.
          ls_return-type = 'I'.
          ls_return-message = 'No data found'(i01).
          APPEND ls_return TO <return>.
        ENDIF.

        LOOP AT lt_maramarc INTO ls_maramarc WHERE lvorm <> space.
          lv_index = sy-tabix.
          IF me->core_object->str_bapi_input-timestamp_from_mobile IS NOT INITIAL AND lref_data IS BOUND.
            LOOP AT <exch_data_tab> ASSIGNING <exch_data>.
              ASSIGN COMPONENT 'OBJKEY' OF STRUCTURE <exch_data> TO <objkey>.
              IF sy-subrc = 0.
                IF ls_maramarc-matnr = <objkey>.
                  MOVE-CORRESPONDING <exch_data> TO ls_marc_deleted.
                  ls_marc_deleted-matnr = ls_maramarc-matnr.
                  ls_marc_deleted-werks = ls_maramarc-werks.
                  ls_marc_deleted-action = /syclo/cl_core_constants=>exch_action_delete.
                  APPEND ls_marc_deleted TO lt_marc_deleted.
                ENDIF.
              ENDIF.
            ENDLOOP.
          ENDIF.
          DELETE lt_maramarc INDEX lv_index.
        ENDLOOP.
*********************************************************************************************************************
* Date : 12/03/2015    Added By : RPATHARE
*  Get the manufacturer and manufacturer part number
********************************************************************************************************************
     SORT lt_mfrnr ASCENDING BY bmatn.
     IF lt_mfrnr[] IS NOT INITIAL.
         LOOP AT lt_maramarc INTO ls_maramarc.

* 2016/01/21 - ACR-486 G. Ymana - Fixed logic bug that was bypassing materials
*                                 without a Manuf. part number
*
*           LOOP AT lt_mfrnr INTO ls_mfrnr WHERE bmatn = ls_maramarc-matnr.
*                MOVE-CORRESPONDING ls_maramarc to ls_maramarc_mfrdetails.
*                ls_maramarc_mfrdetails-mfrnr = ls_mfrnr-mfrnr.
*                ls_maramarc_mfrdetails-mfrpn = ls_mfrnr-mfrpn.
*                ls_maramarc_mfrdetails-mfrnr_name = ls_mfrnr-name1.
*                APPEND ls_maramarc_mfrdetails to lt_maramarc_mfrdetails.
*         ENDLOOP.

          CLEAR: ls_mfrnr, ls_maramarc_mfrdetails-mfrnr, ls_maramarc_mfrdetails-mfrpn,
                 ls_maramarc_mfrdetails-mfrnr_name.
          READ TABLE lt_mfrnr INTO ls_mfrnr WITH KEY bmatn = ls_maramarc-matnr.
          MOVE-CORRESPONDING ls_maramarc to ls_maramarc_mfrdetails.
          ls_maramarc_mfrdetails-mfrnr = ls_mfrnr-mfrnr.
          ls_maramarc_mfrdetails-mfrpn = ls_mfrnr-mfrpn.
          ls_maramarc_mfrdetails-mfrnr_name = ls_mfrnr-name1.
          APPEND ls_maramarc_mfrdetails to lt_maramarc_mfrdetails.
       ENDLOOP.
     ENDIF.

********************************************************************************************************************
* Step 3 - Build output data in OO parameter format
        SORT lt_maramarc.
        DELETE ADJACENT DUPLICATES FROM lt_maramarc.
        SORT lt_marc_deleted.
        DELETE ADJACENT DUPLICATES FROM lt_marc_deleted.
*********************************************************************************************************************
* Date : 12/09/15    Added By : RPATHARE
*  Add the manufacturer and manufacturer part number to complex table
********************************************************************************************************************
*       APPEND LINES OF lt_maramarc TO ls_mdo_output_vals-et_complex_table->*.
        APPEND LINES OF lt_maramarc_mfrdetails TO ls_mdo_output_vals-et_complex_table->*.
********************************************************************************************************************

        APPEND LINES OF  lt_marc_deleted TO ls_mdo_output_vals-et_exchange_action_deleted->*.

        " --return output data to MDO data object, which mapped to BAPI
        " Wrapper data container automatically by POSTPROCESS_MAPPING
        me->core_object->oref_mdo_data->set_mdo_output_via_ref_struct(
           EXPORTING is_mdo_output = ls_mdo_output_vals ).

* Class-Based Exception Handling
      CATCH cx_root INTO lref_exception.                 "#EC CATCH_ALL
        /syclo/cl_core_appl_logger=>logger->catch_class_exception(
          EXPORTING iv_mobile_user = me->core_object->str_bapi_input-mobile_user
                    iv_mobile_id = me->core_object->str_bapi_input-mobile_id
                    iv_user_guid = me->core_object->str_bapi_input-user_guid
                    iref_exception = lref_exception
                    iref_return_tab = iref_rfc_oo_data->dref_return ).

    ENDTRY.
  ENDMETHOD.                    "IOW_ZZ_ENH_CTMATPLANT_DO~GET_MATPLANT
ENDCLASS.
