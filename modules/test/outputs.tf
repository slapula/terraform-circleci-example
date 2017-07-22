output "availability_zones" {
  value = ["${data.aws_availability_zones.all_zones.names}"]
}

output "asg-elb-dns" {
  value = "${aws_elb.asg-elb.dns_name}"
}
