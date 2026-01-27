resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_s3_transport" {
  name = "ansible-s3-transport"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          var.ssm_transport_bucket_arn,
          "${var.ssm_transport_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "secrets_restricted" {
  name        = "${var.project_name}-secrets-policy"
  description = "Restricted policy for Secrets Manager access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "secretsmanager:GetSecretValue"
        Effect   = "Allow"
        Resource = var.secret_arns
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.secrets_restricted.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "app" {
  for_each = { for k, v in var.instances : k => v if v.role != "app" }

  ami                    = coalesce(each.value.ami_id, var.ami_id)
  instance_type          = each.value.instance_type
  subnet_id              = var.subnet_ids[0] 
  vpc_security_group_ids = each.value.security_group_ids
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name         = each.value.name
    Role         = each.value.role
    Project      = var.project_name
    Environment  = var.environment
  }
}

# --- Auto Scaling Group for App ---

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-app-lt-"
  image_id      = coalesce(var.instances["app-server"].ami_id, var.ami_id)
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = var.instances["app-server"].security_group_ids
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-app-asg"
      Role        = "app"
      Project     = var.project_name
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-app-asg"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = var.app_target_group_arns
  health_check_type   = "ELB"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2

  health_check_grace_period = 600
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app-asg-instance"
    propagate_at_launch = true
  }
}
