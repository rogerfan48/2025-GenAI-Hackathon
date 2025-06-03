# Taiwan Gen AI Applications Hackathon: Snapport - Advantech Co.

## Proposol Outline

本方案聚焦「人潮密集場域即時安全監控」。於端側導入研華 ICAM-540，利用其多路攝影機與 Edge AI 能力，偵測畫面中推擠／衝突姿態；高風險事件以 MQTT 送至 AWS IoT Core，再透過 Lambda 呼叫 AppSync GraphQL，寫入 DynamoDB 並觸發 Subscription，即時推播至雲端儀表。雲端結合 Amazon Bedrock 圖生文功能，為每筆警示生成敘事圖卡，並使用 Amplify Hosting＋CloudFront 發佈 Flutter Web 儀表板，提供執法與管理人員快速查閱管理，系統同步更新歷史表。方案兼具低延遲（端雲併行）、高擴充（全 serverless）及商業價值：可應用於體育館、捷運站、展演空間、易衝突區域等需即時控管監控人潮之場所，協助業者降低群聚風險並提供事後證據，具市場可行性與後續 SaaS 授權潛力。

This project focuses on real-time safety monitoring in high-density public areas. It deploys the Advantech ICAM-540 on the edge, leveraging its multi-camera setup and Edge AI capabilities to detect crowd-pushing or conflict-related postures in video feeds. High-risk events are transmitted via MQTT to AWS IoT Core, which triggers an AWS Lambda function to call AppSync GraphQL. The data is then written into DynamoDB and pushes real-time updates via Subscriptions to a cloud-based dashboard.

The cloud system integrates Amazon Bedrock’s image-to-text capabilities to automatically generate narrative alert cards for each incident. These are published through a Flutter Web dashboard hosted on Amplify Hosting with CloudFront, enabling law enforcement and administrative personnel to quickly access and manage alerts. The system also maintains a synchronized historical log.

This solution offers low latency (edge-cloud parallel processing), high scalability (fully serverless architecture), and commercial value. It is applicable in environments such as stadiums, metro stations, exhibition venues, and other high-conflict-risk areas where real-time crowd monitoring is essential. It helps organizations mitigate the risk of overcrowding and provides post-event evidence, demonstrating strong market viability and potential for future SaaS licensing.

## Amazon AWS Architecture

![Amazon AWS Architecture](https://github.com/user-attachments/assets/50b0fed5-605b-4009-a1d2-0a683612031d)

### What model did we use in Amazon Bedrock

Claude 3.7 Sonnet

## Project Presentation Slide

[presentation.pdf](https://github.com/rogerfan48/2025-GenAI-Hackathon/blob/main/presentation.pdf)

## Project Demo

[Demo Video](https://drive.google.com/file/d/1xsR5o3TdAOiNXzGXnvMhrRhFlFRj-iPE/view)

## Hackathon Presentation Photo

![Hackathon_Presentation Photo](https://github.com/user-attachments/assets/4eb15c89-8901-4aa4-a4c7-95996974a268)
