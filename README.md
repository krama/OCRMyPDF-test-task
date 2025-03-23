#Project structure

This diagram illustrates the architecture and workflow of the OCRMyPDF AWS solution. Here's how the system works:

flowchart TD
    subgraph Frontend
        WebUI["S3 Website Bucket\n(HTML/CSS/JS)"]
    end

    subgraph API
        APIGateway["API Gateway"]
        UploadLambda["Upload Lambda\nfile_uploader.py"]
        StatusLambda["Status Lambda\nfile_updater.py"]
    end

    subgraph Storage
        S3["S3 PDF Storage"]
        S3Input["Input/ Directory"]
        S3Processing["Processing/ Directory"]
        S3Output["Output/ Directory"]
        StatusJSON["status.json"]
    end

    subgraph Messaging
        SQS["SQS Queue\nOCR Tasks"]
        DLQ["Dead Letter Queue"]
        SNS["SNS Topic\nNotifications"]
    end

    subgraph Processing
        ECSCluster["ECS Cluster"]
        OCRContainer["OCRMyPDF Container\nocr_processor.py"]
    end

    %% User interactions
    User["User"] -->|1. Uploads PDF| WebUI
    WebUI -->|2. Fetch API| APIGateway
    
    %% API flow
    APIGateway -->|3. Invoke| UploadLambda
    UploadLambda -->|4. Store PDF| S3Input
    UploadLambda -->|5. Queue Task| SQS
    SQS -->|Failed Tasks| DLQ
    
    %% Processing flow
    SQS -->|6. Poll Tasks| OCRContainer
    OCRContainer -->|7. Download PDF| S3Input
    OCRContainer -->|8. Process with OCRMyPDF| OCRContainer
    OCRContainer -->|9. Upload Result| S3Output
    OCRContainer -->|10. Send Notification| SNS
    
    %% Status update flow
    SNS -->|11. Trigger| StatusLambda
    StatusLambda -->|12. Update Status| StatusJSON
    WebUI -->|13. Poll Status| StatusJSON
    
    %% Visual representation of the PDF flow
    S3Input -.->|PDF Flow| S3Processing
    S3Processing -.->|PDF Flow| S3Output
    
    %% Return path to user
    StatusJSON -->|14. Show Status| WebUI
    S3Output -->|15. Download Result| User
    
    %% Container execution
    ECSCluster -->|Runs| OCRContainer
    
    %% Styling
    classDef aws fill:#FF9900,stroke:#232F3E,color:white;
    classDef lambda fill:#FF9900,stroke:#232F3E,color:white;
    classDef s3 fill:#3F8624,stroke:#232F3E,color:white;
    classDef sqs fill:#CC2264,stroke:#232F3E,color:white;
    classDef sns fill:#CC2264,stroke:#232F3E,color:white;
    classDef ecs fill:#FF9900,stroke:#232F3E,color:white;
    classDef container fill:#069,stroke:#232F3E,color:white;
    
    class APIGateway,ECSCluster aws;
    class UploadLambda,StatusLambda lambda;
    class S3,S3Input,S3Output,S3Processing,StatusJSON,WebUI s3;
    class SQS,DLQ sqs;
    class SNS sns;
    class OCRContainer container;
