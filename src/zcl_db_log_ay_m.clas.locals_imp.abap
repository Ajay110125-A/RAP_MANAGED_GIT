CLASS lsc_zi_travel_ay_m DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zi_travel_ay_m IMPLEMENTATION.

  METHOD save_modified.

    DATA : lt_travel_log TYPE TABLE OF zlog_travel_ay.
    DATA : lt_travel_log_c TYPE TABLE OF zlog_travel_ay.
    DATA : lt_travel_log_u TYPE TABLE OF zlog_travel_ay.
    DATA : lt_travel_log_d TYPE TABLE OF zlog_travel_ay.

    IF create-zi_travel_ay_m IS NOT INITIAL.

      lt_travel_log = CORRESPONDING #( create-zi_travel_ay_m ).
      LOOP AT lt_travel_log ASSIGNING FIELD-SYMBOL(<fs_travel>).

        READ TABLE create-zi_travel_ay_m ASSIGNING FIELD-SYMBOL(<fs_cre_travel>) WITH TABLE KEY entity
                                                                                 COMPONENTS TravelId = <fs_travel>-travelid.
        IF sy-subrc EQ 0.

          <fs_travel>-user_id = cl_abap_context_info=>get_user_technical_name( ).
          <fs_travel>-change_operation = 'CREATE'.
          GET TIME STAMP FIELD <fs_travel>-created_at.


          IF <fs_cre_travel>-%control-BookingFee = cl_abap_behv=>flag_changed.

            TRY.
                <fs_travel>-change_id = cl_system_uuid=>create_uuid_x16_static( ).
              CATCH cx_uuid_error.
                "handle exception
            ENDTRY.

            <fs_travel>-change_field_name = 'Booking Fee'.
            <fs_travel>-change_value = <fs_cre_travel>-BookingFee.

            APPEND <fs_travel> TO lt_travel_log_c.

          ENDIF.

          IF <fs_cre_travel>-%control-OverallStatus = cl_abap_behv=>flag_changed.

            TRY.
                <fs_travel>-change_id = cl_system_uuid=>create_uuid_x16_static( ).
              CATCH cx_uuid_error.
                "handle exception
            ENDTRY.

            <fs_travel>-change_field_name = 'Overall Status'.
            <fs_travel>-change_value = <fs_cre_travel>-%data-OverallStatus.

            APPEND <fs_travel> TO lt_travel_log_c.

          ENDIF.

        ENDIF.


      ENDLOOP.

    ENDIF.

    CLEAR lt_travel_log.
    IF update-zi_travel_ay_m IS NOT INITIAL.

      lt_travel_log = CORRESPONDING #( update-zi_travel_ay_m ).

      LOOP AT lt_travel_log ASSIGNING <fs_travel>.

        READ TABLE update-zi_travel_ay_m ASSIGNING FIELD-SYMBOL(<fs_upd_travel>) WITH TABLE KEY entity
                                                                                 COMPONENTS TravelId = <fs_travel>-travelid.
        IF sy-subrc EQ 0.

          <fs_travel>-user_id = cl_abap_context_info=>get_user_technical_name( ).
          <fs_travel>-change_operation = 'UPDATE'.
          GET TIME STAMP FIELD <fs_travel>-created_at.

          IF <fs_upd_travel>-%control-BookingFee = cl_abap_behv=>flag_changed.

            TRY.
                <fs_travel>-change_id = cl_system_uuid=>create_uuid_x16_static( ).
              CATCH cx_uuid_error.
                "handle exception
            ENDTRY.

            <fs_travel>-change_field_name = 'Booking Fee'.
            <fs_travel>-change_value = <fs_upd_travel>-%data-BookingFee.
            APPEND <fs_travel> TO lt_travel_log_u.

          ENDIF.

          IF <fs_upd_travel>-%control-OverallStatus = cl_abap_behv=>flag_changed.

            TRY.
                <fs_travel>-change_id = cl_system_uuid=>create_uuid_x16_static( ).
              CATCH cx_uuid_error.
                "handle exception
            ENDTRY.

            <fs_travel>-change_field_name = 'Overall Status'.
            <fs_travel>-change_value = <fs_upd_travel>-%data-OverallStatus.
            APPEND <fs_travel> TO lt_travel_log_u.

          ENDIF.


        ENDIF.

      ENDLOOP.


    ENDIF.

    CLEAR lt_travel_log.

    IF delete-zi_travel_ay_m IS NOT INITIAL.

      lt_travel_log = CORRESPONDING #( delete-zi_travel_ay_m ).

      LOOP AT lt_travel_log ASSIGNING <fs_travel>.

        READ TABLE delete-zi_travel_ay_m ASSIGNING FIELD-SYMBOL(<fs_d_travel>) WITH TABLE KEY entity
                                                                               COMPONENTS TravelId = <fs_travel>-travelid.
        IF sy-subrc EQ 0.

          TRY.
              <fs_travel>-change_id = cl_system_uuid=>create_uuid_x16_static( ).
            CATCH cx_uuid_error.
              "handle exception
          ENDTRY.

          <fs_travel>-user_id = cl_abap_context_info=>get_user_technical_name( ).
          <fs_travel>-change_operation = 'DELETE'.
          GET TIME STAMP FIELD <fs_travel>-created_at.

        ENDIF.

        APPEND <fs_travel> TO lt_travel_log_d.

      ENDLOOP.

    ENDIF.

    IF lt_travel_log_c IS NOT INITIAL.

      MODIFY zlog_travel_ay FROM TABLE @lt_travel_log_c.

    ENDIF.
    IF lt_travel_log_u IS NOT INITIAL.

      MODIFY zlog_travel_ay FROM TABLE @lt_travel_log_u.

    ENDIF.
    IF lt_travel_log_d IS NOT INITIAL.

      MODIFY zlog_travel_ay FROM TABLE @lt_travel_log_d.

    ENDIF.

**********************************************************************
**********************************************************************
** For Booking Unmanaged SAVE*****************************************

    DATA : lt_book_supp TYPE TABLE OF zay_booksupp_m.

    IF create-zi_booksupp_ay_m IS NOT INITIAL.

      lt_book_supp = VALUE #(
                              FOR ls_booksupp IN create-zi_booksupp_ay_m
                              (
                                  travel_id = ls_booksupp-TravelId
                                  booking_id = ls_booksupp-BookingId
                                  booking_suppliment_id = ls_booksupp-BookingSupplimentId
                                  suppliment_id = ls_booksupp-SupplimentId
                                  price  = ls_booksupp-Price
                                  currency_code = ls_booksupp-CurrencyCode
                                  last_changed_at = ls_booksupp-LastChangedAt
                              )
                            ).

      INSERT zay_booksupp_m FROM TABLE @lt_book_supp.

    ENDIF.
    IF update-zi_booksupp_ay_m IS NOT INITIAL.

      lt_book_supp = VALUE #(
                      FOR ls_booksupp IN update-zi_booksupp_ay_m
                      (
                          travel_id = ls_booksupp-TravelId
                          booking_id = ls_booksupp-BookingId
                          booking_suppliment_id = ls_booksupp-BookingSupplimentId
                          suppliment_id = ls_booksupp-SupplimentId
                          price  = ls_booksupp-Price
                          currency_code = ls_booksupp-CurrencyCode
                          last_changed_at = ls_booksupp-LastChangedAt
                      )
                    ).

      MODIFY zay_booksupp_m FROM TABLE @lt_book_supp.

    ENDIF.
    IF delete-zi_booksupp_ay_m IS NOT INITIAL.

      lt_book_supp = VALUE #(
                       FOR ls_booksu_d IN delete-zi_booksupp_ay_m
                       (
                           travel_id = ls_booksu_d-TravelId
                           booking_id = ls_booksu_d-BookingId
                           booking_suppliment_id = ls_booksu_d-BookingSupplimentId
*                           suppliment_id = ls_booksu_d-SupplimentId
*                           price  = ls_booksu_d-Price
*                           currency_code = ls_booksu_d-CurrencyCode
*                           last_changed_at = ls_booksu_d-LastChangedAt
                       )
                     ).

      DELETE zay_booksupp_m FROM TABLE @lt_book_supp.

    ENDIF.

  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
