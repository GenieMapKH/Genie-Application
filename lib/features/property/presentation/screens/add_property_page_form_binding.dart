import 'package:genie/features/property/presentation/view_models/property_form_input.dart';
import 'add_property_page.dart';

/// Moves the form's values between the page's fields and a
/// [PropertyFormInput]: out to save them, in to open a listing for editing.
extension AddPropertyPageFormBinding on AddPropertyPageState {
  PropertyFormInput collectFormInput() {
    return PropertyFormInput(
      propertyType: selectedPropertyType,
      title: titleController.text,
      price: priceController.text,
      listingType: selectedListingSetting,
      titleType: selectedTitleType,
      landSize: landSizeController.text,
      buildingSize: buildingSizeController.text,
      unitSize: unitSizeController.text,
      maintenanceFee: maintenanceFeeController.text,
      developerName: developerNameController.text,
      projectName: projectNameController.text,
      totalProjectArea: totalProjectAreaController.text,
      totalUnitsText: totalUnitsTextController.text,
      startingPrice: startingPriceController.text,
      monthlyRent: monthlyRentController.text,
      leaseRemaining: leaseRemainingController.text,
      equipmentIncluded: equipmentIncludedController.text,
      reasonForSelling: reasonForSellingController.text,
      description: descriptionController.text,
      contactPhone: phoneController.text,
      discount: discountController.text,
      discountType: selectedDiscountType,
      bedrooms: selectedBedrooms,
      bathrooms: selectedBathrooms,
      floors: selectedFloors,
      floorNumber: selectedFloorNumber,
      parking: selectedParking,
      furnished: selectedFurnished,
      buildingType: selectedBuildingType,
      totalUnits: selectedTotalUnits,
      balcony: selectedBalcony,
      completionStatus: selectedCompletionStatus,
      viewType: selectedViewType,
      projectType: selectedProjectType,
      leaseUnit: selectedLeaseUnit,
      keywords: {...selectedKeywords},
    );
  }

  /// Fills the form; called before the first build, so no setState.
  void applyFormInput(PropertyFormInput input) {
    selectedPropertyType = input.propertyType;
    titleController.text = input.title;
    priceController.text = input.price;
    selectedListingSetting = input.listingType;
    selectedTitleType = input.titleType;
    landSizeController.text = input.landSize;
    buildingSizeController.text = input.buildingSize;
    unitSizeController.text = input.unitSize;
    maintenanceFeeController.text = input.maintenanceFee;
    developerNameController.text = input.developerName;
    projectNameController.text = input.projectName;
    totalProjectAreaController.text = input.totalProjectArea;
    totalUnitsTextController.text = input.totalUnitsText;
    startingPriceController.text = input.startingPrice;
    monthlyRentController.text = input.monthlyRent;
    leaseRemainingController.text = input.leaseRemaining;
    equipmentIncludedController.text = input.equipmentIncluded;
    reasonForSellingController.text = input.reasonForSelling;
    descriptionController.text = input.description;
    phoneController.text = input.contactPhone;
    discountController.text = input.discount;
    selectedDiscountType = input.discountType;
    selectedBedrooms = input.bedrooms;
    selectedBathrooms = input.bathrooms;
    selectedFloors = input.floors;
    selectedFloorNumber = input.floorNumber;
    selectedParking = input.parking;
    selectedFurnished = input.furnished;
    selectedBuildingType = input.buildingType;
    selectedTotalUnits = input.totalUnits;
    selectedBalcony = input.balcony;
    selectedCompletionStatus = input.completionStatus;
    selectedViewType = input.viewType;
    selectedProjectType = input.projectType;
    selectedLeaseUnit = input.leaseUnit;
    selectedKeywords
      ..clear()
      ..addAll(input.keywords);
  }
}
