//jaki serwis ma wziąc 
//definiuje jak dziala loadBalancer, jak sie skaluje
resource "aws_appautoscaling_target" "target" {
    //Określa, że skalowanie dotyczy usługi ECS.
  service_namespace  = "ecs"
  //dentyfikuje usługę ECS, która ma być skalowana, używając nazwy klastra i usługi.
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  //Określa, że skalowanie dotyczy pożądanej liczby zadań w usłudze ECS.
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = "${data.aws_iam_role.ecs_task_execution_role.arn}"
 //Ustawia minimalną i maksymalną liczbę instancji zadania
  min_capacity       = 1
  max_capacity       = 1
}

# Automatically scale capacity up by one
//jak przekroczy okreslona liczbe procesora, to zwiększa określoną liczbę aplikacji o 1
resource "aws_appautoscaling_policy" "up" {
    //nazwa polityki skalowania w góre
  name               = "cb_scale_up"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    // Okres czasu (w sekundach) po skalowaniu, w którym nowe skalowanie nie będzie inicjowane.
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
    //Dolny limit interwału metryk.
      metric_interval_lower_bound = 0
      //Liczba instancji, o którą należy zwiększyć pojemność.
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

# Automatically scale capacity down by one
resource "aws_appautoscaling_policy" "down" {
  name               = "cb_scale_down"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

# CloudWatch alarm that triggers the autoscaling up policy
resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  alarm_name          = "cb_cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "85"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }

  alarm_actions = [aws_appautoscaling_policy.up.arn]
}

# CloudWatch alarm that triggers the autoscaling down policy
resource "aws_cloudwatch_metric_alarm" "service_cpu_low" {
  alarm_name          = "cb_cpu_utilization_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }

  alarm_actions = [aws_appautoscaling_policy.down.arn]
}