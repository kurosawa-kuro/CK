../script/reset-hard.sh

この大量の問題群を精査して、  
**CKAD本番直前2日間で「先に完璧にすべき問題」と「後回しにしていい問題」**を明確に振り分けます。

---

## ✅ 判断基準

| 分類 | 意図 |
|------|------|
| 🟩 先に完璧にすべき | 基本リソースで確実に満点を取れる／出題頻度が高い／構造がシンプル |
| 🟨 後回しだが拾えるなら拾う | 応用だが得点源になりうる／理解しやすければやる価値あり |
| 🟥 捨ててよい or 最後に一気見 | 出題頻度が低い／重い／時間を食いやすい or CKAD範囲外（helmなど） |

---

## ✅ 各問題の分類とコメント

| 問題番号 | 優先 | 技術内容 | コメント |
|----------|------|-----------|----------|
| 1        | 🟩   | `Podログ + ラベルselector` | 基本操作・早く処理できる、完璧にすべき |
| 2        | 🟩   | `Secret更新（envFrom）` | CKAD頻出。修正構文に慣れるべき |
| 3        | 🟩   | `ConfigMap + volumeMount` | 必須分野。テンプレ再現に自信を持ちたい |
| 4        | 🟨   | `マルチコンテナ + ConfigMapマウント` | 応用系、余裕があればやる |
| 5        | 🟩   | `RBACでPod一覧権限修正` | 出題数少なめだが、読解力確認に良い。部分点狙いでも価値あり |
| 6        | 🟥   | `NetworkPolicy` | 出たら拾う。試験では最小構文を暗記だけしておく戦略でOK |
| 7        | 🟨   | `Resource制限（LimitRange）` | 出題数少ないが、構造は軽い。余裕があれば習得 |
| 8        | 🟨   | `CronJob構文・Job生成` | 最小構文だけ覚えれば得点源、深追いは不要 |
| 9        | 🟨   | `マルチコンテナ + emptyDir共有` | 応用系だがvolume理解の確認に最適。演習価値あり |
| 10       | 🟨   | `SecurityContext` | 余裕があれば演習。試験頻度は低め |
| 11       | 🟥   | `Ingress` | 構文重く、クラスタ依存。最小構文だけ暗記戦略で十分 |
| 12       | 🟨   | `Canary Deployment` | CKADっぽくないが設問がわかりやすいなら拾う |
| 13       | 🟩   | `Service selector修正` | めちゃくちゃ頻出。完璧にしておくべき |
| 14       | 🟩   | `RollingUpdate戦略` | 出題多い。`maxSurge`と`maxUnavailable`に慣れるべき |
| 15       | 🟩   | `Liveness/Readiness Probe` | 超頻出。httpGet固定で書けるようにする |
| 16       | 🟥   | `Helm` | CKAD対象外。完全スキップでOK |
| 17       | 🟩   | `PVC Pending → PV条件不一致修正` | PVC/PVマッチングはよく出る。必ずできるように |
| 18       | 🟩   | `Podエラー原因修正（イメージ・構文など）` | 出題頻度高、現場力も試される、完璧にすべき |

---

## 🎯 最優先で「完璧」にすべき問題（復習・再現順）

1. 問題1（ログ・Pod選択）
2. 問題2（Secretの修正）
3. 問題3（ConfigMapマウント）
4. 問題5（RBACエラー調査）
5. 問題13（Service接続）
6. 問題14（RollingUpdate）
7. 問題15（Probes）
8. 問題17（PVC→PV）
9. 問題18（Pod起動失敗の調査）

👉 **これだけで6〜8割の得点ゾーンをカバーできます。**

---

## 🔥 学習効率を上げる実行例（直前2日）

| 時間帯 | タスク |
|--------|--------|
| 午前   | 問題1,2,3,13（手癖を固める） |
| 午後   | 問題14,15,17,18（中核技術に集中） |
| 夜     | 問題5（RBAC読解）、3問通し模試 |

---

必要であれば、「この優先順で並んだYAML再現セット（+構造確認チェックリスト）」も作成できます。欲しいですか？

=========================================================
問題1
=========================================================
環境準備

../script/reset-hard.sh

次のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/1/resources.yaml

問題
filter名前空間では、pod-1からpod-10までの10個のPodが実行されています。それぞれのPodには、app: "Pod名"のラベルが付与されています。以下のラベルを持つPodのログを、/etc/pods.logに出力して下さい。

app: pod-3
app: pod-7
app: pod-8

---------------------------------------------------------
---------------------------------------------------------

・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題2
=========================================================
環境準備

次のコマンドを実行して、問題に必要なリソースをデプロイして下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/2/resources.yaml



問題

credential名前空間で、login Deploymentが実行するコンテナは環境変数USERNAMEとPASSWORDをcreds Secretから参照しています。credsが保持しているPASSWORDの値をmy-new-passwordに変更して下さい。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・





・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・

=========================================================
問題3
=========================================================
環境準備

1. wgetコマンドを使用して、以下のURLからファイルをダウンロードして下さい。

wget https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/3/updated_index.html



2. 次のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/3/resources.yaml



問題

web名前空間で実行されているmy-web Deploymentは、nginxイメージコンテナを実行するPodを管理しています。DeploymentはNodePortタイプのサービスで公開されており、curl controlplane:32100を実行してコンテナに接続できます。コンテナが表示するindex.htmlファイルを、updated_index.htmlに変更する必要があります。

index.htmlをキー、updated_index.htmlファイルをバリューとして保持するConfigMapを作成し、/usr/share/nginx/htmlディレクトリにマウントされているConfigMapを更新して下さい。ConfigMapの名前はnew-index-cmとします

---------------------------------------------------------


---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・




・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・

=========================================================
問題4
=========================================================
環境準備

1. wgetコマンドを実行して、次のURLからfrontend.yamlファイルをダウンロードして下さい。

wget https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/4/frontend.yaml



2. wgetコマンドを実行して、次のURLからhaproxy.cfgファイルをダウンロードして下さい。

wget https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/4/haproxy.cfg



3. 次のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/4/resources.yaml



問題

ambassador名前空間で稼働しているfrontend Podは、ポート番号8080を使用して、５秒毎にapi-serviceに接続します。api-serviceのポート番号は、9090に変更する必要があります。以下のタスクを実行し、frontend Podが引き続きapi-serviceに接続できる様に、新しいコンテナを追加して下さい。



1. api-serviceの公開するポート番号を、9090番に変更して下さい



2. haproxy.cfgファイルを使用して、haproxy-cfgというConfigMapを作成して下さい。



3. frontend Podに、haproxy:alpineイメージを使用したコンテナを追加して下さい。コンテナ名はhaproxyとし、/usr/local/etc/haproxyディレクトリにhaproxy-cfg ConfigMapをマウントして下さい。なお、変更にはfrontend Podのマニフェストファイルであるfrontend.yamlを使用して下さい。



4. frontendコンテナからServiceへの接続が、新しいエンドポイントに正しくプロキシされる様に、接続先をapi-serviceからlocalhostに変更して下さい。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・

・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・



=========================================================
問題5
=========================================================
環境準備

次のコマンドを実行して、問題に必要なリソースをデプロイして下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/5/resources.yaml



問題

service名前空間で実行されるpod-reader Deploymentは、5秒ごとに"kubectl get pods"コマンドを実行します。

現在、Deploymentのログにはエラーメッセージが出力されています。以下のタスクを実行し、エラーを修正して下さい。なお、解答に必要なリソースは全て作成されており、新しいリソースを作成する必要はありません。



1. pod-reader Deploymentのログを確認し、エラーメッセージを調査して下さい。



2. pod-reader Deploymentを修正し、エラーの原因となっている問題を解決して下さい。


---------------------------------------------------------


---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・




=========================================================
問題6
=========================================================
環境準備

次のコマンドを実行して問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/6/resources.yaml



問題

network名前空間では、デフォルトでは全てのPodの内向き（ingress）トラフィックが無効化されています。web Podからapi Podへの内向きのトラフィックを許可するため、api-netpolというNetworkPolicyが作成されましたが、エラーが発生しています。web Podに必要な設定を追加し、api Podへの接続を有効化して下さい。

なお、解答に必要なKubernetesリソースは全て作成されており、新しく作成する必要はありません。また、既存のNetworkPolicyは変更または削除しないでください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題7
=========================================================
環境準備

次のコマンドを実行して問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/7/resources.yaml



問題

resource-management名前空間では、cpu-resource-constraintというLimitRangeによって、CPUリソース使用量の最大値が定義されています。

nginxイメージを使用してmanagedというPodを作成して下さい。なお、Podには以下の条件を満たすリソース管理を設定して下さい。



コンテナのCPUリソース要求として、200mを設定して下さい。

resource-management名前空間に設定された最大cpu制約の半分を、コンテナのリソース制限として設定して下さい。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題8
=========================================================
問題

1. cronという名前空間を作成し、以下の条件を満たすCronJobを作成して下さい。

コンテナイメージはalpineを使用し、CronJobの名前はps-cronとします。ps-cronは"ps aux"コマンドを1分毎に実行し、成功したJobを5、失敗したJobを3まで保存します。また、Jobは開始から6秒経過したPodを終了させます。



2. CronJobからJobを作成して下さい。Job名はps-jobとします。

---------------------------------------------------------


---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・

・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題9
=========================================================
環境準備

1. wgetコマンドを使用して、次のURLからyamlファイルをダウンロードして下さい。

wget https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/9/logger.yaml



2. 次のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/9/resources.yaml



問題

adapter名前空間において、loggerという名前のPodがbusyboxイメージを使用してコンテナを実行しています。このコンテナは、10秒ごとにdateコマンドの結果をJSON形式でinput.logファイルに記録します。PodはemptyDirボリュームを/tmp/logディレクトリにマウントし、input.logファイルをそこに保存します。



Podにfluent/fluentd:edgeイメージを使用したコンテナを追加し、/tmp/log/input.logの内容を/tmp/log/output/ディレクトリ内のbufferファイルに出力します。次の手順を実行して下さい。



コンテナ名をfluentdに設定して下さい

loggerコンテナと共有するボリュームを/tmp/logディレクトリにマウントして下さい。

/fluentd/etcディレクトリにfluentd-configmapをマウントして下さい。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題10
=========================================================
問題

contextという名前空間を作成し、そこにsecure-redisというPodを作成して下さい。コンテナイメージには、redis:alpineを使用し、コンテナのSecurityContextには以下の項目を設定して下さい。



ユーザーID: 2000で実行する。

Privilege escalationをtrueとする。

NET_ADMIN capabilityを付与する。

---------------------------------------------------------
---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題11
=========================================================
環境準備

1. 次のコマンドを実行して、Ingress Controllerをインストールして下さい。

curl -s https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/11/init-ingress.sh | sh



2. 次のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/11/resources.yaml



問題

path-ingress名前空間では、menu-svcとcontact-svcというClusterIPタイプのServiceが、それぞれmenu-appとcontact-appというPodを公開しています。どちらのServiceも、ポート番号は80番を使用します。

contact-svcはinfo-ingressというIngressによってルーティングされ、http://path-ingress.info:31100/contactを使用してcontact-appにアクセスすることが出来ます。



info-ingressを変更し、http://path-ingress.info:31100/menuを使用してmenu-appにアクセスできる設定を追加して下さい。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題12
=========================================================
環境準備

1. wgetコマンドを使用して、次のURLからyamlファイルをダウンロードして下さい。

wget https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/12/payment.yaml



2. 次のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/12/resources.yaml



問題

pay名前空間では、payment  Deploymentがpayment-svcというServiceにより、NodePort番号31120を使用して外部のネットワークに公開されています。

カナリアデプロイメント戦略を利用し、アプリケーションの新しいバージョンをリリースする必要があります。以下のタスクを実行し、新しいバージョンをDeploymentで作成されるレプリカの20％に展開して下さい。また、アプリケーションを実行するレプリカ数の合計は5に設定して下さい。



1. paymentと同じPodの構成で、payment-canary というDeploymentを作成して下さい。app-versionラベルの値には、canaryを設定して下さい。レプリカ数には、アプリケーションを実行する合計の20％を設定して下さい。

（payment.yamlは、payment Deploymentのマニフェストです。ファイルをコピーしてpayment-canary Deploymentの作成に使用して下さい。）



2. payment-svcを更新し、トラフィックの20％をpayment-canaryに送信して下さい。



なお、curl controlplane:31120を実行することでpayment-svcへの接続をテストする事が出来ます。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題13
=========================================================
環境準備

以下のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/13/resources.yaml



問題

server名前空間で作成されているwebapp Podは、bitnami/expressイメージを使用するコンテナを実行しています。Podは同じ名前空間に作成されているwebsvc Serviceによって公開される必要があります。

現在、websvc Serviceを通じてwebapp Podに接続することができません。websvc Serviceの構成を確認し、問題の原因を修正してください。なお、変更はwebsvcにのみ適用し、webapp Podは変更しないで下さい。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題14
=========================================================
問題

1. rolling-updateという名前空間を作成し、rollingという名前のDeploymentを作成して下さい。イメージはredis:6.2-alpineを使用し、レプリカ数は5とします。strategyのtypeにはRollingUpdateを指定し、maxSurgeを20%、maxUnavailableを2に設定して下さい。



2. kubectl setコマンドを実行し、rollingDeploymentが実行するコンテナのイメージをredis:7.2-alpineに更新して下さい。



3. rollingDeploymentを一つ前のリビジョンにロールバックして下さい。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
 問題15
=========================================================
環境準備

1. wgetコマンドを使用して、次のURLからyamlファイルをダウンロードして下さい。

wget https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/15/web.yaml



2. 以下のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/15/resources.yaml



問題

probes名前空間では、webという名前のPodが作成されています。web PodにHTTPリクエストによるLiveness ProbeとReadiness Probeを追加して下さい。詳細は以下のとおりです。



Liveness Probeでは、80番ポートを使用して/liveエンドポイントが正常なステータスコードを返すかどうかを認識します。最初のProbeを実行する前に5秒間待機し、その後、10秒おきに実行されます。

Readiness Probeでは、80番ポートを使用して/readyエンドポイントが正常なステータスコードを返すかどうかを認識します。最初のProbeを実行する前に15秒間待機し、その後、10秒おきに実行されます。



ダウンロードしたweb.yamlは、web Podのマニフェストファイルです。上記のLiveness ProbeとReadiness Probeをweb.yamlに追加し、実行中のPodに変更を適用して下さい。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題16
=========================================================
問題

1. helmにbitnamiという名前のリポジトリを追加して下さい。リポジトリのURLはhttps://charts.bitnami.com/bitnamiを使用して下さい。



2. helm search repoコマンドを使用してbitnami/nginxチャートが存在することを確認して下さい。



3. helmを使用してckad-helm名前空間にbitnami/nginxチャートをインストールして下さい。リリース名はmy-nginxとします。



4. helm listコマンドを実行して、my-nginxがデプロイされていることを確認後、kubectl get deploy コマンドを実行して、レプリカの数を確認して下さい。



5. helm upgradeコマンドを実行して、my-nginxのレプリカ数を2に更新して下さい。

---------------------------------------------------------
helmはＣＫＡＤ対象外なので、スキップ
---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題17
=========================================================
環境準備

1. wgetコマンドを実行し、次のURLから問題に必要なyamlファイルをダウンロードして下さい。

wget https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/17/ckad-pv-claim.yaml



2. 以下のコマンドを実行し、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/17/resources.yaml



問題

persistent名前空間では、ckad-pv Persistent Volumeとckad-pv-claim Persistent Volume Claimが作成されています。ckad-pv は、ckad-pv-claim をバインドする必要があります。

ckad-pv-claimのSTATUSがPendingになっている原因を特定し、Boundになる様に修正して下さい。



なお、修正にはダウンロードしたckad-pv-claim.yamlファイルを使用し、ckad-pv は変更しないで下さい。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題18
=========================================================
環境準備

次のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/18/resources.yaml



問題

session名前空間では、redis-deployという名前のDeploymentが作成されています。このDeploymentは、redis:alpineイメージを使用したコンテナをレプリカ数1で実行することを目的としていますが、現在エラーが発生しており、Podの起動に失敗しています。エラーの原因を特定し、問題を解決して下さい。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・

