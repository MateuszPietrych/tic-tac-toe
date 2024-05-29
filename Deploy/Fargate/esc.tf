# ecs.tf

resource "aws_ecs_cluster" "main" {
    name = "cb-cluster"
}

//zmienne 
data "template_file" "cb_app" {
    //sciezka do pliku, z ktorego fargate zbuduje kontenery
    template = file("./templates/ecs/cb_app.json.tpl")

    vars = {
        fargate_cpu    = var.fargate_cpu
        fargate_memory = var.fargate_memory
        aws_region     = var.aws_region

        app_cpu         = var.app_cpu
        app_memory      = var.app_memory

        backend_image  = var.backend_image
        backend_port   = var.backend_port
        frontend_image = var.frontend_image
        frontend_port  = var.frontend_port


    }
}

//zadanie na klastrze ecs, 
resource "aws_ecs_task_definition" "app" {
    //nazwa
    family                   = "cb-app-task"
    //rola z jaką wykonuje
    execution_role_arn       = "${data.aws_iam_role.ecs_task_execution_role.arn}"
    //ustawienie seciowe
    network_mode             = "awsvpc"
    //sposób komunikacji między kontenerami
    requires_compatibilities = ["FARGATE"]
    cpu                      = var.fargate_cpu
    memory                   = var.fargate_memory
    container_definitions    = data.template_file.cb_app.rendered
}

//service jest, żeby odpalic zadania z klastra
resource "aws_ecs_service" "main" {
    name            = "cb-service"
    cluster         = aws_ecs_cluster.main.id
    task_definition = aws_ecs_task_definition.app.arn
    desired_count   = var.app_count
    launch_type     = "FARGATE"

    network_configuration {
        security_groups  = [aws_security_group.ecs_tasks.id]
        subnets          = aws_subnet.private.*.id
        assign_public_ip = true
    }

    load_balancer {
        target_group_arn = aws_alb_target_group.app.id
        //nazwa kontenera frontendowego
        container_name   = "frontned"
        container_port   = var.frontend_port
    }

    depends_on = [aws_alb_listener.front_end]
}