import 'package:genie/features/property/presentation/view_models/saved_properties_provider.dart';
import 'package:genie/l10n/l10n.dart';

/// How a value a listing stores in English is shown: property and listing
/// types, statuses and the options of the listing form. What is stored and
/// sent to the server never changes, only what the user reads. A value not
/// known here is shown as it is.
String propertyValueLabel(AppLocalizations l10n, String value) {
  return switch (value) {
    // Property types.
    'Land' => l10n.propertyTypeLand,
    'House' => l10n.propertyTypeHouse,
    'Building' => l10n.propertyTypeBuilding,
    'Condo' => l10n.propertyTypeCondo,
    'Borey' => l10n.propertyTypeBorey,
    'Business for Sale' => l10n.propertyTypeBusiness,
    'Warehouse' => l10n.propertyTypeWarehouse,
    // Listing types.
    'Sale' => l10n.listingTypeSale,
    'Rent' => l10n.listingTypeRent,
    'To Let' => l10n.listingTypeToLet,
    // Statuses.
    'Active' => l10n.propertyStatusActive,
    'Pending' => l10n.propertyStatusPending,
    'Draft' => l10n.propertyStatusDraft,
    'Sold' => l10n.propertyStatusSold,
    'Expired' => l10n.propertyStatusExpired,
    // Form options.
    'Hard Title' => l10n.propertyOptionHardTitle,
    'Soft Title' => l10n.propertyOptionSoftTitle,
    'Other' => l10n.propertyOptionOther,
    'Studio' => l10n.propertyOptionStudio,
    'Yes' => l10n.propertyOptionYes,
    'No' => l10n.propertyOptionNo,
    'Unfurnished' => l10n.propertyOptionUnfurnished,
    'Fully Furnished' => l10n.propertyOptionFullyFurnished,
    'Electrical appliances' => l10n.propertyOptionElectricalAppliances,
    'Commercial Building' => l10n.propertyOptionCommercialBuilding,
    'Office Building' => l10n.propertyOptionOfficeBuilding,
    'Mixed-use' => l10n.propertyOptionMixedUse,
    'Retail Building' => l10n.propertyOptionRetailBuilding,
    'Off-plan' => l10n.propertyOptionOffPlan,
    'Under Construction' => l10n.propertyOptionUnderConstruction,
    'Completed' => l10n.propertyOptionCompleted,
    'City View' => l10n.propertyOptionCityView,
    'River View' => l10n.propertyOptionRiverView,
    'Garden View' => l10n.propertyOptionGardenView,
    'Pool View' => l10n.propertyOptionPoolView,
    'No View' => l10n.propertyOptionNoView,
    'Commercial' => l10n.propertyOptionCommercial,
    'Land Subdivision' => l10n.propertyOptionLandSubdivision,
    'Pre-launch' => l10n.propertyOptionPreLaunch,
    '50% Completed' => l10n.propertyOptionCompleted50,
    '80% Completed' => l10n.propertyOptionCompleted80,
    'Months' => l10n.propertyOptionMonths,
    'Years' => l10n.propertyOptionYears,
    _ => value,
  };
}

/// A listing keyword (its server code) as the user reads it.
String propertyKeywordLabel(AppLocalizations l10n, String code) {
  return switch (code) {
    'road_access' => l10n.keywordRoadAccess,
    'corner_land' => l10n.keywordCornerLand,
    'near_market' => l10n.keywordNearMarket,
    'near_school' => l10n.keywordNearSchool,
    'near_hospital' => l10n.keywordNearHospital,
    'river_lake_nearby' => l10n.keywordRiverLakeNearby,
    'electricity_ready' => l10n.keywordElectricityReady,
    'water_supply' => l10n.keywordWaterSupply,
    'residential_area' => l10n.keywordResidentialArea,
    'commercial_area' => l10n.keywordCommercialArea,
    _ => code,
  };
}

String sortOptionLabel(AppLocalizations l10n, SortOption option) {
  return switch (option) {
    SortOption.propertyForYou => l10n.sortPropertyForYou,
    SortOption.recentlyPosted => l10n.sortRecentlyPosted,
    SortOption.newest => l10n.sortNewest,
    SortOption.priceHighToLow => l10n.sortPriceHighToLow,
    SortOption.priceLowToHigh => l10n.sortPriceLowToHigh,
  };
}
