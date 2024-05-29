# security.tf
//dostęp z zewnątrz jest potrzebny tylko do frontnedu
//Backend jest dostępny tylko dla frontendu, co zwiększa bezpieczeństwo i kontrolę nad ruchem do backendowych usług aplikacji.
# ALB security Group: Edit to restrict access to the application
//Zezwala na ruch przychodzący na określonym porcie (frontend_port) z dowolnego adresu IP (publiczny dostęp).
//Zezwala na wszelki ruch wychodzący.
resource "aws_security_group" "lb" {
    name        = "cb-load-balancer-security-group"
    description = "controls access to the ALB"
    vpc_id      = aws_vpc.main.id

    ingress {
        protocol    = "tcp"
        from_port   = var.frontend_port
        to_port     = var.frontend_port
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        cidr_blocks = ["0.0.0.0/0"]
    }
}

//Zezwala na ruch przychodzący na określonym porcie (frontend_port), ale tylko z grupy bezpieczeństwa ALB.
//Zezwala na wszelki ruch wychodzący.
# Traffic to the ECS cluster should only come from the ALB
resource "aws_security_group" "ecs_tasks" {
    name        = "cb-ecs-tasks-security-group"
    description = "allow inbound access from the ALB only"
    vpc_id      = aws_vpc.main.id

    ingress {
        protocol        = "tcp"
        from_port       = var.frontend_port
        to_port         = var.frontend_port
        security_groups = [aws_security_group.lb.id]
    }

    egress {
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        cidr_blocks = ["0.0.0.0/0"]
    }
}

//Te konfiguracje zapewniają, że tylko ALB może komunikować się z zadaniami ECS na określonym porcie,
// podczas gdy ALB jest dostępny publicznie na tym samym porcie. To pomaga chronić aplikację,
// ograniczając bezpośredni dostęp do zadań ECS tylko do ruchu pochodzącego z ALB.

//baza danych
    # ALB security Group: Edit to restrict access to the application
resource "aws_security_group" "rds" {
    name        = "rds-security-group"
    description = "controls access to the RDS"
    vpc_id      = aws_vpc.main.id

    ingress {
        protocol    = "tcp"
        from_port   = 3306
        to_port     = 3306
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        cidr_blocks = ["0.0.0.0/0"]
    }
}