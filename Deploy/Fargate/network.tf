# Fetch AZs in the current region
data "aws_availability_zones" "available" {
}

resource "aws_vpc" "main" {
      //okreslamy zakres adres ip, których bedzie 65536 i zaczyna sie od 10.0.0.0 d0 255.255.255.255
    cidr_block = "172.17.0.0/16"
}

# Create var.az_count private subnets, each in a different AZ
resource "aws_subnet" "private" {
    //Tworzy określoną liczbę podsieci w zależności od wartości zmiennej az_count. 
    //Każda podsieć zostanie utworzona w innej Strefie Dostępności (Availability Zone, AZ).
    //ograniczenie do tylko dwóch stref
    count             = var.az_count
   // Funkcja cidrsubnet jest używana do podzielenia głównego bloku CIDR przypisanego do VPC na mniejsze bloki, 
   //które będą używane przez każdą podsieć. Parametry funkcji to:
    //aws_vpc.main.cidr_block: Blok CIDR przypisany do głównej VPC.
   //8: Liczba dodatkowych bitów do dodania do bloku CIDR, co pozwala na podział na mniejsze podsieci.
    //count.index: Indeks pętli count, który jest używany do generowania różnych bloków CIDR dla każdej podsieci.
    //sposób zapisu ip
    cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
    //dynamicznego przypisywania podsieci do różnych Stref Dostępności (AZ) w regionie AWS
    availability_zone = data.aws_availability_zones.available.names[count.index]
    vpc_id            = aws_vpc.main.id
}

# Create var.az_count public subnets, each in a different AZ
resource "aws_subnet" "public" {
    count                   = var.az_count
    cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, var.az_count + count.index)
    availability_zone       = data.aws_availability_zones.available.names[count.index]
    vpc_id                  = aws_vpc.main.id
//zeby instancje mialy zawsze publiczne adresy ip
    map_public_ip_on_launch = true
}

# Internet Gateway for the public subnet
resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.main.id
}


// Ruch z publicznych podsieci jest kierowany do Internet Gateway, co umożliwia pełny dostęp do internetu.
# Route the public subnet traffic through the IGW
resource "aws_route" "internet_access" {
    route_table_id         = aws_vpc.main.main_route_table_id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.gw.id
}

///Publiczne adresy IP są przydzielane do NAT Gateway, aby mogły one komunikować się z internetem.
# Create a NAT gateway with an Elastic IP for each private subnet to get internet connectivity
//tworzy publiczne adresy ip, których ilość jest zgodna z wartością zmiennej az_count, określa, że EIP jest przypisamy do VPC,
//depends_on upewnia się, że EIP są tworzone po utworzeniu ig
resource "aws_eip" "gw" {
    count      = var.az_count
    domain = "vpc"
    depends_on = [aws_internet_gateway.gw]
}

//NAT Gateway: Umożliwia instancjom w prywatnych podsieciach inicjowanie połączeń z internetem (np. do pobierania aktualizacji) 
//bez bezpośredniego narażania ich na dostęp z zewnątrz.
//Prywatne podsieci: Instancje w tych podsieciach nie są bezpośrednio dostępne z internetu,
 //co zwiększa bezpieczeństwo. Mogą jednak inicjować połączenia wychodzące przez NAT Gateway.
///Prywatne podsieci korzystają z NAT Gateway do dostępu do internetu, co pozwala na wychodzący ruch internetowy
// (np. pobieranie aktualizacji) bez bezpośredniego wystawiania instancji w prywatnych podsieciach na internet.
resource "aws_nat_gateway" "gw" {
   // Tworzy określoną liczbę NAT Gateway, zgodnie z wartością zmiennej az_count.
    count         = var.az_count
    // Przypisuje NAT Gateway do publicznej podsieci, wybierając odpowiednią podsieć za pomocą element i count.index.
    //Zatem aws_subnet.public.*.id oznacza listę wszystkich identyfikatorów (id) dla wszystkich zasobów typu aws_subnet z nazwą public.
    //element(aws_subnet.public.*.id, count.index) jest używana w celu dynamicznego przypisania odpowiedniej podsieci do NAT Gateway. Oto jak to działa:
    subnet_id     = element(aws_subnet.public.*.id, count.index)
    //Przypisuje NAT Gateway do odpowiedniego Elastic IP za pomocą element i count.index.
    allocation_id = element(aws_eip.gw.*.id, count.index)
}

//Nowe tabele routingu są tworzone dla prywatnych podsieci i przypisywane, aby zapewnić poprawne trasy ruchu przez NAT Gateway.
# Create a new route table for the private subnets, make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private" {
    //Tworzy określoną liczbę tabel routingu, zgodnie z wartością zmiennej az_count.
    count  = var.az_count
    vpc_id = aws_vpc.main.id
    //Dodaje trasę dla ruchu skierowanego do dowolnego adresu IP (0.0.0.0/0), kierując go przez odpowiedni NAT Gateway.
    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = element(aws_nat_gateway.gw.*.id, count.index)
    }
}

# Explicitly associate the newly created route tables to the private subnets (so they don't default to the main route table)
resource "aws_route_table_association" "private" {
    count          = var.az_count
    subnet_id      = element(aws_subnet.private.*.id, count.index)
    route_table_id = element(aws_route_table.private.*.id, count.index)
}