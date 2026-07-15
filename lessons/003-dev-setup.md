# Lesson 003: Dev Environment Setup (Ruby 3.4, Rails 8, Next.js, AWS CLI)

## Objectives

- Install and configure the AWS CLI on your local development machine.
- Set up local credentials using AWS IAM profile configuration.
- Install Ruby 3.4 and initialize the Rails 8 backend workspace.
- Install Node.js and initialize the Next.js frontend workspace.
- Establish environment file configurations for local AI applications.

---

## Theory

A robust development environment is essential when writing cloud-connected AI applications. Rather than copying keys into source code, we rely on the standard AWS Credential Provider Chain. Both the AWS SDK for Ruby and the AWS SDK for JavaScript automatically resolve credentials sequentially from:

1. Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`).
2. Shared credential files (`~/.aws/credentials`).
3. IAM Roles associated with the compute instance (ECS Tasks, Lambda execution roles, or EC2 instances).

```text
+-----------------------------------------------------------+
|               AWS SDK Credential Resolution Chain         |
+-----------------------------------------------------------+
| 1. Process Environment Variables                          |
|    (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)             |
+-----------------------------------------------------------+
                            || (If not found)
                            \/
+-----------------------------------------------------------+
| 2. Local Shared Credentials File                          |
|    (~/.aws/credentials) via Named Profiles                |
+-----------------------------------------------------------+
                            || (If not found)
                            \/
+-----------------------------------------------------------+
| 3. IAM Metadata Service Roles                             |
|    (ECS Task Role / Lambda Execution Role)                |
+-----------------------------------------------------------+
```

---

## AWS CLI Setup & Walkthrough

### Step 1: Installing the AWS CLI

- **macOS**: Install using Homebrew:

  ```bash
  brew install awscli
  ```

- **Windows**: Use the MSI Installer:

  ```powershell
  msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
  ```

- **Linux**: Install using curl:

  ```bash
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  ```

### Step 2: Configuring Credentials

Run the command to setup a default local credentials configuration:

```bash
aws configure
```

You will be prompted to enter:

- **AWS Access Key ID**: Your developer user Access Key.
- **AWS Secret Access Key**: Your developer user Secret Key.
- **Default region name**: Enter `us-east-1` (or your preferred region with model access).
- **Default output format**: Enter `json`.

---

## Workspace Setup

### 1. Ruby 3.4 & Rails 8 Setup

Check your Ruby version (we recommend using a manager like `rbenv`, `rvm`, or `asdf`):

```bash
ruby -v
```

Ensure it reports 3.4.x. Install the bundler and rails gems:

```bash
gem install bundler rails
```

We will structure the Rails API under the `code/rails` directory.

### 2. Node.js & Next.js Setup

Verify Node.js version is v22+ (using `nvm` or `fnm`):

```bash
node -v
```

Ensure it reports v22.x or v24.x. We will structure the Next.js client under the `code/nextjs` directory.

### 3. Environment Variables Configuration

We use dotenv files locally to specify configurations without hardcoding. Create a template file:

```text
# code/rails/.env
AWS_REGION=us-east-1
BEDROCK_MODEL_ID=anthropic.claude-3-5-sonnet-20241022-v2:0
```

---

## Labs & Exercises

### Lab 3.1: Verifying the AWS CLI & Runtimes

1. Confirm the CLI is active and calling the AWS STS API to identify your user:

   ```bash
   aws sts get-caller-identity
   ```

2. Verify you can list bedrock models using:

   ```bash
   aws bedrock list-foundation-models --query "modelSummaries[0]"
   ```

3. Verify that your system outputs correct node and ruby runtime versions.

### Exercise

Configure a secondary AWS profile named `sandbox` using:

```bash
aws configure --profile sandbox
```

Verify that you can run commands using this profile:

```bash
aws sts get-caller-identity --profile sandbox
```

---

## Quiz

See [Lesson 003 Quiz](../quizzes/lesson-003-quiz.md).

## Interview Questions

See [Lesson 003 Interview Questions](../interview/lesson-003-interview.md).

## Best Practices & Production Notes

- **Never Commit Secrets**: Ensure `.env` is listed inside `.gitignore` before starting development.
- **Developer Account Isolation**: Developers should always use local profiles that match sandbox AWS accounts, not production accounts, to avoid accidental deletions or high invocation billing.
- **Region Matching**: Set your local AWS region to `us-east-1` or `us-west-2` where model access was granted in Lesson 002.
