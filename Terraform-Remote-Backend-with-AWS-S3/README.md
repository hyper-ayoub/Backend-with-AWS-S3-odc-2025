## **Remote Backend with AWS S3**

Terraform can use an **S3 bucket** to store the state file.  
 To avoid race conditions (two people applying at once), we use **DynamoDB for locking**.

### **1\. Create S3 bucket & DynamoDB table**

`# Create S3 bucket`  
`aws s3api create-bucket --bucket my-terraform-backend-dev --region us-east-1`

`# Enable versioning (good practice for state recovery)`  
`aws s3api put-bucket-versioning \`  
  `--bucket my-terraform-backend-dev \`  
  `--versioning-configuration Status=Enabled`

`# Create DynamoDB table for locking`  
`aws dynamodb create-table \`  
  `--table-name terraform-locks \`  
  `--attribute-definitions AttributeName=LockID,AttributeType=S \`  
  `--key-schema AttributeName=LockID,KeyType=HASH \`  
  `--billing-mode PAY_PER_REQUEST`
  
<img width="1049" height="641" alt="Capture d’écran 2025-08-30 015828" src="https://github.com/user-attachments/assets/58bfb01a-bd09-4028-ab8d-a06460125bd6" />
<img width="1616" height="299" alt="Capture d’écran 2025-08-30 015948" src="https://github.com/user-attachments/assets/a4342328-ef79-4238-8eb3-ad4e904f4b11" />

### **2\. Configure Terraform backend**

In your Terraform project, create `backend.tf`:

`terraform {`  
  `backend "s3" {`  
    `bucket         = "my-terraform-backend-dev"   # S3 bucket name`  
    `key            = "global/s3/terraform.tfstate" # Path inside bucket`  
    `region         = "us-east-1"`  
    `dynamodb_table = "terraform-locks"             # DynamoDB for state locking`  
    `encrypt        = true                          # Encrypt state at rest`  
  `}`  
`}`

### 

### **3\. Initialize backend**

**`terraform init`**

* Terraform will ask to **migrate local state** (if exists) to S3.

### **4\. Example Resource**

`main.tf`:

`provider "aws" {`  
  `region = "us-east-1"`  
`}`

`resource "aws_s3_bucket" "example" {`  
  `bucket = "my-example-bucket-12345"`  
  `aws_s3_bucket_acl    = "private"`  
`}`

Now run:

`terraform apply`

* State will be stored in **S3**, not locally.

* Locking will be handled by **DynamoDB**.

**Benefits of Remote Backend (S3 \+ DynamoDB):**

* Centralized state management.

* Safe collaboration (no overwrites).

* Versioning \+ recovery from S3.

* Automatic locking with DynamoDB.

**test Terraform remote backend with two collaborators** to see how state locking and sharing work in practice. 

**Pre-requisites**

1. **Both collaborators** have:

   * AWS CLI configured with permissions for S3 \+ DynamoDB.

   * Terraform installed.

   * Access to the **same Git repository** containing your Terraform code (`backend.tf`, `main.tf`, etc.).

2. You already set up:

   * S3 bucket (`my-terraform-backend-dev`) with versioning.

   * DynamoDB table `(terraform-locks`) for state locking.

## **Step 1: First collaborator initializes**

On **Collaborator A’s machine**:

`terraform init`  
`terraform apply`

This will:

* Store state in S3.

* Acquire a lock in DynamoDB while applying.

* Release the lock when finished.

## **Step 2: Second collaborator tries to run at the same time**

On **Collaborator B’s machine** (while A is still running `apply`):

`terraform apply`

Terraform will **detect the lock in DynamoDB** and show an error like:

`Error: Error acquiring the state lock`

`Error message: ConditionalCheckFailedException: The conditional request failed`  
`Lock Info:`  
  `ID:        12345678-abcd`  
  `Path:      my-terraform-backend-dev/global/s3/terraform.tfstate`  
  `Operation: OperationTypeApply`  
  `Who:       user@machine`  
  `Version:   0.12.29`  
  `Created:   2025-08-29 08:21:47.593 +0000 UTC`

This proves locking is working — B cannot run Terraform until A finishes.

## **Step 3: Verify shared state**

After **A finishes**, **B can pull the latest state**:

`terraform refresh`

Or simply run:

`terraform show`

Both will read the **same state** from S3 (so if A created an S3 bucket, B will see it immediately).

## **Step 4: Simulate collaboration workflow**

Typical workflow for two people working together:

1. **Collaborator A**: Runs `terraform plan` and `terraform apply`.  
2. State is updated in **S3**.  
3. **Collaborator B**: Pulls latest changes (git \+ terraform refresh).  
4. **Collaborator B**: Runs another change.

State is always **in sync** because of remote backend. 


