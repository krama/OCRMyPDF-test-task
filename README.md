#Project structure

This diagram illustrates the architecture and workflow of the OCRMyPDF AWS solution. Here's how the system works:

---
config:
  theme: redux-dark
  look: neo
  layout: elk
---
flowchart TD
 subgraph Frontend["Frontend"]
        WebUI["S3 Website Bucket\n(HTML/CSS/JS)"]
  end
 subgraph API["API"]
        APIGateway["API Gateway"]
        UploadLambda["Upload Lambda\nfile_uploader.py"]
        StatusLambda["Status Lambda\nfile_updater.py"]
  end
 subgraph Storage["Storage"]
        S3["S3 PDF Storage"]
        S3Input["Input/ Directory"]
        S3Processing["Processing/ Directory"]
        S3Output["Output/ Directory"]
        StatusJSON["status.json"]
  end
 subgraph Messaging["Messaging"]
        SQS["SQS Queue\nOCR Tasks"]
        DLQ["Dead Letter Queue"]
        SNS["SNS Topic\nNotifications"]
  end
 subgraph Processing["Processing"]
        ECSCluster["ECS Cluster"]
        OCRContainer["OCRMyPDF Container\nocr_processor.py"]
  end
    User["User"] L_User_WebUI_0@-- Uploads PDF --> WebUI
    WebUI L_WebUI_APIGateway_0@-- Fetch API --> APIGateway
    APIGateway -- Invoke --> UploadLambda
    UploadLambda L_UploadLambda_S3Input_0@-- Store PDF --> S3Input
    UploadLambda L_UploadLambda_SQS_0@-- Queue Task --> SQS
    SQS -- Failed Tasks --> DLQ
    SQS L_SQS_OCRContainer_0@-- Poll Tasks --> OCRContainer
    OCRContainer L_OCRContainer_S3Input_0@-- Download PDF --> S3Input
    OCRContainer -- Process with OCRMyPDF --> OCRContainer
    OCRContainer L_OCRContainer_S3Output_0@-- Upload Result --> S3Output
    OCRContainer L_OCRContainer_SNS_0@-- Send Notification --> SNS
    SNS L_SNS_StatusLambda_0@-- Trigger --> StatusLambda
    StatusLambda L_StatusLambda_StatusJSON_0@-- Update Status --> StatusJSON
    WebUI L_WebUI_StatusJSON_0@-- Poll Status --> StatusJSON
    S3Input -. PDF Flow .-> S3Processing
    S3Processing -. PDF Flow .-> S3Output
    StatusJSON L_StatusJSON_WebUI_0@-- Show Status --> WebUI
    S3Output -- Download Result --> User
    ECSCluster -- Runs --> OCRContainer
     WebUI:::s3
     APIGateway:::aws
     UploadLambda:::lambda
     StatusLambda:::lambda
     S3:::s3
     S3Input:::s3
     S3Processing:::s3
     S3Output:::s3
     StatusJSON:::s3
     SQS:::sqs
     DLQ:::sqs
     SNS:::sns
     ECSCluster:::aws
     OCRContainer:::container
    classDef aws fill:#FF9900,stroke:#232F3E,color:white
    classDef lambda fill:#FF9900,stroke:#232F3E,color:white
    classDef s3 fill:#3F8624,stroke:#232F3E,color:white
    classDef sqs fill:#CC2264,stroke:#232F3E,color:white
    classDef sns fill:#CC2264,stroke:#232F3E,color:white
    classDef ecs fill:#FF9900,stroke:#232F3E,color:white
    classDef container fill:#069,stroke:#232F3E,color:white
    L_User_WebUI_0@{ animation: slow } 
    L_WebUI_APIGateway_0@{ animation: slow } 
    L_UploadLambda_S3Input_0@{ animation: slow } 
    L_UploadLambda_SQS_0@{ animation: slow } 
    L_SQS_OCRContainer_0@{ animation: slow } 
    L_OCRContainer_S3Input_0@{ animation: slow } 
    L_OCRContainer_S3Output_0@{ animation: slow } 
    L_OCRContainer_SNS_0@{ animation: slow } 
    L_SNS_StatusLambda_0@{ animation: slow } 
    L_StatusLambda_StatusJSON_0@{ animation: slow } 
    L_WebUI_StatusJSON_0@{ animation: slow } 
    L_StatusJSON_WebUI_0@{ animation: slow }
