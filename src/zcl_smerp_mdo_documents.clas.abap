class ZCL_SMERP_MDO_DOCUMENTS definition
  public
  final
  create public .

public section.
*"* public components of class ZCL_SMERP_MDO_DOCUMENTS
*"* do not include other source files here!!!

  interfaces /SMERP/IF_CORE_DOCUMENT_BADI .
  interfaces IF_BADI_INTERFACE .
protected section.
*"* protected components of class ZCL_SMERP_MDO_DOCUMENTS
*"* do not include other source files here!!!
private section.
*"* private components of class ZCL_SMERP_MDO_DOCUMENTS
*"* do not include other source files here!!!
ENDCLASS.



CLASS ZCL_SMERP_MDO_DOCUMENTS IMPLEMENTATION.


method /SMERP/IF_CORE_DOCUMENT_BADI~BDS_DETERMINE_PUSH_RECIPIENTS.
endmethod.


method /SMERP/IF_CORE_DOCUMENT_BADI~DMS_DETERMINE_PUSH_RECIPIENTS.
endmethod.


method /SMERP/IF_CORE_DOCUMENT_BADI~END_BDS_CREATE.
endmethod.


method /SMERP/IF_CORE_DOCUMENT_BADI~END_BDS_FETCH.
endmethod.


method /SMERP/IF_CORE_DOCUMENT_BADI~END_DMS_CREATE.
endmethod.


METHOD /smerp/if_core_document_badi~end_dms_fetch.

  DATA: lt_x_data       TYPE dms_tbl_file,
        lv_x_data       TYPE LINE OF dms_tbl_file.

  DATA: ls_dms_ph_cd1   TYPE dms_ph_cd1,
        lv_phios_object_id  TYPE sdokobject,
        lt_file_info    TYPE STANDARD TABLE OF sdokfilaci,
        ls_file_info    TYPE sdokfilaci.

  FIELD-SYMBOLS: <fs_dms_doc>   TYPE /smerp/core_dms_info_str,
                 <fs_x_data>    TYPE dms_rec_file,
                 <fs_phios>     TYPE dms_rec_phio.

  LOOP AT et_dms_document ASSIGNING <fs_dms_doc>.

    "Check for file size
    IF <fs_dms_doc>-filesize IS INITIAL.

      CALL FUNCTION 'CV120_KPRO_MASTER_DATA_GET'
        EXPORTING
          pf_dokar  = <fs_dms_doc>-documenttype
          pf_doknr  = <fs_dms_doc>-documentnumber
          pf_dokvr  = <fs_dms_doc>-documentversion
          pf_doktl  = <fs_dms_doc>-documentpart
        TABLES
          ptx_data  = lt_x_data
        EXCEPTIONS
          not_found = 1
          error     = 2
          OTHERS    = 3.

      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

*
      READ TABLE lt_x_data ASSIGNING <fs_x_data> INDEX 1.

      CHECK sy-subrc = 0.

      READ TABLE <fs_x_data>-tbl_phios ASSIGNING <fs_phios> INDEX 1.

      CHECK sy-subrc = 0.

      SELECT SINGLE * INTO ls_dms_ph_cd1
        FROM dms_ph_cd1
        WHERE phio_id = <fs_phios>-ph_objid.

      IF sy-subrc = 0.
        lv_phios_object_id-class = ls_dms_ph_cd1-ph_class.
        lv_phios_object_id-objid = ls_dms_ph_cd1-phio_id.

        CALL FUNCTION 'SDOK_PHIO_LOAD_CONTENT'
          EXPORTING
            object_id        = lv_phios_object_id
          TABLES
            file_access_info = lt_file_info
          EXCEPTIONS
            not_existing     = 1
            not_authorized   = 2
            no_content       = 3
            bad_storage_type = 4
            OTHERS           = 5.

        IF sy-subrc = 0.

          READ TABLE lt_file_info INTO ls_file_info INDEX 1.

          IF sy-subrc = 0.
            <fs_dms_doc>-filesize = ls_file_info-file_size.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDLOOP.

ENDMETHOD.


method /SMERP/IF_CORE_DOCUMENT_BADI~END_DMS_UPDATE.
endmethod.


method /SMERP/IF_CORE_DOCUMENT_BADI~KPRO_DMS_CONTENT_FETCH.

  DATA: lt_x_data TYPE dms_tbl_file,
          lv_x_data TYPE LINE OF dms_tbl_file.

  DATA: lv_dms_ph_cd1 TYPE dms_ph_cd1.

  DATA: lt_file_access_info TYPE TABLE OF sdokfilaci,
        lv_file_access_info TYPE sdokfilaci,
        lt_file_content_ascii TYPE TABLE OF sdokcntasc,
        lv_file_content_ascii TYPE sdokcntasc,
        lt_file_content_binary TYPE TABLE OF sdokcntbin,
        lv_file_content_binary TYPE sdokcntbin.

  DATA: lv_phios_object_id TYPE sdokobject.
  DATA: ls_dms_content TYPE /smerp/core_dms_content_str.

  FIELD-SYMBOLS: <fs_x_data> TYPE dms_rec_file,
                 <fs_phios> TYPE dms_rec_phio.

  CALL FUNCTION 'CV120_KPRO_MASTER_DATA_GET'
    EXPORTING
      pf_dokar            = iv_dms_doc_type
      pf_doknr            = iv_dms_doc_id
      pf_dokvr            = iv_dms_version
      pf_doktl            = iv_dms_part
*     PF_ACTIVE_ONLY      = ' '
*     PF_ACTIVE_ATTR_ONLY = ' '
*     PF_COMP_GET         = 'X'
    TABLES
      ptx_data            = lt_x_data
    EXCEPTIONS
      not_found           = 1
      error               = 2
      OTHERS              = 3.
  IF sy-subrc <> 0.
    EXIT.
  ENDIF.

  READ TABLE lt_x_data ASSIGNING <fs_x_data> INDEX 1.
  IF sy-subrc = 0.
    READ TABLE <fs_x_data>-tbl_phios ASSIGNING <fs_phios> INDEX 1.
    IF sy-subrc = 0.
* Get the document class
      SELECT SINGLE * INTO lv_dms_ph_cd1
      FROM dms_ph_cd1
      WHERE phio_id = <fs_phios>-ph_objid.
* Check record is found
      IF sy-subrc = 0.
        lv_phios_object_id-class = lv_dms_ph_cd1-ph_class.
        lv_phios_object_id-objid = lv_dms_ph_cd1-phio_id.
        DATA: lt_drao TYPE TABLE OF drao,
        ls_drao TYPE drao.

        CALL FUNCTION 'CV120_KPRO_CHECKOUT_TO_TABLE'
          EXPORTING
            ps_phio_id    = lv_phios_object_id
*           PF_COMP_GET   = ' '
          TABLES
*           PT_COMPONENTS =
            ptx_content   = lt_drao
          EXCEPTIONS
            ERROR         = 1
            NO_CONTENT    = 2
            OTHERS        = 3.

        IF sy-subrc <> 0.
*         MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*               WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
        ELSE.
          LOOP AT lt_drao INTO ls_drao.
            ls_dms_content-documenttype = iv_dms_doc_type.
            ls_dms_content-documentnumber = iv_dms_doc_id.
            ls_dms_content-documentversion = iv_dms_version.
            ls_dms_content-documentpart = iv_dms_part.
            ls_dms_content-originaltype = '1'.
            ls_dms_content-line = ls_drao-orblk.
            APPEND ls_dms_content TO et_dms_content.
          ENDLOOP.
        ENDIF.

      ENDIF.
    ENDIF.
  ENDIF.

endmethod.


method /SMERP/IF_CORE_DOCUMENT_BADI~START_BDS_CREATE.
endmethod.


method /SMERP/IF_CORE_DOCUMENT_BADI~START_BDS_FETCH.
endmethod.


method /SMERP/IF_CORE_DOCUMENT_BADI~START_DMS_CREATE.
endmethod.


method /SMERP/IF_CORE_DOCUMENT_BADI~START_DMS_FETCH.
endmethod.


method /SMERP/IF_CORE_DOCUMENT_BADI~START_DMS_UPDATE.
endmethod.
ENDCLASS.
