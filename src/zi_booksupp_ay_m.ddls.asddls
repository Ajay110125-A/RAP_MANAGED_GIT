@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Supplement Interface CDS View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZI_BOOKSUPP_AY_M
  as select from ZAY_BOOKSUPP_M
  association        to parent ZI_BOOKING_AY_M as _Booking    on  $projection.TravelId  = _Booking.TravelId
                                                              and $projection.BookingId = _Booking.BookingId
  association [1..1] to /DMO/I_Supplement      as _Supplement on  $projection.SupplimentId = _Supplement.SupplementID
  association [1..*] to /DMO/I_SupplementText  as _SuppText   on  $projection.SupplimentId = _SuppText.SupplementID
  association [1..1] to ZI_TRAVEL_AY_M         as _Travel     on  $projection.TravelId = _Travel.TravelId
{
  key travel_id             as TravelId,
  key booking_id            as BookingId,
  key booking_suppliment_id as BookingSupplimentId,
      suppliment_id         as SupplimentId,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      price                 as Price,
      currency_code         as CurrencyCode,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      last_changed_at       as LastChangedAt,

      //Parent
      _Booking,
      //Associations
      _Supplement,
      _SuppText,
      _Travel
}
