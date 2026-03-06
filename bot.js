require('dotenv').config()
const { WechatyBuilder } = require('wechaty')
const axios = require('axios')

// Kimi API配置
const KIMI_API_KEY = process.env.KIMI_API_KEY
const KIMI_API_URL = 'https://api.moonshot.cn/v1/chat/completions'

// 检查API Key是否配置
if (!KIMI_API_KEY) {
  console.error('错误: 请在 .env 文件中配置 KIMI_API_KEY')
  console.error('示例: KIMI_API_KEY=your_api_key_here')
  process.exit(1)
}

/**
 * 调用Kimi大模型API
 * @param {string} userMessage - 用户消息
 * @returns {Promise<string>} - AI回复
 */
async function callKimiAPI(userMessage) {
  try {
    const response = await axios.post(
      KIMI_API_URL,
      {
        model: 'kimi-k2.5',
        messages: [
          {
            role: 'system',
            content: '你是一个友好的AI助手，请用简洁明了的方式回答用户问题。'
          },
          {
            role: 'user',
            content: userMessage
          }
        ],
        temperature: 1,
        max_tokens: 2000
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${KIMI_API_KEY}`
        }
      }
    )

    return response.data.choices[0].message.content
  } catch (error) {
    console.error('调用Kimi API失败:', error.response?.data || error.message)
    return '抱歉，我现在遇到了一些问题，请稍后再试。'
  }
}

const wechaty = WechatyBuilder.build()

wechaty
  .on('scan', (qrcode, status) => {
    console.log(`扫描二维码登录: ${status}`)
    console.log(`https://wechaty.js.org/qrcode/${encodeURIComponent(qrcode)}`)
  })
  .on('login', user => {
    console.log(`用户 ${user} 登录成功`)
  })
  .on('message', async message => {
    try {
      console.log(`收到消息: ${message}`)
      
      // 跳过自己发的消息
      if (message.self()) {
        return
      }

      // 获取消息内容
      const text = message.text()
      const room = message.room() // 获取群聊对象
      const contact = message.from() // 获取发送者

      // 私聊处理
      if (!room) {
        console.log(`[私聊] 来自 ${contact.name()}: ${text}`)
        
        // 调用Kimi API获取回复
        const reply = await callKimiAPI(text)
        console.log(`[私聊] 回复: ${reply}`)
        
        // 发送回复
        await message.say(reply)
      } 
      // 群聊处理
      else {
        const topic = await room.topic()
        console.log(`[群聊] ${topic} - ${contact.name()}: ${text}`)
        
        // 检查是否被@
        const mentionSelf = await message.mentionSelf()
        
        if (mentionSelf) {
          console.log(`[群聊] 机器人被@了`)
          
          // 获取@之后的消息内容
          const mentionText = await message.mentionText()
          console.log(`[群聊] 提取的内容: ${mentionText}`)
          
          // 调用Kimi API获取回复
          const reply = await callKimiAPI(mentionText)
          console.log(`[群聊] 回复: ${reply}`)
          
          // 在群里回复（会自动@发送者）
          await room.say(reply, contact)
        }
      }
    } catch (error) {
      console.error('处理消息时出错:', error)
    }
  })

wechaty.start()
  .then(() => {
    console.log('Wechaty 启动成功！')
    console.log('请确保已设置环境变量 KIMI_API_KEY')
  })
  .catch(error => {
    console.error('Wechaty 启动失败:', error)
  })
