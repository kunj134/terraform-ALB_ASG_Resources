# ASG creation and RegisterInstances To the existing Targetgroup
module "asg" {
  source = "terraform-aws-modules/autoscaling/aws"

  name = "kunjan-tf-nodejs"

  min_size                  = 1
  max_size                  = 5
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = ["subnet-09a50a0db3bdf9d87", "subnet-0c7ecd015c8189600"]

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      checkpoint_delay       = 600
      checkpoint_percentages = [35, 70, 100]
      instance_warmup        = 60
      min_healthy_percentage = 50
    }
    triggers = ["tag"]

  }

  # Launch template
  launch_template_name        = "kunjan-wp-CICD-Template"
  launch_template_description = "Launch template example"
  update_default_version      = true



  image_id          = "ami-019633e3f003e5dad"
  instance_type     = "t3a.small"
  key_name          = "KunjanKey"
  ebs_optimized     = true
  enable_monitoring = true


  # IAM role & instance profile
  create_iam_instance_profile = true
  iam_role_name               = "example-asg-kunjan"
  iam_role_path               = "/ec2/"
  iam_role_description        = "IAM role example"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AmazonEC2FullAccess = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
    CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    CloudWatchAgentAdminPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"
  }
  instance_market_options = {
    market_type = "spot"
  }
  tags = {
    Name = "terraform-asg-kunjan-nodejs"
  }
}


# Scaling Policy
resource "aws_autoscaling_policy" "asg-policy" {
  count                     = 1
  name                      = "asg-cpu-policy"
  autoscaling_group_name    = module.asg.autoscaling_group_name
  estimated_instance_warmup = 60
  policy_type               = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}

# Loadbalancer attachment
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = module.asg.autoscaling_group_name
  lb_target_group_arn    = "arn:aws:elasticloadbalancing:us-east-2:421320058418:targetgroup/kunjanWP-ASG-LB-TG/9b00e717398b20a9"
}
