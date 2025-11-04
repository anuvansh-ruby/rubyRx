# AppDropdownWithLabel Component

A fully customizable dropdown field component with label that follows the Ruby RX design system. This component provides complete control over colors, sizes, and styling while maintaining consistency across the application.

## Features

- 🎨 **Fully Customizable**: Configure colors, sizes, fonts, and spacing
- 🏥 **Ruby RX Design**: Matches the existing design system
- 📱 **Responsive**: Works across different screen sizes
- ⚡ **Pre-configured Variants**: Ready-to-use configurations for common cases
- 🩺 **Medical Options**: Pre-defined lists for common medical fields
- ♿ **Accessible**: Built with accessibility in mind

## Basic Usage

### Standard Ruby RX Style
```dart
AppDropdownWithLabel_.standard(
  label: 'Frequency',
  value: selectedFrequency,
  items: MedicalDropdownOptions.frequency,
  hintText: 'Select frequency',
  onChanged: (String? newValue) {
    setState(() {
      selectedFrequency = newValue;
    });
  },
)
```

### With Required Field Indicator
```dart
AppDropdownWithLabel_.standard(
  label: 'Gender',
  value: selectedGender,
  items: MedicalDropdownOptions.gender,
  hintText: 'Select gender',
  isRequired: true,
  onChanged: (String? newValue) {
    setState(() {
      selectedGender = newValue;
    });
  },
)
```

## Pre-configured Variants

### 1. Standard (Default Ruby RX styling)
```dart
AppDropdownWithLabel_.standard(
  label: 'Field Label',
  value: selectedValue,
  items: ['Option 1', 'Option 2', 'Option 3'],
  hintText: 'Select option',
  onChanged: (value) => setState(() => selectedValue = value),
)
```

### 2. Compact (Smaller size)
```dart
AppDropdownWithLabel_.compact(
  label: 'Compact Field',
  value: selectedValue,
  items: ['Option 1', 'Option 2'],
  hintText: 'Select',
  onChanged: (value) => setState(() => selectedValue = value),
)
```

### 3. Large (Bigger size for important fields)
```dart
AppDropdownWithLabel_.large(
  label: 'Important Field',
  value: selectedValue,
  items: ['Important A', 'Important B'],
  hintText: 'Select important option',
  onChanged: (value) => setState(() => selectedValue = value),
)
```

### 4. Custom Colors
```dart
AppDropdownWithLabel_.withCustomColors(
  label: 'Custom Field',
  value: selectedValue,
  items: ['Custom 1', 'Custom 2'],
  hintText: 'Custom styled',
  backgroundColor: Colors.purple.withOpacity(0.1),
  borderColor: Colors.purple,
  labelColor: Colors.purple,
  dropdownTextColor: Colors.purple.shade800,
  onChanged: (value) => setState(() => selectedValue = value),
)
```

## Medical Dropdown Options

The component includes pre-defined lists for common medical fields:

### Medication Frequency
```dart
MedicalDropdownOptions.frequency
// ['Once a day', 'Twice a day', 'Thrice a day', 'Once weekly', 'Twice weekly', 'Once a month']
```

### Medication Duration
```dart
MedicalDropdownOptions.duration
// ['1 Day', '2 Days', '3 Days', '1 Week', '2 Weeks', '3 Weeks', '1 Month', '2 Months', '3 Months']
```

### Gender Options
```dart
MedicalDropdownOptions.gender
// ['Male', 'Female', 'Other']
```

### Common Medical Conditions
```dart
MedicalDropdownOptions.commonConditions
// ['Diabetes', 'Hypertension', 'Asthma', 'Heart Disease', 'Kidney Disease', ...]
```

## Full Customization

For complete control, use the main constructor:

```dart
AppDropdownWithLabel(
  label: 'Fully Custom Dropdown',
  value: selectedValue,
  items: ['Option A', 'Option B', 'Option C'],
  hintText: 'Custom everything!',
  onChanged: (value) => setState(() => selectedValue = value),
  
  // Label styling
  labelFontSize: 16,
  labelFontWeight: FontWeight.bold,
  labelColor: Colors.orange,
  labelMaxLines: 1,
  labelOverflow: TextOverflow.ellipsis,
  
  // Container styling
  containerHeight: 60,
  backgroundColor: Colors.orange.withOpacity(0.1),
  borderColor: Colors.orange,
  borderRadius: 20,
  borderWidth: 2,
  containerPadding: EdgeInsets.symmetric(horizontal: 20),
  
  // Dropdown styling
  dropdownFontSize: 16,
  dropdownTextColor: Colors.orange.shade800,
  hintTextColor: Colors.orange.shade400,
  hintFontSize: 14,
  iconColor: Colors.orange,
  
  // Layout
  spaceBetweenLabelAndField: 12,
  
  // Behavior
  isRequired: false,
  validator: (value) => value == null ? 'Please select an option' : null,
)
```

## Available Parameters

### Required Parameters
- `label`: The label text displayed above the dropdown
- `value`: Currently selected value (String? for nullable selection)
- `items`: List of options to display in the dropdown
- `hintText`: Placeholder text shown when no option is selected
- `onChanged`: Callback when selection changes

### Optional Parameters
- `isRequired`: Whether to show * indicator (default: false)
- `validator`: Validation function for form validation

### Label Styling
- `labelFontSize`: Size of the label text (default: 14)
- `labelFontWeight`: Weight of the label text (default: FontWeight.w500)
- `labelColor`: Color of the label text (default: theme text color)
- `labelMaxLines`: Maximum lines for label (default: 1)
- `labelOverflow`: How to handle label overflow (default: ellipsis)

### Container Styling
- `containerHeight`: Height of the dropdown container (default: 50)
- `containerPadding`: Padding inside the container (default: horizontal 16)
- `backgroundColor`: Background color (default: primary1 with opacity)
- `borderColor`: Border color (default: primary1 with opacity)
- `borderRadius`: Corner radius (default: 12)
- `borderWidth`: Border thickness (default: 1)

### Dropdown Styling
- `dropdownFontSize`: Size of the dropdown text (default: 14)
- `dropdownTextColor`: Color of the dropdown text (default: theme text color)
- `hintTextColor`: Color of the hint text (default: grey)
- `hintFontSize`: Size of the hint text (default: 14)
- `iconColor`: Color of the dropdown arrow icon (default: primary1)

### Layout
- `spaceBetweenLabelAndField`: Space between label and dropdown (default: 8)

## Usage with GetX (Observable)

When using with GetX reactive variables:

```dart
class MyController extends GetxController {
  final RxString selectedFrequency = ''.obs;
  final RxString selectedDuration = ''.obs;
}

// In your widget:
Obx(
  () => AppDropdownWithLabel_.standard(
    label: 'Frequency',
    value: controller.selectedFrequency.value.isEmpty 
        ? null 
        : controller.selectedFrequency.value,
    items: MedicalDropdownOptions.frequency,
    hintText: 'Select frequency',
    onChanged: (String? newValue) {
      if (newValue != null) {
        controller.selectedFrequency.value = newValue;
      }
    },
  ),
)
```

## Design Guidelines

### When to Use Each Variant

- **Standard**: Most common use case, follows Ruby RX design
- **Compact**: Use in dense forms or secondary information
- **Large**: Use for important or primary selections
- **Custom Colors**: Use when you need to match specific branding or highlight certain fields

### Medical Field Conventions

- **Frequency**: Use predefined medical frequency options
- **Duration**: Use predefined duration options with consistent formatting
- **Gender**: Use standard gender options with inclusive "Other" choice
- **Conditions**: Use common medical conditions with "Other" option for flexibility

### Color Theming

The component automatically adapts to the Ruby RX color palette:
- Primary colors for borders and icons
- Theme-appropriate text colors
- Consistent opacity levels for subtle backgrounds

### Accessibility

- Labels are properly associated with dropdowns
- Color contrast meets accessibility standards
- Touch targets are appropriately sized
- Keyboard navigation is supported
- Screen reader friendly

## Migration from Manual Text Fields

If you're upgrading from text fields to dropdowns for standardized options:

### Old Code
```dart
AppTextFieldWithLabel.standard(
  label: 'Frequency',
  controller: frequencyController,
  hintText: 'e.g., Twice daily',
)
```

### New Code
```dart
Obx(
  () => AppDropdownWithLabel_.standard(
    label: 'Frequency',
    value: selectedFrequency.value.isEmpty ? null : selectedFrequency.value,
    items: MedicalDropdownOptions.frequency,
    hintText: 'Select frequency',
    onChanged: (String? newValue) {
      if (newValue != null) {
        selectedFrequency.value = newValue;
      }
    },
  ),
)
```

## Examples

See `lib/examples/app_dropdown_with_label_example.dart` for a complete example showing all variants and customization options.