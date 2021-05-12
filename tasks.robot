# +
*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.Tables
Library           RPA.FileSystem
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Robocloud.Secrets
Library           RPA.Dialogs
# -

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${path_secret}=    Get Secret    keys
    Open the robot order website    ${path_secret}[url]
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    3x    2s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    ${zipname}=    Ask Zip File Name to User
    Create a ZIP file of the receipts    ${zipname}[filename]
    Close Browser

*** Keywords ***
Open the robot order website
    [Arguments]    ${url}
    Open Available Browser    ${url}

*** Keywords ***
Ask Zip File Name to User
    Create Form    Question to the user
    Add Text Input    label=What is the name of your output .zip file?    name=filename    value=
    &{response}=    Request Response
    Log    Username is "${response}[filename]"
    [Return]    &{response}

*** Keywords ***
Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${table_csv}=    Read Table From Csv    path=orders.csv    header=True
    Log    ${table_csv}
    [Return]    ${table_csv}

*** Keywords ***
Close the annoying modal
    Wait Until Page Contains Element    class:alert-buttons
    Click Button    class:btn-dark

*** Keywords ***
Fill the form
    [Arguments]    ${row}
    ${head}=    Convert To String    ${row}[Head]
    Select From List By Value    id:head    ${head}
    ${body}=    Convert To String    ${row}[Body]
    Select Radio Button    body    ${body}
    ${legs}=    Convert To Integer    ${row}[Legs]
    Input Text    class:form-control    ${legs}
    Input Text    id:address    ${row}[Address]

*** Keywords ***
Preview the robot
    Click Button    id:preview
    Wait Until Page Contains Element    id:robot-preview-image

*** Keywords ***
Submit the order
    Click Button    id:order
    Wait Until Page Contains Element    id:receipt

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${receipt_result_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_result_html}    ${OUTPUT_DIR}${/}${order_number}.pdf
    [Return]    ${OUTPUT_DIR}${/}${order_number}.pdf

*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}${order_number}.png
    [Return]    ${OUTPUT_DIR}${/}${order_number}.png

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf Document    ${pdf}
    Add Image To Pdf    ${screenshot}    ${pdf}    ${pdf}
    Close Pdf Document    ${pdf}

*** Keywords ***
Go to order another robot
    Click Button    id:order-another

*** Keywords ***

    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

*** Keywords ***
Create a ZIP file of the receipts
    [Arguments]    ${zipname}
    Archive Folder With ZIP    ${OUTPUT_DIR}    ${OUTPUT_DIR}${/}${zipname}.zip    recursive=True    include=*.pdf    exclude=/.*
