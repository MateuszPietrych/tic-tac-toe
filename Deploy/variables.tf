variable "aws_region" {
    description = "The AWS region things are created in"
    default  = "us-east-1"
}

//Rola IAM, która pozwala ECS uruchamiać zadania na 
//instancjach EC2, zapewniając dostęp do zasobów, takich jak ECR (Elastic Container Registry) i CloudWatch.
//Rola wykonawcza zadania ECS dla Fargate (ec2_task_execution_role_name) jest nadal potrzebna, ale odnosi się do Fargate, 
//gdyż kontenery Fargate również potrzebują dostępu do zasobów AWS, 
//takich jak rejestr ECR, do pobierania obrazów kontenerów i wysyłania logów do CloudWatch.
variable "ec2_task_execution_role_name" {
    description = "ECS task execution role name"
    default = "myEcsTaskExecutionRole"
}

//Rola IAM używana przez ECS do automatycznego skalowania usług,
// zapewniająca dostęp do Auto Scaling.
//Rola autoskalowania ECS (ecs_auto_scale_role_name)
// może być używana do automatycznego skalowania zadań Fargate, 
//aby dostosować się do zmieniającego się obciążenia.
variable "ecs_auto_scale_role_name" {
    description = "ECS auto scale role name"
    default = "myEcsAutoScaleRole"
}

// służy do określenia liczby Stref Dostępności (AZ - Availability Zones)
// do pokrycia w danym regionie AWS. Jest to zmienna, która może być używana 
//w innych częściach konfiguracji Terraform do dynamicznego definiowania liczby AZs,
// które mają być używane, na przykład w przypadku tworzenia zasobów takich jak VPC, subnets, czy grupy autoskalowania.
variable "az_count" {
    description = "Number of AZs to cover in a given region"
    default = "1"
}


//liczba kontenerów
variable "app_count" {
    description = "Number of docker containers to run"
    default = 1
}

//definiuje ścieżkę URL, która będzie używana do sprawdzania stanu zdrowia aplikacji lub serwisu.
// Jest to częsta praktyka w kontekście konfiguracji load balancerów (np. AWS Application Load Balancer, ALB),
// które używają tej ścieżki do okresowego sprawdzania, czy serwisy za nimi działają prawidłowo.
variable "health_check_path" {
  default = "/"
}

variable "fargate_cpu" {
    description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
    default = "1024"
}

variable "fargate_memory" {
    description = "Fargate instance memory to provision (in MiB)"
    default = "2048"
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "labRole"
}

variable "app_image" {
    description = "Docker image to run in the ECS cluster"
    default = "bradfordhamilton/crystal_blockchain:latest"
}

variable "app_port" {
    description = "Port exposed by the docker image to redirect traffic to"
    default = 3000

}

variable "backend_image" {
    description = "Docker image to run in the ECS cluster"
    default = "471112957000.dkr.ecr.us-east-1.amazonaws.com/tic-tac-toe-spring:latest"
}

variable "backend_port" {
    description = "Port exposed by the docker image to redirect traffic to"
    default = 8080
}

variable "frontend_image" {
    description = "Docker image to run in the ECS cluster"
    default = "471112957000.dkr.ecr.us-east-1.amazonaws.com/tic-tac-toe-react:latest"
}

variable "frontend_port" {
    description = "Port exposed by the docker image to redirect traffic to"
    default = 3000
}

variable "app_cpu" {
    description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
    default = "1024"
}

variable "app_memory" {
    description = "Fargate instance memory to provision (in MiB)"
    default = "2048"
}
