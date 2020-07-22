# Terraform + ECSでWordpressを立ち上げる

Terraformで、AWS ECSとRDSを使ったWordpressサイトを立ち上げてみることにします。日本語でもチュートリアル記事は沢山あるんですが、Terraform 0.12+系を扱った記事が現状ではあまりないので、ある程度ニーズあるかな、と思います。



## Terraformとは

> Use Infrastructure as Code to provision and manage any cloud, infrastructure, or service

[Terraform by HashiCorp](https://www.terraform.io/)



Vagrantの[HashiCorp](https://www.hashicorp.com/)が開発した、インフラの構成管理をコードで行うためのツール。



- インフラ環境の改善、拡張、複製が管理・共有できる
- [200以上のプロバイダー](https://www.terraform.io/docs/providers/index.html)で実行可能



## インストール

- terraform v0.12+



```sh
$ brew update
$ brew install tfenv
$ tfenv install 0.12.28
$ tfenv use 0.12.28
```



AWSのクレデンシャルを登録しておいてください。  
こんな感じでプロファイル登録。



```sh
[{profile名}]
aws_access_key_id = AKI**************
aws_secret_access_key = *****************
```



## 初期化

Terraformのプロジェクトディレクトリで、初期化を行います。初期化の際に、プロバイダー毎のプラグインを自動的にダウンロードしてきたりするので、とても重要な処理です。自動的に`.terraform`というフォルダを作成しますが、これは共有禁止です。



```sh
$ terraform init
```



## 確認

構成を変えたらDryRunして内容を確認しましょう。書式のミスとかはここで潰せます。しかしながら、実際にリソースを作成していく際には、多々エラーが起こるものなので、あんま過信しすぎないよう。



```sh
$ terraform plan
```



## 反映！！

実際の反映！ここは慎重に。



```sh
$ terraform apply
```



## 削除

`terraform apply`した後は当然ながら課金が発生したりするので、きちんと`terraform destroy`しておきます。見事、跡形もない状態にしてくれるはず。途中でエラーが発生したりすると、削除処理自体が走らなかったりするので、その時はきちんと確認しておくことをオススメします。意外と時間かかる（RDS立ち上げるのに5分とか）ので、気長に待つのが良い。



```sh
$ terraform destroy
```



---

## 準備

### ECR

今回はAWSなので、ECR（Elastic Container Repository）を使用してDocker Imageを管理します。ここもTerraform管理できるんですが、実際のDocker Imageを操作するのはまた別の作業。ローカルでBuildしたDocker ImageをPushします。



実際にAWSのコンソールを確認すると、下記のようなコマンドを表示できます。



![ecr_images](./img/ecr_images.png)



![ecr_cmds](img/ecr_cmds-5040055.png)



```sh
$ aws ecr get-login-password --region ap-northeast-1 --profile harga | docker login --username AWS --password-stdin *****.dkr.ecr.ap-northeast-1.amazonaws.com
$ docker build -t ***** .
$ docker tag harga_wp:latest *****.dkr.ecr.ap-northeast-1.amazonaws.com/*****:latest
$ docker push *****.dkr.ecr.ap-northeast-1.amazonaws.com/*****:latest
```



## 設定

今回は、以下のような構成でソースを管理しています。



- `/environments`以下に、Terraformのメインソースを配置してあります
  - 実行時は、`/enviroments/*****`以下をワークディレクトリとします
    - `/environments/production`が本番環境のワークディレクトリ
      - ここにはありませんが、ステージングを作るのであれば、`/environments/staging`がワークディレクトリになると思います
    - それぞれの環境で`terraform init`を行うため、それぞれのディレクトリに`.terraform`が生成されます
  - メインのコードは`main.tf`に記述しています
  - この実行環境管理については、色々なプラクティスがあるんですが、試した結果これが一番効率良さそう
    - Workspaceという機能で環境を分けられるんですが、ソース内分岐が増えて見通しが悪くなりそうなので、今回は却下
- **tfstate**: 現在の状態を記録するファイル
  - 作成したリソースのIDなどが記録されている重要なファイルです
  - 一度構成が固まったらプロジェクト管理者同士で共有するのが良さそうだが、ソースには含めない（`.gitignore`すること）
- **tfvars**: 変数を記録するファイル
  - トークンなどが含まれるのでソースには含めない
  - `.tfvars.default`をコピーして使いましょう
- `/modules`以下に、実際の構成が記述されていきます
  - `.tf`ファイルが自動的に読まれます
  - 依存関係などを勝手に判断してくれる（！）ので、好き勝手に書いちゃって大丈夫です
    - とはいえ、依存関係を明示したい場合は、それはそれできちんと指定できる



```
.
├── environments
│   └── production
│       ├── main.tf
│       ├── terraform.tfstate
│       ├── terraform.tfstate.backup
│       ├── terraform.tfvars
│       └── terraform.tfvars.default
└── modules
    └── ecs
        ├── alb.tf
        ├── ecs.tf
        ├── iam.tf
        ├── log.tf
        ├── rds.tf
        ├── route53.tf
        ├── templates
        │   └── ecs.json
        ├── variables.tf
        └── vpc.tf
```



---

## 記法

### module

他のディレクトリにあるtfファイルを扱うためのブロック。

```
module "ecs" {
  source = "../../modules/ecs"
  build_env = var.build_env
}
```



### provider

利用するサービスプロバイダーを定義する。

```
provider "aws" {
  version = "~> 2.0"
  shared_credentials_file = var.aws_shared_credentials_file
  region  = var.aws_region
  profile = var.aws_profile
}
```

AWS以外にも、様々なサービスを利用できます。

https://www.terraform.io/docs/providers/aws/index.html

サンプルも充実！

https://github.com/terraform-providers/terraform-provider-aws



### resource

利用するサービスの設定を行うブロック。サービスごとに設定項目が異なる。`resource "{サービス}" "{任意のID}"`のような形で設定でき、同一モジュール内他のブロックから`{ID}.{変数名}`という形でアクセスできる。

```
resource "aws_cloudwatch_log_stream" "ecs-log-stream" {
  name           = "ecs-log-group-${var.build_env}"
  log_group_name = aws_cloudwatch_log_group.ecs-log-group.name
}
```

上記resource内変数は、例えば`ecs-log-stream.log_group_name`という形でアクセス可能



### data

サービスの設定を読み込むブロック。`resource`はリソースの作成まで行うが、`data`は読み込みのみ。Terraformでは管理しないサービスの情報を取得する時などに利用できる。



### variable

変数の定義。`variable {変数名} {}`のような形で定義し、環境変数などは各モジュールなどで読み込む。デフォルト値を設定したり、環境（Workspace）に合わせて、デフォルト値を変更したりできる。

```
variable aws_region {
	default = "ap-northeast-1"
}
```



### locals

設定ファイル内でのみ使われる変数

```
locals {
  rds_name = "${var.prefix}-rds-mysql"
}
```





---

## モジュール

### VPC

VPC（Virtual Private Cloud）とは、ネットワーク構成をクラウド上で仮想的に構築したものです。これを使うことでネットワークの「中」と「外」を明示的に構築することができます。



![VPC](https://docs.aws.amazon.com/ja_jp/vpc/latest/userguide/images/custom-route-table-diagram.png)



- [AWS初心者-AWSネットワーク関連用語を基礎からおさらい｜ソニー](https://www.bit-drive.ne.jp/managed-cloud/column/column_31.html)
- [VPC - Terraformで構築するAWS](https://y-ohgi.com/introduction-terraform/handson/vpc/)
- [AWSのVPCって何？メリットや使えるシーンなど徹底解説！｜TECH PLAY Magazine ［テックプレイマガジン］](https://techplay.jp/column/541)




### サブネット

ネットワークを分割して作った小さなネットワーク。サブネットごとに、セキュリティ設定を変更したりできる。



### インターネットゲートウェイ

VPC内部から、外部インターネットにアクセスするためのゲートウェイ。

- [インターネットゲートウェイ - Amazon Virtual Private Cloud](https://docs.aws.amazon.com/ja_jp/vpc/latest/userguide/VPC_Internet_Gateway.html)



### NAT（Network Address Transform）

「プライベートサブネット」から、外部インターネットに接続するためのゲートウェイ。

- [NAT ゲートウェイ - Amazon Virtual Private Cloud](https://docs.aws.amazon.com/ja_jp/vpc/latest/userguide/vpc-nat-gateway.html)



### ルートテーブル

それぞれのサブネットがどこに接続できるのかを記したもの。



### セキュリティグループ

インスタンス単位で設定できるセキュリティ権限。




### ALB（Application Load Balancer）

AWSのロードバランサー。



### Route53

AWSのドメイン管理システム（DNS）

- [TerraformでACM証明書を作成してみた | Developers.IO](https://dev.classmethod.jp/articles/acm-cert-by-terraform/)



### RDS（Relational Database Service）

RDBのマネージドサービス。使いやすくて高機能だが高い。



### ECS（Elastic Container Service）

AWSのDockerコンテナサービス。Dockerが動きます。



### ECR（Elastic Container Repository）

AWSのコンテナリポジトリ。Docker Hubみたいなもので、Docker Imageを管理します。



---

### Workspace

```sh
$ terraform workspace list
$ terraform workspace new stg
$ terraform workspace select stg
```

- [Terraform workspaceを利用して環境毎のリソース名の変更を行う | Goldstine研究所](https://blog.mosuke.tech/entry/2018/06/16/terraform-workspaces/)
- [Terraform 運用ベストプラクティス 2019 ~workspace をやめてみた等諸々~ - 長生村本郷Engineers'Blog](https://kenzo0107.hatenablog.com/entry/2019/04/17/103558)

結論：いろいろきつい



---

## 参照

- [【Terraform + ECS + RDS】Terraform で ECS環境構築してみた - yyh-gl's Tech Blog](https://yyh-gl.github.io/tech-blog/blog/terraform_ecs/)
- [Terraformのベストなプラクティスってなんだろうか | フューチャー技術ブログ](https://future-architect.github.io/articles/20190903/)
- [Terraform職人入門: 日々の運用で学んだ知見を淡々とまとめる - Qiita](https://qiita.com/minamijoyo/items/1f57c62bed781ab8f4d7)
- [【AWS&Docker初心者向け】WordPressをAWSのDockerで公開　~Mac編~ | CodeCampus](https://blog.codecamp.jp/wordpress-aws-docker-mac)




