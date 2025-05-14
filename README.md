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
3. Commit the file to your repository (main branch is recommended for immediate availability)

### Permissions for PR Comments (Optional)

By default, the GitHub Action will display the component lists in the workflow summary, which is viewable from the Actions tab. If you want to enable automatic PR comments instead:

1. Go to your repository settings
2. Navigate to Settings > Actions > General
3. Scroll down to "Workflow permissions"
4. Select "Read and write permissions"
5. Check "Allow GitHub Actions to create and approve pull requests"
6. Save the changes

Then modify your workflow file to include this code instead of the GitHub Step Summary section:

```yaml
- name: Prepare PR Comment Content
  if: github.event_name == 'pull_request'
  run: |
    # Create the PR comment file
    echo "## Copado Component and Test Lists" > pr_comment.md
    echo "" >> pr_comment.md
    echo "### Component Import List" >> pr_comment.md
    echo "Copy this list and paste into Copado: More > Import Component Selections" >> pr_comment.md
    echo "\`\`\`" >> pr_comment.md
    cat copado_import_list.txt >> pr_comment.md
    echo "\`\`\`" >> pr_comment.md
    echo "" >> pr_comment.md
    echo "### Test Class Selection" >> pr_comment.md
    echo "Copy this comma-separated list and paste into Copado's \"Specify Tests\" field" >> pr_comment.md
    echo "\`\`\`" >> pr_comment.md
    cat test_classes_comma_list.txt >> pr_comment.md
    echo "\`\`\`" >> pr_comment.md

- name: Post PR Comment
  if: github.event_name == 'pull_request'
  uses: peter-evans/create-or-update-comment@v2
  with:
    issue-number: ${{ github.event.pull_request.number }}
    body-file: pr_comment.md
```

This configuration will post the component lists directly as a comment on your PR after setting the appropriate permissions.

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
3. Once complete:
   - The component lists will appear in the workflow summary
   - To access them: Go to Actions tab > Click on the workflow run > View the summary at the top

4. If you prefer to have the lists automatically posted as PR comments (optional):
   - Go to your repository settings
   - Navigate to Settings > Actions > General
   - Scroll down to "Workflow permissions"
   - Select "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"
   - Save the changes
   - Modify the workflow file to use PR comments (see "Enabling PR Comments" section)

5. Copy the lists directly from the workflow summary (or PR comment if enabled)

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
   - Example format: `ProductListClassTest,SearchAccountsLWCControllerTest`

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
ProductListClassTest,SearchAccountsLWCControllerTest
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
