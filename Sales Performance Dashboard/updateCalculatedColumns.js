function updateCalculatedColumns() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("DB");
  const lastRow = sheet.getLastRow();

  if (lastRow < 2) return;

  const dataRange = sheet.getRange(2, 1, lastRow - 1, 16);
  const data = dataRange.getValues();

for (let i = 0; i < data.length; i++) {
  const orderDate = new Date(data[i][1]); 
  const deliveryDays = data[i][10];       
  const rating = data[i][11];             
  const revenue = data[i][12];            

  // Year 
  data[i][2] = orderDate.getFullYear();
    // Rating category 
    if (rating >= 4) {
      data[i][13] = "Positive";
    } else if (rating >= 3) {
      data[i][13] = "Neutral";
    } else {
      data[i][13] = "Negative";
    }

    // Delivery category 
    if (deliveryDays <= 3) {
      data[i][14] = "Fast";
    } else if (deliveryDays <= 7) {
      data[i][14] = "Normal";
    } else {
      data[i][14] = "Delayed";
    }

    // Order value segment 
    if (revenue >= 1000) {
      data[i][15] = "High Value";
    } else if (revenue >= 500) {
      data[i][15] = "Medium Value";
    } else {
      data[i][15] = "Low Value";
    }
  }

  dataRange.setValues(data);
}