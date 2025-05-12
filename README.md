Table of Contents

Setup Instructions
How It Works
Usage Guide
Supported Component Types
Test Classes Detection
Troubleshooting
Customization

Setup Instructions
1. Add the GitHub Action to your repository
Create a new file at .github/workflows/copado-import-generator.yml with the following content:
yamlname: Copado Import Component List Generator

on:
  pull_request:
    types: [opened, synchronize, reopened]
  workflow_dispatch:  # Allow manual trigger

jobs:
  generate-component-list:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
        with:
          fetch-depth: 0  # Fetch all history to properly identify changed files

      - name: Get changed files
        id: changed-files
        run: |
          if [[ "${{ github.event_name }}" == "pull_request" ]]; then
            # For pull requests, get files changed between PR base and head
            echo "Getting changed files in PR"
            CHANGED_FILES=$(git diff --name-only ${{ github.event.pull_request.base.sha }} ${{ github.event.pull_request.head.sha }})
          else
            # For workflow_dispatch, get all files in the repo (excluding hidden)
            echo "Getting all files in repo (excluding hidden)"
            CHANGED_FILES=$(find . -type f -not -path "*/\.*" | sed 's/^\.\///')
          fi
          
          # Save to file
          echo "$CHANGED_FILES" > changed_files.txt
          
          # Display detected files for debugging
          echo "Detected files:"
          echo "------------------------------------------------------------"
          cat changed_files.txt
          echo "------------------------------------------------------------"
          echo "Total files detected: $(wc -l < changed_files.txt)"

      - name: Generate Copado Import List
        id: generate-import-list
        run: |
          # Create output file
          touch copado_import_list.txt
          
          echo "Processing files for Copado format..."
          echo "------------------------------------------------------------"
          
          # Process each file and convert to Copado format
          while IFS= read -r file; do
            # Skip if file is empty or just whitespace
            if [[ -z "${file// }" ]]; then
              continue
            fi
            
            echo "Analyzing file: $file"
            COPADO_FORMAT=""
            
            # Extract component information from the path
            if [[ $file == *"force-app/main/default/"* ]]; then
              # SFDX format handling
              path_without_prefix=${file#*force-app/main/default/}
              echo "  - SFDX format detected: $path_without_prefix"
              
              # Handle different metadata types
              if [[ $path_without_prefix == classes/* ]]; then
                if [[ $path_without_prefix == *.cls ]]; then
                  name=${path_without_prefix#classes/}
                  name=${name%.cls}
                  COPADO_FORMAT="ApexClass/$name"
                  echo "  - Found Apex Class: $name"
                fi
              elif [[ $path_without_prefix == triggers/* ]]; then
                if [[ $path_without_prefix == *.trigger ]]; then
                  name=${path_without_prefix#triggers/}
                  name=${name%.trigger}
                  COPADO_FORMAT="ApexTrigger/$name" 
                  echo "  - Found Apex Trigger: $name"
                fi
              elif [[ $path_without_prefix == pages/* ]]; then
                if [[ $path_without_prefix == *.page ]]; then
                  name=${path_without_prefix#pages/}
                  name=${name%.page}
                  COPADO_FORMAT="ApexPage/$name"
                  echo "  - Found Apex Page: $name"
                fi
              elif [[ $path_without_prefix == components/* ]]; then
                if [[ $path_without_prefix == *.component ]]; then
                  name=${path_without_prefix#components/}
                  name=${name%.component}
                  COPADO_FORMAT="ApexComponent/$name"
                  echo "  - Found Apex Component: $name"
                fi
              elif [[ $path_without_prefix == lwc/* ]]; then
                # LWC components are in directories
                dir=$(dirname "$path_without_prefix")
                if [[ $dir != "lwc" ]]; then
                  component_name=${dir#lwc/}
                  # Only add once per component
                  if [[ $path_without_prefix == *"$component_name/$component_name.js" ]]; then
                    COPADO_FORMAT="LightningComponentBundle/$component_name"
                    echo "  - Found LWC: $component_name"
                  fi
                fi
              elif [[ $path_without_prefix == aura/* ]]; then
                # Aura components are in directories
                dir=$(dirname "$path_without_prefix")
                if [[ $dir != "aura" ]]; then
                  component_name=${dir#aura/}
                  # Only add once per component
                  if [[ $path_without_prefix == *"$component_name/$component_name.cmp" ]]; then
                    COPADO_FORMAT="AuraDefinitionBundle/$component_name"
                    echo "  - Found Aura Component: $component_name"
                  fi
                fi
              elif [[ $path_without_prefix == objects/* ]]; then
                if [[ $path_without_prefix == *.object-meta.xml ]]; then
                  name=${path_without_prefix#objects/}
                  name=${name%.object-meta.xml}
                  COPADO_FORMAT="CustomObject/$name"
                  echo "  - Found Custom Object: $name"
                elif [[ $path_without_prefix == */fields/*.field-meta.xml ]]; then
                  obj_name=$(echo $path_without_prefix | awk -F/ '{print $2}')
                  field_name=$(basename $path_without_prefix .field-meta.xml)
                  COPADO_FORMAT="CustomField/$obj_name.$field_name"
                  echo "  - Found Custom Field: $obj_name.$field_name"
                fi
              elif [[ $path_without_prefix == customMetadata/* ]]; then
                if [[ $path_without_prefix == *.md-meta.xml ]]; then
                  file_name=$(basename $path_without_prefix .md-meta.xml)
                  md_type=$(dirname $path_without_prefix | sed 's/customMetadata\///')
                  COPADO_FORMAT="CustomMetadata/$md_type.$file_name"
                  echo "  - Found Custom Metadata: $md_type.$file_name"
                fi
              elif [[ $path_without_prefix == layouts/* ]]; then
                if [[ $path_without_prefix == *.layout-meta.xml ]]; then
                  name=${path_without_prefix#layouts/}
                  name=${name%.layout-meta.xml}
                  COPADO_FORMAT="Layout/$name"
                  echo "  - Found Layout: $name"
                fi
              elif [[ $path_without_prefix == flows/* ]]; then
                if [[ $path_without_prefix == *.flow-meta.xml ]]; then
                  name=${path_without_prefix#flows/}
                  name=${name%.flow-meta.xml}
                  COPADO_FORMAT="Flow/$name"
                  echo "  - Found Flow: $name"
                fi
              elif [[ $path_without_prefix == permissionsets/* ]]; then
                if [[ $path_without_prefix == *.permissionset-meta.xml ]]; then
                  name=${path_without_prefix#permissionsets/}
                  name=${name%.permissionset-meta.xml}
                  COPADO_FORMAT="PermissionSet/$name"
                  echo "  - Found Permission Set: $name"
                fi
              elif [[ $path_without_prefix == profiles/* ]]; then
                if [[ $path_without_prefix == *.profile-meta.xml ]]; then
                  name=${path_without_prefix#profiles/}
                  name=${name%.profile-meta.xml}
                  COPADO_FORMAT="Profile/$name"
                  echo "  - Found Profile: $name"
                fi
              fi
            elif [[ $file == *"src/"* ]]; then
              # Handle classic format
              path_without_prefix=${file#*src/}
              echo "  - Classic format detected: $path_without_prefix"
              
              # Handle different metadata types based on classic format
              if [[ $path_without_prefix == classes/* ]]; then
                if [[ $path_without_prefix == *.cls ]]; then
                  name=${path_without_prefix#classes/}
                  name=${name%.cls}
                  COPADO_FORMAT="ApexClass/$name"
                  echo "  - Found Apex Class: $name"
                fi
              elif [[ $path_without_prefix == triggers/* ]]; then
                if [[ $path_without_prefix == *.trigger ]]; then
                  name=${path_without_prefix#triggers/}
                  name=${name%.trigger}
                  COPADO_FORMAT="ApexTrigger/$name"
                  echo "  - Found Apex Trigger: $name"
                fi
              fi
            elif [[ $file == *.cls ]]; then
              # Fallback for standard class files without standard path structure
              name=$(basename "$file" .cls)
              COPADO_FORMAT="ApexClass/$name"
              echo "  - Found standalone Apex Class: $name"
            elif [[ $file == *.trigger ]]; then
              # Fallback for standard trigger files without standard path structure
              name=$(basename "$file" .trigger)
              COPADO_FORMAT="ApexTrigger/$name"
              echo "  - Found standalone Apex Trigger: $name"
            elif [[ $file == *.page ]]; then
              # Fallback for standard page files without standard path structure
              name=$(basename "$file" .page)
              COPADO_FORMAT="ApexPage/$name"
              echo "  - Found standalone Apex Page: $name"
            fi
            
            # Add to the import list if a format was determined
            if [[ ! -z "$COPADO_FORMAT" ]]; then
              echo "$COPADO_FORMAT" >> copado_import_list.txt
              echo "  → Added to Copado list: $COPADO_FORMAT"
            else
              echo "  ✕ No Copado format determined for this file"
            fi
            
          done < changed_files.txt
          
          # Remove duplicates
          sort copado_import_list.txt | uniq > copado_import_list_unique.txt
          mv copado_import_list_unique.txt copado_import_list.txt
          
          # Count results
          COMP_COUNT=$(wc -l < copado_import_list.txt)
          
          # Display the result
          echo "------------------------------------------------------------"
          echo "Found $COMP_COUNT components for Copado import:"
          if [ "$COMP_COUNT" -gt 0 ]; then
            cat copado_import_list.txt
          else
            echo "NO COMPONENTS FOUND! Make sure your PR includes Salesforce metadata files."
          fi
          echo "------------------------------------------------------------"

      - name: Generate Test Classes List
        id: generate-test-list
        run: |
          # Create output file for test classes
          touch test_classes_list.txt
          
          echo "Identifying test classes..."
          echo "------------------------------------------------------------"
          
          # Process each file to find test classes
          while IFS= read -r file; do
            # Skip if file is empty or just whitespace
            if [[ -z "${file// }" ]]; then
              continue
            fi
            
            # Only look at apex class files
            if [[ $file == *.cls ]]; then
              echo "Checking for test class: $file"
              
              # Read the file content and check for @isTest or testMethod
              if grep -q -E '@isTest|testMethod' "$file"; then
                # Extract class name from path
                if [[ $file == *"force-app/main/default/classes/"* ]]; then
                  # SFDX format
                  name=${file#*force-app/main/default/classes/}
                  name=${name%.cls}
                  echo "  ✓ Found test class: $name"
                  echo "$name" >> test_classes_list.txt
                elif [[ $file == *"src/classes/"* ]]; then
                  # Classic format
                  name=${file#*src/classes/}
                  name=${name%.cls}
                  echo "  ✓ Found test class: $name"
                  echo "$name" >> test_classes_list.txt
                else
                  # Try general extraction for non-standard paths
                  name=$(basename "$file" .cls)
                  echo "  ✓ Found standalone test class: $name"
                  echo "$name" >> test_classes_list.txt
                fi
              else
                echo "  ✕ Not a test class"
              fi
            fi
          done < changed_files.txt
          
          # Create comma-separated list
          TEST_CLASSES_CSV=$(paste -sd "," test_classes_list.txt)
          
          # Count results
          TEST_COUNT=$(wc -l < test_classes_list.txt)
          
          # Display the result
          echo "------------------------------------------------------------"
          echo "Found $TEST_COUNT test classes:"
          if [ "$TEST_COUNT" -gt 0 ]; then
            echo "Individual classes:"
            cat test_classes_list.txt
            echo ""
            echo "Comma-separated list for Copado:"
            echo "$TEST_CLASSES_CSV"
          else
            echo "NO TEST CLASSES FOUND in the analyzed files."
          fi
          echo "------------------------------------------------------------"
          
          # Save for later use
          echo "$TEST_CLASSES_CSV" > test_classes_comma_list.txt

      - name: Display Component List for Copado Import
        run: |
          # Check if we found any components
          COMP_COUNT=$(wc -l < copado_import_list.txt)
          
          echo "================================================================="
          echo "                     COPADO IMPORT COMPONENT LIST                "
          echo "================================================================="
          echo ""
          
          if [ "$COMP_COUNT" -gt 0 ]; then
            echo "Copy everything between the START and END markers below:"
            echo ""
            echo "---------------------START COPY FROM HERE----------------------"
            cat copado_import_list.txt
            echo "----------------------END COPY HERE---------------------------"
            echo ""
            echo "Paste this list into Copado: More > Import Component Selections"
          else
            echo "NO COMPONENTS FOUND IN THIS PR!"
            echo ""
            echo "Possible reasons:"
            echo "1. The PR doesn't contain any Salesforce metadata files"
            echo "2. The files don't match the expected patterns
2. Commit the file to your repository
You can commit directly to your main branch, or create a new branch and then open a PR to merge it.
How It Works
This GitHub Action:

Automatically runs when:

Pull requests are opened, updated, or reopened
Manually triggered via the "Actions" tab in your repository


Identifies files by:

For PRs: Examining files changed in the pull request
For manual runs: Scanning all files in the repository


Analyzes each file to:

Detect if it's a Salesforce metadata component
Determine its component type (Apex Class, LWC, etc.)
Format it correctly for Copado Essentials
Identify test classes by scanning for @isTest or testMethod


Generates two formatted lists:

A component list ready to paste into Copado's "Import Component Selections"
A comma-separated test class list for Copado's "Specify Tests" feature



Usage Guide
Using with Pull Requests

Create or update a pull request with Salesforce metadata changes
The action will automatically run
Go to the "Actions" tab in your repository
Click on the latest workflow run for your PR
Click on the "generate-component-list" job
Find the following sections in the logs:

For Component Import List

Find the "Display Component List for Copado Import" step
Copy the text between the START and END markers
In Copado Essentials:

Open your deployment
Click "More > Import Component Selections"
Paste the copied text and click Import



For Test Class Selection

Find the "Display Test Classes for Copado Test Selection" step
Copy the comma-separated list between the START and END markers
In Copado Essentials:

When running tests, select "Specify Tests"
Paste the comma-separated list of test classes
Example format: ProductListClassTest,CoolantControllerTest,SearchAccountsLWCControllerTest



Using Manually

Go to the "Actions" tab in your repository
Select "Copado Import Component List Generator" from the list
Click "Run workflow" (Use the default branch, typically "main")
Once complete, click on the workflow run
Click on the "generate-component-list" job
Find the "Display Component List for Copado Import" step or "Display Test Classes for Copado Test Selection" step
Copy the text between the appropriate START and END markers
Paste into the corresponding section in Copado Essentials

Supported Component Types
The action automatically detects and formats the following Salesforce component types:
Component TypeFormat ExampleFile PatternApex ClassesApexClass/MyClass*.clsApex TriggersApexTrigger/MyTrigger*.triggerApex PagesApexPage/MyPage*.pageApex ComponentsApexComponent/MyComponent*.componentLightning Web ComponentsLightningComponentBundle/myComponentlwc/myComponent/myComponent.jsAura ComponentsAuraDefinitionBundle/myComponentaura/myComponent/myComponent.cmpCustom ObjectsCustomObject/MyObject__cobjects/MyObject__c/MyObject__c.object-meta.xmlCustom FieldsCustomField/MyObject__c.MyField__cobjects/MyObject__c/fields/MyField__c.field-meta.xmlCustom MetadataCustomMetadata/MyType.MyRecordcustomMetadata/MyType.MyRecord.md-meta.xmlLayoutsLayout/MyObject__c-Layoutlayouts/MyObject__c-Layout.layout-meta.xmlFlowsFlow/MyFlowflows/MyFlow.flow-meta.xmlPermission SetsPermissionSet/MyPermSetpermissionsets/MyPermSet.permissionset-meta.xmlProfilesProfile/MyProfileprofiles/MyProfile.profile-meta.xml
Troubleshooting
No Components Found
If the action runs successfully but doesn't find any components:

Check file paths: The action primarily looks for files in standard Salesforce project structures:

SFDX format: force-app/main/default/...
Classic format: src/...


Verify file extensions: Make sure files have the correct extensions (.cls, .trigger, etc.)
Run manually: Try running the action manually from the Actions tab to process all files in the repository
Check the logs: Look at the "Get changed files" and "Generate Copado Import List" steps for debugging information

Adding Components Manually
If the action can't automatically detect your components, you can manually create a list using these formats:
ApexClass/MyClassName
ApexTrigger/MyTriggerName
CustomObject/MyObject__c
CustomField/MyObject__c.MyField__c
LightningComponentBundle/myLwcName
Customization
Adding Support for Additional Component Types
To add support for additional component types, modify the workflow file and add your component detection logic in the "Generate Copado Import List" step.
For example, to add support for Email Templates:
bashelif [[ $path_without_prefix == email/* ]]; then
  if [[ $path_without_prefix == *.email-meta.xml ]]; then
    folder=$(dirname "$path_without_prefix" | sed 's/email\///')
    template=$(basename "$path_without_prefix" .email-meta.xml)
    COPADO_FORMAT="EmailTemplate/$folder/$template"
    echo "  - Found Email Template: $folder/$template"
  fi
fi
Customizing Output Format
If you need a different output format, modify the "Display Component List for Copado Import" step in the workflow file.
