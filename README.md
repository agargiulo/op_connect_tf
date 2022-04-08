## 1Password Connect Server Simple AIO AWS Module

### References
* [1Password Connect Server][op-connect-docs]
* [Fargate example][op-fargate-docs]

### Prerequisites
* 1Password account
* 1Password Connect Server - [docs here][op-connect-docs]
* AWS resources:
  * VPC
  * Subnets for ALB and ECS Service
  * TLS Certificate in ACM
    * can be imported to ACM or generated within ACM
  * Route53 Hosted Zone

### Features
* Deploys 1Password `connect-sync` and `connect-api` containers to AWS Fargate
* Configures Application Load Balancer with provided TLS Certificate
* Sets up DNS record(s)

### Module Variable Inputs
* `prefix`: a string to prefix resources with
* `op_creds_base64`
  * `cat 1password-credentials.json | base64 | tr '/+' '_-' | tr -d '=' | tr -d '\n'`
* `op_networking`
  * `vpc_id`: VPC ID e.g. `aws_vpc.example.id` 
  * `subnets`: list of subnet ids for the ALB and ECS Service
* `op_alb`:
  * `inbound_cidr`: where to allow traffic to the ALB from
  * `acm_cert_arn`: ARN of certificate from ACM
  * `domain`: domain name to point at the ALB
    * MUST MATCH the domain name in the ACM certificate
  * `hosted_zone`: the Route53 Hosted Zone for the record pointing to the ALB

### Example:
```hcl
data "dns_a_record_set" "some_source" {
  host = "some_source.your_tld"
}

data "aws_acm_certificate" "your_cert_here" {
  domain = "my-op-connect.some_tld"
}

data "aws_route53_zone" "some_hosted_zone" {
  name = "your_zone.your_tld."
}

module "op_connect" {
  source = "git::https://code.agarg.me/agargiulo/op_connect_tf.git?ref=main"

  op_creds_base64 = "8TQ93COi-F0TDXBxd7si.FAKE.DATA.OiPKkmqKyhiZgIzt1foXN2B"

  op_networking = {
    vpc_id = data.aws_vpc.example.id
    subnets = [aws_subnet.exampleA.id, aws_subnet.exampleB.id]
  }

  op_alb = {
    inbound_cidr = ["${data.dns_a_record_set.some_source[0]}/32"]
    acm_cert_arn = data.aws_acm_certificate.your_cert_here.arn
    domain = data.aws_acm_certificate.your_cert_here.domain
    hosted_zone = data.aws_route53_zone.some_hosted_zone.zone_id
  }
}
```

### Deployed Resource
* (1x) Application Load Balancer (elbv2)
  * (1x) ALB HTTPS Listener
  * (1x) ALB Target Group
* (1x) CloudWatch Log Group (container log streams)
* (1x) ECS Cluster (Fargate)
* (1x) ECS Service (Fargate)
* (1x) ECS Task Definition (Fargate - 1Password `api` and `sync` containers)
* (1x) IAM Role (ECS/Fargate Task Execution)
  * (1x) Policy:
    * `ecr:BatchCheckLayerAvailability`
    * `ecr:BatchGetImage`
    * `ecr:GetAuthorizationToken`
    * `ecr:GetDownloadUrlForLayer`
    * `logs:CreateLogStream`
    * `logs:PutLogEvents`
* (1x) Route53 DNS A Record (Alias for the ALB)
* (2x) AWS Security Groups:
  * ALB Group
    * Ingress from: `var.op_alb.inbound_cidr`
    * Egress to: Fargate security group (See below)
  * Fargate Group
    * Ingress from: 
      * ALB security group (See above)
      * Other fargate containers
    * Egress to: 0.0.0.0/0



[op-connect-docs]: https://developer.1password.com/docs/connect
[op-fargate-docs]: https://developer.1password.com/docs/connect/aws-ecs-fargate
