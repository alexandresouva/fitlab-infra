# 🏗️ FitLab Infrastructure (IaC)

Este repositório centraliza o gerenciamento da infraestrutura de nuvem na AWS para todo o ecossistema de Micro Frontends (MFE) do **FitLab** utilizando **Terraform**.

Seguindo o padrão de Engenharia de Plataforma (*Platform Engineering*), a infraestrutura de nuvem é mantida de forma isolada das aplicações. As aplicações se preocupam apenas com o build e deploy dos arquivos estáticos, enquanto este repositório gerencia as origens, permissões e distribuições globais.

---

## 🗺️ Arquitetura de Nuvem

A arquitetura utiliza uma única distribuição global do **AWS CloudFront** roteando requisições sob o mesmo domínio para múltiplos buckets **AWS S3** privados e isolados:

*   **Estado do Terraform (Remote State):** Armazenado de forma segura e compartilhada no bucket `fitlab-terraform-state-340271092785` com versionamento ativo.
*   **S3 Buckets de Aplicação:**
    *   Shell (Host): `fitlab-mfe-shell-dev`
    *   Workout Planner MFE: `fitlab-mfe-workouts-dev`
*   **CDN Roteamento (CloudFront behaviors):**
    *   `/*` (Padrão) -> Direciona as chamadas para a Shell.
    *   `/workouts/*` -> Direciona as chamadas para o Workout Planner.

---

## 🚀 Como adicionar um novo Micro Frontend (MFE)

O ecossistema é projetado para escalabilidade infinita de forma declarativa. Para adicionar um novo MFE (ex: `timer`):

### 1. Declarar o novo MFE
Edite o arquivo [`terraform/variables.tf`](terraform/variables.tf) e adicione o nome do MFE na lista da variável `micro_frontends`:

```hcl
variable "micro_frontends" {
  type    = list(string)
  default = ["workouts", "timer"] # <-- Adicionado "timer"
}
```

### 2. Aplicar a Infraestrutura
Faça o commit e envie para a branch `main` deste repositório (ou execute localmente na pasta `terraform/`):
```bash
terraform apply -auto-approve
```
Isso criará automaticamente o bucket `fitlab-mfe-timer-dev` no S3 e criará as rotas de Behavior correspondentes no CloudFront.

### 3. Configurar a Esteira do Novo MFE
No pipeline do repositório da aplicação do novo MFE (`fitlab-mfe-timer`), configure o deploy para sincronizar com o novo bucket gerado:
```bash
aws s3 sync dist/ s3://fitlab-mfe-timer-dev/timer/ --delete
```

---

## 🛠️ Executando Localmente

Para rodar o Terraform de forma local na sua máquina, certifique-se de possuir credenciais AWS ativas no terminal e execute:

```bash
cd terraform/
terraform init -reconfigure
terraform plan
terraform apply
```
