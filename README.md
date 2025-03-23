#Project structure

This diagram illustrates the architecture and workflow of the OCRMyPDF AWS solution. Here's how the system works:
Components and Flow:

#User Interaction

Users interact with a web interface hosted on an S3 bucket
They upload PDF files through the interface that need OCR processing


#API Layer

API Gateway receives file uploads and forwards them to a Lambda function
The upload Lambda (file_uploader.py) processes the file and initiates the OCR workflow


#Storage

S3 bucket with organized directories (input, processing, output) stores PDFs at different stages
A status.json file maintains the state of each processing job


#Messaging

SQS queue manages the OCR processing tasks
SNS topic handles notifications about job status changes
Dead letter queue captures failed processing attempts


#Processing

ECS cluster runs Docker containers with OCRMyPDF
The OCR processor container (ocr_processor.py) polls the SQS queue for tasks
It applies OCR to PDFs and sends status updates via SNS


#Status Updates

Status Lambda (file_updater.py) processes notifications
Updates status.json when processing completes or fails
Web UI periodically polls status.json to show current processing status

flowchart TD

%% Frontend
subgraph Frontend
    WebUI["S3 Website Bucket\n(HTML/CSS/JS)"]
end

%% API Layer
subgraph API
    APIGateway["API Gateway"]
    UploadLambda["Upload Lambda\nfile_uploader.py"]
    StatusLambda["Status Lambda\nfile_updater.py"]
end

%% Storage Layer
subgraph Storage
    S3Input["Input/ Directory"]
    S3Processing["Processing/ Directory"]
    S3Output["Output/ Directory"]
    StatusJSON["status.json"]
end

%% Messaging Layer
subgraph Messaging
    SQS["SQS Queue\nOCR Tasks"]
    DLQ["Dead Letter Queue"]
    SNS["SNS Topic\nNotifications"]
end

%% Processing Layer
subgraph Processing
    ECSCluster["ECS Cluster"]
    OCRContainer["OCRMyPDF Container\nocr_processor.py"]
end

%% User interactions
User -->|1. Upload PDF| WebUI
WebUI -->|2. Fetch API| APIGateway

%% API flow
APIGateway -->|3. Invoke| UploadLambda
UploadLambda -->|4. Store PDF| S3Input
UploadLambda -->|5. Queue Task| SQS
SQS -->|Failed Tasks| DLQ

%% Processing flow
SQS -->|6. Poll Tasks| OCRContainer
OCRContainer -->|7. Download PDF| S3Input
OCRContainer -->|8. Process OCR| OCRContainer
OCRContainer -->|9. Upload Result| S3Output
OCRContainer -->|10. Notify| SNS

%% Status update flow
SNS -->|11. Trigger| StatusLambda
StatusLambda -->|12. Update Status| StatusJSON
WebUI -->|13. Poll Status| StatusJSON

%% PDF data flow
S3Input -.->|PDF Flow| S3Processing
S3Processing -.->|PDF Flow| S3Output

%% Return flow
StatusJSON -->|14. Display Status| WebUI
S3Output -->|15. Download Result| User

%% Container Execution
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
class S3Input,S3Output,S3Processing,StatusJSON,WebUI s3;
class SQS,DLQ sqs;
class SNS sns;
class OCRContainer container;

