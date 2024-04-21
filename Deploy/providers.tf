# definiuje ustawienia globalne dla całego pliku konfiguracyjnego Terraform
terraform {
  # mapa, która określa niezbędnych dostawców, czyli usługi chmurowe lub inne platformy, z których Terraform będzie korzystać do zarządzania zasobami.
  required_providers {
    aws = {
      # trybut w bloku aws, który określa źródło dostawcy. W tym przypadku jest to "hashicorp/aws", co oznacza, 
      # że Terraform będzie pobierać dostawcę AWS z publicznego rejestru dostawców prowadzonego przez HashiCorp.
      source  = "hashicorp/aws"
      # atrybut w bloku aws, który określa wymaganą wersję dostawcy AWS. 
      # W tym przypadku "~> 4.16" oznacza, że Terraform będzie korzystać z wersji dostawcy AWS w zakresie od 4.16 do poniżej 5.0.
      version = "~> 4.67.0"
    }
  }
  # deklaracja wersji Terraforma
  required_version = ">= 1.2.0"
}
