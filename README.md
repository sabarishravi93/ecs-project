# ECS VPC Infrastructure Documentation

This Terraform configuration creates a complete VPC infrastructure for ECS deployment with proper network segmentation and security.

## Infrastructure Overview

The setup creates a VPC with the following components:
- **VPC**: Main network container
- **Public Subnets**: For internet-facing resources
- **Private Subnets**: For internal resources
- **Internet Gateway**: Provides internet connectivity
- **Route Tables**: Control traffic flow
- **Route Table Associations**: Link subnets to route tables

## Architecture Diagram

```
Internet
    │
    ▼
┌─────────────────┐
│ Internet Gateway│
└─────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│                        VPC                            │
│  ┌─────────────────┐    ┌─────────────────┐          │
│  │ Public Subnet 1 │    │ Public Subnet 2 │          │
│  │ (us-east-1a)    │    │ (us-east-1b)    │          │
│  │ 10.0.1.0/24     │    │ 10.0.2.0/24     │          │
│  └─────────────────┘    └─────────────────┘          │
│           │                       │                   │
│           ▼                       ▼                   │
│  ┌─────────────────┐    ┌─────────────────┐          │
│  │ Private Subnet 1│    │ Private Subnet 2│          │
│  │ (us-east-1a)    │    │ (us-east-1b)    │          │
│  │ 10.0.3.0/24     │    │ 10.0.4.0/24     │          │
│  └─────────────────┘    └─────────────────┘          │
└─────────────────────────────────────────────────────────┘
```

## Step-by-Step Implementation

### 1. Variables Configuration (`variables.tf`)

#### Purpose
Define configurable parameters for the infrastructure to make it reusable and maintainable.

#### Key Variables:
- **`region`**: AWS region (default: us-east-1)
- **`vpc_cidr`**: Main VPC CIDR block (default: 10.0.0.0/16)
- **`public_subnet_cidrs`**: CIDR blocks for public subnets
- **`private_subnet_cidrs`**: CIDR blocks for private subnets
- **`availability_zones`**: AWS availability zones for high availability

### 2. Provider Configuration (`providers.tf`)

#### Purpose
Configure the AWS provider to specify which region and credentials to use.

#### Configuration:
```hcl
provider "aws" {
  region = "us-east-1"
}
```

### 3. VPC Creation (`vpc.tf`)

#### Step 1: Create VPC
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}
```
**Purpose**: Creates the main network container
- **`cidr_block`**: Defines the IP range (10.0.0.0/16)
- **`enable_dns_support`**: Enables DNS resolution within VPC
- **`enable_dns_hostnames`**: Enables DNS hostnames for instances

#### Step 2: Create Public Subnets
```hcl
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = true
}
```
**Purpose**: Creates subnets for internet-facing resources
- **`count`**: Creates multiple subnets using the count parameter
- **`map_public_ip_on_launch`**: Automatically assigns public IPs to instances
- **Availability Zones**: Distributes across multiple AZs for high availability

#### Step 3: Create Private Subnets
```hcl
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
}
```
**Purpose**: Creates subnets for internal resources (no direct internet access)

#### Step 4: Create Internet Gateway
```hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
```
**Purpose**: Provides internet connectivity to the VPC

#### Step 5: Create Public Route Table
```hcl
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}
```
**Purpose**: Routes traffic from public subnets to the internet
- **`0.0.0.0/0`**: Routes all traffic to the internet gateway

#### Step 6: Associate Public Subnets with Route Table
```hcl
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
```
**Purpose**: Links public subnets to the public route table

#### Step 7: Create Private Route Table
```hcl
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
}
```
**Purpose**: Creates a route table for private subnets (no internet access)

#### Step 8: Associate Private Subnets with Route Table
```hcl
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
```
**Purpose**: Links private subnets to the private route table

### 4. Outputs Configuration (`outputs.tf`)

#### Purpose
Display important resource IDs and information after deployment for reference and use in other modules.

#### Key Outputs:
- VPC ID and CIDR block
- Public and private subnet IDs
- Internet Gateway ID
- Route table IDs

## Network Security Features

### Public Subnets
- ✅ Direct internet access via Internet Gateway
- ✅ Auto-assign public IPs
- ✅ Suitable for load balancers, bastion hosts

### Private Subnets
- ❌ No direct internet access
- ✅ Enhanced security for application servers
- ✅ Suitable for ECS tasks, databases

## Deployment Steps

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Review the Plan**:
   ```bash
   terraform plan
   ```

3. **Apply the Configuration**:
   ```bash
   terraform apply
   ```

4. **View Outputs**:
   ```bash
   terraform output
   ```

## Resource Naming Convention

All resources follow the naming pattern: `ecs-demo-{resource-type}-{identifier}`
- Example: `ecs-demo-vpc`, `ecs-demo-public-subnet-1`

## CIDR Block Allocation

- **VPC**: 10.0.0.0/16 (65,536 IP addresses)
- **Public Subnet 1**: 10.0.1.0/24 (256 IP addresses)
- **Public Subnet 2**: 10.0.2.0/24 (256 IP addresses)
- **Private Subnet 1**: 10.0.3.0/24 (256 IP addresses)
- **Private Subnet 2**: 10.0.4.0/24 (256 IP addresses)

## Best Practices Implemented

1. **High Availability**: Resources distributed across multiple AZs
2. **Security**: Private subnets for sensitive resources
3. **Scalability**: Count-based resource creation
4. **Maintainability**: Variables for easy configuration
5. **Documentation**: Clear resource naming and tagging

## Next Steps

This VPC infrastructure provides the foundation for:
- ECS Cluster deployment
- Application Load Balancer setup
- RDS database deployment
- Security group configuration
- ECS service deployment

## Troubleshooting

### Common Issues:
1. **CIDR Block Conflicts**: Ensure VPC CIDR doesn't overlap with existing networks
2. **Availability Zone Issues**: Verify AZs exist in your region
3. **Route Table Associations**: Check that subnets are properly associated

### Useful Commands:
```bash
# View current state
terraform show

# List all resources
terraform state list

# Destroy infrastructure (if needed)
terraform destroy
```
