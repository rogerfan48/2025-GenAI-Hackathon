import boto3
import json
import urllib.request
from datetime import datetime
import os

APPSYNC_URL = os.getenv('APPSYNC_URL')
API_KEY = os.getenv('API_KEY')

def lambda_handler(event, context):
    # 建立 Bedrock client
    bedrock_runtime = boto3.client('bedrock-runtime', region_name='us-west-2')

    # 解析 event
    body = event['body']
    if isinstance(body, dict):
        pass
    elif isinstance(body, str):
        body = json.loads(body)
    else:
        return { 'statusCode': 400 }

    location = body.get('location', 'none')
    ts = body.get('ts', 'none')
    image_base64 = body.get('image', 'none')
    
    if image_base64 == 'none':
        return { 'statusCode': 400 }

    try:
        datetime.strptime(ts, "%Y-%m-%dT%H:%M:%SZ")
    except ValueError:
        ts = datetime.now().strftime('%Y-%m-%dT%H:%M:%SZ')


    # 構建 Claude 3 Sonnet multimodal 請求
    user_prompt = f"""

    請根據以下圖片的內容，判斷此圖片中是否發生暴力事件，指出衝突等級（嚴重程度）。
    並且，說明影響你判斷等級的理由，以及建議此地管理方採取的行動。
    - 地點：{location}
    - 時間：{ts}
    請仔細觀察圖片細節，讓文字與圖片內容相呼應。
    msg 的內容盡量以客觀的角度描述，level 範圍為 1-5。
    注意！你的判斷將影響管理者將如何行動，務必嚴謹分析，以堅定肯定的語句，作為警報系統用詞。
    """

    payload = {
        "anthropic_version": "bedrock-2023-05-31",
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": f'''
    請根據以下內容回答，並只輸出 JSON，格式為：
    {{
    "msg": str,
    "level": int
    }}
    內容如下：{user_prompt}'''},
                    {
                        "type": "image",
                        "source": {
                            "type": "base64",
                            "media_type": "image/jpeg",  # 或根據你的圖片選 png
                            "data": image_base64
                        }
                    }
                ]
            }
        ],
        "temperature": 0.7,
        "max_tokens": 300
    }

    # 呼叫 Bedrock model
    response = bedrock_runtime.invoke_model(
        modelId="anthropic.claude-3-sonnet-20240229-v1:0",
        body=json.dumps(payload),
        accept="application/json",
        contentType="application/json"
    )

    # # 解析結果
    result = json.loads(response['body'].read().decode('utf-8'))
    generated = json.loads(result['content'][0]['text'])
    # generated = {'msg': 'gg', 'level': 1}

    # 構建 GraphQL mutation 請求
    mutation = """
    mutation {
      createAlert(input: {
        ts: "%s",
        msg: "%s",
        level: %d,
        imgUrl: "%s",
        location: "%s",
        resolved: false
      }) { ts msg level imgUrl location resolved }
    }
    """ % (ts,
           generated['msg'],
           int(generated['level']),
           'data:image/jpeg;base64,' + image_base64,
           location)

    # 發送 GraphQL 請求到 AppSync
    payload = {'query': mutation}
    headers = {
        "Content-Type": "application/json",
        "x-api-key": API_KEY
    }

    req = urllib.request.Request(APPSYNC_URL, headers=headers, data=json.dumps(payload).encode(), method='POST')
    with urllib.request.urlopen(req) as resp:
        response_text = resp.read().decode('utf8')

    # 返回結果
    return {
        'statusCode': 200,
        'body': json.dumps({
            'status': 'success'
        }),
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        }
    }
