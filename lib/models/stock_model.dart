/// Stock Business data models. Pure Dart; no third-party dependencies.
typedef JsonMap = Map<String, dynamic>;

double _d(dynamic v, [double fallback = 0]) => v is num ? v.toDouble() : double.tryParse('$v') ?? fallback;
String _s(dynamic v, [String fallback = '']) => v == null ? fallback : '$v';
DateTime? _dt(dynamic v) => v == null || '$v'.isEmpty ? null : DateTime.tryParse('$v');
String? _iso(DateTime? v) => v?.toIso8601String();
List<String> _strings(dynamic v) => List<String>.from(v ?? const <String>[]);
Map<String, dynamic> _map(dynamic v) => Map<String, dynamic>.from(v ?? const <String, dynamic>{});

/// Product master and current inventory balance.
class StockItem {
  const StockItem({
    required this.id, required this.name, required this.sku,
    required this.category, required this.unit,
    this.description = '', this.brand = '', this.model = '', this.grade = '',
    this.barcode = '', this.qrCode = '', this.batchNumber = '', this.lotNumber = '',
    this.warehouseId = '', this.warehouseName = '', this.room = '', this.shelf = '', this.rack = '',
    this.quantity = 0, this.reservedQuantity = 0, this.damagedQuantity = 0,
    this.returnedQuantity = 0, this.reorderLevel = 0, this.minimumStock = 0, this.maximumStock = 0,
    this.purchasePrice = 0, this.landedUnitCost = 0, this.expectedSalePrice = 0, this.taxRate = 0,
    this.expiryDate, this.warrantyUntil, this.warrantyDetails = '',
    this.imageUrls = const [], this.attachmentUrls = const [], this.customFields = const {},
    this.isActive = true, this.isArchived = false, this.createdAt, this.updatedAt,
    this.createdBy = '', this.updatedBy = '',
  });
  final String id, name, sku, category, unit, description, brand, model, grade;
  final String barcode, qrCode, batchNumber, lotNumber;
  final String warehouseId, warehouseName, room, shelf, rack;
  final double quantity, reservedQuantity, damagedQuantity, returnedQuantity;
  final double reorderLevel, minimumStock, maximumStock, purchasePrice, landedUnitCost, expectedSalePrice, taxRate;
  final DateTime? expiryDate, warrantyUntil;
  final String warrantyDetails;
  final List<String> imageUrls, attachmentUrls;
  final Map<String, dynamic> customFields;
  final bool isActive, isArchived;
  final DateTime? createdAt, updatedAt;
  final String createdBy, updatedBy;
  double get availableQuantity => (quantity - reservedQuantity - damagedQuantity).clamp(0, double.infinity).toDouble();
  double get stockValuation => availableQuantity * landedUnitCost;
  double get potentialSalesValue => availableQuantity * expectedSalePrice;
  double get expectedGrossProfit => potentialSalesValue - stockValuation;
  bool get isLowStock => availableQuantity <= reorderLevel;
  bool get isOutOfStock => availableQuantity <= 0;
  bool get isExpiringSoon => expiryDate != null && expiryDate!.difference(DateTime.now()).inDays >= 0 && expiryDate!.difference(DateTime.now()).inDays <= 30;

  StockItem copyWith({String? name, String? sku, String? category, String? unit, String? description,
    String? brand, String? model, String? grade, String? barcode, String? qrCode, String? batchNumber,
    String? lotNumber, String? warehouseId, String? warehouseName, String? room, String? shelf, String? rack,
    double? quantity, double? reservedQuantity, double? damagedQuantity, double? returnedQuantity,
    double? reorderLevel, double? minimumStock, double? maximumStock, double? purchasePrice,
    double? landedUnitCost, double? expectedSalePrice, double? taxRate, DateTime? expiryDate,
    DateTime? warrantyUntil, String? warrantyDetails, List<String>? imageUrls,
    List<String>? attachmentUrls, Map<String,dynamic>? customFields, bool? isActive, bool? isArchived,
    DateTime? updatedAt, String? updatedBy}) => StockItem(
      id:id, name:name??this.name, sku:sku??this.sku, category:category??this.category, unit:unit??this.unit,
      description:description??this.description, brand:brand??this.brand, model:model??this.model,
      grade:grade??this.grade, barcode:barcode??this.barcode, qrCode:qrCode??this.qrCode,
      batchNumber:batchNumber??this.batchNumber, lotNumber:lotNumber??this.lotNumber,
      warehouseId:warehouseId??this.warehouseId, warehouseName:warehouseName??this.warehouseName,
      room:room??this.room, shelf:shelf??this.shelf, rack:rack??this.rack,
      quantity:quantity??this.quantity, reservedQuantity:reservedQuantity??this.reservedQuantity,
      damagedQuantity:damagedQuantity??this.damagedQuantity, returnedQuantity:returnedQuantity??this.returnedQuantity,
      reorderLevel:reorderLevel??this.reorderLevel, minimumStock:minimumStock??this.minimumStock,
      maximumStock:maximumStock??this.maximumStock, purchasePrice:purchasePrice??this.purchasePrice,
      landedUnitCost:landedUnitCost??this.landedUnitCost, expectedSalePrice:expectedSalePrice??this.expectedSalePrice,
      taxRate:taxRate??this.taxRate, expiryDate:expiryDate??this.expiryDate, warrantyUntil:warrantyUntil??this.warrantyUntil,
      warrantyDetails:warrantyDetails??this.warrantyDetails, imageUrls:imageUrls??this.imageUrls,
      attachmentUrls:attachmentUrls??this.attachmentUrls, customFields:customFields??this.customFields,
      isActive:isActive??this.isActive, isArchived:isArchived??this.isArchived,
      createdAt:createdAt, updatedAt:updatedAt??this.updatedAt, createdBy:createdBy, updatedBy:updatedBy??this.updatedBy);

  JsonMap toJson() => {'id':id,'name':name,'sku':sku,'category':category,'unit':unit,'description':description,
    'brand':brand,'model':model,'grade':grade,'barcode':barcode,'qrCode':qrCode,'batchNumber':batchNumber,
    'lotNumber':lotNumber,'warehouseId':warehouseId,'warehouseName':warehouseName,'room':room,'shelf':shelf,'rack':rack,
    'quantity':quantity,'reservedQuantity':reservedQuantity,'damagedQuantity':damagedQuantity,'returnedQuantity':returnedQuantity,
    'reorderLevel':reorderLevel,'minimumStock':minimumStock,'maximumStock':maximumStock,'purchasePrice':purchasePrice,
    'landedUnitCost':landedUnitCost,'expectedSalePrice':expectedSalePrice,'taxRate':taxRate,
    'expiryDate':_iso(expiryDate),'warrantyUntil':_iso(warrantyUntil),'warrantyDetails':warrantyDetails,
    'imageUrls':imageUrls,'attachmentUrls':attachmentUrls,'customFields':customFields,'isActive':isActive,
    'isArchived':isArchived,'createdAt':_iso(createdAt),'updatedAt':_iso(updatedAt),'createdBy':createdBy,'updatedBy':updatedBy};
  factory StockItem.fromJson(JsonMap j) => StockItem(
    id:_s(j['id']),name:_s(j['name']),sku:_s(j['sku']),category:_s(j['category']),unit:_s(j['unit'],'পিস'),
    description:_s(j['description']),brand:_s(j['brand']),model:_s(j['model']),grade:_s(j['grade']),
    barcode:_s(j['barcode']),qrCode:_s(j['qrCode']),batchNumber:_s(j['batchNumber']),lotNumber:_s(j['lotNumber']),
    warehouseId:_s(j['warehouseId']),warehouseName:_s(j['warehouseName']),room:_s(j['room']),shelf:_s(j['shelf']),rack:_s(j['rack']),
    quantity:_d(j['quantity']),reservedQuantity:_d(j['reservedQuantity']),damagedQuantity:_d(j['damagedQuantity']),
    returnedQuantity:_d(j['returnedQuantity']),reorderLevel:_d(j['reorderLevel']),minimumStock:_d(j['minimumStock']),
    maximumStock:_d(j['maximumStock']),purchasePrice:_d(j['purchasePrice']),landedUnitCost:_d(j['landedUnitCost']),
    expectedSalePrice:_d(j['expectedSalePrice']),taxRate:_d(j['taxRate']),expiryDate:_dt(j['expiryDate']),
    warrantyUntil:_dt(j['warrantyUntil']),warrantyDetails:_s(j['warrantyDetails']),imageUrls:_strings(j['imageUrls']),
    attachmentUrls:_strings(j['attachmentUrls']),customFields:_map(j['customFields']),isActive:j['isActive'] as bool? ?? true,
    isArchived:j['isArchived'] as bool? ?? false,createdAt:_dt(j['createdAt']),updatedAt:_dt(j['updatedAt']),
    createdBy:_s(j['createdBy']),updatedBy:_s(j['updatedBy']));
}

/// One product row inside a purchase, sale, or return document.
class StockTransactionLine {
  const StockTransactionLine({required this.id,required this.productId,required this.productName,
    this.sku='',this.batchNumber='',this.lotNumber='',this.warehouseId='',this.warehouseName='',
    this.quantity=0,this.unit='',this.unitPrice=0,this.discountAmount=0,this.taxAmount=0,this.lineTotal=0,
    this.landedCostAllocation=0,this.returnedQuantity=0,this.note=''});
  final String id,productId,productName,sku,batchNumber,lotNumber,warehouseId,warehouseName,unit,note;
  final double quantity,unitPrice,discountAmount,taxAmount,lineTotal,landedCostAllocation,returnedQuantity;
  JsonMap toJson()=>{'id':id,'productId':productId,'productName':productName,'sku':sku,'batchNumber':batchNumber,
    'lotNumber':lotNumber,'warehouseId':warehouseId,'warehouseName':warehouseName,'quantity':quantity,'unit':unit,
    'unitPrice':unitPrice,'discountAmount':discountAmount,'taxAmount':taxAmount,'lineTotal':lineTotal,
    'landedCostAllocation':landedCostAllocation,'returnedQuantity':returnedQuantity,'note':note};
  factory StockTransactionLine.fromJson(JsonMap j)=>StockTransactionLine(id:_s(j['id']),productId:_s(j['productId']),
    productName:_s(j['productName']),sku:_s(j['sku']),batchNumber:_s(j['batchNumber']),lotNumber:_s(j['lotNumber']),
    warehouseId:_s(j['warehouseId']),warehouseName:_s(j['warehouseName']),quantity:_d(j['quantity']),unit:_s(j['unit']),
    unitPrice:_d(j['unitPrice']),discountAmount:_d(j['discountAmount']),taxAmount:_d(j['taxAmount']),
    lineTotal:_d(j['lineTotal']),landedCostAllocation:_d(j['landedCostAllocation']),
    returnedQuantity:_d(j['returnedQuantity']),note:_s(j['note']));
}

/// Purchase, sale, purchase return, or sales return header.
class StockTransaction {
  const StockTransaction({required this.id,required this.type,required this.date,this.referenceNumber='',
    this.partyId='',this.partyName='',this.partyPhone='',this.partyAddress='',this.warehouseId='',this.warehouseName='',
    this.subtotal=0,this.discountAmount=0,this.taxAmount=0,this.shippingAmount=0,this.otherCharges=0,
    this.totalAmount=0,this.paidAmount=0,this.dueAmount=0,this.paymentStatus='Due',this.paymentMethod='',
    this.note='',this.attachmentUrls=const [],this.lines=const [],this.status='Completed',this.returnedAmount=0,
    this.createdAt,this.updatedAt,this.createdBy='',this.approvedBy=''});
  final String id,type,referenceNumber,partyId,partyName,partyPhone,partyAddress,warehouseId,warehouseName;
  final DateTime date;
  final double subtotal,discountAmount,taxAmount,shippingAmount,otherCharges,totalAmount,paidAmount,dueAmount,returnedAmount;
  final String paymentStatus,paymentMethod,note,status,createdBy,approvedBy;
  final List<String> attachmentUrls;
  final List<StockTransactionLine> lines;
  final DateTime? createdAt,updatedAt;
  JsonMap toJson()=>{'id':id,'type':type,'date':date.toIso8601String(),'referenceNumber':referenceNumber,
    'partyId':partyId,'partyName':partyName,'partyPhone':partyPhone,'partyAddress':partyAddress,
    'warehouseId':warehouseId,'warehouseName':warehouseName,'subtotal':subtotal,'discountAmount':discountAmount,
    'taxAmount':taxAmount,'shippingAmount':shippingAmount,'otherCharges':otherCharges,'totalAmount':totalAmount,
    'paidAmount':paidAmount,'dueAmount':dueAmount,'paymentStatus':paymentStatus,'paymentMethod':paymentMethod,
    'note':note,'attachmentUrls':attachmentUrls,'lines':lines.map((e)=>e.toJson()).toList(),'status':status,
    'returnedAmount':returnedAmount,'createdAt':_iso(createdAt),'updatedAt':_iso(updatedAt),'createdBy':createdBy,'approvedBy':approvedBy};
  factory StockTransaction.fromJson(JsonMap j)=>StockTransaction(id:_s(j['id']),type:_s(j['type']),date:_dt(j['date'])??DateTime.now(),
    referenceNumber:_s(j['referenceNumber']),partyId:_s(j['partyId']),partyName:_s(j['partyName']),partyPhone:_s(j['partyPhone']),
    partyAddress:_s(j['partyAddress']),warehouseId:_s(j['warehouseId']),warehouseName:_s(j['warehouseName']),
    subtotal:_d(j['subtotal']),discountAmount:_d(j['discountAmount']),taxAmount:_d(j['taxAmount']),shippingAmount:_d(j['shippingAmount']),
    otherCharges:_d(j['otherCharges']),totalAmount:_d(j['totalAmount']),paidAmount:_d(j['paidAmount']),dueAmount:_d(j['dueAmount']),
    paymentStatus:_s(j['paymentStatus'],'Due'),paymentMethod:_s(j['paymentMethod']),note:_s(j['note']),
    attachmentUrls:_strings(j['attachmentUrls']),lines:(j['lines'] as List? ?? const []).map((e)=>StockTransactionLine.fromJson(Map<String,dynamic>.from(e as Map))).toList(),
    status:_s(j['status'],'Completed'),returnedAmount:_d(j['returnedAmount']),createdAt:_dt(j['createdAt']),updatedAt:_dt(j['updatedAt']),
    createdBy:_s(j['createdBy']),approvedBy:_s(j['approvedBy']));
}

/// Partial payment or collection. Each payment is a separate immutable ledger row.
class StockPayment {
  const StockPayment({required this.id,required this.referenceId,required this.referenceType,required this.date,required this.amount,
    this.partyId='',this.partyName='',this.method='Cash',this.transactionReference='',this.note='',this.receivedBy='',this.createdAt});
  final String id,referenceId,referenceType,partyId,partyName,method,transactionReference,note,receivedBy;
  final DateTime date; final double amount; final DateTime? createdAt;
  JsonMap toJson()=>{'id':id,'referenceId':referenceId,'referenceType':referenceType,'date':date.toIso8601String(),
    'amount':amount,'partyId':partyId,'partyName':partyName,'method':method,'transactionReference':transactionReference,
    'note':note,'receivedBy':receivedBy,'createdAt':_iso(createdAt)};
  factory StockPayment.fromJson(JsonMap j)=>StockPayment(id:_s(j['id']),referenceId:_s(j['referenceId']),
    referenceType:_s(j['referenceType']),date:_dt(j['date'])??DateTime.now(),amount:_d(j['amount']),partyId:_s(j['partyId']),
    partyName:_s(j['partyName']),method:_s(j['method'],'Cash'),transactionReference:_s(j['transactionReference']),
    note:_s(j['note']),receivedBy:_s(j['receivedBy']),createdAt:_dt(j['createdAt']));
}

/// Business expense or purchase-cost allocation (freight, rent, labour, etc.).
class StockExpense {
  const StockExpense({required this.id,required this.title,required this.category,required this.amount,required this.date,
    this.referenceId='',this.referenceType='General',this.allocationMethod='Manual',this.allocatedAmount=0,
    this.note='',this.attachmentUrls=const [],this.createdBy='',this.createdAt});
  final String id,title,category,referenceId,referenceType,allocationMethod,note,createdBy;
  final double amount,allocatedAmount; final DateTime date; final List<String> attachmentUrls; final DateTime? createdAt;
  double get unallocatedAmount=>(amount-allocatedAmount).clamp(0,double.infinity).toDouble();
  JsonMap toJson()=>{'id':id,'title':title,'category':category,'amount':amount,'date':date.toIso8601String(),
    'referenceId':referenceId,'referenceType':referenceType,'allocationMethod':allocationMethod,'allocatedAmount':allocatedAmount,
    'note':note,'attachmentUrls':attachmentUrls,'createdBy':createdBy,'createdAt':_iso(createdAt)};
  factory StockExpense.fromJson(JsonMap j)=>StockExpense(id:_s(j['id']),title:_s(j['title']),category:_s(j['category']),
    amount:_d(j['amount']),date:_dt(j['date'])??DateTime.now(),referenceId:_s(j['referenceId']),
    referenceType:_s(j['referenceType'],'General'),allocationMethod:_s(j['allocationMethod'],'Manual'),
    allocatedAmount:_d(j['allocatedAmount']),note:_s(j['note']),attachmentUrls:_strings(j['attachmentUrls']),
    createdBy:_s(j['createdBy']),createdAt:_dt(j['createdAt']));
}

/// Warehouse, shop, room, shelf, or rack.
class StockLocation {
  const StockLocation({required this.id,required this.name,this.type='Warehouse',this.parentId='',this.address='',
    this.description='',this.capacity=0,this.monthlyRent=0,this.isActive=true,this.createdAt});
  final String id,name,type,parentId,address,description; final double capacity,monthlyRent; final bool isActive; final DateTime? createdAt;
  JsonMap toJson()=>{'id':id,'name':name,'type':type,'parentId':parentId,'address':address,'description':description,
    'capacity':capacity,'monthlyRent':monthlyRent,'isActive':isActive,'createdAt':_iso(createdAt)};
  factory StockLocation.fromJson(JsonMap j)=>StockLocation(id:_s(j['id']),name:_s(j['name']),type:_s(j['type'],'Warehouse'),
    parentId:_s(j['parentId']),address:_s(j['address']),description:_s(j['description']),capacity:_d(j['capacity']),
    monthlyRent:_d(j['monthlyRent']),isActive:j['isActive'] as bool? ?? true,createdAt:_dt(j['createdAt']));
}

/// Supplier or customer record and running ledger balance.
class StockParty {
  const StockParty({required this.id,required this.name,this.type='Supplier',this.phone='',this.email='',this.address='',
    this.contactPerson='',this.openingBalance=0,this.currentBalance=0,this.note='',this.isActive=true,this.createdAt,this.updatedAt});
  final String id,name,type,phone,email,address,contactPerson,note; final double openingBalance,currentBalance;
  final bool isActive; final DateTime? createdAt,updatedAt;
  JsonMap toJson()=>{'id':id,'name':name,'type':type,'phone':phone,'email':email,'address':address,'contactPerson':contactPerson,
    'openingBalance':openingBalance,'currentBalance':currentBalance,'note':note,'isActive':isActive,
    'createdAt':_iso(createdAt),'updatedAt':_iso(updatedAt)};
  factory StockParty.fromJson(JsonMap j)=>StockParty(id:_s(j['id']),name:_s(j['name']),type:_s(j['type'],'Supplier'),
    phone:_s(j['phone']),email:_s(j['email']),address:_s(j['address']),contactPerson:_s(j['contactPerson']),
    openingBalance:_d(j['openingBalance']),currentBalance:_d(j['currentBalance']),note:_s(j['note']),
    isActive:j['isActive'] as bool? ?? true,createdAt:_dt(j['createdAt']),updatedAt:_dt(j['updatedAt']));
}

/// Transfer or stock movement ledger entry.
class StockMovement {
  const StockMovement({required this.id,required this.productId,required this.quantity,required this.date,
    this.batchNumber='',this.fromLocationId='',this.fromLocationName='',this.toLocationId='',this.toLocationName='',
    this.movementType='Transfer',this.referenceId='',this.reason='',this.createdBy='',this.createdAt});
  final String id,productId,batchNumber,fromLocationId,fromLocationName,toLocationId,toLocationName,movementType,referenceId,reason,createdBy;
  final double quantity; final DateTime date; final DateTime? createdAt;
  JsonMap toJson()=>{'id':id,'productId':productId,'batchNumber':batchNumber,'quantity':quantity,'fromLocationId':fromLocationId,
    'fromLocationName':fromLocationName,'toLocationId':toLocationId,'toLocationName':toLocationName,'movementType':movementType,
    'referenceId':referenceId,'date':date.toIso8601String(),'reason':reason,'createdBy':createdBy,'createdAt':_iso(createdAt)};
  factory StockMovement.fromJson(JsonMap j)=>StockMovement(id:_s(j['id']),productId:_s(j['productId']),batchNumber:_s(j['batchNumber']),
    quantity:_d(j['quantity']),fromLocationId:_s(j['fromLocationId']),fromLocationName:_s(j['fromLocationName']),
    toLocationId:_s(j['toLocationId']),toLocationName:_s(j['toLocationName']),movementType:_s(j['movementType'],'Transfer'),
    referenceId:_s(j['referenceId']),date:_dt(j['date'])??DateTime.now(),reason:_s(j['reason']),createdBy:_s(j['createdBy']),createdAt:_dt(j['createdAt']));
}

/// Damaged, lost, expired, returned, write-off, or correction record.
class StockAdjustment {
  const StockAdjustment({required this.id,required this.productId,required this.type,required this.quantity,required this.date,
    this.batchNumber='',this.locationId='',this.reason='',this.approvalStatus='Pending',this.approvedBy='',this.approvedAt,
    this.createdBy='',this.createdAt});
  final String id,productId,type,batchNumber,locationId,reason,approvalStatus,approvedBy,createdBy;
  final double quantity; final DateTime date; final DateTime? approvedAt,createdAt;
  JsonMap toJson()=>{'id':id,'productId':productId,'type':type,'quantity':quantity,'batchNumber':batchNumber,'locationId':locationId,
    'date':date.toIso8601String(),'reason':reason,'approvalStatus':approvalStatus,'approvedBy':approvedBy,
    'approvedAt':_iso(approvedAt),'createdBy':createdBy,'createdAt':_iso(createdAt)};
  factory StockAdjustment.fromJson(JsonMap j)=>StockAdjustment(id:_s(j['id']),productId:_s(j['productId']),type:_s(j['type']),
    quantity:_d(j['quantity']),batchNumber:_s(j['batchNumber']),locationId:_s(j['locationId']),date:_dt(j['date'])??DateTime.now(),
    reason:_s(j['reason']),approvalStatus:_s(j['approvalStatus'],'Pending'),approvedBy:_s(j['approvedBy']),approvedAt:_dt(j['approvedAt']),
    createdBy:_s(j['createdBy']),createdAt:_dt(j['createdAt']));
}

/// Append-only audit entry; immutability must be enforced by the backend.
class StockAuditLog {
  const StockAuditLog({required this.id,required this.action,required this.entityType,required this.entityId,
    required this.actorId,required this.actorName,required this.timestamp,this.oldValues=const {},this.newValues=const {},
    this.reason='',this.referenceId=''});
  final String id,action,entityType,entityId,actorId,actorName,reason,referenceId;
  final DateTime timestamp; final Map<String,dynamic> oldValues,newValues;
  JsonMap toJson()=>{'id':id,'action':action,'entityType':entityType,'entityId':entityId,'actorId':actorId,'actorName':actorName,
    'timestamp':timestamp.toIso8601String(),'oldValues':oldValues,'newValues':newValues,'reason':reason,'referenceId':referenceId};
  factory StockAuditLog.fromJson(JsonMap j)=>StockAuditLog(id:_s(j['id']),action:_s(j['action']),entityType:_s(j['entityType']),
    entityId:_s(j['entityId']),actorId:_s(j['actorId']),actorName:_s(j['actorName']),timestamp:_dt(j['timestamp'])??DateTime.now(),
    oldValues:_map(j['oldValues']),newValues:_map(j['newValues']),reason:_s(j['reason']),referenceId:_s(j['referenceId']));
}

/// Reservation for orders not yet dispatched; reduces available stock.
class StockReservation {
  const StockReservation({required this.id,required this.productId,required this.quantity,required this.createdAt,
    this.referenceId='',this.customerId='',this.status='Reserved',this.expiresAt,this.note=''});
  final String id,productId,referenceId,customerId,status,note; final double quantity;
  final DateTime createdAt; final DateTime? expiresAt;
  JsonMap toJson()=>{'id':id,'productId':productId,'quantity':quantity,'createdAt':createdAt.toIso8601String(),
    'referenceId':referenceId,'customerId':customerId,'status':status,'expiresAt':_iso(expiresAt),'note':note};
  factory StockReservation.fromJson(JsonMap j)=>StockReservation(id:_s(j['id']),productId:_s(j['productId']),quantity:_d(j['quantity']),
    createdAt:_dt(j['createdAt'])??DateTime.now(),referenceId:_s(j['referenceId']),customerId:_s(j['customerId']),
    status:_s(j['status'],'Reserved'),expiresAt:_dt(j['expiresAt']),note:_s(j['note']));
}
