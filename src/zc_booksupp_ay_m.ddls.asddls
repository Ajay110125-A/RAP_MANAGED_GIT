@EndUserText.label: 'Projection of Booking Supplement View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZC_BOOKSUPP_AY_M
  as projection on ZI_BOOKSUPP_AY_M
{
  key TravelId,
  key BookingId,
  key BookingSupplimentId,
      @ObjectModel.text.element: [ 'SupplementDesc' ]
      SupplimentId,
      _SuppText.Description as SupplementDesc : localized,
      Price,
      CurrencyCode,
      LastChangedAt,
      /* Associations */
      _Booking : redirected to parent zc_booking_ay_m,
      _Supplement,
      _SuppText,
      _Travel  : redirected to zc_travel_ay_m
}
