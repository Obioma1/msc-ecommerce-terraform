
# ------------------------------------------------------------
# Traditional EC2 Baseline
# Launch Template and Auto Scaling Group
# ------------------------------------------------------------

# Retrieve the latest Amazon Linux 2023 AMI
data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# EC2 Launch Template
resource "aws_launch_template" "ecommerce" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_application_profile.name
  }

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  user_data = base64encode(templatefile("${path.module}/ec2/user_data.sh", {
    aws_region  = var.aws_region
    bucket_name = aws_s3_bucket.ecommerce_images.id
  }))

  # user_data = filebase64("${path.module}/ec2/user_data.sh")

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name         = "${var.project_name}-ec2"
      Architecture = "Traditional"
    }
  }
}

# EC2 Auto Scaling Group
resource "aws_autoscaling_group" "ecommerce" {
  name = "${var.project_name}-asg"

  min_size         = 1
  desired_capacity = 1
  max_size         = 3

  vpc_zone_identifier = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  target_group_arns = [
    aws_lb_target_group.ecommerce.arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 300
  default_instance_warmup   = 300

  launch_template {
    id      = aws_launch_template.ecommerce.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-ec2"
    propagate_at_launch = true
  }

  depends_on = [
    aws_lb_listener.http,
    aws_iam_role_policy.ec2_dynamodb_policy
  ]
}

# CPU-based Target Tracking Scaling Policy
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${var.project_name}-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.ecommerce.name
  policy_type            = "TargetTrackingScaling"

  estimated_instance_warmup = 300

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value     = 50.0
    disable_scale_in = false
  }
}

