class ShippingDetails {
  DateTime? shipmentDate;
  String? productName;
  int? quantity;
  double? unitPrice;
  String? unit;
  String? customerName;
  DateTime? expectedRepaymentDate;

  ShippingDetails({
    this.shipmentDate,
    this.productName,
    this.quantity,
    this.unitPrice,
    this.unit,
    this.customerName,
    this.expectedRepaymentDate,
  });
} 