# AI-Hackathon

## 提案大綱

本方案聚焦「人潮密集場域即時安全監控」。於端側導入研華 ICAM-540，利用其多路攝影機與 Edge AI 能力，偵測畫面中推擠／衝突姿態；高風險事件以 MQTT 送至 AWS IoT Core，再透過 Lambda 呼叫 AppSync GraphQL，寫入 DynamoDB 並觸發 Subscription，即時推播至雲端儀表。雲端結合 Amazon Bedrock 圖生文功能，為每筆警示生成敘事圖卡，並使用 Amplify Hosting＋CloudFront 發佈 Flutter Web 儀表板，提供執法與管理人員快速查閱管理，系統同步更新歷史表。方案兼具低延遲（端雲併行）、高擴充（全 serverless）及商業價值：可應用於體育館、捷運站、展演空間、易衝突區域等需即時控管監控人潮之場所，協助業者降低群聚風險並提供事後證據，具市場可行性與後續 SaaS 授權潛力。

## 採用 Amazon Bedrock 或 SageMaker JumpStart 中的何種基礎模型

Claude 3.7 Sonnet

## GitHub 網站連結

(連結請設為公開，並留存至 2025/12/31)

https://github.com/93wilsonlu/AI-Hackathon


