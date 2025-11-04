# AppTextFieldWithLabel Component

A fully customizable text field component with label that follows the Ruby RX design system. This component provides complete control over colors, sizes, and styling while maintaining consistency across the application.

## Features

- 🎨 **Fully Customizable**: Configure colors, sizes, fonts, and spacing
- 🏥 **Ruby RX Design**: Matches the existing design system
- 📱 **Responsive**: Works across different screen sizes
- ⚡ **Pre-configured Variants**: Ready-to-use configurations for common cases
- 🔧 **Flexible Input Types**: Supports all text input types and behaviors
- ♿ **Accessible**: Built with accessibility in mind

## Basic Usage

### Standard Ruby RX Style
```dart
AppTextFieldWithLabel_.standard(
  label: 'Doctor Name *',
  controller: doctorNameController,
  hintText: 'Enter doctor name',
)
```

### With Keyboard Type
```dart
AppTextFieldWithLabel_.standard(
  label: 'Email Address',
  controller: emailController,
  hintText: 'your.email@example.com',
  keyboardType: TextInputType.emailAddress,
)
```

### Read-only with Tap Handler
```dart
AppTextFieldWithLabel_.standard(
  label: 'Date of Birth',
  controller: dobController,
  hintText: 'Select date',
  readOnly: true,
  onTap: () => _showDatePicker(),
  suffixIcon: Icon(Icons.calendar_today),
)
```

## Pre-configured Variants

### 1. Standard (Default Ruby RX styling)
```dart
AppTextFieldWithLabel_.standard(
  label: 'Field Label',
  controller: controller,
  hintText: 'Hint text',
)
```

### 2. Compact (Smaller size)
```dart
AppTextFieldWithLabel_.compact(
  label: 'Compact Field',
  controller: controller,
  hintText: 'Smaller field',
)
```

### 3. Large (Bigger size for important fields)
```dart
AppTextFieldWithLabel_.large(
  label: 'Important Field',
  controller: controller,
  hintText: 'Large field',
)
```

### 4. Text Area (Multi-line)
```dart
AppTextFieldWithLabel_.textArea(
  label: 'Notes',
  controller: controller,
  hintText: 'Enter detailed notes...',
  maxLines: 4,
  height: 100,
)
```

### 5. Custom Colors
```dart
AppTextFieldWithLabel_.withCustomColors(
  label: 'Custom Field',
  controller: controller,
  hintText: 'Custom styled',
  backgroundColor: Colors.purple.withOpacity(0.1),
  borderColor: Colors.purple,
  labelColor: Colors.purple,
  inputTextColor: Colors.purple.shade800,
)
```

## Full Customization

For complete control, use the main constructor:

```dart
AppTextFieldWithLabel(
  label: 'Fully Custom Field',
  controller: controller,
  hintText: 'Custom everything!',
  
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
  
  // Input styling
  inputFontSize: 16,
  inputTextColor: Colors.orange.shade800,
  hintTextColor: Colors.orange.shade400,
  hintFontSize: 14,
  
  // Layout
  spaceBetweenLabelAndField: 12,
  
  // Input behavior
  keyboardType: TextInputType.text,
  readOnly: false,
  onTap: null,
  maxLines: 1,
  obscureText: false,
  suffixIcon: null,
  prefixIcon: null,
  onChanged: (value) => print('Changed: $value'),
)
```

## Available Parameters

### Required Parameters
- `label`: The label text displayed above the field
- `controller`: TextEditingController for the input
- `hintText`: Placeholder text shown when field is empty

### Input Behavior
- `keyboardType`: Type of keyboard to show
- `readOnly`: Whether the field is read-only
- `onTap`: Callback when field is tapped
- `maxLines`: Maximum number of lines (use >1 for text areas)
- `obscureText`: Whether to hide input (for passwords)
- `suffixIcon`: Icon shown at the end of the field
- `prefixIcon`: Icon shown at the start of the field
- `onChanged`: Callback when text changes
- `onSubmitted`: Callback when user submits

### Label Styling
- `labelFontSize`: Size of the label text (default: 14)
- `labelFontWeight`: Weight of the label text (default: FontWeight.w500)
- `labelColor`: Color of the label text (default: theme text color)
- `labelMaxLines`: Maximum lines for label (default: 1)
- `labelOverflow`: How to handle label overflow (default: ellipsis)

### Container Styling
- `containerHeight`: Height of the input container (default: 50)
- `containerPadding`: Padding inside the container (default: horizontal 16)
- `backgroundColor`: Background color (default: primary1 with opacity)
- `borderColor`: Border color (default: primary1 with opacity)
- `borderRadius`: Corner radius (default: 12)
- `borderWidth`: Border thickness (default: 1)

### Input Text Styling
- `inputFontSize`: Size of the input text (default: 14)
- `inputTextColor`: Color of the input text (default: theme text color)
- `hintTextColor`: Color of the placeholder text (default: grey)
- `hintFontSize`: Size of the placeholder text (default: 14)
- `contentPadding`: Padding for the text input (default: zero)

### Layout
- `spaceBetweenLabelAndField`: Space between label and field (default: 8)

## Design Guidelines

### When to Use Each Variant

- **Standard**: Most common use case, follows Ruby RX design
- **Compact**: Use in dense forms or secondary information
- **Large**: Use for important or primary fields
- **Text Area**: Use for multi-line input like notes or descriptions
- **Custom Colors**: Use when you need to match specific branding or highlight certain fields

### Color Theming

The component automatically adapts to the Ruby RX color palette:
- Primary colors for borders and backgrounds
- Theme-appropriate text colors
- Consistent opacity levels for subtle backgrounds

### Accessibility

- Labels are properly associated with inputs
- Color contrast meets accessibility standards
- Touch targets are appropriately sized
- Keyboard navigation is supported

## Migration from _buildTextFieldWithLabel

The old `_buildTextFieldWithLabel` method has been replaced with this component. Here's how to migrate:

### Old Code
```dart
_buildTextFieldWithLabel(
  label: 'Doctor Name',
  controller: controller.doctorNameController,
  hintText: 'Enter doctor name',
)
```

### New Code
```dart
AppTextFieldWithLabel_.standard(
  label: 'Doctor Name',
  controller: controller.doctorNameController,
  hintText: 'Enter doctor name',
)
```

The new component provides the same functionality with additional customization options.

## Examples

See `lib/examples/app_text_field_with_label_example.dart` for a complete example showing all variants and customization options.