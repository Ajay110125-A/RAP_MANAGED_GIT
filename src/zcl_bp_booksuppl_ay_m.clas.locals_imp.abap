CLASS lhc_zi_booksupp_ay_m DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS validateCurrencyCode FOR VALIDATE ON SAVE
      IMPORTING keys FOR zi_booksupp_ay_m~validateCurrencyCode.

    METHODS validatePrice FOR VALIDATE ON SAVE
      IMPORTING keys FOR zi_booksupp_ay_m~validatePrice.

    METHODS validateSupplement FOR VALIDATE ON SAVE
      IMPORTING keys FOR zi_booksupp_ay_m~validateSupplement.
    METHODS calculatePrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ZI_BOOKSUPP_AY_M~calculatePrice.

ENDCLASS.

CLASS lhc_zi_booksupp_ay_m IMPLEMENTATION.

  METHOD validateCurrencyCode.

*    READ ENTITIES OF zi_travel_ay_m IN LOCAL MODE
    READ ENTITY IN LOCAL MODE zi_booksupp_ay_m
        FIELDS ( CurrencyCode )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_result).

    IF lt_result IS NOT INITIAL.

      SELECT *
       FROM I_Currency
       FOR ALL ENTRIES IN @lt_result
       WHERE Currency = @lt_result-%data-CurrencyCode
       INTO TABLE @DATA(lt_curcode).
    ENDIF.

    LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<fs_curr>).

      IF <fs_curr>-%data-CurrencyCode IS INITIAL.

        APPEND VALUE #( %key = <fs_curr>-%key ) TO failed-zi_booksupp_ay_m.

        APPEND VALUE #(
                        %key = <fs_curr>-%key
                        %msg = NEW /dmo/cm_flight_messages(
                                                            textid                = /dmo/cm_flight_messages=>currency_required
                                                            travel_id             = <fs_curr>-%key-TravelId
                                                            booking_id            = <fs_curr>-%key-BookingId
                                                            booking_supplement_id = <fs_curr>-%key-BookingSupplimentId
                                                            severity              = if_abap_behv_message=>severity-error
                                                          )
                        %element-currencycode = if_abap_behv=>mk-on
                      ) TO reported-zi_booksupp_ay_m.

      ELSEIF NOT line_exists( lt_curcode[ Currency = <fs_curr>-%data-CurrencyCode ] ).

        APPEND VALUE #( %key = <fs_curr>-%key ) TO failed-zi_booksupp_ay_m.

        APPEND VALUE #(
                        %key = <fs_curr>-%key
                        %msg = NEW /dmo/cm_flight_messages(
                                                            textid                = /dmo/cm_flight_messages=>currency_not_existing
                                                            travel_id             = <fs_curr>-%key-TravelId
                                                            booking_id            = <fs_curr>-%key-BookingId
                                                            booking_supplement_id = <fs_curr>-%key-BookingSupplimentId
                                                            currency_code         = <fs_curr>-%data-CurrencyCode
                                                            severity              = if_abap_behv_message=>severity-error
                                                          )
                        %element-currencycode = if_abap_behv=>mk-on
                      ) TO reported-zi_booksupp_ay_m.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validatePrice.

    READ ENTITY IN LOCAL MODE zi_booksupp_ay_m
    FIELDS ( Price )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_result).

    LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<fs_price>).

      IF <fs_price>-%data-Price IS INITIAL.

        APPEND VALUE #( %key = <fs_price>-%key ) TO failed-zi_booksupp_ay_m.

        APPEND VALUE #(
                        %key = <fs_price>-%key
                        %msg = me->new_message(
                                                id       = 'Z_MESSAGES_AY_M'
                                                number   = '004'
                                                severity = if_abap_behv_message=>severity-error
                                               )
                        %element-price = if_abap_behv=>mk-on
                      ) TO reported-zi_booksupp_ay_m.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateSupplement.

    READ ENTITY IN LOCAL MODE zi_booksupp_ay_m
    FIELDS ( SupplimentId )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_result).

    IF lt_result IS NOT INITIAL.

      SELECT
          FROM /DMO/I_Supplement
          FIELDS SupplementID
          FOR ALL ENTRIES IN @lt_result
          WHERE SupplementID = @lt_result-%data-SupplimentId
          INTO TABLE @DATA(lt_suppliment).

    ENDIF.

    LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<fs_supp>).

      IF <fs_supp>-%data-SupplimentId IS INITIAL.

        APPEND VALUE #( %key = <fs_supp>-%key ) TO failed-zi_booksupp_ay_m.

        APPEND VALUE #(
                        %key = <fs_supp>-%key
                        %msg = NEW /dmo/cm_flight_messages(
                                                            textid                = /dmo/cm_flight_messages=>enter_supplement_id
                                                            travel_id             = <fs_supp>-%key-TravelId
                                                            booking_id            = <fs_supp>-%key-BookingId
                                                            booking_supplement_id = <fs_supp>-%key-BookingSupplimentId
                                                            severity              = if_abap_behv_message=>severity-error
                                                          )
                        %element-supplimentid = if_abap_behv=>mk-on
                      ) TO reported-zi_booksupp_ay_m.

      ELSEIF NOT line_exists( lt_suppliment[ SupplementID = <fs_supp>-%data-SupplimentId ] ).

        APPEND VALUE #( %key = <fs_supp>-%key ) TO failed-zi_booksupp_ay_m.

        APPEND VALUE #(
                        %key = <fs_supp>-%key
                        %msg = NEW /dmo/cm_flight_messages(
                                                            textid                = /dmo/cm_flight_messages=>supplement_unknown
                                                            travel_id             = <fs_supp>-%key-TravelId
                                                            booking_id            = <fs_supp>-%key-BookingId
                                                            booking_supplement_id = <fs_supp>-%key-BookingSupplimentId
                                                            supplement_id         = <fs_supp>-%data-SupplimentId
                                                            severity              = if_abap_behv_message=>severity-error
                                                          )
                        %element-supplimentid = if_abap_behv=>mk-on
                      ) TO reported-zi_booksupp_ay_m.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD calculatePrice.

    DATA : lt_travel TYPE STANDARD TABLE OF zi_travel_ay_m WITH UNIQUE HASHED KEY key COMPONENTS TravelId.

    lt_travel = CORRESPONDING #( keys DISCARDING DUPLICATES MAPPING TravelId = TravelId ).

    MODIFY ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_travel_ay_m
        EXECUTE reCalTotalPrice
        FROM CORRESPONDING #( lt_travel ).

  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
