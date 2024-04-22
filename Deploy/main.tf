# określa dostawcę, który będzie używany w konfiguracji
provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

# definiuje zasob typu "aws_instance", nazwa zasobu to "ec2_proj_1_terraform"
resource "aws_instance" "ec2_proj_1_terraform" {
  # określa ID Amazon Machine Image (AMI), na podstawie którego zostanie utworzona instancja
  ami                    = "ami-080e1f13689e07408"
  # T2 instances are a low-cost, general purpose instance type that provides 
  # a baseline level of CPU performance with the ability to burst above the baseline when needed
  instance_type          = "t2.small"
  # określa nazwę klucza SSH, który ma być używany do uwierzytelniania połączenia z instancją.
  key_name               = "deploy"
  # określa, czy instancja ma mieć przypisany publiczny adres IP
  #associate_public_ip_address = true
  # przypisana grupa zabepieczen
  #vpc_security_group_ids = [aws_security_group.security_group_proj_1_terraform.id]

  tags = {
    Name = "Ec2 Projekt 1 terraform"
  }

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.interface_proj_1.id
  }

  # określa dane użytkownika, które mają zostać przekazane do instancji
  user_data = "${file("install-app.sh")}"
}

# tworzy wirtualną sieć prywatną (VPC) w AWS. VPC jest izolowanym obszarem w chmurze, w którym można uruchamiać zasoby, takie jak instancje EC2
# https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html  <-- VPC
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-availability-zones  <-- Availability Zones

# tworzymy VPC (opis w linku), nazwa tego z zasobu to  "vpc_proj_1_terraform"
resource "aws_vpc" "vpc_proj_1_terraform" {
  # określa zakres adresów IP dla VPC      10.0.0.0/16" == 10.0.0.0 - 10.255.255.255 (10/8 prefix)
  cidr_block           = "10.0.0.0/16"   
  enable_dns_support   = true
  # hosty w VPC to wszystkie zasoby sieciowe, które działają wewnątrz tej sieci, takie jak instancje EC2, kontenery ECS (Elastic Container Service), 
  # instancje RDS (Relational Database Service) czy też inne zasoby usług AWS, które są uruchamiane wewnątrz VPC.
  enable_dns_hostnames = true

  tags = {
    Name = "Vpc Projekt 1 terraform"
  }
}
# tworzy internetową bramę dla VPC, co umożliwia instancjom w VPC dostęp do Internetu oraz komunikację z zewnętrznymi zasobami
resource "aws_subnet" "subnet_proj_1_terraform" {
  # określa identyfikator VPC, do którego podsieć ma być przypisana
  vpc_id     = aws_vpc.vpc_proj_1_terraform.id
  # zakres podsieci, 10.0.1.1 to 10.0.1.255
  cidr_block = "10.0.1.0/24"    

  tags = {
    Name = "Subnet Projekt 1 terraform"
  }
}

resource "aws_internet_gateway" "internet_gateway_proj_1_terraform" {
  # określa identyfikator VPC, do którego brama ma być przypisana
  vpc_id = aws_vpc.vpc_proj_1_terraform.id

  tags = {
    Name = "Gateway Projekt 1 terraform"
  }
}

# pozwala na komuniacje miezy instancjami w VPC, nie potrzebuje tego, ale wymagane jest do stworzenia EIP
resource "aws_network_interface" "interface_proj_1" {
  subnet_id = aws_subnet.subnet_proj_1_terraform.id
  security_groups = [aws_security_group.security_group_proj_1_terraform.id]
}

# pozwala przypisa stałe  IP
resource "aws_eip" "terra_eip" {
  vpc = true
  network_interface = aws_network_interface.interface_proj_1.id
  associate_with_private_ip = aws_network_interface.interface_proj_1.private_ip
  depends_on = [aws_internet_gateway.internet_gateway_proj_1_terraform, aws_instance.ec2_proj_1_terraform]
}

resource "aws_route_table" "route_table_proj_1_terraform" {
  vpc_id = aws_vpc.vpc_proj_1_terraform.id

  route {
  #  czyli to o co jest tutaj zapiasne to: dla okreslonych adresow (wszystkich), przekierowuj je na taki adres
    # oznacza to wszystkie adresy IP
    cidr_block = "0.0.0.0/0"
    # określa identyfikator bramy internetowej, przez którą ma być kierowany ruch dla podanego zakresu adresów IP
    gateway_id = aws_internet_gateway.internet_gateway_proj_1_terraform.id
  }

  tags = {
    Name = "Route table Tic-tac-toe tf"
  }

}

#  laczymy subnet z route table, odnoszac sie do wczesniej stworzonym elementow
resource "aws_route_table_association" "route_table_association_proj_1_terraform" {
  subnet_id      = aws_subnet.subnet_proj_1_terraform.id
  route_table_id = aws_route_table.route_table_proj_1_terraform.id
}

# security group w AWS to zestaw reguł zapory sieciowej, które kontrolują ruch do i z instancji EC2 lub innych zasobów sieciowych w AWS
resource "aws_security_group" "security_group_proj_1_terraform" {

  vpc_id      = aws_vpc.vpc_proj_1_terraform.id
  # (wychodzący) pozwala na cały ruch wychodzący (do wszystkich portów i protokołów) 
  # z instancji zabezpieczonej przez tę grupę do wszelkich adresów IP (0.0.0.0/0).
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress (przychodzący)
  # pozwala na ruch porcie 22 (protokół TCP) z dowolnego adresu IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "SSH"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # pozwala na ruch na porcie 3000 (protokół TCP) z dowolnego adresu IP
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    description = "Backend"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # pozwala na ruch na porcie 5173 (protokół TCP) z dowolnego adresu IP
  ingress {
    from_port   = 5173
    to_port     = 5173
    protocol    = "tcp"
    description = "Frontend"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# pary kluczy w AWS są używane do uwierzytelniania połączeń SSH z instancjami EC2
resource "aws_key_pair" "deployer" {
  key_name = "deploy"
  public_key = "${file("deploy.pub")}"
}
