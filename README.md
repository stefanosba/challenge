# Tech Challenge

After running terraform apply, the pipeline will be created which builds the Docker images and pushes them to ECR. Applying the pipeline will automatically deploy the images as well.
Before running Terraform, make sure to update the following variables in terraform.tfvars according to your environment: aws_profile, aws_region, and account_id. Pleasae check also the "terraform" block in tf-0-init.tf.

As the CodePipeline source is connected to my Github repository (https://github.com/stefanosba/challenge.git), you need to create a secret in AWS Secrets Manager to allow interaction with GitHub. Use this command to create the secret with my git token (only read repo permissions): 

aws secretsmanager create-secret --name github-token --secret-string "LEGGERE README.md NEL challenge.zip" (Github blocks the token when push, even if it has only read permissions)

Then the commands for apply terraform are:

export GITHUB_OAUTH_TOKEN=$(aws secretsmanager get-secret-value --secret-id github-token --query SecretString --output text)
terraform apply -var "github_oauth_token=$GITHUB_OAUTH_TOKEN"

After the deploy you can test the application by:
    Check the current status and users saved on the db:
        http://ALBDNS/users
        http://ALBDNS/health
    Add a new user:
        curl -X POST http://ALBDNS:80/user -H "Content-Type: application/json" -d '{"name": "Mario Rossi", "email": "m.rossi@satispay.it"}'

## Table of Contents

- [Task 1: Python REST API](#task-1-python-rest-api)
- [Task 2: Nginx ReverseProxy](#task-2-nginx-reverse-proxy)
- [Task 2: Dockerization](#task-2-dockerization)
- [Task 3: Infrastructure with Terraform](#task-3-infrastructure-with-terraform)

## Task 1: Python REST API

    Requirements:
      Python 3.9+

    Install dependencies:
      pip install -r requirements.txt

    Running the Application:

    1. Initialize the DB and start the server:
        uvicorn main:api --reload

    2. The API will be available at:
       http://127.0.0.1:8000

    GET /users returns a list of all registered users:
      curl http://127.0.0.1:8000/users

    POST /user creates a new user and requires `name` (letters and spaces only) and a valid "email":
      curl -X POST http://127.0.0.1:8000/user -H "Content-Type: application/json" -d '{"name": "Mario Rossi", "email": "m.rossi@satispay.it"}'

    GET /health returns 'ok':
      curl http://127.0.0.1:8000/health

    Technical Notes:
      Uses SQLite ("users.db") for local data persistence.
      The "email" field is unique.
      Input is validated via Pydantic (email format, name length/pattern).

    Error Handling
      400 Bad Request: for duplicate emails or invalid input.
      500 Internal Server Error: for unexpected failures.

    Production Considerations

    In a real-world scenario, improvements would include:

      Using PostgreSQL or a managed database
      Authentication (JWT or OAuth2)
      Logging and monitoring

## Task 2: Nginx reverse proxy

    The configuration is saved into a file named `nginx.conf`.

    Notes:
    - NGINX acts as a reverse proxy forwarding HTTP requests to the REST API.

## Task 2: Dockerization

    The Python REST API server has been containerised using a lightweight python:3.9-slim base image to ensure minimal image size and fast deployments.

    Build the image:
      docker build -t rest-api .

    Run the container:
      docker run -d -p 8000:8000 rest-api

    Nginx alpine.

## Task 3: Infrastructure with Terraform

    tf-0-init.tf:

        Terraform backend to store state in an S3 bucket.

        Variables and values to Update:

        bucket = "tech-challenge-terraf-state" → replace with your own S3 bucket name
        profile = "techchallenge" → set to your AWS CLI profile

        Provider Variables (in terraform.tfvars):

        aws_region
        aws_profile

    tf-1-vpc.tf:

        Provisioning the networking layer using the official AWS VPC Terraform module. It creates:

        A VPC with 3 Availability Zones in eu-central-1.
        Public, private, and intra subnets.
        A single NAT gateway for outbound internet from private subnets.

        Variables in terraform.tfvars:

        vpc_cidr 
        private_subnets 
        public_subnets
        intra_subnets
    
    tf-2-ec2.tf:

    Creates the Application Load Balancer (ALB) and related networking components:

        Public ALB across public subnets.
        Target Group for reverse proxy (ECS, IP-based).
        HTTP Listener forwarding to the Target Group.
        Security Groups:

            'alb_sg': allows HTTP (port 80) from the internet.
            'reverse_proxy_sg': allows inbound HTTP and all outbound traffic.

    tf-3-ecs.tf:
        Deploys the ECS Fargate service and configures autoscaling:

        ECS Cluster and Task Definition with two containers:
            reverse-proxy (port 80)
            rest-api (port 8000)

        Fargate Service with:
            1 desired task

        Load Balancer integration (reverse proxy)
        Private subnets and security group
        CloudWatch logging enabled for both containers
        Autoscaling configuration:
            Min: 1, Max: 4 tasks
            CPU-based scaling (target: 70%)
            Memory-based scaling (target: 75%)
    
    tf-4-iam.tf:
        Creates IAM roles and policies required by ECS, VPC Flow Logs, CodeBuild, and CodePipeline.

    tf-5-cloudwatch.tf:
        Sets up monitoring and logging resources:

        Metric Alarm for high CPU usage on the reverse-proxy ECS service (threshold: 70%, 2-minute window).

        Log Groups with 7-day retention for:
            reverse-proxy container
            rest-api container

        VPC Flow Logs
    
    tf-6-pipeline.tf:
        Defines the CI/CD pipeline using CodeBuild and CodePipeline:

        Source from GitHub repo stefanosba/challenge.

        CodeBuild Project:

            Environment variables for AWS account, region, ECS cluster/service, and ECR repos.

            Builds and pushes Docker images for reverse-proxy and rest-api.

            Updates ECS service to deploy new images.

        CodePipeline:

            Pipeline with two stages:

            Source: pulls code from GitHub (main branch) using OAuth token.

            Build: triggers CodeBuild project.

        Artifacts stored in an S3 bucket (pipeline_bucket).
    
    tf-7-ecr.tf:
        ECR repository for images.
    
    tf-8-s3.tf:
        S3 bucket for codepipeline.

    tf-8-output.tf:
        Outputs.