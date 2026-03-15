# Merapar Challenge

A serverless web application that serves an HTML page displaying a dynamic string that can be changed at runtime without redeployment. Built with **Python (FastAPI)** on **AWS Lambda**, provisioned entirely with **Terraform**.

**Live URL**: After deployment, Terraform outputs the public Function URL.

## Architecture

```
User → Lambda Function URL → Lambda (Python 3.12 / FastAPI + Mangum) → SSM Parameter Store
```

The application reads a dynamic string from AWS Systems Manager Parameter Store on every request. Updating the parameter instantly changes what users see — no code change or redeployment required.

### AWS Resources Created

| Resource | Purpose |
|---|---|
| Lambda Function | Runs the FastAPI app via Mangum adapter |
| Lambda Function URL | Public HTTPS endpoint (no API Gateway needed) |
| SSM Parameter Store | Stores the dynamic string, editable at runtime |
| IAM Role + Policy | Least-privilege permissions (logs + SSM read) |
| CloudWatch Log Group | Lambda execution logs with 7-day retention |
| AWS Budgets | $1 USD monthly cost alert |

## Project Structure

```
├── app/
│   ├── main.py              # FastAPI application + Mangum handler
│   └── templates/
│       └── index.html        # Jinja2 template
├── infra/aws/
│   ├── lambda.tf             # Lambda, Function URL, permissions
│   ├── iam.tf                # IAM role and policy
│   ├── ssm.tf                # SSM parameter
│   ├── budget.tf             # Cost alert
│   ├── provider.tf           # AWS provider + default tags
│   ├── variables.tf          # Parameterized configuration
│   ├── terraform.tfvars      # Environment-specific values
│   └── outputs.tf            # Function URL output
├── Makefile                  # Build, test, package, deploy targets
├── requirements.txt          # Production dependencies
└── requirements-dev.txt      # Development dependencies
```

## Quick Start

### Prerequisites

- Python 3.12+, Terraform 1.0+, AWS CLI configured, `zip` utility

### Deploy

```bash
make install          # Install dependencies
make deploy           # Build ZIP + terraform plan
cd infra/aws
terraform apply       # Review plan, then confirm
```

### Change the Dynamic String (no redeploy)

```bash
aws ssm put-parameter \
  --name "/merapar-challenge/dynamic_string" \
  --value "Any new value" \
  --overwrite \
  --region us-east-2
```

Refresh the page — the new value appears immediately.

## Solution Discussion & Available Options

### Compute: Why Lambda over alternatives

| Option | Pros | Cons | Cost |
|---|---|---|---|
| **Lambda + Function URL** (chosen) | Zero servers, scales to zero, free tier covers this use case | Cold starts (~1s), 15-min timeout | $0 |
| EC2 | Full control, no cold starts | Runs 24/7, needs patching, overkill for this | ~$8/mo minimum |
| ECS Fargate | Container-native, no servers to manage | Always-on cost, more infrastructure | ~$10/mo minimum |
| App Runner | Simple container deployment | Less control, still has baseline cost | ~$5/mo minimum |

Lambda was the clear choice: the challenge requires a simple HTML page, not a high-throughput API. The free tier provides 1M requests/month and 400,000 GB-seconds — more than enough.

### Dynamic String Storage: Why SSM over alternatives

| Option | Pros | Cons |
|---|---|---|
| **SSM Parameter Store** (chosen) | Free (standard tier), native AWS integration, simple API | No versioning UI, 10K param limit |
| DynamoDB | Flexible schema, fast | Overkill for a single value, adds cost complexity |
| S3 object | Cheap storage | Higher latency, no atomic reads for small values |
| Environment variable | Simplest | Requires redeployment to change — violates the challenge requirement |

SSM Parameter Store is the right tool for this: a single configuration value that needs to change without redeployment. The `ssm:GetParameter` call adds ~10ms of latency, which is negligible for this use case.

### HTTP Exposure: Why Function URL over API Gateway

| Option | Pros | Cons |
|---|---|---|
| **Lambda Function URL** (chosen) | Zero config, free, built-in HTTPS | No custom domain, no rate limiting, no caching |
| API Gateway (REST) | Custom domains, throttling, caching, API keys | $3.50/million requests, more Terraform code |
| API Gateway (HTTP) | Cheaper than REST, simpler | Still adds cost and complexity |
| ALB | Path-based routing | $16/mo minimum, intended for multi-target setups |

Function URL provides a free HTTPS endpoint with no additional infrastructure. For a single-page challenge, API Gateway's features (custom domains, throttling) add cost without value.

## Decisions and Rationale

1. **FastAPI + Mangum**: FastAPI provides a modern Python web framework with automatic OpenAPI docs. Mangum adapts ASGI apps to Lambda's event format with zero code changes. The same app runs locally with `make dev` and on Lambda without modification.

2. **Terraform variables and `default_tags`**: All resource names are composed from `var.project_name`, making the infrastructure reusable. Default tags propagate `Project` and `Environment` to every resource automatically.

3. **IAM least privilege**: The Lambda role only has `ssm:GetParameter` on the specific parameter ARN and `logs:*` scoped to its own log group — not `Resource: "*"`.

4. **Makefile as build orchestrator**: `make deploy` chains clean → package → plan in a single command. Dependencies are installed into a `build/` directory, zipped with the application code, and the temporary directory is removed. This ensures reproducible builds.

5. **Budget alert**: A $1 USD monthly budget with email notification demonstrates cost awareness, even for a challenge.

## Improvements With More Time

**Infrastructure**:
- Remote Terraform state (S3 + DynamoDB) for team collaboration and state locking
- CI/CD pipeline (GitHub Actions): `fmt` → `validate` → `plan` on PR, `apply` on merge
- Custom domain via Route 53 + ACM certificate

**Application**:
- SSM parameter caching with TTL (e.g., 60s) to reduce API calls and latency
- Unit tests mocking SSM calls, integration test hitting the Function URL
- `/health` endpoint for monitoring
- Structured logging with AWS Lambda Powertools

**Security**:
- SSM `SecureString` with KMS encryption
- CORS configuration on the Function URL

**Operational**:
- Terraform workspaces or directory-per-environment structure for dev/staging/prod
- Alerting on Lambda errors via CloudWatch Alarms → SNS
- X-Ray tracing for request observability
