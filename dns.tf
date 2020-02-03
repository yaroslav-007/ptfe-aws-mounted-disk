resource "aws_route53_record" "ptfe" {
  zone_id = ""
  name    = "ptfe.example.com"
  type    = "A"
  ttl     = "60"
  records = ["${aws_instance.ptfe.private_ip}"]
}


resource "aws_route53_record" "hop" {
  zone_id = ""
  name    = "hop.example.com"
  type    = "A"
  ttl     = "60"
  records = ["${aws_instance.hopping-station.public_ip}"]
}