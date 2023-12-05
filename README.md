# Arquitetura Cloud na AWS com Terraform

## Objetivo do projeto

Provisionar uma arquitetura na AWS utilizando o Terraform, que englobe o uso de instâncias EC2 com uma aplicação API simples contendo Application Load Balancer (ALB) e Auto Scaling, contando também com umbanco de dados RDS .

## Desenho da arquitetura

<img src="/img/Diagrama.jpg">

## Explicando a arquitetura

### Aplicação

A aplicação que roda dentro das maquinas é um CRUD bem simples que está em repositório publico, sendo iniciado toda vez que uma maquina nova sobe. Os comandos usados estão dentro do user_data definido no lauch teamplate.


### VPC (Virtual Private Cloud)


A configuração da VPC (Virtual Private Cloud) é fundamental para a rede AWS. A VPC isola recursos, enquanto subnets organizam com base no acesso. Subnets públicas permitem conexão à Internet, enquanto as privadas limitam-se à VPC, garantindo segurança.

Elementos-chave incluem o Internet Gateway, que facilita comunicação VPC-Internet, e as Route Tables, que direcionam o tráfego na VPC de forma eficiente. Esses componentes são vitais para uma VPC funcional.

### ALB (Load Balancer)

O Balanceador de Carga de Aplicações (ALB) desempenha um papel central na administração e distribuição do tráfego de entrada entre as instâncias do EC2. Especialmente projetado para aplicações baseadas em HTTP/HTTPS, o ALB oferece funcionalidades avançadas, como o roteamento baseado em conteúdo, otimizando a distribuição do tráfego de maneira inteligente.

O Grupo de Destino (Target Group) é configurado com um teste de integridade (health check), garantindo que apenas as instâncias saudáveis estejam aptas a receber tráfego. Essa abordagem não apenas aprimora a confiabilidade e disponibilidade da aplicação, mas também permite uma resposta ágil a possíveis problemas que possam surgir nas instâncias.

O Listener no ALB é ajustado para garantir que as solicitações na porta 80 (HTTP) sejam redirecionadas para o grupo de destinos apropriado. Essa configuração é crucial para uma gestão eficaz e segura do tráfego de entrada.

### EC2 com Auto Scaling

Template de Lançamento (Launch Template): O template de lançamento estabelece os parâmetros essenciais das instâncias EC2, como a imagem da máquina Amazon (AMI) e o tipo de instância. Ao incorporar um script de inicialização, o template automatiza a configuração das instâncias com todas as dependências necessárias, promovendo uma inicialização eficiente e padronizada das novas instâncias.

Grupo de Dimensionamento Automático (Auto Scaling Group - ASG): O ASG desempenha um papel vital na escalabilidade da aplicação, ajustando automaticamente o número de instâncias EC2 em resposta à demanda. Essa funcionalidade garante que a aplicação mantenha um desempenho estável e responsivo diante de variações na carga de trabalho. Além disso, o ASG é configurado para distribuir as instâncias em diversas zonas de disponibilidade, assegurando a resiliência da aplicação em situações de falhas.

Alarmes do CloudWatch: Os alarmes do CloudWatch são implementados para monitorar métricas críticas, como a utilização da CPU. Esses alarmes capacitam o ASG a ajustar dinamicamente o número de instâncias, mantendo a aplicação otimizada para a demanda atual.

### DATABASE -- RDS 

A instância do Amazon RDS está adequadamente configurada para utilizar o MySQL, com ênfase na garantia de alta disponibilidade e segurança dos dados. Para assegurar a continuidade dos negócios e possibilitar uma recuperação rápida em caso de falhas, foram implementados recursos como backups automáticos e a opção Multi-AZ.

Além disso, a configuração da instância RDS foi realizada nas sub-redes privadas, o que impede o acesso direto pela Internet. Essa medida reforça a segurança do ambiente, protegendo os dados armazenados na instância contra ameaças externas.


### S3 (Backend)


O Amazon S3 é um serviço essencial na AWS, oferecendo a capacidade de armazenar diversos tipos de arquivos, como imagens, vídeos, documentos e mais. Desempenha um papel fundamental na construção da arquitetura na AWS, servindo como o repositório principal para os arquivos da aplicação.

A primeira etapa envolve a criação de um "bucket", que é o local destinado ao armazenamento dos arquivos. Nesse processo, é possível especificar o nome do bucket, a região onde será criado, entre outras configurações.

Importante ressaltar que a criação do bucket deve ser realizada diretamente no site da AWS, na seção dedicada ao S3.


### Custos

Uma possivel melhoria nesses valores seria fazer o uso de um RDS com maior definição de tamanho já que o criado é de 10 GB com backup de 5 dias, mas para o mundo real deveriamos rodar a aplicação por um tempo para detectar qual seria o melhor tamanho.
O valor não é muito alto tendo em vista que o maior gasto é com o banco de dados em si.


### Guia Utilização 
1. *Pré-requisitos*: Verifique se o Terraform e a AWS CLI estão instalados.
2. *Criação das Chaves de Acesso AWS*: Acesse o IAM na AWS, crie um novo usuário com acesso programático e anote as chaves de acesso.
3. *Configuração da AWS CLI*: Use o comando aws configure para inserir suas credenciais e configurações regionais.
4. *Criação do Bucket S3*: Crie um bucket S3 pelo dashboard da AWS para armazenar o estado do Terraform e atualize o nome do bucket no arquivo main.tf na parte inicial do codigo.
5. *Inicialização do Terraform*: Prepare seu ambiente com terraform init.
6. *Aplicação do Terraform*: Implemente a infraestrutura com terraform apply -auto-approve.
7. *Validação*: Após a aplicação, use o link de output (link_to_docs) para acessar a documentação da aplicação e verificar se ela está funcionando corretamente.
8. *Destruição da Infraestrutura*: Destrua a infraestrutura com terraform destroy -auto-approve.

<img src="/img/custo.png">