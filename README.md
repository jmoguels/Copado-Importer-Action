# Copado Import Component List Generator

This GitHub Action automatically generates a formatted list of Salesforce components from your pull requests, ready to be imported into Copado Essentials using the "Import Component Selections" feature. It also identifies test classes and creates a comma-separated list for Copado's "Specify Tests" feature.

## Table of Contents

- [Setup Instructions](#setup-instructions)
- [How It Works](#how-it-works)
- [Usage Guide](#usage-guide)
- [Supported Component Types](#supported-component-types)
- [Test Classes Detection](#test-classes-detection)
- [Troubleshooting](#troubleshooting)
- [Customization](#customization)

## Setup Instructions

### Add the GitHub Action to your repository

1. Create a new file at `.github/workflows/copado-import-generator.yml` in your repository
2. Copy the complete GitHub Action workflow code into this file
   (For the full workflow code, please see the [GitHub Action Code](#) section at the bottom of this document or in the repository)
3. Commit the file to your repository (main branch is recommended for immediate availability)

## How It Works

This GitHub Action:

1. **Automatically runs** when:
   - Pull requests are opened, updated, or reopened
   - Manually triggered via the "Actions" tab in your repository

2. **Identifies files** by:
   - For PRs: Examining files changed in the pull request
   - For manual runs: Scanning all files in the repository

3. **Analyzes each file** to:
   - Detect if it's a Salesforce metadata component
   - Determine its component type (Apex Class, LWC, etc.)
   - Format it correctly for Copado Essentials
   - Identify test classes by scanning for @isTest or testMethod

4. **Generates two formatted lists**:
   - A component list ready to paste into Copado's "Import Component Selections"
   - A comma-separated test class list for Copado's "Specify Tests" feature

## Usage Guide

### Using with Pull Requests

1. Create or update a pull request with Salesforce metadata changes
2. The action will automatically run
3. Go to the "Actions" tab in your repository
4. Click on the latest workflow run for your PR
5. Click on the "generate-component-list" job
6. Find the following sections in the logs:

#### For Component Import List
1. Find the "Display Component List for Copado Import" step
2. Copy the text between the START and END markers
3. In Copado Essentials:
   - Open your deployment
   - Click "More > Import Component Selections"
   - Paste the copied text and click Import

#### For Test Class Selection
1. Find the "Display Test Classes for Copado Test Selection" step
2. Copy the comma-separated list between the START and END markers
3. In Copado Essentials:
   - When running tests, select "Specify Tests"
   - Paste the comma-separated list of test classes
   - Example format: `ProductListClassTest,CategoriesControllerTest,SearchAccountsLWCControllerTest`

### Using Manually

1. Go to the "Actions" tab in your repository
2. Select "Copado Import Component List Generator" from the list
3. Click "Run workflow" (Use the default branch, typically "main")
4. Once complete, click on the workflow run
5. Click on the "generate-component-list" job
6. Find the "Display Component List for Copado Import" step or "Display Test Classes for Copado Test Selection" step
7. Copy the text between the appropriate START and END markers
8. Paste into the corresponding section in Copado Essentials

## Supported Component Types

The action automatically detects and formats the following Salesforce component types:

| Component Type | Format Example | File Pattern |
|----------------|----------------|--------------|
| Apex Classes | `ApexClass/MyClass` | `*.cls` |
| Apex Triggers | `ApexTrigger/MyTrigger` | `*.trigger` |
| Apex Pages | `ApexPage/MyPage` | `*.page` |
| Apex Components | `ApexComponent/MyComponent` | `*.component` |
| Lightning Web Components | `LightningComponentBundle/myComponent` | `lwc/myComponent/myComponent.js` |
| Aura Components | `AuraDefinitionBundle/myComponent` | `aura/myComponent/myComponent.cmp` |
| Custom Objects | `CustomObject/MyObject__c` | `objects/MyObject__c/MyObject__c.object-meta.xml` |
| Custom Fields | `CustomField/MyObject__c.MyField__c` | `objects/MyObject__c/fields/MyField__c.field-meta.xml` |
| Custom Metadata | `CustomMetadata/MyType.MyRecord` | `customMetadata/MyType.MyRecord.md-meta.xml` |
| Layouts | `Layout/MyObject__c-Layout` | `layouts/MyObject__c-Layout.layout-meta.xml` |
| Flows | `Flow/MyFlow` | `flows/MyFlow.flow-meta.xml` |
| Permission Sets | `PermissionSet/MyPermSet` | `permissionsets/MyPermSet.permissionset-meta.xml` |
| Profiles | `Profile/MyProfile` | `profiles/MyProfile.profile-meta.xml` |

## Test Classes Detection

The GitHub Action automatically identifies test classes in your Salesforce code and generates a comma-separated list ready for use with Copado Essentials' "Specify Tests" feature.

### How Test Classes are Detected

The action identifies test classes by:

1. Scanning all Apex class files (`.cls`) in the PR or repository
2. Looking for patterns that indicate a test class:
   - The `@isTest` annotation
   - Methods using the `testMethod` keyword

### Supported Test Class Formats

The action handles test classes in:

- SFDX format: `force-app/main/default/classes/MyTest.cls`
- Classic format: `src/classes/MyTest.cls`
- Custom locations: Any `.cls` file with test methods

### Using the Test Class List in Copado

1. Find the "Display Test Classes for Copado Test Selection" step in the workflow logs
2. Copy the comma-separated list between the START and END markers
3. In Copado Essentials:
   - Open your deployment
   - Click "Run Apex Tests"
   - Select "Specify Tests"
   - Paste the comma-separated list

### Example Format

```
ProductListClassTest,CategoriesControllerTest,SearchAccountsLWCControllerTest
```

This format works directly with Copado's test selection field without requiring any modifications.

## Troubleshooting

### No Components Found

If the action runs successfully but doesn't find any components:

1. **Check file paths**: The action primarily looks for files in standard Salesforce project structures:
   - SFDX format: `force-app/main/default/...`
   - Classic format: `src/...`
   
2. **Verify file extensions**: Make sure files have the correct extensions (`.cls`, `.trigger`, etc.)

3. **Run manually**: Try running the action manually from the Actions tab to process all files in the repository

4. **Check the logs**: Look at the "Get changed files" and "Generate Copado Import List" steps for debugging information

### No Test Classes Found

If the action doesn't find any test classes:

1. **Check test annotations**: Make sure your test classes use `@isTest` or `testMethod` keywords
2. **Run on entire repository**: Try running the action manually to scan all files, not just changed ones
3. **Review logs**: Check the "Generate Test Classes List" step for detailed information

### Adding Components Manually

If the action can't automatically detect your components, you can manually create a list using these formats:

```
ApexClass/MyClassName
ApexTrigger/MyTriggerName
CustomObject/MyObject__c
CustomField/MyObject__c.MyField__c
LightningComponentBundle/myLwcName
```

## Customization

### Adding Support for Additional Component Types

To add support for additional component types, modify the workflow file and add your component detection logic in the "Generate Copado Import List" step.

For example, to add support for Email Templates:

```bash
elif [[ $path_without_prefix == email/* ]]; then
  if [[ $path_without_prefix == *.email-meta.xml ]]; then
    folder=$(dirname "$path_without_prefix" | sed 's/email\///')
    template=$(basename "$path_without_prefix" .email-meta.xml)
    COPADO_FORMAT="EmailTemplate/$folder/$template"
    echo "  - Found Email Template: $folder/$template"
  fi
fi
```

### Customizing Test Class Detection

If you have a custom pattern for test classes, you can modify the "Generate Test Classes List" step to include additional patterns or naming conventions.
