@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS Entity for Travel August Challenge'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@Metadata.allowExtensions: true
define view entity ZAJ_AUG_CHALL_CDS
  as select from zaj_aug_chall
  association [0..1] to /DMO/I_Overall_Status_VH as _Status on $projection.Status = _Status.OverallStatus
{
  key travel_id                                                                      as TravelId,
      description                                                                    as Description,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_price                                                                    as TotalPrice,
      currency_code                                                                  as CurrencyCode,
      concat_with_space( cast( total_price as abap.char( 18 ) ), currency_code , 2 ) as PriceCurrencyCode,
      status                                                                         as Status,
      @UI.hidden: true
      case
        when status = 'A' then 3
        when status = 'O' then 2
        when status = 'X' then 1
        else 0
      end                                                                            as StatusCriticality,

      _Status._Text.Text                                                             as OverallStatusText,

      _Status
}
