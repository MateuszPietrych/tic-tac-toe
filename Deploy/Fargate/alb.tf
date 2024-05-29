# alb.tf
//Application Load Balancer (ALB) to usługa oferowana przez Amazon Web Services (AWS) w ramach rodziny
// Elastic Load Balancing (ELB). ALB jest przeznaczony do rozkładania ruchu sieciowego (HTTP/HTTPS)
// w aplikacjach działających na wielu instancjach w różnych strefach dostępności (AZ). 
//bo bedzie za dużo kontenerów, bedzie kilka instancji tej samej aplikacji i jego rolą jest przekazanie pracy tym instancjom,
// które mają jej akutlanie najmniej

resource "aws_alb" "main" {
    name        = "cb-load-balancer"
    subnets         = aws_subnet.public.*.id
    security_groups = [aws_security_group.lb.id]
}

//określa gdzie lb powinien kierować ruch
resource "aws_alb_target_group" "app" {
    name        = "cb-target-group"
    port        = 80
    protocol    = "HTTP"
    vpc_id      = aws_vpc.main.id
    //grupą docelową są adresy ip, anie identyfikatory instancji ec2
    target_type = "ip"

// w razie bezpieczenstwa, jakby load balancer chcial w trakcie gry przerzucic na inna instancje
    stickiness {
      type = "app_cookie"
      enabled = true
      cookie_name = "Cookie"
      cookie_duration = 600
    }

//Definiuje parametry kontroli zdrowia (health check), które ALB będzie używał do monitorowania stanu instancji w grupie docelowej.
    health_check {
        //określa liczbę pomyślnych prób kontroli, aby uznać instanjcę za zdrową
        healthy_threshold   = "3"
        //czas pomiędzy kolejnymi kontrolami
        interval            = "30"
        protocol            = "HTTP"
        //odpowiedz jak git
        matcher             = "200"
        //maksymalny czas oczekiwania na odpowiedz z kontroli zdrowia
        timeout             = "3"
        //Określa ścieżkę URL, której ALB używa do przeprowadzania kontroli zdrowia. 
        path                = var.health_check_path
        //Określa liczbę nieudanych prób kontroli zdrowia wymaganych, aby uznać instancję za niezdrową.
        unhealthy_threshold = "2"
    }
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.main.id
  port              = var.frontend_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.app.id
    type             = "forward"
  }
}