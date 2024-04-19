CLASS lcl_zz_enh_smerp_workorder_do DEFINITION DEFERRED.
CLASS /smerp/cl_pm_workorder_do DEFINITION LOCAL FRIENDS lcl_zz_enh_smerp_workorder_do.
*----------------------------------------------------------------------*
*       CLASS LCL_ZZ_ENH_SMERP_WORKORDER_DO DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_zz_enh_smerp_workorder_do DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA obj TYPE REF TO lcl_zz_enh_smerp_workorder_do. "#EC NEEDED
    DATA core_object TYPE REF TO /smerp/cl_pm_workorder_do . "#EC NEEDED
 INTERFACES  IOW_ZZ_ENH_SMERP_WORKORDER_DO.
    METHODS:
     constructor IMPORTING core_object
       TYPE REF TO /smerp/cl_pm_workorder_do OPTIONAL.
ENDCLASS.                    "LCL_ZZ_ENH_SMERP_WORKORDER_DO DEFINITION
*----------------------------------------------------------------------*
*       CLASS LCL_ZZ_ENH_SMERP_WORKORDER_DO IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_zz_enh_smerp_workorder_do IMPLEMENTATION.
  METHOD constructor.
    me->core_object = core_object.
  ENDMETHOD.                    "CONSTRUCTOR

  METHOD iow_zz_enh_smerp_workorder_do~get_work_order_operation.
*"------------------------------------------------------------------------*
*" Declaration of Overwrite-method, do not insert any comments here please!
*"
*"methods GET_WORK_ORDER_OPERATION
*"  importing
*"    value(IREF_RFC_OO_DATA) type ref to /SYCLO/CL_CORE_RFC_OO_DATA .
*"------------------------------------------------------------------------*
************************************************************************
* Data Declaration Section
************************************************************************
*OO Reference Variables
    DATA: lref_exception TYPE REF TO cx_root,
          lref_bom_mbl_stat TYPE REF TO /syclo/cl_core_bom_mbl_status.

*Variables
    DATA: ls_return TYPE bapiret2,
          lv_mbl_stat_objkey TYPE /syclo/core_status_objkey_dte,
          ls_wo_operation TYPE /syclo/pm_afvc_str,
          lv_spras TYPE thead-tdspras,                    "<--Ins SMERP 610_700 SP1 BugID ERPADDON-141
          lv_tdline TYPE felfd,
          lv_tdname TYPE tdobname,
          lv_index TYPE sy-tabix,
          lv_select_clause TYPE string,
          lv_select_clause_tmp TYPE string,
          lv_system_Status type BSVX-STTXT,
          lv_user_Status type BSVX-STTXT.

*Tables and Structures
    DATA: BEGIN OF ls_arbpl,
            objty TYPE cr_objty,
            objid TYPE cr_objid,
            arbpl TYPE arbpl,
          END OF ls_arbpl,
          lt_arbpl LIKE HASHED TABLE OF ls_arbpl WITH UNIQUE KEY objty objid.

    DATA: lt_tline TYPE STANDARD TABLE OF tline.

* Constants
    CONSTANTS: BEGIN OF lc_tab_name,
                afvc  TYPE string VALUE 'AFVC',
                afvv  TYPE string VALUE 'AFVV',
               END OF lc_tab_name.

    CONSTANTS: lc_wo_header_tdobject TYPE tdobject VALUE 'AUFK',
               lc_wo_op_tdid TYPE tdid VALUE 'AVOT'.
    CONSTANTS: BEGIN OF lc_mobile_stat,
                received  TYPE /syclo/core_mobile_status_dte VALUE 'RECEIVED',
                started   TYPE /syclo/core_mobile_status_dte VALUE 'STARTED',
                hold      TYPE /syclo/core_mobile_status_dte VALUE 'HOLD',
                completed TYPE /syclo/core_mobile_status_dte VALUE 'COMPLETED',
              END OF lc_mobile_stat.

* Field Symbols
    FIELD-SYMBOLS: <return>         TYPE bapiret2_t,
                   <tline>          TYPE tline,
                   <longtext>       TYPE /syclo/pm_longtext_str,
*{   DELETE                                                           1
*\                   <wo_header>      TYPE /syclo/pm_caufv_str,
*}   DELETE
*{   INSERT                                                           2
                     <wo_header>      TYPE /syclo/cs_caufv_str,
*}   INSERT
                   <wo_operation>   TYPE /syclo/pm_afvc_str,
                   <wo_operation_t> TYPE /syclo/pm_afvc_tab,
                   <wo_operation1>  TYPE /syclo/pm_afvc_str.

************************************************************************
* Main Section
************************************************************************
************************************************************************
*Step 1 - Initialization
************************************************************************
    TRY.
        me->core_object->message = 'Entering method ~ GET_WORK_ORDER_OPERATION...'(m27).
        me->core_object->logger->loginfo( iv_mobile_user = me->core_object->str_bapi_input-mobile_user
                             iv_mobile_id = me->core_object->str_bapi_input-mobile_id
                             iv_user_guid = me->core_object->str_bapi_input-user_guid
                             iv_message = me->core_object->message
                             iv_source = me->core_object->source ).

        "Initialize local reference objects
        CREATE OBJECT: lref_bom_mbl_stat.

**************************************************************************
* Overwrite Method: For Assignment Type "6", we want all operations
* For a selected work order to go to Work Manager so remove Work Center
* Check
**************************************************************************

**************************************************************************
*Step 2 - Work Order Operation Query logic
**************************************************************************

        "--> Work Order Operation
        IF me->core_object->str_mdo_input_vals-is_wo_return_data_demand->workorder_operation IS NOT INITIAL.
          "Determine if there is a field catelog associated with this get method
          CLEAR: lv_select_clause, lv_select_clause_tmp.
          lv_select_clause = me->core_object->build_field_selector_string( iv_mthd = me->core_object->active_do_mthd
                                                              iv_tabname = lc_tab_name-afvc ).
          lv_select_clause_tmp = me->core_object->build_field_selector_string( iv_mthd = me->core_object->active_do_mthd
                                                              iv_tabname = lc_tab_name-afvv ).
          IF lv_select_clause <> '*' AND lv_select_clause_tmp <> '*'.
            CONCATENATE lv_select_clause lv_select_clause_tmp INTO lv_select_clause
                                                              SEPARATED BY space.
          ENDIF.
          IF lv_select_clause <> '*' AND lv_select_clause IS NOT INITIAL.
            CONCATENATE lv_select_clause 'AFKO~AUFNR' INTO lv_select_clause SEPARATED BY space.
          ENDIF.

          CASE me->core_object->assignment_type.
            WHEN '1' OR '5' OR '7' OR '8'.              "Header assignment
              IF me->core_object->gt_oper_object IS INITIAL.
                SELECT (lv_select_clause) FROM afko INNER JOIN afvc ON afvc~aufpl = afko~aufpl
                                                    INNER JOIN afvv ON afvv~aufpl = afvc~aufpl AND
                                                                       afvv~aplzl = afvc~aplzl
                  INTO CORRESPONDING FIELDS OF TABLE me->core_object->str_mdo_output_vals-et_workorder_operation->*
                  FOR ALL ENTRIES IN me->core_object->gt_aufnr_delta
                  WHERE afko~aufnr = me->core_object->gt_aufnr_delta-aufnr
                    AND afvc~aufpl IN me->core_object->str_mdo_input_vals-it_oper_routing_no_ra->*
                    AND afvc~aplzl IN me->core_object->str_mdo_input_vals-it_oper_counter_ra->*
                    AND afvc~arbid IN me->core_object->arbid_merged
                    AND afvc~werks IN me->core_object->str_dof_filter_vals-oper_plant->*
                    AND afvc~werks IN me->core_object->str_mdo_input_vals-it_oper_plant_ra->*
                    AND afvc~steus IN me->core_object->str_dof_filter_vals-oper_control_key->*
                    AND afvc~steus IN me->core_object->str_mdo_input_vals-it_oper_control_key_ra->*
                    AND afvc~larnt IN me->core_object->str_dof_filter_vals-oper_acttype->*
                    AND afvc~larnt IN me->core_object->str_mdo_input_vals-it_oper_acttype_ra->*.
              ELSE.
                SELECT (lv_select_clause) FROM afko INNER JOIN afvc ON afvc~aufpl = afko~aufpl
                                                    INNER JOIN afvv ON afvv~aufpl = afvc~aufpl AND
                                                                       afvv~aplzl = afvc~aplzl
                  INTO CORRESPONDING FIELDS OF TABLE me->core_object->str_mdo_output_vals-et_workorder_operation->*
                  FOR ALL ENTRIES IN me->core_object->gt_oper_object
                  WHERE afko~aufnr = me->core_object->gt_oper_object-aufnr
                    AND afvc~aufpl = me->core_object->gt_oper_object-aufpl
                    AND afvc~aplzl = me->core_object->gt_oper_object-aplzl
                    AND afvc~aufpl IN me->core_object->str_mdo_input_vals-it_oper_routing_no_ra->*
                    AND afvc~aplzl IN me->core_object->str_mdo_input_vals-it_oper_counter_ra->*
                    AND afvc~arbid IN me->core_object->arbid_merged
                    AND afvc~werks IN me->core_object->str_dof_filter_vals-oper_plant->*
                    AND afvc~werks IN me->core_object->str_mdo_input_vals-it_oper_plant_ra->*
                    AND afvc~steus IN me->core_object->str_dof_filter_vals-oper_control_key->*
                    AND afvc~steus IN me->core_object->str_mdo_input_vals-it_oper_control_key_ra->*
                    AND afvc~larnt IN me->core_object->str_dof_filter_vals-oper_acttype->*
                    AND afvc~larnt IN me->core_object->str_mdo_input_vals-it_oper_acttype_ra->*.
              ENDIF.

            WHEN '2'.              "Operation assignment type 2
              IF me->core_object->gt_oper_object IS INITIAL.
                SELECT (lv_select_clause) FROM afko INNER JOIN afvc ON afvc~aufpl = afko~aufpl
                                                    INNER JOIN afvv ON afvv~aufpl = afvc~aufpl AND
                                                                       afvv~aplzl = afvc~aplzl
                  INTO CORRESPONDING FIELDS OF TABLE me->core_object->str_mdo_output_vals-et_workorder_operation->*
                  FOR ALL ENTRIES IN me->core_object->gt_aufnr_delta
                  WHERE afko~aufnr = me->core_object->gt_aufnr_delta-aufnr
                    AND afvc~pernr IN me->core_object->pernr_merged
                    AND afvc~aufpl IN me->core_object->str_mdo_input_vals-it_oper_routing_no_ra->*
                    AND afvc~aplzl IN me->core_object->str_mdo_input_vals-it_oper_counter_ra->*
                    AND afvc~arbid IN me->core_object->arbid_merged
                    AND afvc~werks IN me->core_object->str_dof_filter_vals-oper_plant->*
                    AND afvc~werks IN me->core_object->str_mdo_input_vals-it_oper_plant_ra->*
                    AND afvc~steus IN me->core_object->str_dof_filter_vals-oper_control_key->*
                    AND afvc~steus IN me->core_object->str_mdo_input_vals-it_oper_control_key_ra->*
                    AND afvc~larnt IN me->core_object->str_dof_filter_vals-oper_acttype->*
                    AND afvc~larnt IN me->core_object->str_mdo_input_vals-it_oper_acttype_ra->*.
              ELSE.
                SELECT (lv_select_clause) FROM afko INNER JOIN afvc ON afvc~aufpl = afko~aufpl
                                                    INNER JOIN afvv ON afvv~aufpl = afvc~aufpl AND
                                                                       afvv~aplzl = afvc~aplzl
                  INTO CORRESPONDING FIELDS OF TABLE me->core_object->str_mdo_output_vals-et_workorder_operation->*
                  FOR ALL ENTRIES IN me->core_object->gt_oper_object
                  WHERE afko~aufnr = me->core_object->gt_oper_object-aufnr
                    AND afvc~aufpl = me->core_object->gt_oper_object-aufpl
                    AND afvc~aplzl = me->core_object->gt_oper_object-aplzl
                    AND afvc~pernr IN me->core_object->pernr_merged
                    AND afvc~aufpl IN me->core_object->str_mdo_input_vals-it_oper_routing_no_ra->*
                    AND afvc~aplzl IN me->core_object->str_mdo_input_vals-it_oper_counter_ra->*
                    AND afvc~arbid IN me->core_object->arbid_merged
                    AND afvc~werks IN me->core_object->str_dof_filter_vals-oper_plant->*
                    AND afvc~werks IN me->core_object->str_mdo_input_vals-it_oper_plant_ra->*
                    AND afvc~steus IN me->core_object->str_dof_filter_vals-oper_control_key->*
                    AND afvc~steus IN me->core_object->str_mdo_input_vals-it_oper_control_key_ra->*
                    AND afvc~larnt IN me->core_object->str_dof_filter_vals-oper_acttype->*
                    AND afvc~larnt IN me->core_object->str_mdo_input_vals-it_oper_acttype_ra->*.
              ENDIF.

              DELETE me->core_object->str_mdo_output_vals-et_workorder_operation->* WHERE sumnr > 0.
              ASSIGN me->core_object->str_mdo_output_vals-et_workorder_operation->* TO <wo_operation_t>.

              IF  <wo_operation_t> IS NOT INITIAL.
                "Get all the Sub-Operations for the Operation
                SELECT (lv_select_clause) FROM afko INNER JOIN afvc ON afvc~aufpl = afko~aufpl
                                                    INNER JOIN afvv ON afvv~aufpl = afvc~aufpl AND
                                                                       afvv~aplzl = afvc~aplzl
                  APPENDING CORRESPONDING FIELDS OF TABLE me->core_object->str_mdo_output_vals-et_workorder_operation->*
                  FOR ALL ENTRIES IN <wo_operation_t>
                  WHERE afko~aufnr = <wo_operation_t>-aufnr
                    AND afvc~aufpl = <wo_operation_t>-aufpl
                    AND afvc~sumnr = <wo_operation_t>-aplzl.
                SORT me->core_object->str_mdo_output_vals-et_workorder_operation->* BY aufnr aufpl aplzl.
              ENDIF.

            WHEN '6'.              "Operation assignment type 6
              IF me->core_object->gt_oper_object IS INITIAL.
                SELECT (lv_select_clause) FROM afko INNER JOIN afvc ON afvc~aufpl = afko~aufpl
                                                    INNER JOIN afvv ON afvv~aufpl = afvc~aufpl AND
                                                                       afvv~aplzl = afvc~aplzl
                  INTO CORRESPONDING FIELDS OF TABLE me->core_object->str_mdo_output_vals-et_workorder_operation->*
                  FOR ALL ENTRIES IN me->core_object->gt_aufnr_delta
                  WHERE afko~aufnr = me->core_object->gt_aufnr_delta-aufnr
                    AND afvc~arbid IN me->core_object->arbid_merged
                    AND afvc~aufpl IN me->core_object->str_mdo_input_vals-it_oper_routing_no_ra->*
                    AND afvc~aplzl IN me->core_object->str_mdo_input_vals-it_oper_counter_ra->*
                    "AND afvc~arbid IN me->core_object->arbid_merged
                    AND afvc~werks IN me->core_object->str_dof_filter_vals-oper_plant->*
                    AND afvc~werks IN me->core_object->str_mdo_input_vals-it_oper_plant_ra->*
                    AND afvc~steus IN me->core_object->str_dof_filter_vals-oper_control_key->*
                    AND afvc~steus IN me->core_object->str_mdo_input_vals-it_oper_control_key_ra->*
                    AND afvc~larnt IN me->core_object->str_dof_filter_vals-oper_acttype->*
                    AND afvc~larnt IN me->core_object->str_mdo_input_vals-it_oper_acttype_ra->*.
              ELSE.
                SELECT (lv_select_clause) FROM afko INNER JOIN afvc ON afvc~aufpl = afko~aufpl
                                                    INNER JOIN afvv ON afvv~aufpl = afvc~aufpl AND
                                                                       afvv~aplzl = afvc~aplzl
                  INTO CORRESPONDING FIELDS OF TABLE me->core_object->str_mdo_output_vals-et_workorder_operation->*
                  FOR ALL ENTRIES IN me->core_object->gt_oper_object
                  WHERE afko~aufnr = me->core_object->gt_oper_object-aufnr
                    AND afvc~aufpl = me->core_object->gt_oper_object-aufpl
                    AND afvc~aplzl = me->core_object->gt_oper_object-aplzl
                    "AND afvc~arbid IN me->core_object->arbid_merged
                    AND afvc~aufpl IN me->core_object->str_mdo_input_vals-it_oper_routing_no_ra->*
                    AND afvc~aplzl IN me->core_object->str_mdo_input_vals-it_oper_counter_ra->*
                    AND afvc~werks IN me->core_object->str_dof_filter_vals-oper_plant->*
                    AND afvc~werks IN me->core_object->str_mdo_input_vals-it_oper_plant_ra->*
                    AND afvc~steus IN me->core_object->str_dof_filter_vals-oper_control_key->*
                    AND afvc~steus IN me->core_object->str_mdo_input_vals-it_oper_control_key_ra->*
                    AND afvc~larnt IN me->core_object->str_dof_filter_vals-oper_acttype->*
                    AND afvc~larnt IN me->core_object->str_mdo_input_vals-it_oper_acttype_ra->*.
              ENDIF.

              DELETE me->core_object->str_mdo_output_vals-et_workorder_operation->* WHERE sumnr > 0.
              ASSIGN me->core_object->str_mdo_output_vals-et_workorder_operation->* TO <wo_operation_t>.
              IF  <wo_operation_t> IS NOT INITIAL.
                "Get all the Sub-Operations for the Operation
                SELECT (lv_select_clause) FROM afko INNER JOIN afvc ON afvc~aufpl = afko~aufpl
                                                    INNER JOIN afvv ON afvv~aufpl = afvc~aufpl AND
                                                                       afvv~aplzl = afvc~aplzl
                  APPENDING CORRESPONDING FIELDS OF TABLE me->core_object->str_mdo_output_vals-et_workorder_operation->*
                  FOR ALL ENTRIES IN <wo_operation_t>
                  WHERE afko~aufnr = <wo_operation_t>-aufnr
                    AND afvc~aufpl = <wo_operation_t>-aufpl
                    AND afvc~sumnr = <wo_operation_t>-aplzl.
                SORT me->core_object->str_mdo_output_vals-et_workorder_operation->* BY aufnr aufpl aplzl.
              ENDIF.

            WHEN '3'.              "Sub-operation assignment
              IF me->core_object->gt_oper_object IS INITIAL.
                SELECT (lv_select_clause) FROM afko INNER JOIN afvc ON afvc~aufpl = afko~aufpl
                                                    INNER JOIN afvv ON afvv~aufpl = afvc~aufpl AND
                                                                       afvv~aplzl = afvc~aplzl
                  INTO CORRESPONDING FIELDS OF TABLE me->core_object->str_mdo_output_vals-et_workorder_operation->*
                  FOR ALL ENTRIES IN me->core_object->gt_aufnr_delta
                  WHERE afko~aufnr = me->core_object->gt_aufnr_delta-aufnr
                    AND afvc~pernr IN me->core_object->pernr_merged
                    AND afvc~aufpl IN me->core_object->str_mdo_input_vals-it_oper_routing_no_ra->*
                    AND afvc~aplzl IN me->core_object->str_mdo_input_vals-it_oper_counter_ra->*
                    AND afvc~arbid IN me->core_object->arbid_merged
                    AND afvc~werks IN me->core_object->str_dof_filter_vals-oper_plant->*
                    AND afvc~werks IN me->core_object->str_mdo_input_vals-it_oper_plant_ra->*
                    AND afvc~steus IN me->core_object->str_dof_filter_vals-oper_control_key->*
                    AND afvc~steus IN me->core_object->str_mdo_input_vals-it_oper_control_key_ra->*
                    AND afvc~larnt IN me->core_object->str_dof_filter_vals-oper_acttype->*
                    AND afvc~larnt IN me->core_object->str_mdo_input_vals-it_oper_acttype_ra->*.
              ELSE.
                SELECT (lv_select_clause) FROM afko INNER JOIN afvc ON afvc~aufpl = afko~aufpl
                                                    INNER JOIN afvv ON afvv~aufpl = afvc~aufpl AND
                                                                       afvv~aplzl = afvc~aplzl
                  INTO CORRESPONDING FIELDS OF TABLE me->core_object->str_mdo_output_vals-et_workorder_operation->*
                  FOR ALL ENTRIES IN me->core_object->gt_oper_object
                  WHERE afko~aufnr = me->core_object->gt_oper_object-aufnr
                    AND afvc~aufpl = me->core_object->gt_oper_object-aufpl
                    AND afvc~aplzl = me->core_object->gt_oper_object-aplzl
                    AND afvc~pernr IN me->core_object->pernr_merged
                    AND afvc~aufpl IN me->core_object->str_mdo_input_vals-it_oper_routing_no_ra->*
                    AND afvc~aplzl IN me->core_object->str_mdo_input_vals-it_oper_counter_ra->*
                    AND afvc~arbid IN me->core_object->arbid_merged
                    AND afvc~werks IN me->core_object->str_dof_filter_vals-oper_plant->*
                    AND afvc~werks IN me->core_object->str_mdo_input_vals-it_oper_plant_ra->*
                    AND afvc~steus IN me->core_object->str_dof_filter_vals-oper_control_key->*
                    AND afvc~steus IN me->core_object->str_mdo_input_vals-it_oper_control_key_ra->*
                    AND afvc~larnt IN me->core_object->str_dof_filter_vals-oper_acttype->*
                    AND afvc~larnt IN me->core_object->str_mdo_input_vals-it_oper_acttype_ra->*.
              ENDIF.
              DELETE me->core_object->str_mdo_output_vals-et_workorder_operation->* WHERE sumnr < 1.

            WHEN '4' OR 'A'.              "Work center crew/MRS
              IF me->core_object->gt_oper_object IS INITIAL.
                SELECT (lv_select_clause) FROM afko INNER JOIN kbed ON afko~bedid = kbed~bedid
                                                    INNER JOIN afvc ON kbed~aufpl = afvc~aufpl AND
                                                                       kbed~aplzl = afvc~aplzl
                                                    INNER JOIN afvv ON kbed~aufpl = afvv~aufpl AND
                                                                       kbed~aplzl = afvv~aplzl
                  INTO CORRESPONDING FIELDS OF TABLE me->core_object->str_mdo_output_vals-et_workorder_operation->*
                  FOR ALL ENTRIES IN me->core_object->gt_aufnr_delta
                  WHERE afko~aufnr = me->core_object->gt_aufnr_delta-aufnr
                    AND kbed~pernr IN me->core_object->pernr_merged
                    AND afvc~aufpl IN me->core_object->str_mdo_input_vals-it_oper_routing_no_ra->*
                    AND afvc~aplzl IN me->core_object->str_mdo_input_vals-it_oper_counter_ra->*
                    AND afvc~arbid IN me->core_object->arbid_merged
                    AND afvc~werks IN me->core_object->str_dof_filter_vals-oper_plant->*
                    AND afvc~werks IN me->core_object->str_mdo_input_vals-it_oper_plant_ra->*
                    AND afvc~steus IN me->core_object->str_dof_filter_vals-oper_control_key->*
                    AND afvc~steus IN me->core_object->str_mdo_input_vals-it_oper_control_key_ra->*
                    AND afvc~larnt IN me->core_object->str_dof_filter_vals-oper_acttype->*
                    AND afvc~larnt IN me->core_object->str_mdo_input_vals-it_oper_acttype_ra->*.
              ELSE.
                SELECT (lv_select_clause) FROM afko INNER JOIN kbed ON afko~bedid = kbed~bedid
                                                    INNER JOIN afvc ON kbed~aufpl = afvc~aufpl AND
                                                                       kbed~aplzl = afvc~aplzl
                                                    INNER JOIN afvv ON kbed~aufpl = afvv~aufpl AND
                                                                       kbed~aplzl = afvv~aplzl
                  INTO CORRESPONDING FIELDS OF TABLE me->core_object->str_mdo_output_vals-et_workorder_operation->*
                  FOR ALL ENTRIES IN me->core_object->gt_oper_object
                  WHERE afko~aufnr = me->core_object->gt_oper_object-aufnr
                    AND kbed~pernr IN me->core_object->pernr_merged
                    AND afvc~aufpl = me->core_object->gt_oper_object-aufpl
                    AND afvc~aplzl = me->core_object->gt_oper_object-aplzl
                    AND afvc~aufpl IN me->core_object->str_mdo_input_vals-it_oper_routing_no_ra->*
                    AND afvc~aplzl IN me->core_object->str_mdo_input_vals-it_oper_counter_ra->*
                    AND afvc~arbid IN me->core_object->arbid_merged
                    AND afvc~werks IN me->core_object->str_dof_filter_vals-oper_plant->*
                    AND afvc~werks IN me->core_object->str_mdo_input_vals-it_oper_plant_ra->*
                    AND afvc~steus IN me->core_object->str_dof_filter_vals-oper_control_key->*
                    AND afvc~steus IN me->core_object->str_mdo_input_vals-it_oper_control_key_ra->*
                    AND afvc~larnt IN me->core_object->str_dof_filter_vals-oper_acttype->*
                    AND afvc~larnt IN me->core_object->str_mdo_input_vals-it_oper_acttype_ra->*.
              ENDIF.

              SORT me->core_object->str_mdo_output_vals-et_workorder_operation->* BY aufnr aufpl aplzl.
              DELETE ADJACENT DUPLICATES FROM me->core_object->str_mdo_output_vals-et_workorder_operation->*
                                                                COMPARING aufnr aufpl aplzl.

              DELETE me->core_object->str_mdo_output_vals-et_workorder_operation->* WHERE sumnr > 0.
              ASSIGN me->core_object->str_mdo_output_vals-et_workorder_operation->* TO <wo_operation_t>.

              IF  <wo_operation_t> IS NOT INITIAL.
                "Get all the Sub-Operations for the Operation
                SELECT (lv_select_clause) FROM afko INNER JOIN afvc ON afvc~aufpl = afko~aufpl
                                                    INNER JOIN afvv ON afvv~aufpl = afvc~aufpl AND
                                                                       afvv~aplzl = afvc~aplzl
                  APPENDING CORRESPONDING FIELDS OF TABLE me->core_object->str_mdo_output_vals-et_workorder_operation->*
                  FOR ALL ENTRIES IN <wo_operation_t>
                  WHERE afko~aufnr = <wo_operation_t>-aufnr
                    AND afvc~aufpl = <wo_operation_t>-aufpl
                    AND afvc~sumnr = <wo_operation_t>-aplzl.
                SORT me->core_object->str_mdo_output_vals-et_workorder_operation->* BY aufnr aufpl aplzl.
              ENDIF.

            WHEN OTHERS.
              IF me->core_object->gt_oper_object IS INITIAL.
                SELECT (lv_select_clause) FROM afko INNER JOIN afvc ON afvc~aufpl = afko~aufpl
                                                    INNER JOIN afvv ON afvv~aufpl = afvc~aufpl AND
                                                                       afvv~aplzl = afvc~aplzl
                  INTO CORRESPONDING FIELDS OF TABLE me->core_object->str_mdo_output_vals-et_workorder_operation->*
                  FOR ALL ENTRIES IN me->core_object->gt_aufnr_delta
                  WHERE afko~aufnr = me->core_object->gt_aufnr_delta-aufnr
                    AND afvc~aufpl IN me->core_object->str_mdo_input_vals-it_oper_routing_no_ra->*
                    AND afvc~aplzl IN me->core_object->str_mdo_input_vals-it_oper_counter_ra->*
                    AND afvc~arbid IN me->core_object->arbid_merged
                    AND afvc~werks IN me->core_object->str_dof_filter_vals-oper_plant->*
                    AND afvc~werks IN me->core_object->str_mdo_input_vals-it_oper_plant_ra->*
                    AND afvc~steus IN me->core_object->str_dof_filter_vals-oper_control_key->*
                    AND afvc~steus IN me->core_object->str_mdo_input_vals-it_oper_control_key_ra->*
                    AND afvc~larnt IN me->core_object->str_dof_filter_vals-oper_acttype->*
                    AND afvc~larnt IN me->core_object->str_mdo_input_vals-it_oper_acttype_ra->*.
              ELSE.
                SELECT (lv_select_clause) FROM afko INNER JOIN afvc ON afvc~aufpl = afko~aufpl
                                                    INNER JOIN afvv ON afvv~aufpl = afvc~aufpl AND
                                                                       afvv~aplzl = afvc~aplzl
                  INTO CORRESPONDING FIELDS OF TABLE me->core_object->str_mdo_output_vals-et_workorder_operation->*
                  FOR ALL ENTRIES IN me->core_object->gt_oper_object
                  WHERE afko~aufnr = me->core_object->gt_oper_object-aufnr
                    AND afvc~aufpl = me->core_object->gt_oper_object-aufpl
                    AND afvc~aplzl = me->core_object->gt_oper_object-aplzl
                    AND afvc~aufpl IN me->core_object->str_mdo_input_vals-it_oper_routing_no_ra->*
                    AND afvc~aplzl IN me->core_object->str_mdo_input_vals-it_oper_counter_ra->*
                    AND afvc~arbid IN me->core_object->arbid_merged
                    AND afvc~werks IN me->core_object->str_dof_filter_vals-oper_plant->*
                    AND afvc~werks IN me->core_object->str_mdo_input_vals-it_oper_plant_ra->*
                    AND afvc~steus IN me->core_object->str_dof_filter_vals-oper_control_key->*
                    AND afvc~steus IN me->core_object->str_mdo_input_vals-it_oper_control_key_ra->*
                    AND afvc~larnt IN me->core_object->str_dof_filter_vals-oper_acttype->*
                    AND afvc~larnt IN me->core_object->str_mdo_input_vals-it_oper_acttype_ra->*.
              ENDIF.
          ENDCASE.
        ENDIF.

        LOOP AT me->core_object->str_mdo_output_vals-et_workorder_operation->* ASSIGNING <wo_operation>.
          lv_index = sy-tabix.

          IF <wo_operation>-sumnr > 0.
            READ TABLE me->core_object->str_mdo_output_vals-et_workorder_operation->* INTO ls_wo_operation
              WITH KEY aufpl = <wo_operation>-aufpl
                       aplzl = <wo_operation>-sumnr
              TRANSPORTING vornr.
            IF sy-subrc = 0.
              <wo_operation>-uvorn = <wo_operation>-vornr.
              <wo_operation>-vornr = ls_wo_operation-vornr.
            ELSE.
              <wo_operation>-uvorn = <wo_operation>-vornr.
              SELECT SINGLE vornr FROM afvc INTO <wo_operation>-vornr
                WHERE aufpl = <wo_operation>-aufpl
                  AND aplzl = <wo_operation>-sumnr.
            ENDIF.
          ENDIF.

          "Get Mobile status
          lv_mbl_stat_objkey = <wo_operation>-objnr.
          <wo_operation>-mobile_status = lref_bom_mbl_stat->get_current_mbl_status(
                                    iv_objkey = lv_mbl_stat_objkey
                                    iv_mobile_app = me->core_object->str_do_setting-mobile_app ).

          "Get System & User status
          CALL FUNCTION 'STATUS_TEXT_EDIT'
            EXPORTING
              objnr            = <wo_operation>-objnr
              flg_user_stat    = 'X'
              spras            = sy-langu
            IMPORTING
              line             = <wo_operation>-system_status
              user_line        = <wo_operation>-user_status
            EXCEPTIONS
              object_not_found = 1
              OTHERS           = 2.
          IF sy-subrc <> 0.
            CLEAR: <wo_operation>-system_status, <wo_operation>-user_status.
          ENDIF.
          "if mobile status of operation is complete and system status is not complete
          "then change the mobile status because it change in status does allow to complete
          "the operation at Work Manager
          IF <wo_operation>-mobile_status = lc_mobile_stat-completed AND
             <wo_operation>-system_status IS NOT INITIAL.
            FIND FIRST OCCURRENCE OF 'CNF' IN <wo_operation>-system_status.
            IF sy-subrc <> 0.
              <wo_operation>-mobile_status = lc_mobile_stat-received.
            ENDIF.
          ENDIF.
          "Update Work Center data
          IF <wo_operation>-arbid IS NOT INITIAL.
            CLEAR lt_arbpl.
            READ TABLE lt_arbpl INTO ls_arbpl WITH KEY objty = 'A'
                                                       objid = <wo_operation>-arbid.
            IF sy-subrc = 0.
              <wo_operation>-arbpl = ls_arbpl-arbpl.
            ELSE.
              SELECT SINGLE objty objid arbpl FROM crhd
                INTO CORRESPONDING FIELDS OF ls_arbpl
                WHERE objty = 'A'
                  AND objid = <wo_operation>-arbid.
              IF sy-subrc = 0.
                <wo_operation>-arbpl = ls_arbpl-arbpl.
                INSERT ls_arbpl INTO TABLE lt_arbpl.
              ENDIF.
            ENDIF.
          ENDIF.

          IF me->core_object->str_mdo_input_vals-is_wo_return_data_demand->workorder_longtext IS NOT INITIAL.
            IF <wo_operation>-txtsp IS NOT INITIAL.                   "<--Ins SMERP 610_700 SP1 BugID ERPADDON-141
              MOVE <wo_operation>-txtsp TO lv_spras.                  "<--Ins SMERP 610_700 SP1 BugID ERPADDON-141
              REFRESH lt_tline.
              CONCATENATE sy-mandt <wo_operation>-aufpl <wo_operation>-aplzl INTO lv_tdname.
* End Start <-- SMERP 610_700 SP01 bugid ERPADDON-98 JONESCHRI1
*            CALL FUNCTION 'READ_TEXT'
*              EXPORTING
**                language                = sy-langu                 "<--Ins SMERP 610_700 SP1 BugID ERPADDON-141
*                language                = lv_spras                  "<--Ins SMERP 610_700 SP1 BugID ERPADDON-141
*                id                      = lc_wo_op_tdid
*                name                    = lv_tdname
*                object                  = lc_wo_header_tdobject
*              TABLES
*                lines                   = lt_tline
*              EXCEPTIONS
*                id                      = 1
*                language                = 2
*                name                    = 3
*                not_found               = 4
*                object                  = 5
*                reference_check         = 6
*                wrong_access_to_archive = 7
*                OTHERS                  = 8.
* End Delete <-- SMERP 610_700 SP01 bugid ERPADDON-98 JONESCHRI1

* Start Insert <-- SMERP 610_700 SP01 bugid ERPADDON-98 JONESCHRI1
              CALL METHOD /smerp/cl_core_mdo_tools=>get_standard_text
                EXPORTING
                  iv_language        = lv_spras
                  iv_id              = lc_wo_op_tdid
                  iv_name            = lv_tdname
                  iv_object          = lc_wo_header_tdobject
                IMPORTING
                  et_tline           = lt_tline
                EXCEPTIONS
                  ex_read_text_error = 1
                  OTHERS             = 2.
* End Insert <-- SMERP 610_700 SP01 bugid ERPADDON-98 JONESCHRI1
              IF sy-subrc EQ 0.
                CLEAR: lv_tdname, lv_tdline.
                CONCATENATE <wo_operation>-aufnr <wo_operation>-vornr INTO lv_tdname.
                IF <wo_operation>-uvorn > 0.
                  CONCATENATE lv_tdname <wo_operation>-uvorn INTO lv_tdname.
                ENDIF.
                LOOP AT lt_tline ASSIGNING <tline>.
                  lv_tdline = sy-tabix.
                  APPEND INITIAL LINE TO me->core_object->str_mdo_output_vals-et_workorder_longtext->* ASSIGNING <longtext>.
                  <longtext>-objtype = lc_wo_op_tdid.
                  <longtext>-objkey = lv_tdname.
                  <longtext>-tdlinenum = lv_tdline.
                  IF <tline>-tdformat(1) = '>'.
                    <longtext>-tdformat = <tline>-tdline(2).
                    <longtext>-tdline = <tline>-tdline+2.
                  ELSE.
                    <longtext>-tdformat = <tline>-tdformat.
                    <longtext>-tdline = <tline>-tdline.
                  ENDIF.
                ENDLOOP.
              ENDIF.
            ENDIF.                                                      "<--Ins SMERP 610_700 SP1 BugID ERPADDON-141
          ENDIF.
        ENDLOOP.

        IF me->core_object->assignment_type = '2' OR me->core_object->assignment_type = '3' OR me->core_object->assignment_type = '4' OR
           me->core_object->assignment_type = '6' OR me->core_object->assignment_type = 'A'.
*       Implement the fetch logic for mobile status update when assignement type = 2, 3, 4, 6 and A.
*       1.If any operation assigned to the user's mobile status is STARTED,
          "then workorder header mobile status is displayed as STARTED for the user.
*       2.If any operation is on HOLD and no operations are STARTED, then workorder status is HOLD.
*       3.If all operations for the user are in status COMPLETED,
          "then the workorder header mobile status is COMPLETED for the user.
*       4.If any operation is in status COMPLETED and no operations are in STARTED,
          "then workorder mobile status is HOLD indicating that workorder is in progress.
*       5.Displayed Workorder header mobile status will be calculated as above,
          "Actual Workorder mobile status in SAP table will not be affected since multiple users may share the same workorder
          LOOP AT me->core_object->str_mdo_output_vals-et_workorder_header->* ASSIGNING <wo_header>.
            lv_index = sy-tabix.
            "Remove header and valid WO records if there is no relevent operations
            READ TABLE me->core_object->str_mdo_output_vals-et_workorder_operation->*
              WITH KEY aufnr = <wo_header>-aufnr TRANSPORTING NO FIELDS.
            IF sy-subrc <> 0.
              DELETE me->core_object->gt_aufnr_delta WHERE aufnr = <wo_header>-aufnr.
              DELETE me->core_object->str_mdo_output_vals-et_valid_workorder->* WHERE aufnr = <wo_header>-aufnr.
              DELETE me->core_object->str_mdo_output_vals-et_workorder_longtext->* WHERE objkey = <wo_header>-aufnr.
              DELETE me->core_object->str_mdo_output_vals-et_workorder_header->* INDEX lv_index.
              CONTINUE.
            ENDIF.
*
            READ TABLE me->core_object->str_mdo_output_vals-et_workorder_operation->* ASSIGNING <wo_operation>
              WITH KEY aufnr = <wo_header>-aufnr mobile_status = lc_mobile_stat-started.
            IF sy-subrc = 0.
              <wo_header>-mobile_status = lc_mobile_stat-started.
              CONTINUE.
            ENDIF.
*
            READ TABLE me->core_object->str_mdo_output_vals-et_workorder_operation->* ASSIGNING <wo_operation>
              WITH KEY aufnr = <wo_header>-aufnr mobile_status = lc_mobile_stat-hold.
            IF sy-subrc = 0.
              <wo_header>-mobile_status = lc_mobile_stat-hold.
              CONTINUE.
            ENDIF.
*
            READ TABLE me->core_object->str_mdo_output_vals-et_workorder_operation->* ASSIGNING <wo_operation>
              WITH KEY aufnr = <wo_header>-aufnr mobile_status = lc_mobile_stat-completed.
            IF sy-subrc = 0.
              LOOP AT me->core_object->str_mdo_output_vals-et_workorder_operation->* ASSIGNING <wo_operation1>
                WHERE aufnr = <wo_header>-aufnr.
                IF <wo_operation1>-mobile_status = lc_mobile_stat-completed.
                  "------------------
                   "Get System & User status
                   clear: lv_system_Status,
                          lv_user_Status.
                     CALL FUNCTION 'STATUS_TEXT_EDIT'
                       EXPORTING
                         objnr            = <wo_operation1>-objnr
                         flg_user_stat    = 'X'
                         spras            = sy-langu
                       IMPORTING
                         line             = lv_system_status
                         user_line        = lv_user_status
                       EXCEPTIONS
                         object_not_found = 1
                         OTHERS           = 2.
                     "if mobile status of operation is complete and system status is not complete
                     "then change the mobile status because it change in status does allow to complete
                     "the operation at Work Manager
                     IF lv_system_status IS NOT INITIAL.
                       FIND FIRST OCCURRENCE OF 'CNF' IN lv_system_status.
                       IF sy-subrc <> 0.
                         <wo_header>-mobile_status = lc_mobile_stat-received.
                       else.
                         <wo_header>-mobile_status = lc_mobile_stat-completed.
                       ENDIF.
                     else.
                       <wo_header>-mobile_status = lc_mobile_stat-completed.
                     ENDIF.
                  "------------------
                  "<wo_header>-mobile_status = lc_mobile_stat-completed.
                ELSE.
                  <wo_header>-mobile_status = lc_mobile_stat-hold.
                  EXIT.
                ENDIF.
              ENDLOOP.
            ENDIF.
          ENDLOOP.
        ENDIF.

        "<--Del SMERP 610_700 SP03 BugID: ERPADDON-177 - Begin
*      "If all operations are invalid then Header is invalid
*      IF me->core_object->gt_aufnr_delta IS INITIAL.
*        IF me->core_object->str_mdo_output_vals-et_valid_workorder->* IS NOT INITIAL.
*          " -->return output data valid orders,
*          me->core_object->oref_mdo_data->set_mdo_output_via_ref_struct(
*            EXPORTING is_mdo_output = me->core_object->str_mdo_output_vals ).
*        ENDIF.
*        ASSIGN iref_rfc_oo_data->dref_return->* TO <return>.
*        ls_return-type = 'I'.
*        ls_return-message = 'No data found'(i05).
*        APPEND ls_return TO <return>.
*        RETURN.
*      ENDIF.
        "<--Del SMERP 610_700 SP03 BugID: ERPADDON-177 - End
*----------------------------------------------------------------------*
* Step 3 - Error checking
*----------------------------------------------------------------------*
*     Class-Based Exception Handling
      CATCH cx_root INTO lref_exception.                 "#EC CATCH_ALL
        /syclo/cl_core_appl_logger=>logger->catch_class_exception(
          EXPORTING is_bapi_input = me->core_object->str_bapi_input
                    iref_exception = lref_exception
                    iref_return_tab = iref_rfc_oo_data->dref_return ).
    ENDTRY.

  ENDMETHOD.                    "IOW_ZZ_ENH_SMERP_WORKORDER_DO~GET_WORK_ORDER_OPERATION
  METHOD iow_zz_enh_smerp_workorder_do~get_assignment.
*"------------------------------------------------------------------------*
*" Declaration of Overwrite-method, do not insert any comments here please!
*"
*"methods GET_ASSIGNMENT
*"  importing
*"    !IREF_RFC_OO_DATA type ref to /SYCLO/CL_CORE_RFC_OO_DATA
*"  exporting
*"    value(ET_RETURN) type BAPIRET2_T .
*"------------------------------------------------------------------------*


*METHOD get_assignment.
*======================================================================*
*<SMERPDOC>
*  <CREATE_DATE> 06/25/2013 </CREATE_DATE>
*  <AUTHOR> Syam Yalamati </AUTHOR>
*  <DESCRIPTION>
*     Apply assignment type filter to valid work order list for mobile
*  </DESCRIPTION>
*<!-- *----------------------CHANGE HISTORY------------------------* -->
*  <REVISION_TAG date='06/25/2013' version='SMERP 610_700' user='YALAMATIS'>
*    <DESCRIPTION>Initial release.</DESCRIPTION>
*    <BugID> ERPADDON-68 </BugID>
*  </REVISION_TAG>
*<!-- *----------------------CHANGE HISTORY------------------------* -->
*  <REVISION_TAG date='04/25/2014' version='SMERP 610_700 SP03' user='YALAMATIS'>
*    <DESCRIPTION> BADI addition for Exchange Key list </DESCRIPTION>
*    <BugID> ERPADDON-168 </BugID>
*  </REVISION_TAG>
*<!-- *----------------------CHANGE HISTORY------------------------* -->
*</SMERPDOC>
*======================================================================*
************************************************************************
* Data Declaration Section
************************************************************************
*OO Reference Variables
    DATA: lref_exception TYPE REF TO cx_root,
          lref_do_serv TYPE REF TO /syclo/cl_core_do_services, "#EC NEEDED
          lref_exch_keylist TYPE REF TO data.

*Tables and Structures
    DATA: lt_return            TYPE bapiret2_t.             "#EC NEEDED

    DATA: BEGIN OF ls_pernr,
            pernr TYPE persno,
          END OF ls_pernr,
          lt_pernr LIKE STANDARD TABLE OF ls_pernr.         "#EC NEEDED

    "The following table contains client side object list registered by Agentry App
    DATA: lt_mdw_objkey TYPE /syclo/core_mdw_objkey_tab,
          lv_ref_mdw_obj_active TYPE boolean.

    "Exchange Object data
    DATA: ls_exch_aufnr LIKE LINE OF me->core_object->gt_exch_aufnr.

    DATA: ls_pernr_range LIKE LINE OF me->core_object->pernr_merged,
          ls_gewrk_range LIKE LINE OF me->core_object->gewrk_merged,
          ls_arbid_range LIKE LINE OF me->core_object->arbid_merged.

    DATA: BEGIN OF ls_wo_object,
            aufnr TYPE aufk-aufnr,
            objnr TYPE aufk-objnr,
          END OF ls_wo_object,
          lt_wo_object LIKE STANDARD TABLE OF ls_wo_object,
          lt_wo_objtmp LIKE STANDARD TABLE OF ls_wo_object.

    DATA: ls_return TYPE bapiret2.
    DATA: BEGIN OF ls_wo_stat_obj,
            objnr TYPE jest-objnr,
          END OF ls_wo_stat_obj,
          lt_wo_stat_obj LIKE STANDARD TABLE OF ls_wo_stat_obj.

    DATA:  ls_oper_object TYPE /syclo/pm_oper_object_str,
           lt_oper_objtmp TYPE /syclo/pm_oper_object_tab.

    DATA: lt_valid_wo    TYPE STANDARD TABLE OF /syclo/pm_valid_aufnr_str,
    lwa_woassign         TYPE zsmerp_woassign,
    lt_woassign          TYPE STANDARD TABLE OF zsmerp_woassign.

    DATA  lv_where_clause TYPE string.
    DATA  lt_where_clause TYPE TABLE OF string.

*Variables
    DATA: lv_aufnr TYPE aufnr,
          ls_assignment_type TYPE /syclo/core_range_str,
          lv_pernr_exception TYPE flag,
          lv_index TYPE sy-tabix,
          lv_stat_prof               TYPE j_stsma,
          lv_oper_filter             TYPE flag.
    DATA  lv_msg    TYPE string.

*constants
    CONSTANTS: lc_work_center_objty  TYPE pm_objty VALUE 'A',  "Default workcenter Object
               lc_date_begin         TYPE sy-datum VALUE '19900101', "#EC NEEDED
               lc_date_end           TYPE sy-datum VALUE '99991231',
               lc_opstat_cnf         TYPE j_status VALUE 'I0009',
               lc_obtyp_ori          TYPE j_obtyp VALUE 'ORI',  "Maintenance Order
               lc_obtyp_ovg          TYPE j_obtyp VALUE 'OVG',  "PP/PM Operation
               lc_pernr_dummy        TYPE pernr_d VALUE '99999999'.

    DATA: lwa_validwo LIKE LINE OF  me->core_object->str_mdo_output_vals-et_valid_workorder->*.

* Field Symbols
    FIELD-SYMBOLS:
                   <mdw_objkey>   LIKE LINE OF lt_mdw_objkey,
                   <aufnr_key>    TYPE /syclo/pm_valid_aufnr_str,
                   <range_str>    TYPE /syclo/core_range_str,
                   <return>       TYPE bapiret2_t.
************************************************************************
* Main Section
************************************************************************
    TRY.
        me->core_object->message = 'Entering method ~ GET_ASSIGNMENT...'(m17).
        me->core_object->logger->loginfo( iv_mobile_user = me->core_object->str_bapi_input-mobile_user
                             iv_mobile_id = me->core_object->str_bapi_input-mobile_id
                             iv_user_guid = me->core_object->str_bapi_input-user_guid
                             iv_message = me->core_object->message
                             iv_source = me->core_object->source ).

**************************************************************************
*Step 1 - Initialization
**************************************************************************
        lref_do_serv = /syclo/cl_core_do_services=>get_do_service(
                                         iref_logger = me->core_object->logger ).

        CLEAR: me->core_object->assignment_type, lv_pernr_exception.

        "Determine work order fetch assignment type
        READ TABLE me->core_object->str_dof_filter_vals-wo_assignment_type->* INTO ls_assignment_type
          WITH KEY sign = 'I' option = 'EQ'.
        IF sy-subrc = 0.
          MOVE ls_assignment_type-low TO me->core_object->assignment_type.
        ENDIF.

        "Get the Personnel Number exception filter
        READ TABLE me->core_object->str_dof_filter_vals-persno_exception->* ASSIGNING <range_str>
          WITH KEY sign = 'I' option = 'EQ'.
        IF sy-subrc = 0.
          MOVE <range_str>-low TO lv_pernr_exception.
        ENDIF.
        IF NOT me->core_object->str_mdo_input_vals-it_employee_id_ra->* IS INITIAL.
          SELECT DISTINCT pernr FROM pa0001
            INTO CORRESPONDING FIELDS OF TABLE lt_pernr
            WHERE pernr IN me->core_object->str_mdo_input_vals-it_employee_id_ra->*
              AND endda EQ lc_date_end.
          IF sy-subrc <> 0 AND lv_pernr_exception = abap_false.
            CLEAR me->core_object->str_mdo_input_vals-it_employee_id_ra->*.
          ENDIF.
        ENDIF.

        IF me->core_object->str_mdo_input_vals-it_wo_incl_user_stat->* IS NOT INITIAL.
          APPEND LINES OF me->core_object->str_mdo_input_vals-it_wo_incl_user_stat->*
            TO me->core_object->str_dof_filter_vals-wo_incl_user_stat->*.
        ENDIF.
        IF me->core_object->str_mdo_input_vals-it_wo_excl_user_stat->* IS NOT INITIAL.
          APPEND LINES OF me->core_object->str_mdo_input_vals-it_wo_excl_user_stat->*
            TO me->core_object->str_dof_filter_vals-wo_excl_user_stat->*.
        ENDIF.
        IF me->core_object->str_mdo_input_vals-it_oper_incl_user_stat->* IS NOT INITIAL.
          APPEND LINES OF me->core_object->str_mdo_input_vals-it_oper_incl_user_stat->*
            TO me->core_object->str_dof_filter_vals-oper_incl_user_stat->*.
        ENDIF.
        IF me->core_object->str_mdo_input_vals-it_oper_excl_user_stat->* IS NOT INITIAL.
          APPEND LINES OF me->core_object->str_mdo_input_vals-it_oper_excl_user_stat->*
            TO me->core_object->str_dof_filter_vals-oper_excl_user_stat->*.
        ENDIF.

        " -->Convert Operation System/User status filters to internal format, if provided
        CLEAR lv_oper_filter.
        IF NOT ( me->core_object->str_mdo_input_vals-it_oper_incl_syst_stat_ra->* IS INITIAL
           AND   me->core_object->str_mdo_input_vals-it_oper_excl_syst_stat_ra->* IS INITIAL
           AND   me->core_object->str_dof_filter_vals-oper_incl_syst_stat->*      IS INITIAL
           AND   me->core_object->str_dof_filter_vals-oper_excl_syst_stat->*      IS INITIAL
           AND   me->core_object->str_dof_filter_vals-oper_incl_user_stat->*      IS INITIAL
           AND   me->core_object->str_dof_filter_vals-oper_excl_user_stat->*      IS INITIAL ).
          lv_oper_filter = abap_true.
        ENDIF.

        "Check Confirmed records and remove from the fetch in case of Assignment type '2' / '3' / '4' / '6' / 'A'
        IF me->core_object->assignment_type = '2' OR me->core_object->assignment_type = '3' OR me->core_object->assignment_type = '4' OR
           me->core_object->assignment_type = '6' OR me->core_object->assignment_type = 'A'.
          APPEND INITIAL LINE TO me->core_object->str_dof_filter_vals-oper_excl_syst_stat->*
          ASSIGNING <range_str>.
          <range_str>-sign = 'I'.
          <range_str>-option = 'EQ'.
          <range_str>-low = lc_opstat_cnf.
          lv_oper_filter = abap_true.
        ENDIF.

        "-->Retrieve object key list from exchange layer if
        "   order exchange process is enabled.
        IF me->core_object->mobile_timestamp_in IS NOT INITIAL.
          GET REFERENCE OF me->core_object->gt_exch_aufnr INTO lref_exch_keylist.
          me->core_object->get_keylist_from_exchobj(
            EXPORTING iref_data_manager = iref_rfc_oo_data
                      is_exch_keylist = ls_exch_aufnr
            CHANGING cref_exch_keylist = lref_exch_keylist ).
          "<--Ins SMERP 610_700 SP03 BugID:ERPADDON-168 - Start
          IF NOT me->core_object->gref_badi_wo IS INITIAL.
            CALL BADI me->core_object->gref_badi_wo->get_keylist_from_exchobj
              EXPORTING
                iref_data_manager     = iref_rfc_oo_data
                is_exch_keylist       = ls_exch_aufnr
                iv_exchobj            = me->core_object->str_do_setting-exchobj
                it_exchobj_assignment = me->core_object->tab_exchobj_assignment
              CHANGING
                cref_exch_keylist     = lref_exch_keylist.
          ENDIF.
          "<--Ins SMERP 610_700 SP03 BugID:ERPADDON-168 - End
        ENDIF.

        "-->Retrieve mobile object list registered by Agentry in
        " middleware user object list if supported
        IF me->core_object->active_user_guid IS NOT INITIAL AND
           me->core_object->mobile_timestamp_in IS NOT INITIAL AND
           me->core_object->str_do_setting-ref_mdw_objtyp IS NOT INITIAL.
          lt_mdw_objkey = lref_do_serv->get_mobile_device_objkey_list(
                          iv_user_guid = me->core_object->active_user_guid
                          iv_object_type = me->core_object->str_do_setting-ref_mdw_objtyp ).
          lv_ref_mdw_obj_active = abap_true.
        ENDIF.
*
        "Deter mine the personal number
        IF NOT ( me->core_object->str_mdo_input_vals-it_employee_id_ra->* IS INITIAL AND
                 me->core_object->str_dof_filter_vals-employee_id->* IS INITIAL ).
          SELECT DISTINCT pernr AS low FROM pa0001
            INTO CORRESPONDING FIELDS OF TABLE me->core_object->pernr_merged
            WHERE pernr IN me->core_object->str_mdo_input_vals-it_employee_id_ra->*
              AND pernr IN me->core_object->str_dof_filter_vals-employee_id->*
              AND endda EQ lc_date_end.
          ls_pernr_range-sign = 'I'.                        "#EC NOTEXT
          ls_pernr_range-option = 'EQ'.                     "#EC NOTEXT
          IF me->core_object->pernr_merged[] IS INITIAL.
            ls_pernr_range-low = lc_pernr_dummy.
            APPEND ls_pernr_range TO me->core_object->pernr_merged.
          ELSE.
            MODIFY me->core_object->pernr_merged FROM ls_pernr_range
              TRANSPORTING sign option WHERE sign = space.
          ENDIF.
        ENDIF.

        "Merge Workcenters to internal number format
        IF NOT ( me->core_object->str_dof_filter_vals-work_cntr->* IS INITIAL AND
                 me->core_object->str_mdo_input_vals-it_work_cntr_ra->* IS INITIAL ).
          SELECT DISTINCT objid AS low FROM crhd
            INTO CORRESPONDING FIELDS OF TABLE me->core_object->gewrk_merged
            WHERE objid IN me->core_object->str_dof_filter_vals-work_cntr->*
              AND objid IN me->core_object->str_mdo_input_vals-it_work_cntr_ra->*
              AND objty EQ lc_work_center_objty.

          ls_gewrk_range-sign = 'I'.                        "#EC NOTEXT
          ls_gewrk_range-option = 'EQ'.                     "#EC NOTEXT
          IF me->core_object->gewrk_merged[] IS NOT INITIAL.
            MODIFY me->core_object->gewrk_merged FROM ls_gewrk_range
            TRANSPORTING sign option WHERE sign = space.
          ENDIF.

          SELECT DISTINCT objid AS low FROM crhd
            APPENDING CORRESPONDING FIELDS OF TABLE me->core_object->gewrk_merged
            WHERE arbpl IN me->core_object->str_dof_filter_vals-work_cntr->*
              AND arbpl IN me->core_object->str_mdo_input_vals-it_work_cntr_ra->*
              AND objty EQ lc_work_center_objty.
          ls_gewrk_range-sign = 'I'.                        "#EC NOTEXT
          ls_gewrk_range-option = 'EQ'.                     "#EC NOTEXT
          IF me->core_object->gewrk_merged[] IS NOT INITIAL.
            MODIFY me->core_object->gewrk_merged FROM ls_gewrk_range
            TRANSPORTING sign option WHERE sign = space.
          ENDIF.
        ENDIF.

        "Merge Operational Workcenters to internal number format
        IF NOT ( me->core_object->str_mdo_input_vals-it_oper_work_cntr_ra->* IS INITIAL AND
                 me->core_object->str_dof_filter_vals-oper_work_cntr->* IS INITIAL ).
          SELECT DISTINCT objid AS low FROM crhd
            INTO CORRESPONDING FIELDS OF TABLE me->core_object->arbid_merged
            WHERE objid IN me->core_object->str_mdo_input_vals-it_oper_work_cntr_ra->*
              AND objid IN me->core_object->str_dof_filter_vals-oper_work_cntr->*
              AND objty EQ lc_work_center_objty.

          ls_arbid_range-sign = 'I'.                        "#EC NOTEXT
          ls_arbid_range-option = 'EQ'.                     "#EC NOTEXT
          IF me->core_object->arbid_merged[] IS NOT INITIAL.
            MODIFY me->core_object->arbid_merged FROM ls_arbid_range
            TRANSPORTING sign option WHERE sign = space.
          ENDIF.

          SELECT DISTINCT objid AS low FROM crhd
            APPENDING CORRESPONDING FIELDS OF TABLE me->core_object->arbid_merged
            WHERE arbpl IN me->core_object->str_mdo_input_vals-it_oper_work_cntr_ra->*
              AND arbpl IN me->core_object->str_dof_filter_vals-oper_work_cntr->*
              AND objty EQ lc_work_center_objty.
          ls_arbid_range-sign = 'I'.                        "#EC NOTEXT
          ls_arbid_range-option = 'EQ'.                     "#EC NOTEXT
          IF me->core_object->arbid_merged[] IS NOT INITIAL.
            MODIFY me->core_object->arbid_merged FROM ls_arbid_range
            TRANSPORTING sign option WHERE sign = space.
          ENDIF.
        ENDIF.

**************************************************************************
*Step 2 - Get Assignment Filter logic
**************************************************************************
        "Apply Assignment Type filters before status filters to improve the performence
        "Apply assignment type filter to valid work order list for mobile

        CASE me->core_object->assignment_type.
          WHEN '1'.                                           "Header level
            me->core_object->get_assignment1(
              EXPORTING
                 iref_rfc_oo_data = iref_rfc_oo_data
              IMPORTING
                 et_return        = lt_return
                 et_wo_object     = lt_wo_object ).

            IF NOT me->core_object->gref_badi_wo IS INITIAL.
              CALL BADI me->core_object->gref_badi_wo->get_assignment_type1
                EXPORTING
                  iref_mdo_data = me->core_object->oref_mdo_data
                CHANGING
                  ct_wo_object  = lt_wo_object.
            ENDIF.

          WHEN '2'.                                           "Operation level
            me->core_object->get_assignment2(
              EXPORTING
                 iref_rfc_oo_data = iref_rfc_oo_data
              IMPORTING
                 et_return        = lt_return
                 et_wo_object     = lt_wo_object ).

            IF NOT me->core_object->gref_badi_wo IS INITIAL.
              CALL BADI me->core_object->gref_badi_wo->get_assignment_type2
                EXPORTING
                  iref_mdo_data = me->core_object->oref_mdo_data
                CHANGING
                  ct_wo_object  = lt_wo_object.
            ENDIF.

          WHEN '3'.                                           "Suboperation level
            me->core_object->get_assignment3(
              EXPORTING
                 iref_rfc_oo_data = iref_rfc_oo_data
              IMPORTING
                 et_return        = lt_return
                 et_wo_object     = lt_wo_object ).

            IF NOT me->core_object->gref_badi_wo IS INITIAL.
              CALL BADI me->core_object->gref_badi_wo->get_assignment_type3
                EXPORTING
                  iref_mdo_data = me->core_object->oref_mdo_data
                CHANGING
                  ct_wo_object  = lt_wo_object.
            ENDIF.

          WHEN '4'.                                           "Capacity requirement level
            me->core_object->get_assignment4(
              EXPORTING
                 iref_rfc_oo_data = iref_rfc_oo_data
              IMPORTING
                 et_return        = lt_return
                 et_wo_object     = lt_wo_object ).

            IF NOT me->core_object->gref_badi_wo IS INITIAL.
              CALL BADI me->core_object->gref_badi_wo->get_assignment_type4
                EXPORTING
                  iref_mdo_data = me->core_object->oref_mdo_data
                CHANGING
                  ct_wo_object  = lt_wo_object.
            ENDIF.

          WHEN '5'.                                           "Header level Planner Group
            me->core_object->get_assignment5(
              EXPORTING
                 iref_rfc_oo_data = iref_rfc_oo_data
              IMPORTING
                 et_return        = lt_return
                 et_wo_object     = lt_wo_object ).

            IF NOT me->core_object->gref_badi_wo IS INITIAL.
              CALL BADI me->core_object->gref_badi_wo->get_assignment_type5
                EXPORTING
                  iref_mdo_data = me->core_object->oref_mdo_data
                CHANGING
                  ct_wo_object  = lt_wo_object.
            ENDIF.

          WHEN '6'.                                           "Operation level Work Center
            me->core_object->get_assignment6(
              EXPORTING
                 iref_rfc_oo_data = iref_rfc_oo_data
              IMPORTING
                 et_return        = lt_return
                 et_wo_object     = lt_wo_object ).

            IF NOT me->core_object->gref_badi_wo IS INITIAL.
              CALL BADI me->core_object->gref_badi_wo->get_assignment_type6
                EXPORTING
                  iref_mdo_data = me->core_object->oref_mdo_data
                CHANGING
                  ct_wo_object  = lt_wo_object.
            ENDIF.

          WHEN '7'.                                           "Header Level Business Partner
            me->core_object->get_assignment7(
              EXPORTING
                 iref_rfc_oo_data = iref_rfc_oo_data
              IMPORTING
                 et_return        = lt_return
                 et_wo_object     = lt_wo_object ).

            IF NOT me->core_object->gref_badi_wo IS INITIAL.
              CALL BADI me->core_object->gref_badi_wo->get_assignment_type7
                EXPORTING
                  iref_mdo_data = me->core_object->oref_mdo_data
                CHANGING
                  ct_wo_object  = lt_wo_object.
            ENDIF.

          WHEN '8'.                                           "Header Level Work Center
            me->core_object->get_assignment8(
              EXPORTING
                 iref_rfc_oo_data = iref_rfc_oo_data
              IMPORTING
                 et_return        = lt_return
                 et_wo_object     = lt_wo_object ).

            IF NOT me->core_object->gref_badi_wo IS INITIAL.
              CALL BADI me->core_object->gref_badi_wo->get_assignment_type8
                EXPORTING
                  iref_mdo_data = me->core_object->oref_mdo_data
                CHANGING
                  ct_wo_object  = lt_wo_object.
            ENDIF.

          WHEN '9'.                                          "Free Form Search
            me->core_object->get_assignment9(
              EXPORTING
                 iref_rfc_oo_data = iref_rfc_oo_data
              IMPORTING
                 et_return        = lt_return
                 et_wo_object     = lt_wo_object ).

            IF NOT me->core_object->gref_badi_wo IS INITIAL.    "BADI Assignment Type 9 - free search
              CALL BADI me->core_object->gref_badi_wo->get_assignment_type9
                EXPORTING
                  iref_mdo_data = me->core_object->oref_mdo_data
                CHANGING
                  ct_wo_object  = lt_wo_object.
            ENDIF.

          WHEN 'A'.                                           "Multi Resource Planning(MRP)
            me->core_object->get_assignmenta(
              EXPORTING
                 iref_rfc_oo_data = iref_rfc_oo_data
              IMPORTING
                 et_return        = lt_return
                 et_wo_object     = lt_wo_object ).

            IF NOT me->core_object->gref_badi_wo IS INITIAL.
              CALL BADI me->core_object->gref_badi_wo->get_assignment_typea
                EXPORTING
                  iref_mdo_data = me->core_object->oref_mdo_data
                CHANGING
                  ct_wo_object  = lt_wo_object.
            ENDIF.

          WHEN 'Z'.                                           "Other / Custom Search
            "Badi implementation for custom Workorder assignment
            IF NOT me->core_object->gref_badi_wo IS INITIAL.    "BADI Assignment Type Others/Z
              CALL BADI me->core_object->gref_badi_wo->get_assignment_others
                EXPORTING
                  iref_mdo_data = me->core_object->oref_mdo_data
                CHANGING
                  ct_wo_object  = lt_wo_object.
            ENDIF.
        ENDCASE.
        IF lt_wo_object IS INITIAL.
          ASSIGN iref_rfc_oo_data->dref_return->* TO <return>.
          ls_return-type = 'I'.
          ls_return-message = 'No data found'(i05).
          APPEND ls_return TO <return>.
          APPEND ls_return TO et_return.
          RETURN.
        ENDIF.

*     "Apply System Status Filters
        " -->Check for inclusive system status restrictions for the orders
        IF NOT ( me->core_object->str_dof_filter_vals-wo_incl_syst_stat->* IS INITIAL AND
                 me->core_object->str_mdo_input_vals-it_wo_incl_syst_stat_ra->* IS INITIAL ).
          SELECT DISTINCT objnr FROM jest INTO TABLE lt_wo_stat_obj
            FOR ALL ENTRIES IN lt_wo_object
            WHERE objnr EQ lt_wo_object-objnr
              AND stat  IN me->core_object->str_dof_filter_vals-wo_incl_syst_stat->*
              AND stat  IN me->core_object->str_mdo_input_vals-it_wo_incl_syst_stat_ra->*
              AND inact EQ space.

          lt_wo_objtmp[] = lt_wo_object[].
          CLEAR lt_wo_object.
          SORT lt_wo_objtmp BY objnr.
          LOOP AT lt_wo_stat_obj INTO ls_wo_stat_obj.
            READ TABLE lt_wo_objtmp INTO ls_wo_object
              WITH KEY objnr = ls_wo_stat_obj-objnr BINARY SEARCH.
            IF sy-subrc = 0.
              APPEND ls_wo_object TO lt_wo_object.
            ENDIF.
          ENDLOOP.
          IF lt_wo_object IS INITIAL.
            ASSIGN iref_rfc_oo_data->dref_return->* TO <return>.
            ls_return-type = 'I'.
            ls_return-message = 'No data found'(i05).
            APPEND ls_return TO <return>.
            APPEND ls_return TO et_return.
            RETURN.
          ENDIF.
          CLEAR: lt_wo_stat_obj, lt_wo_objtmp.
        ENDIF.

        " -->Check for exclusive system status restrictions for the orders
        IF NOT ( me->core_object->str_dof_filter_vals-wo_excl_syst_stat->* IS INITIAL AND
                 me->core_object->str_mdo_input_vals-it_wo_excl_syst_stat_ra->* IS INITIAL ).
          SELECT DISTINCT objnr FROM jest INTO TABLE lt_wo_stat_obj
            FOR ALL ENTRIES IN lt_wo_object
            WHERE objnr EQ lt_wo_object-objnr
              AND stat  IN me->core_object->str_dof_filter_vals-wo_excl_syst_stat->*
              AND stat  IN me->core_object->str_mdo_input_vals-it_wo_excl_syst_stat_ra->*
              AND inact EQ space.
          SORT lt_wo_object BY objnr.
          LOOP AT lt_wo_stat_obj INTO ls_wo_stat_obj.
            READ TABLE lt_wo_object TRANSPORTING NO FIELDS
              WITH KEY objnr = ls_wo_stat_obj-objnr BINARY SEARCH.
            IF sy-subrc = 0.
              DELETE lt_wo_object INDEX sy-tabix.
            ENDIF.
          ENDLOOP.
          IF lt_wo_object IS INITIAL.
            ASSIGN iref_rfc_oo_data->dref_return->* TO <return>.
            ls_return-type = 'I'.
            ls_return-message = 'No data found'(i05).
            APPEND ls_return TO <return>.
            APPEND ls_return TO et_return.
            RETURN.
          ENDIF.
          CLEAR lt_wo_stat_obj.
        ENDIF.
*
        " -->Check for inclusive user status restrictions for the orders
        IF me->core_object->str_dof_filter_vals-wo_incl_user_stat->* IS NOT INITIAL.
          CLEAR: lv_where_clause, lt_where_clause.
          /syclo/cl_core_mdo_tools=>build_dyn_sql_where_table(
            EXPORTING
              it_table        = me->core_object->str_dof_filter_vals-wo_incl_user_stat->*
              iv_alias        = 'A'
            IMPORTING
              ev_where_clause = lv_where_clause
              et_where_clause = lt_where_clause ).
          REPLACE ALL OCCURRENCES OF 'A~ESTAT' IN lv_where_clause WITH 'B~STAT'.
          SELECT DISTINCT a~objnr FROM jsto AS a INNER JOIN jest AS b ON b~objnr = a~objnr
            INTO TABLE lt_wo_stat_obj
            FOR ALL ENTRIES IN lt_wo_object
            WHERE a~objnr = lt_wo_object-objnr
              AND (lv_where_clause)
              AND b~inact EQ space.

          lt_wo_objtmp[] = lt_wo_object[].
          CLEAR lt_wo_object.
          SORT lt_wo_objtmp BY objnr.
          LOOP AT lt_wo_stat_obj INTO ls_wo_stat_obj.
            READ TABLE lt_wo_objtmp INTO ls_wo_object
              WITH KEY objnr = ls_wo_stat_obj-objnr BINARY SEARCH.
            IF sy-subrc = 0.
              APPEND ls_wo_object TO lt_wo_object.
            ENDIF.
          ENDLOOP.
          IF lt_wo_object IS INITIAL.
            ASSIGN iref_rfc_oo_data->dref_return->* TO <return>.
            ls_return-type = 'I'.
            ls_return-message = 'No data found'(i05).
            APPEND ls_return TO <return>.
            APPEND ls_return TO et_return.
            RETURN.
          ENDIF.
          CLEAR: lt_wo_stat_obj, lt_wo_objtmp.
        ENDIF.

        "-->Check for exclusive user status restrictions for the orders
        IF me->core_object->str_dof_filter_vals-wo_excl_user_stat->* IS NOT INITIAL.
          CLEAR: lv_where_clause, lt_where_clause.
          /syclo/cl_core_mdo_tools=>build_dyn_sql_where_table(
            EXPORTING
              it_table        = me->core_object->str_dof_filter_vals-wo_excl_user_stat->*
              iv_alias        = 'A'
            IMPORTING
              ev_where_clause = lv_where_clause
              et_where_clause = lt_where_clause ).
          REPLACE ALL OCCURRENCES OF 'A~ESTAT' IN lv_where_clause WITH 'B~STAT'.
          SELECT DISTINCT a~objnr FROM jsto AS a INNER JOIN jest AS b ON b~objnr = a~objnr
            INTO TABLE lt_wo_stat_obj
            FOR ALL ENTRIES IN lt_wo_object
            WHERE a~objnr = lt_wo_object-objnr
              AND (lv_where_clause)
              AND b~inact EQ space.

          SORT lt_wo_object BY objnr.
          LOOP AT lt_wo_stat_obj INTO ls_wo_stat_obj.
            READ TABLE lt_wo_object TRANSPORTING NO FIELDS
              WITH KEY objnr = ls_wo_stat_obj-objnr BINARY SEARCH.
            IF sy-subrc = 0.
              DELETE lt_wo_object INDEX sy-tabix.
            ENDIF.
          ENDLOOP.
          IF lt_wo_object IS INITIAL.
            ASSIGN iref_rfc_oo_data->dref_return->* TO <return>.
            ls_return-type = 'I'.
            ls_return-message = 'No data found'(i05).
            APPEND ls_return TO <return>.
            APPEND ls_return TO et_return.
            RETURN.
          ENDIF.
          CLEAR lt_wo_stat_obj.
        ENDIF.

        "Apply Operation level filters
        IF NOT lv_oper_filter IS INITIAL .
          SELECT afko~aufnr afvc~aufpl afvc~aplzl afvc~objnr
            FROM afko INNER JOIN afvc ON afvc~mandt = afko~mandt
                                     AND afvc~aufpl = afko~aufpl
            INTO CORRESPONDING FIELDS OF TABLE me->core_object->gt_oper_object
            FOR ALL ENTRIES IN lt_wo_object
            WHERE afko~aufnr EQ lt_wo_object-aufnr.
          IF me->core_object->gt_oper_object IS INITIAL.
            ASSIGN iref_rfc_oo_data->dref_return->* TO <return>.
            ls_return-type = 'I'.
            ls_return-message = 'No data found'(i05).
            APPEND ls_return TO <return>.
            APPEND ls_return TO et_return.
            RETURN.
          ENDIF.

          " -->Check for inclusive system status restrictions for the operations
          IF NOT ( me->core_object->str_dof_filter_vals-oper_incl_syst_stat->*      IS INITIAL
             AND   me->core_object->str_mdo_input_vals-it_oper_incl_syst_stat_ra->* IS INITIAL ).
            SELECT DISTINCT objnr FROM jest INTO TABLE lt_wo_stat_obj
              FOR ALL ENTRIES IN me->core_object->gt_oper_object
              WHERE objnr EQ me->core_object->gt_oper_object-objnr
                AND stat  IN me->core_object->str_dof_filter_vals-oper_incl_syst_stat->*
                AND stat  IN me->core_object->str_mdo_input_vals-it_oper_incl_syst_stat_ra->*
                AND inact EQ space.
            lt_oper_objtmp[] = me->core_object->gt_oper_object[].
            CLEAR me->core_object->gt_oper_object.
            SORT lt_oper_objtmp BY objnr.
            LOOP AT lt_wo_stat_obj INTO ls_wo_stat_obj.
              READ TABLE lt_oper_objtmp INTO ls_oper_object
                WITH KEY objnr = ls_wo_stat_obj-objnr BINARY SEARCH.
              IF sy-subrc = 0.
                APPEND ls_oper_object TO me->core_object->gt_oper_object.
              ENDIF.
            ENDLOOP.
            IF me->core_object->gt_oper_object IS INITIAL.
              ASSIGN iref_rfc_oo_data->dref_return->* TO <return>.
              ls_return-type = 'I'.
              ls_return-message = 'No data found'(i05).
              APPEND ls_return TO <return>.
              APPEND ls_return TO et_return.
              RETURN.
            ENDIF.
            CLEAR: lt_wo_stat_obj, lt_oper_objtmp.
          ENDIF.

          " -->Check for inclusive user status restrictions for the operations
          IF me->core_object->str_dof_filter_vals-oper_incl_user_stat->* IS NOT INITIAL.
            CLEAR: lv_where_clause, lt_where_clause.
            /syclo/cl_core_mdo_tools=>build_dyn_sql_where_table(
              EXPORTING
                it_table        = me->core_object->str_dof_filter_vals-oper_incl_user_stat->*
                iv_alias        = 'A'
              IMPORTING
                ev_where_clause = lv_where_clause
                et_where_clause = lt_where_clause ).
            REPLACE ALL OCCURRENCES OF 'A~ESTAT' IN lv_where_clause WITH 'B~STAT'.
            SELECT DISTINCT a~objnr FROM jsto AS a INNER JOIN jest AS b ON b~objnr = a~objnr
              INTO TABLE lt_wo_stat_obj
              FOR ALL ENTRIES IN me->core_object->gt_oper_object
              WHERE a~objnr = me->core_object->gt_oper_object-objnr
                AND (lv_where_clause)
                AND b~inact EQ space.

            lt_oper_objtmp[] = me->core_object->gt_oper_object[].
            CLEAR me->core_object->gt_oper_object.
            SORT lt_oper_objtmp BY objnr.
            LOOP AT lt_wo_stat_obj INTO ls_wo_stat_obj.
              READ TABLE lt_oper_objtmp INTO ls_oper_object
                WITH KEY objnr = ls_wo_stat_obj-objnr BINARY SEARCH.
              IF sy-subrc = 0.
                APPEND ls_oper_object TO me->core_object->gt_oper_object.
              ENDIF.
            ENDLOOP.
            IF me->core_object->gt_oper_object IS INITIAL.
              ASSIGN iref_rfc_oo_data->dref_return->* TO <return>.
              ls_return-type = 'I'.
              ls_return-message = 'No data found'(i05).
              APPEND ls_return TO <return>.
              APPEND ls_return TO et_return.
              RETURN.
            ENDIF.
            CLEAR: lt_wo_stat_obj, lt_oper_objtmp.
          ENDIF.

          " -->Check for exclusive system status restrictions for the operations
          IF NOT ( me->core_object->str_dof_filter_vals-oper_excl_syst_stat->*      IS INITIAL
             AND   me->core_object->str_mdo_input_vals-it_oper_excl_syst_stat_ra->* IS INITIAL ).
            SELECT DISTINCT objnr FROM jest INTO TABLE lt_wo_stat_obj
              FOR ALL ENTRIES IN me->core_object->gt_oper_object
              WHERE objnr EQ me->core_object->gt_oper_object-objnr
                AND stat  IN me->core_object->str_dof_filter_vals-oper_excl_syst_stat->*
                AND stat  IN me->core_object->str_mdo_input_vals-it_oper_excl_syst_stat_ra->*
                AND inact EQ space.
            SORT me->core_object->gt_oper_object BY objnr.
            LOOP AT lt_wo_stat_obj INTO ls_wo_stat_obj.
              READ TABLE me->core_object->gt_oper_object TRANSPORTING NO FIELDS
                WITH KEY objnr = ls_wo_stat_obj-objnr BINARY SEARCH.
              IF sy-subrc = 0.
                DELETE me->core_object->gt_oper_object INDEX sy-tabix.
              ENDIF.
            ENDLOOP.
            IF me->core_object->gt_oper_object IS INITIAL.
              ASSIGN iref_rfc_oo_data->dref_return->* TO <return>.
              ls_return-type = 'I'.
              ls_return-message = 'No data found'(i05).
              APPEND ls_return TO <return>.
              APPEND ls_return TO et_return.
              RETURN.
            ENDIF.
            CLEAR lt_wo_stat_obj.
          ENDIF.

          " -->Check for exclusive user status restrictions for the operations
          IF me->core_object->str_dof_filter_vals-oper_excl_user_stat->* IS NOT INITIAL.
            CLEAR: lv_where_clause, lt_where_clause.
            /syclo/cl_core_mdo_tools=>build_dyn_sql_where_table(
              EXPORTING
                it_table        = me->core_object->str_dof_filter_vals-oper_excl_user_stat->*
                iv_alias        = 'A'
              IMPORTING
                ev_where_clause = lv_where_clause
                et_where_clause = lt_where_clause ).
            REPLACE ALL OCCURRENCES OF 'A~ESTAT' IN lv_where_clause WITH 'B~STAT'.
            SELECT DISTINCT a~objnr FROM jsto AS a INNER JOIN jest AS b ON b~objnr = a~objnr
              INTO TABLE lt_wo_stat_obj
              FOR ALL ENTRIES IN me->core_object->gt_oper_object
              WHERE a~objnr = me->core_object->gt_oper_object-objnr
                AND (lv_where_clause)
                AND b~inact EQ space.

            SORT me->core_object->gt_oper_object BY objnr.
            LOOP AT lt_wo_stat_obj INTO ls_wo_stat_obj.
              READ TABLE me->core_object->gt_oper_object TRANSPORTING NO FIELDS
                WITH KEY objnr = ls_wo_stat_obj-objnr BINARY SEARCH.
              IF sy-subrc = 0.
                DELETE me->core_object->gt_oper_object INDEX sy-tabix.
              ENDIF.
            ENDLOOP.
            IF me->core_object->gt_oper_object IS INITIAL.
              ASSIGN iref_rfc_oo_data->dref_return->* TO <return>.
              ls_return-type = 'I'.
              ls_return-message = 'No data found'(i05).
              APPEND ls_return TO <return>.
              APPEND ls_return TO et_return.
              RETURN.
            ENDIF.
            CLEAR lt_wo_stat_obj.
          ENDIF.
*
          SORT me->core_object->gt_oper_object BY aufnr.
          LOOP AT lt_wo_object INTO ls_wo_object.
            lv_index = sy-tabix.
            READ TABLE me->core_object->gt_oper_object INTO ls_oper_object
              WITH KEY aufnr = ls_wo_object-aufnr BINARY SEARCH.
            IF sy-subrc <> 0.
              DELETE lt_wo_object INDEX lv_index.
            ENDIF.
          ENDLOOP.
        ENDIF.
        IF lt_wo_object IS INITIAL.
          ASSIGN iref_rfc_oo_data->dref_return->* TO <return>.
          ls_return-type = 'I'.
          ls_return-message = 'No data found'(i05).
          APPEND ls_return TO <return>.
          APPEND ls_return TO et_return.
          RETURN.
        ELSE.
           "sahmad - start
          "----------------------------------------------------------
          "If Open work order has only open operations which do not belong to
          "the owner user. then those order should be filtered-out.
          DATA:  lv_arbpl TYPE arbpl,
                 lt_aufnr TYPE RANGE OF aufnr,
                 ls_aufnr LIKE LINE OF lt_aufnr,
                 lt_afvc TYPE TABLE OF afvc,
                 ls_afvc TYPE afvc,
                 lv_opcnt TYPE i,
                 ls_operation TYPE LINE OF /syclo/pm_oper_object_tab,
                 lt_crhd TYPE TABLE OF crhd,
                 ls_crhd TYPE crhd.

          CLEAR lt_afvc.
          IF me->core_object->gt_oper_object[] IS NOT INITIAL.
            SELECT * FROM afvc INTO TABLE lt_afvc
              FOR ALL ENTRIES IN me->core_object->gt_oper_object
              WHERE aufpl = me->core_object->gt_oper_object-aufpl
                AND aplzl = me->core_object->gt_oper_object-aplzl.
            IF lt_afvc[] IS NOT INITIAL.
              SELECT * FROM crhd INTO TABLE lt_crhd
                FOR ALL ENTRIES IN lt_afvc
                WHERE objid = lt_afvc-arbid.
            ENDIF.
          ENDIF.
          GET PARAMETER ID 'VAP' FIELD lv_arbpl.
          CLEAR lt_aufnr.
          LOOP AT lt_wo_object INTO ls_wo_object.
            lv_opcnt = 0.
            LOOP AT me->core_object->gt_oper_object INTO ls_operation
                                    WHERE aufnr = ls_wo_object-aufnr.
              READ TABLE lt_afvc INTO ls_afvc WITH KEY aufpl = ls_operation-aufpl
                                                       aplzl = ls_operation-aplzl.
              IF sy-subrc <> 0.
                CONTINUE.
              ENDIF.
              READ TABLE lt_crhd INTO ls_crhd WITH KEY objid = ls_afvc-arbid.
              IF ls_crhd-arbpl <> lv_arbpl.
                CONTINUE.
              ENDIF.
              lv_opcnt = lv_opcnt + 1.
            ENDLOOP.
            IF lv_opcnt > 0.
              "these workorders should go to user.
              ls_aufnr-sign   = 'I'.
              ls_aufnr-option = 'EQ'.
              ls_aufnr-low    = ls_wo_object-aufnr.
              ls_aufnr-high   = space.
              APPEND ls_aufnr TO lt_aufnr.
            ENDIF.
          ENDLOOP.
          if lt_aufnr[] is not INITIAL.
            DELETE lt_wo_object WHERE aufnr NOT IN lt_aufnr.
          else.
            clear lt_wo_object.
          endif.
          "--------------end
          lt_valid_wo[] = lt_wo_object[].                   "#EC ENHOK
        ENDIF.

        "Perform main SQL selection
        me->core_object->gt_aufnr_delta[] = lt_valid_wo[].
        IF me->core_object->gt_exch_aufnr[] IS NOT INITIAL.
          SORT me->core_object->gt_exch_aufnr BY aufnr.
          LOOP AT me->core_object->gt_aufnr_delta ASSIGNING <aufnr_key>.
            lv_index = sy-tabix.
            READ TABLE me->core_object->gt_exch_aufnr TRANSPORTING NO FIELDS
              WITH KEY aufnr = <aufnr_key>-aufnr BINARY SEARCH.
            IF sy-subrc <> 0.
              DELETE me->core_object->gt_aufnr_delta INDEX lv_index.
            ENDIF.
          ENDLOOP.
        ENDIF.

        "Support for User remote object management
        IF lv_ref_mdw_obj_active = abap_true.
          LOOP AT lt_mdw_objkey ASSIGNING <mdw_objkey>.
            lv_aufnr = <mdw_objkey>-object_key.
            CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
              EXPORTING
                input  = lv_aufnr
              IMPORTING
                output = lv_aufnr.
            <mdw_objkey>-object_key = lv_aufnr.
          ENDLOOP.
          "Check for valid workorders not present in the current fetch
          LOOP AT lt_valid_wo ASSIGNING <aufnr_key>.
            READ TABLE lt_mdw_objkey ASSIGNING <mdw_objkey>
              WITH KEY object_key = <aufnr_key>-aufnr.
            IF sy-subrc <> 0.
              APPEND <aufnr_key> TO me->core_object->gt_aufnr_delta.
            ELSEIF <mdw_objkey>-effective_ts >= me->core_object->mobile_timestamp_in.
              DELETE me->core_object->gt_aufnr_delta WHERE aufnr = <aufnr_key>-aufnr.
            ENDIF.
          ENDLOOP.
        ENDIF.

        "Build the delta values based on Operation key
        IF me->core_object->gt_oper_object IS NOT INITIAL.
          SORT me->core_object->gt_oper_object BY aufnr.
          LOOP AT me->core_object->gt_aufnr_delta ASSIGNING <aufnr_key>.
            lv_index = sy-tabix.
            READ TABLE me->core_object->gt_oper_object INTO ls_oper_object
              WITH KEY aufnr = <aufnr_key>-aufnr BINARY SEARCH.
            IF sy-subrc <> 0.
              DELETE me->core_object->gt_aufnr_delta INDEX lv_index.
            ENDIF.
          ENDLOOP.
        ENDIF.

        "--> Valid workorders
        IF me->core_object->str_mdo_input_vals-is_wo_return_data_demand->valid_workorder = abap_true.
          APPEND LINES OF lt_valid_wo TO me->core_object->str_mdo_output_vals-et_valid_workorder->*.
        ENDIF.

        DELETE FROM zsmerp_woassign WHERE uname = sy-uname.

        REFRESH lt_woassign.
        LOOP AT  me->core_object->str_mdo_output_vals-et_valid_workorder->* INTO lwa_validwo.
          lwa_woassign-uname = sy-uname.
          lwa_woassign-aufnr = lwa_validwo-aufnr.
          APPEND lwa_woassign TO lt_woassign.
          CLEAR lwa_woassign.
        ENDLOOP.

        INSERT zsmerp_woassign FROM TABLE lt_woassign.

        IF me->core_object->gt_aufnr_delta[] IS INITIAL.
          IF me->core_object->str_mdo_output_vals-et_valid_workorder->* IS NOT INITIAL.
            " -->return output data valid orders,
            me->core_object->oref_mdo_data->set_mdo_output_via_ref_struct(
              EXPORTING is_mdo_output = me->core_object->str_mdo_output_vals ).
          ENDIF.
          ASSIGN iref_rfc_oo_data->dref_return->* TO <return>.
          ls_return-type = 'I'.
          ls_return-message = 'No data found'(i05).
          APPEND ls_return TO <return>.
          APPEND ls_return TO et_return.
          RETURN.
        ENDIF.

        SORT me->core_object->gt_aufnr_delta.
        DELETE ADJACENT DUPLICATES FROM me->core_object->gt_aufnr_delta.
**************************************************************************
*Step 3  - Catch Errors
**************************************************************************
* Class-Based Exception Handling
      CATCH cx_root INTO lref_exception.                 "#EC CATCH_ALL
        /syclo/cl_core_appl_logger=>logger->catch_class_exception(
          EXPORTING iv_mobile_user = me->core_object->str_bapi_input-mobile_user
                    iv_mobile_id = me->core_object->str_bapi_input-mobile_id
                    iv_user_guid = me->core_object->str_bapi_input-user_guid
                    iref_exception = lref_exception
                    iref_return_tab = iref_rfc_oo_data->dref_return ).
    ENDTRY.
*ENDMETHOD.

  ENDMETHOD.                    "IOW_ZZ_ENH_SMERP_WORKORDER_DO~GET_ASSIGNMENT
ENDCLASS.
