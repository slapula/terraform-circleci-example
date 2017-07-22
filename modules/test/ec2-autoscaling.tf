resource "aws_launch_configuration" "syn_asg" {
  image_id = "${var.asg_instance_ami}"
  instance_type = "${var.asg_instance_type}"
  security_groups = ["${aws_security_group.syn_web_sg.id}"]
  key_name = "${var.aws_key_name}"
  user_data = <<-EOF
    #!/bin/bash
    yum install -y busybox
    echo "hello, I am WebServer" >index.html
    nohup busybox httpd -f -p 80 &
  EOF

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_availability_zones" "all_zones" {}

resource "aws_autoscaling_group" "syn_asg" {
  launch_configuration = "${aws_launch_configuration.syn_asg.name}"
  availability_zones = ["${data.aws_availability_zones.all_zones.names}"]
  min_size = 1
  max_size = 4
  enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]
  metrics_granularity="1Minute"
  load_balancers= ["${aws_elb.asg-elb.id}"]
  health_check_type="ELB"
  tag {
    key = "Name"
    value = "synoptic-asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "syn_asg_policy" {
  name = "syn_asg_policy"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.syn_asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "cpualarm" {
  alarm_name = "terraform-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "60"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.syn_asg.name}"
  }

  alarm_description = "This metric monitor EC2 instance cpu utilization"
  alarm_actions = ["${aws_autoscaling_policy.syn_asg_policy.arn}"]
}

resource "aws_autoscaling_policy" "syn_asg_policy-down" {
  name = "terraform-autoplicy-down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.syn_asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "cpualarm-down" {
  alarm_name = "terraform-alarm-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "10"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.syn_asg.name}"
  }

  alarm_description = "This metric monitor EC2 instance cpu utilization"
  alarm_actions = ["${aws_autoscaling_policy.syn_asg_policy-down.arn}"]
}

resource "aws_security_group" "syn_web_sg" {
  name = "security_group_for_web_server"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "syn_elb_sg" {
  name = "security_group_for_elb"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "asg-elb" {
  name = "syn-asg-elb"
  availability_zones = ["${data.aws_availability_zones.all_zones.names}"]
  security_groups = ["${aws_security_group.syn_elb_sg.id}"]
#  access_logs {
#    bucket = "synoptic-elb-logs-${var.environment_name}"
#    bucket_prefix = "elb"
#    interval = 5
#  }
  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags {
    Name = "syn-asg-elb"
  }
}

resource "aws_lb_cookie_stickiness_policy" "cookie_stick" {
  name = "cookiestickpolicy"
  load_balancer = "${aws_elb.asg-elb.id}"
  lb_port = 80
  cookie_expiration_period = 600
}
