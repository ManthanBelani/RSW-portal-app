# Invoice HTML Template Issues

## Current Problems

The `_generateInvoiceHtml()` method in `lib/screens/invoice_preview_screen.dart` has several undefined variables in the HTML template:

### Undefined Variables:
1. `clientAddress` - should be `clientAddressHtml`
2. `itemsHtml` - not defined (needs to be created from job description)
3. `bankDetailsHtml` - not defined (needs to be created from bankRows)
4. `discount` - should be `discountAmount`
5. `totalDue` - should be `finalDue`

### Unused Variables (defined but not used in HTML):
- `currencySymbol` ✓ (should be used)
- `invoiceDate` ✓ (should be used)
- `dueDate` ✓ (should be used)
- `finalDue` ✓ (should be used)
- `iconBase64` ✓ (should be used)
- `bgImageBase64` ✓ (should be used)
- `clientAddressHtml` ✓ (should be used)
- `jobDescHtml` ✓ (should be used)

## Quick Fix

The new HTML template I provided uses all the correct variable names. The current template in your file is incomplete/broken.

## Solution

Replace the entire HTML return statement (from `return '''` to `''';`) with the complete template from `NEW_HTML_METHOD.txt`.

The new template:
- Uses all the correct variable names
- Includes the background image
- Has proper styling
- Displays all invoice information correctly

## Manual Steps

Since the file is large and auto-formatted, here's what to do:

1. Open `lib/screens/invoice_preview_screen.dart`
2. Find the `_generateInvoiceHtml()` method (around line 548)
3. Find the `return '''` statement (around line 603)
4. Select everything from `return '''` to the closing `''';` before the closing `}`
5. Replace it with the content from `NEW_HTML_METHOD.txt`

Or I can help you fix the specific undefined variables one by one.
